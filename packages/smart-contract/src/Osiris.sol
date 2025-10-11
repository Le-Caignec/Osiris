// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {UniV4Swap} from "./UniV4Swap.sol";
import {IOsiris} from "./interfaces/IOsiris.sol";
import {IUniV4Swap} from "./interfaces/IUniV4Swap.sol";
import {DcaPlanLib} from "./lib/DcaPlanLib.sol";
import {IChainlinkOracle} from "./interfaces/IChainlinkOracle.sol";
import {ChainlinkOracle} from "./ChainlinkOracle.sol";
import {AbstractCallback} from "@reactive-contract/abstract-base/AbstractCallback.sol";
import {AbstractPayer} from "@reactive-contract/abstract-base/AbstractPayer.sol";
/// @title Osiris
/// @notice Project renamed to Osiris; legacy name removed.

contract Osiris is UniV4Swap, IOsiris, AbstractCallback {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    // ---------- ERC-7201 storage ----------
    /// @custom:storage-location bytes32(uint256(keccak256("erc7201:orion.dca.storage")) - 1) & ~bytes32(uint256(0xff))
    bytes32 private constant OSIRIS_STORAGE_LOCATION =
        0x68511e06a47e02615622d3067a6e76777b4a7762af923f31d7c600643617a500;

    /// ERC-7201 storage
    struct OsirisStorage {
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
        mapping(address => IOsiris.DcaPlan) plans;
        uint256 totalUsdc; // aggregate total of user USDC balances
        // Chainlink Oracle for price feeds and volatility
        IChainlinkOracle oracle;
    }

    constructor(address _router, address _permit2, address _usdc, address _callbackSender, address _ethUsdFeed)
        payable
        UniV4Swap(_router, _permit2)
        AbstractCallback(_callbackSender)
    {
        OsirisStorage storage $ = _getOsirisStorage();
        if (_usdc == address(0)) revert IOsiris.InvalidSwapRoute();
        $.usdc = IERC20(_usdc);
        $.zeroForOne = false; // default direction USDC -> Native
        $.swapPool = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(_usdc), // native
            fee: 3000, // default fee tier 0.3%
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });

        // Initialize Chainlink Oracle
        $.oracle = new ChainlinkOracle(_ethUsdFeed);
    }

    // ---------- Public getters to preserve interface ----------

    /// @notice Deposit USDC to the vault to fund your DCA.
    /// This function requires prior USDC approval.
    /// @param amount amount of USDC to deposit.
    function depositUsdc(uint256 amount) external {
        if (amount == 0) revert IOsiris.AmountZero();
        OsirisStorage storage $ = _getOsirisStorage();
        $.usdc.safeTransferFrom(msg.sender, address(this), amount);
        $.usdcBalance[msg.sender] += amount;
        $.totalUsdc += amount;
        emit DepositedUSDC(msg.sender, amount);
    }

    /// @notice Withdraw USDC from your vault balance.
    /// @param amount amount of USDC to withdraw.
    function withdrawUsdc(uint256 amount) external {
        if (amount == 0) revert IOsiris.AmountZero();
        OsirisStorage storage $ = _getOsirisStorage();
        uint256 bal = $.usdcBalance[msg.sender];
        if (bal < amount) revert IOsiris.InsufficientUSDC();
        $.usdcBalance[msg.sender] = bal - amount;
        $.totalUsdc -= amount;
        $.usdc.safeTransfer(msg.sender, amount);
        emit WithdrawnUSDC(msg.sender, amount);
    }

    /// @notice Claim accumulated native output from executed DCA swaps.
    /// @param amount amount of native token to claim.
    function claimNative(uint256 amount) external nonReentrant {
        if (amount == 0) revert IOsiris.AmountZero();
        OsirisStorage storage $ = _getOsirisStorage();
        uint256 bal = $.nativeBalance[msg.sender];
        require(bal >= amount, "insufficient native");
        $.nativeBalance[msg.sender] = bal - amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert IUniV4Swap.NativeTransferFailed();
        emit ClaimedNative(msg.sender, amount);
    }

    /// @notice Create or update your DCA plan with budget and volatility controls.
    /// @param freq execution frequency (Daily, Weekly, Monthly).
    /// @param amountPerPeriod USDC amount to DCA each period.
    /// @param maxBudgetPerExecution Maximum USD price per ETH that user is willing to pay (0 = no limit).
    /// @param enableVolatilityFilter Whether to enable volatility filtering.
    function setPlanWithBudget(
        IOsiris.Frequency freq,
        uint256 amountPerPeriod,
        uint256 maxBudgetPerExecution,
        bool enableVolatilityFilter
    ) public {
        if (amountPerPeriod == 0) revert IOsiris.AmountZero();
        if (amountPerPeriod > type(uint128).max) revert IOsiris.AmountTooLarge(); // bound cast
        OsirisStorage storage $ = _getOsirisStorage();
        IOsiris.DcaPlan storage selectedUserPlan = $.plans[msg.sender];

        // Store the previous frequency to check if it changed
        IOsiris.Frequency previousFreq = selectedUserPlan.freq;
        selectedUserPlan.freq = freq;

        // casting to 'uint128' is safe because we bounded amountPerPeriod above
        // forge-lint: disable-next-line(unsafe-typecast)
        selectedUserPlan.amountPerPeriod = uint128(amountPerPeriod);
        selectedUserPlan.maxBudgetPerExecution = maxBudgetPerExecution;
        selectedUserPlan.enableVolatilityFilter = enableVolatilityFilter;

        // Update nextExecutionTimestamp if:
        // 1. It's a new plan (timestamp == 0), OR
        // 2. The frequency changed from the previous one
        if (selectedUserPlan.nextExecutionTimestamp == 0 || previousFreq != freq) {
            selectedUserPlan.nextExecutionTimestamp = DcaPlanLib.nextExecutionAfter(block.timestamp, freq);
        }
        DcaPlanLib.ensureUserListed($.isUserListed, $.users, msg.sender);
        emit PlanUpdated(msg.sender, freq, amountPerPeriod, selectedUserPlan.nextExecutionTimestamp);
    }

    /// @notice Pause your DCA plan (keeps schedule and balances).
    function pausePlan() external {
        OsirisStorage storage $ = _getOsirisStorage();
        IOsiris.DcaPlan storage selectedUserPlan = $.plans[msg.sender];
        // Mark inactive by zeroing the next execution timestamp
        selectedUserPlan.nextExecutionTimestamp = 0;
        emit PlanUpdated(msg.sender, selectedUserPlan.freq, selectedUserPlan.amountPerPeriod, 0);
    }

    /// @notice Resume your DCA plan. If overdue or inactive, schedules the next period from now.
    function resumePlan() external {
        OsirisStorage storage $ = _getOsirisStorage();
        IOsiris.DcaPlan storage selectedUserPlan = $.plans[msg.sender];
        if (selectedUserPlan.nextExecutionTimestamp == 0 || selectedUserPlan.nextExecutionTimestamp < block.timestamp) {
            selectedUserPlan.nextExecutionTimestamp =
                DcaPlanLib.nextExecutionAfter(block.timestamp, selectedUserPlan.freq);
        }
        DcaPlanLib.ensureUserListed($.isUserListed, $.users, msg.sender);
        emit PlanUpdated(
            msg.sender, selectedUserPlan.freq, selectedUserPlan.amountPerPeriod, selectedUserPlan.nextExecutionTimestamp
        );
    }

    /// @notice Check if current ETH price is within user's budget
    /// @param user The user to check budget for
    /// @return isWithinBudget True if current ETH price is within budget
    function budgetCheck(address user) internal view returns (bool isWithinBudget) {
        OsirisStorage storage $ = _getOsirisStorage();
        IOsiris.DcaPlan storage plan = $.plans[user];

        // If no budget limit set, always pass
        if (plan.maxBudgetPerExecution == 0) return true;

        // Get current ETH price in USD (scaled by 1e8)
        uint256 ethUsdPrice = $.oracle.getEthUsdPrice();

        // Check if current ETH price is below or equal to user's maximum price
        // maxBudgetPerExecution is the maximum USD price per ETH the user is willing to pay
        isWithinBudget = ethUsdPrice <= plan.maxBudgetPerExecution;
    }

    /// @notice CronReactive tick entrypoint. Aggregates eligible users, swaps once, and distributes output.
    function callback(address sender) external authorizedSenderOnly rvmIdOnly(sender) {
        OsirisStorage storage $ = _getOsirisStorage();

        // Get current volatility once for all users
        (bool globalVolatilityOk, uint256 currentVolatility) = $.oracle.volatilityCheck();

        uint256 nbOfUser = $.users.length;
        if (nbOfUser == 0) return;

        address[] memory eligibleUsers = new address[](nbOfUser);
        uint256[] memory eligibleAmounts = new uint256[](nbOfUser);

        uint256 totalIn = 0;
        uint256 eligibleCount = 0;
        uint256 nowTs = block.timestamp;

        for (uint256 i = 0; i < nbOfUser; i++) {
            address selectedUser = $.users[i];
            IOsiris.DcaPlan storage selectedUserPlan = $.plans[selectedUser];

            if (selectedUserPlan.nextExecutionTimestamp != 0 && selectedUserPlan.nextExecutionTimestamp <= nowTs) {
                uint256 amt = uint256(selectedUserPlan.amountPerPeriod);
                if (amt > 0 && $.usdcBalance[selectedUser] >= amt) {
                    // Check budget constraint
                    bool budgetOk = budgetCheck(selectedUser);

                    // Check volatility constraint (only if enabled for this user)
                    bool volatilityOk = !selectedUserPlan.enableVolatilityFilter || globalVolatilityOk;

                    // Log the execution attempt with detailed information
                    emit DcaExecutionLog(selectedUser, amt, budgetOk, volatilityOk, currentVolatility, block.timestamp);

                    if (!budgetOk) {
                        emit DcaExecutionSkipped(selectedUser, "Budget exceeded", block.timestamp);
                        continue;
                    }

                    if (!volatilityOk) {
                        emit DcaExecutionSkipped(selectedUser, "High volatility", block.timestamp);
                        continue;
                    }

                    // User passes all checks, add to eligible list
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
        if (totalIn > type(uint128).max) revert IOsiris.AmountTooLarge(); // bound cast

        // Décrémenter le total global une seule fois pour les montants exécutés
        $.totalUsdc -= totalIn;

        // Single swap USDC -> Native
        PoolKey memory key = $.swapPool; // copy storage to memory for internal call
        // Use an external self-call so msg.sender inside swap is the vault
        uint256 nativeOut = this.swapExactInputSingle(key, $.zeroForOne, uint128(totalIn), 0);

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

    // ---------- Getters (IOsiris) ----------
    function getTotalUsdc() external view returns (uint256) {
        return _getOsirisStorage().totalUsdc;
    }

    function getUserUsdc(address user) external view returns (uint256) {
        return _getOsirisStorage().usdcBalance[user];
    }

    function getUserNative(address user) external view returns (uint256) {
        return _getOsirisStorage().nativeBalance[user];
    }

    function getUserPlan(address user) external view returns (IOsiris.DcaPlan memory) {
        return _getOsirisStorage().plans[user];
    }

    /// @notice Get current ETH/USD price from Chainlink
    function getCurrentEthUsdPrice() external view returns (uint256) {
        return _getOsirisStorage().oracle.getEthUsdPrice();
    }

    /// @notice Get current volatility from Chainlink
    function getCurrentVolatility() external returns (uint256) {
        OsirisStorage storage $ = _getOsirisStorage();
        (, uint256 volatility) = $.oracle.volatilityCheck();
        return volatility;
    }

    /// @notice Get volatility threshold
    function getVolatilityThreshold() external view returns (uint256) {
        return _getOsirisStorage().oracle.volatilityThreshold();
    }

    /// @notice Override receive function to resolve inheritance conflict
    receive() external payable override(AbstractPayer, UniV4Swap) {}

    function _getOsirisStorage() private pure returns (OsirisStorage storage $) {
        //slither-disable-start assembly
        assembly ("memory-safe") {
            $.slot := OSIRIS_STORAGE_LOCATION
        }
        //slither-disable-end assembly
    }
}
