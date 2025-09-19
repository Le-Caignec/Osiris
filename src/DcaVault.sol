// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {UniV4Swap} from "./UniV4Swap.sol";
import {IDcaVault} from "./interfaces/IDcaVault.sol";
import {IUniV4Swap} from "./interfaces/IUniV4Swap.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DcaPlanLib} from "./lib/DcaPlanLib.sol";

/// @custom:storage-location erc7201:orion.dca.storage
contract DcaVault is UniV4Swap, IDcaVault, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    // ---------- ERC-7201 storage ----------
    /// @custom:storage-location bytes32(uint256(keccak256("erc7201:orion.dca.storage")) - 1) & ~bytes32(uint256(0xff))
    bytes32 private constant DCA_VAULT_STORAGE_LOCATION =
        0x1511ad89e97fa2d26f0cd38fdcc0283783989b1ee4d2e82ca85073f029a77700;

    /// ERC-7201 storage
    struct DcaVaultStorage {
        // Roles/config
        address owner;
        address callbackSender; // authorized CronReactive sender
        IERC20 usdc;
        // Round-robin bounded processing
        address[] users;
        mapping(address => bool) isUserListed;
        uint256 cursor;
        uint256 batchSize;
        // Swap route (must output native)
        PoolKey swapPool;
        bool zeroForOne;
        // User accounting (moved here)
        mapping(address => uint256) usdcBalance;
        mapping(address => uint256) nativeBalance;
        mapping(address => Plan) plans;
    }

    struct Plan {
        IDcaVault.Frequency freq;
        uint128 amountPerPeriod;
        uint64 nextExec;
        bool active;
    }

    constructor(address _router, address _permit2, address _usdc, address _callbackSender, uint256 _batchSize)
        UniV4Swap(_router, _permit2)
    {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        $.owner = msg.sender;
        if (_callbackSender == address(0)) revert IDcaVault.NotCallbackSender();
        $.callbackSender = _callbackSender;
        if (_usdc == address(0)) revert IDcaVault.InvalidSwapRoute();
        $.usdc = IERC20(_usdc);
        $.batchSize = _batchSize == 0 ? 32 : _batchSize;
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
    /// @param active whether the plan is active.
    function setPlan(IDcaVault.Frequency freq, uint256 amountPerPeriod, bool active) external {
        if (amountPerPeriod == 0) revert IDcaVault.AmountZero();
        if (amountPerPeriod > type(uint128).max) revert IDcaVault.AmountTooLarge(); // bound cast
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        Plan storage p = $.plans[msg.sender];
        p.freq = freq;
        // casting to 'uint128' is safe because we bounded amountPerPeriod above
        // forge-lint: disable-next-line(unsafe-typecast)
        p.amountPerPeriod = uint128(amountPerPeriod);
        p.active = active;
        if (p.nextExec == 0 || active) {
            p.nextExec = DcaPlanLib.nextExecutionAfter(block.timestamp, freq);
        }
        DcaPlanLib.ensureUserListed($.isUserListed, $.users, msg.sender);
        emit PlanUpdated(msg.sender, freq, amountPerPeriod, active, p.nextExec);
    }

    /// @notice Pause your DCA plan (keeps schedule and balances).
    function pausePlan() external {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        Plan storage p = $.plans[msg.sender];
        p.active = false;
        emit PlanUpdated(msg.sender, p.freq, p.amountPerPeriod, false, p.nextExec);
    }

    /// @notice Resume your DCA plan. If overdue, schedules the next period from now.
    function resumePlan() external {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        Plan storage p = $.plans[msg.sender];
        p.active = true;
        if (p.nextExec < block.timestamp) {
            p.nextExec = DcaPlanLib.nextExecutionAfter(block.timestamp, p.freq);
        }
        DcaPlanLib.ensureUserListed($.isUserListed, $.users, msg.sender);
        emit PlanUpdated(msg.sender, p.freq, p.amountPerPeriod, true, p.nextExec);
    }

    /// @notice Set the maximum number of users processed per callback tick.
    /// @param _batchSize new batch size (1..256).
    function setBatchSize(uint256 _batchSize) external {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        if (msg.sender != $.owner) revert IDcaVault.NotOwner();
        require(_batchSize > 0 && _batchSize <= 256, "bad batch");
        $.batchSize = _batchSize;
    }

    /// @notice CronReactive tick entrypoint. Aggregates eligible users, swaps once, and distributes output.
    /// @param /*sender*/ CronReactive sender id (not used on-chain, reserved for off-chain correlation).
    function callback(address /*sender*/ ) external {
        DcaVaultStorage storage $ = _getDcaVaultStorage();
        if (msg.sender != $.callbackSender) revert IDcaVault.NotCallbackSender();

        uint256 n = $.users.length;
        if (n == 0) return;

        uint256 bSize = $.batchSize;
        address[] memory bufUsers = new address[](bSize);
        uint256[] memory bufAmounts = new uint256[](bSize);

        uint256 totalIn = 0;
        uint256 m = 0;
        uint256 nowTs = block.timestamp;

        uint256 i = 0;
        uint256 idx = $.cursor;
        while (i < n && m < bSize) {
            address u = $.users[idx];
            Plan storage p = $.plans[u];

            if (p.active && p.nextExec != 0 && p.nextExec <= nowTs) {
                uint256 amt = uint256(p.amountPerPeriod);
                if (amt > 0 && $.usdcBalance[u] >= amt) {
                    bufUsers[m] = u;
                    bufAmounts[m] = amt;
                    totalIn += amt;
                    m++;
                }
            }

            idx = (idx + 1) % n;
            i++;
        }
        $.cursor = idx;

        if (totalIn == 0) {
            return;
        }
        if (totalIn > type(uint128).max) revert IDcaVault.AmountTooLarge(); // bound cast

        // Single swap USDC -> Native, keep proceeds in vault
        PoolKey memory key = $.swapPool; // copy storage to memory for internal call
        bool zf1 = $.zeroForOne;
        // casting to 'uint128' is safe because 'totalIn' was bounded above
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 nativeOut = swapExactInputSingle(key, zf1, uint128(totalIn), 0);

        // Distribute pro-rata and reschedule nextExec with catch-up
        uint256 remainingOut = nativeOut;
        for (uint256 j = 0; j < m; j++) {
            address u2 = bufUsers[j];
            uint256 inAmt = bufAmounts[j];

            $.usdcBalance[u2] -= inAmt;

            uint256 outAmt;
            if (j + 1 == m) {
                outAmt = remainingOut;
            } else {
                outAmt = (nativeOut * inAmt) / totalIn;
                remainingOut -= outAmt;
            }
            $.nativeBalance[u2] += outAmt;

            $.plans[u2].nextExec = DcaPlanLib.catchUpNextExecution($.plans[u2].nextExec, $.plans[u2].freq, nowTs);
        }

        emit CallbackProcessed(m, totalIn, nativeOut);
    }

    function _getDcaVaultStorage() private pure returns (DcaVaultStorage storage $) {
        //slither-disable-start assembly
        assembly ("memory-safe") {
            $.slot := DCA_VAULT_STORAGE_LOCATION
        }
        //slither-disable-end assembly
    }
}
