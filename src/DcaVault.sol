// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {UniV4Swap} from "./UniV4Swap.sol";
import {IDcaVault} from "./interfaces/IDcaVault.sol";
import {IUniV4Swap} from "./interfaces/IUniV4Swap.sol";
import {DcaPlanLib} from "./lib/DcaPlanLib.sol";

/// @custom:storage-location erc7201:orion.dca.storage
contract DcaVault is UniV4Swap, IDcaVault {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    // ---------- ERC-7201 storage ----------
    /// @custom:storage-location bytes32(uint256(keccak256("erc7201:orion.dca.storage")) - 1) & ~bytes32(uint256(0xff))
    bytes32 private constant DCA_VAULT_STORAGE_LOCATION =
        0x1511ad89e97fa2d26f0cd38fdcc0283783989b1ee4d2e82ca85073f029a77700;

    /// ERC-7201 storage
    struct DcaVaultStorage {
        IERC20 usdc;
        // Round-robin bounded processing
        address[] users;
        mapping(address => bool) isUserListed;
        // Swap route (must output native)
        PoolKey swapPool;
        bool zeroForOne;
        // User accounting (moved here)
        mapping(address => uint256) usdcBalance;
        mapping(address => uint256) nativeBalance;
        mapping(address => IDcaVault.DcaPlan) plans;
    }

    constructor(address _router, address _permit2, address _usdc) UniV4Swap(_router, _permit2) {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        if (_usdc == address(0)) revert IDcaVault.InvalidSwapRoute();
        $.usdc = IERC20(_usdc);
        $.zeroForOne = false; // default direction USDC -> Native
        $.swapPool = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(_usdc), // native
            fee: 3000, // default fee tier 0.3%
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
    }

    // ---------- Public getters to preserve interface ----------

    /// @notice Deposit USDC to the vault to fund your DCA.
    /// This function requires prior USDC approval.
    /// @param amount amount of USDC to deposit.
    function depositUsdc(uint256 amount) external {
        if (amount == 0) revert IDcaVault.AmountZero();
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        $.usdc.safeTransferFrom(msg.sender, address(this), amount);
        $.usdcBalance[msg.sender] += amount;
        emit DepositedUSDC(msg.sender, amount);
    }

    /// @notice Withdraw USDC from your vault balance.
    /// @param amount amount of USDC to withdraw.
    function withdrawUsdc(uint256 amount) external {
        if (amount == 0) revert IDcaVault.AmountZero();
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        uint256 bal = $.usdcBalance[msg.sender];
        if (bal < amount) revert IDcaVault.InsufficientUSDC();
        $.usdcBalance[msg.sender] = bal - amount;
        $.usdc.safeTransfer(msg.sender, amount);
        emit WithdrawnUSDC(msg.sender, amount);
    }

    /// @notice Claim accumulated native output from executed DCA swaps.
    /// @param amount amount of native token to claim.
    function claimNative(uint256 amount) external nonReentrant {
        if (amount == 0) revert IDcaVault.AmountZero();
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        uint256 bal = $.nativeBalance[msg.sender];
        require(bal >= amount, "insufficient native");
        $.nativeBalance[msg.sender] = bal - amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert IUniV4Swap.NativeTransferFailed();
        emit ClaimedNative(msg.sender, amount);
    }

    /// @notice Create or update your DCA plan.
    /// @param freq execution frequency (Daily, Weekly, Monthly).
    /// @param amountPerPeriod USDC amount to DCA each period.
    function setPlan(IDcaVault.Frequency freq, uint256 amountPerPeriod) external {
        if (amountPerPeriod == 0) revert IDcaVault.AmountZero();
        if (amountPerPeriod > type(uint128).max) revert IDcaVault.AmountTooLarge(); // bound cast
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        IDcaVault.DcaPlan storage selectedUserPlan = $.plans[msg.sender];
        selectedUserPlan.freq = freq;
        // casting to 'uint128' is safe because we bounded amountPerPeriod above
        // forge-lint: disable-next-line(unsafe-typecast)
        selectedUserPlan.amountPerPeriod = uint128(amountPerPeriod);
        if (selectedUserPlan.nextExecutionTimestamp == 0) {
            selectedUserPlan.nextExecutionTimestamp = DcaPlanLib.nextExecutionAfter(block.timestamp, freq);
        }
        DcaPlanLib.ensureUserListed($.isUserListed, $.users, msg.sender);
        emit PlanUpdated(msg.sender, freq, amountPerPeriod, selectedUserPlan.nextExecutionTimestamp);
    }

    /// @notice Pause your DCA plan (keeps schedule and balances).
    function pausePlan() external {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        IDcaVault.DcaPlan storage selectedUserPlan = $.plans[msg.sender];
        // Mark inactive by zeroing the next execution timestamp
        selectedUserPlan.nextExecutionTimestamp = 0;
        emit PlanUpdated(msg.sender, selectedUserPlan.freq, selectedUserPlan.amountPerPeriod, 0);
    }

    /// @notice Resume your DCA plan. If overdue or inactive, schedules the next period from now.
    function resumePlan() external {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        IDcaVault.DcaPlan storage selectedUserPlan = $.plans[msg.sender];
        if (selectedUserPlan.nextExecutionTimestamp == 0 || selectedUserPlan.nextExecutionTimestamp < block.timestamp) {
            selectedUserPlan.nextExecutionTimestamp =
                DcaPlanLib.nextExecutionAfter(block.timestamp, selectedUserPlan.freq);
        }
        DcaPlanLib.ensureUserListed($.isUserListed, $.users, msg.sender);
        emit PlanUpdated(
            msg.sender, selectedUserPlan.freq, selectedUserPlan.amountPerPeriod, selectedUserPlan.nextExecutionTimestamp
        );
    }

    /// @notice CronReactive tick entrypoint. Aggregates eligible users, swaps once, and distributes output.
    function callback() external {
        DcaVaultStorage storage $ = _getDcaVaultStorage();

        uint256 nbOfUser = $.users.length;
        if (nbOfUser == 0) return;

        address[] memory eligibleUsers = new address[](nbOfUser);
        uint256[] memory eligibleAmounts = new uint256[](nbOfUser);

        uint256 totalIn = 0;
        uint256 eligibleCount = 0;
        uint256 nowTs = block.timestamp;

        for (uint256 i = 0; i < nbOfUser; i++) {
            address selectedUser = $.users[i];
            IDcaVault.DcaPlan storage selectedUserPlan = $.plans[selectedUser];

            if (selectedUserPlan.nextExecutionTimestamp != 0 && selectedUserPlan.nextExecutionTimestamp <= nowTs) {
                uint256 amt = uint256(selectedUserPlan.amountPerPeriod);
                if (amt > 0 && $.usdcBalance[selectedUser] >= amt) {
                    eligibleUsers[eligibleCount] = selectedUser;
                    eligibleAmounts[eligibleCount] = amt;
                    totalIn += amt;
                    eligibleCount++;
                }
            }
        }

        if (totalIn == 0) {
            return;
        }
        if (totalIn > type(uint128).max) revert IDcaVault.AmountTooLarge(); // bound cast

        // Single swap USDC -> Native
        PoolKey memory key = $.swapPool; // copy storage to memory for internal call
        uint256 nativeOut = swapExactInputSingle(key, $.zeroForOne, uint128(totalIn), 0);

        // Distribute pro-rata and reschedule nextExecutionTimestamp with catch-up
        uint256 remainingOut = nativeOut;
        for (uint256 j = 0; j < eligibleCount; j++) {
            address eligibleUser = eligibleUsers[j];
            uint256 eligibleAmount = eligibleAmounts[j];

            $.usdcBalance[eligibleUser] -= eligibleAmount;

            uint256 outAmt;
            if (j + 1 == eligibleCount) {
                outAmt = remainingOut;
            } else {
                outAmt = (nativeOut * eligibleAmount) / totalIn;
                remainingOut -= outAmt;
            }
            $.nativeBalance[eligibleUser] += outAmt;

            $.plans[eligibleUser].nextExecutionTimestamp = DcaPlanLib.catchUpNextExecution($.plans[eligibleUser], nowTs);
        }

        emit CallbackProcessed(eligibleCount, totalIn, nativeOut);
    }

    function _getDcaVaultStorage() private pure returns (DcaVaultStorage storage $) {
        //slither-disable-start assembly
        assembly ("memory-safe") {
            $.slot := DCA_VAULT_STORAGE_LOCATION
        }
        //slither-disable-end assembly
    }
}
