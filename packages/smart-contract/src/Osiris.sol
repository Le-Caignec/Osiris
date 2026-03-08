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
import {IDIAOracle} from "./interfaces/IDIAOracle.sol";
import {ChainlinkOracle} from "./ChainlinkOracle.sol";
import {AbstractCallback} from "@reactive-contract/abstract-base/AbstractCallback.sol";
import {AbstractPayer} from "@reactive-contract/abstract-base/AbstractPayer.sol";

/// @title Osiris
/// @notice Pooled DCA vault: users deposit USDC and receive ETH or wReact on each cron tick.

contract Osiris is UniV4Swap, IOsiris, AbstractCallback {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    // ============ Storage ============

    /// @custom:storage-location bytes32(uint256(keccak256("erc7201:orion.dca.storage")) - 1) & ~bytes32(uint256(0xff))
    bytes32 private constant OSIRIS_STORAGE_LOCATION =
        0x68511e06a47e02615622d3067a6e76777b4a7762af923f31d7c600643617a500;

    /// @dev DIA oracle key for REACT/USD price feed
    string private constant DIA_REACT_USD_KEY = "REACT/USD";

    struct OsirisStorage {
        IERC20 usdc;
        // Round-robin bounded processing
        address[] users;
        mapping(address => bool) isUserListed;
        // ETH swap route (currency0=native, currency1=USDC)
        PoolKey swapPool;
        bool zeroForOne;
        // wReact swap route (sorted by address)
        PoolKey wReactPool;
        bool wReactZeroForOne;
        // User accounting
        mapping(address => uint256) usdcBalance;
        mapping(address => uint256) nativeBalance;
        mapping(address => uint256) wReactBalance;
        mapping(address => IOsiris.DcaPlan) plans;
        uint256 totalUsdc;
        // Oracles
        IChainlinkOracle oracle;
        IERC20 wReact;
        IDIAOracle diaOracle;
    }

    // ============ Constructor ============

    /// @param _router Uniswap UniversalRouter address
    /// @param _permit2 Permit2 address
    /// @param _usdc USDC token address
    /// @param _callbackSender Reactive Network callback proxy address
    /// @param _ethUsdFeed Chainlink ETH/USD price feed address
    /// @param _wReact wReact ERC-20 token address (address(0) = wReact DCA disabled)
    /// @param _diaOracle DIA oracle address for REACT/USD (address(0) = budget checks disabled for wReact)
    constructor(
        address _router,
        address _permit2,
        address _usdc,
        address _callbackSender,
        address _ethUsdFeed,
        address _wReact,
        address _diaOracle
    ) payable UniV4Swap(_router, _permit2) AbstractCallback(_callbackSender) {
        OsirisStorage storage $ = _getOsirisStorage();
        if (_usdc == address(0)) revert IOsiris.InvalidSwapRoute();
        $.usdc = IERC20(_usdc);

        // ETH pool: currency0=native(address(0)), currency1=USDC, direction USDC->ETH (zeroForOne=false)
        $.zeroForOne = false;
        $.swapPool = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(_usdc),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });

        // wReact pool: currency0/1 sorted by address, direction inferred from USDC position
        if (_wReact != address(0)) {
            $.wReact = IERC20(_wReact);
            if (uint160(_usdc) < uint160(_wReact)) {
                // USDC is currency0, wReact is currency1 -> zeroForOne=true (USDC->wReact)
                $.wReactPool = PoolKey({
                    currency0: Currency.wrap(_usdc),
                    currency1: Currency.wrap(_wReact),
                    fee: 3000,
                    tickSpacing: 60,
                    hooks: IHooks(address(0))
                });
                $.wReactZeroForOne = true;
            } else {
                // wReact is currency0, USDC is currency1 -> zeroForOne=false (USDC->wReact)
                $.wReactPool = PoolKey({
                    currency0: Currency.wrap(_wReact),
                    currency1: Currency.wrap(_usdc),
                    fee: 3000,
                    tickSpacing: 60,
                    hooks: IHooks(address(0))
                });
                $.wReactZeroForOne = false;
            }
        }

        if (_diaOracle != address(0)) {
            $.diaOracle = IDIAOracle(_diaOracle);
        }

        $.oracle = new ChainlinkOracle(_ethUsdFeed);
    }

    // ============ User Actions ============

    /// @notice Deposit USDC to the vault to fund your DCA.
    /// @param amount Amount of USDC to deposit (requires prior approval).
    function depositUsdc(uint256 amount) external {
        if (amount == 0) revert IOsiris.AmountZero();
        OsirisStorage storage $ = _getOsirisStorage();
        $.usdc.safeTransferFrom(msg.sender, address(this), amount);
        $.usdcBalance[msg.sender] += amount;
        $.totalUsdc += amount;
        emit DepositedUSDC(msg.sender, amount);
    }

    /// @notice Withdraw USDC from your vault balance.
    /// @param amount Amount of USDC to withdraw.
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

    /// @notice Claim accumulated native ETH from executed DCA swaps.
    /// @param amount Amount of native ETH to claim.
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

    /// @notice Claim accumulated wReact tokens from executed DCA swaps.
    /// @param token Must be the wReact token address.
    /// @param amount Amount of wReact to claim.
    function claimToken(address token, uint256 amount) external nonReentrant {
        if (amount == 0) revert IOsiris.AmountZero();
        OsirisStorage storage $ = _getOsirisStorage();
        require(token == address($.wReact) && token != address(0), "unsupported token");
        uint256 bal = $.wReactBalance[msg.sender];
        require(bal >= amount, "insufficient token balance");
        $.wReactBalance[msg.sender] = bal - amount;
        $.wReact.safeTransfer(msg.sender, amount);
        emit ClaimedToken(msg.sender, token, amount);
    }

    // ============ Plan Management ============

    /// @notice Create or update your DCA plan.
    /// @param freq Execution frequency (Daily, Weekly, Monthly).
    /// @param amountPerPeriod USDC amount to DCA each period.
    /// @param maxBudgetPerExecution Maximum USD price per token willing to pay (0 = no limit, 1e8 scale).
    /// @param enableVolatilityFilter Skip execution when market volatility exceeds threshold.
    /// @param targetToken DCA output token: ETH or wReact.
    function setPlanWithBudget(
        IOsiris.Frequency freq,
        uint256 amountPerPeriod,
        uint256 maxBudgetPerExecution,
        bool enableVolatilityFilter,
        IOsiris.TargetToken targetToken
    ) public {
        if (amountPerPeriod == 0) revert IOsiris.AmountZero();
        if (amountPerPeriod > type(uint128).max) revert IOsiris.AmountTooLarge();
        OsirisStorage storage $ = _getOsirisStorage();

        // Ensure wReact is configured before accepting wReact plans
        if (targetToken == IOsiris.TargetToken.WREACT && address($.wReact) == address(0)) {
            revert IOsiris.WReactNotConfigured();
        }

        IOsiris.DcaPlan storage selectedUserPlan = $.plans[msg.sender];
        IOsiris.Frequency previousFreq = selectedUserPlan.freq;

        selectedUserPlan.freq = freq;
        // forge-lint: disable-next-line(unsafe-typecast)
        selectedUserPlan.amountPerPeriod = uint128(amountPerPeriod);
        selectedUserPlan.maxBudgetPerExecution = maxBudgetPerExecution;
        selectedUserPlan.enableVolatilityFilter = enableVolatilityFilter;
        selectedUserPlan.targetToken = targetToken;

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
        selectedUserPlan.nextExecutionTimestamp = 0;
        emit PlanUpdated(msg.sender, selectedUserPlan.freq, selectedUserPlan.amountPerPeriod, 0);
    }

    /// @notice Resume your DCA plan. Schedules next period from now if overdue or inactive.
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

    // ============ CronReactive Callback ============

    /// @notice CronReactive tick entrypoint. Aggregates eligible users, swaps in batches by target token, distributes output.
    function callback(address sender) external authorizedSenderOnly rvmIdOnly(sender) {
        OsirisStorage storage $ = _getOsirisStorage();

        (bool globalVolatilityOk, uint256 currentVolatility) = $.oracle.volatilityCheck();

        uint256 nbOfUser = $.users.length;
        if (nbOfUser == 0) return;

        // Split eligible users by target token
        address[] memory ethUsers = new address[](nbOfUser);
        uint256[] memory ethAmounts = new uint256[](nbOfUser);
        address[] memory wReactUsers = new address[](nbOfUser);
        uint256[] memory wReactAmounts = new uint256[](nbOfUser);

        uint256 totalEthIn = 0;
        uint256 totalWReactIn = 0;
        uint256 ethCount = 0;
        uint256 wReactCount = 0;
        uint256 nowTs = block.timestamp;

        for (uint256 i = 0; i < nbOfUser; i++) {
            address selectedUser = $.users[i];
            IOsiris.DcaPlan storage selectedUserPlan = $.plans[selectedUser];

            if (selectedUserPlan.nextExecutionTimestamp != 0 && selectedUserPlan.nextExecutionTimestamp <= nowTs) {
                uint256 amt = uint256(selectedUserPlan.amountPerPeriod);
                if (amt > 0 && $.usdcBalance[selectedUser] >= amt) {
                    bool budgetOk = _budgetCheck(selectedUser);
                    bool volatilityOk = !selectedUserPlan.enableVolatilityFilter || globalVolatilityOk;

                    emit DcaExecutionLog(selectedUser, amt, budgetOk, volatilityOk, currentVolatility, block.timestamp);

                    if (!budgetOk) {
                        emit DcaExecutionSkipped(selectedUser, "Budget exceeded", block.timestamp);
                        continue;
                    }
                    if (!volatilityOk) {
                        emit DcaExecutionSkipped(selectedUser, "High volatility", block.timestamp);
                        continue;
                    }

                    if (selectedUserPlan.targetToken == IOsiris.TargetToken.WREACT) {
                        wReactUsers[wReactCount] = selectedUser;
                        wReactAmounts[wReactCount] = amt;
                        totalWReactIn += amt;
                        wReactCount++;
                    } else {
                        ethUsers[ethCount] = selectedUser;
                        ethAmounts[ethCount] = amt;
                        totalEthIn += amt;
                        ethCount++;
                    }
                }
            }
        }

        uint256 totalIn = totalEthIn + totalWReactIn;
        if (totalIn == 0) return;
        if (totalEthIn > type(uint128).max) revert IOsiris.AmountTooLarge();
        if (totalWReactIn > type(uint128).max) revert IOsiris.AmountTooLarge();

        $.totalUsdc -= totalIn;

        // ---- ETH batch ----
        uint256 nativeOut = 0;
        if (totalEthIn > 0) {
            PoolKey memory key = $.swapPool;
            nativeOut = this.swapExactInputSingle(key, $.zeroForOne, uint128(totalEthIn), 0);

            uint256 remainingOut = nativeOut;
            for (uint256 j = 0; j < ethCount; j++) {
                address eligibleUser = ethUsers[j];
                uint256 eligibleAmount = ethAmounts[j];
                $.usdcBalance[eligibleUser] -= eligibleAmount;

                uint256 outAmt;
                if (j + 1 == ethCount) {
                    outAmt = remainingOut;
                } else {
                    outAmt = (nativeOut * eligibleAmount) / totalEthIn;
                    remainingOut -= outAmt;
                }
                $.nativeBalance[eligibleUser] += outAmt;
                $.plans[eligibleUser].nextExecutionTimestamp =
                    DcaPlanLib.catchUpNextExecution($.plans[eligibleUser], nowTs);
            }
        }

        // ---- wReact batch ----
        uint256 wReactOut = 0;
        if (totalWReactIn > 0) {
            PoolKey memory wReactKey = $.wReactPool;
            wReactOut = this.swapExactInputSingle(wReactKey, $.wReactZeroForOne, uint128(totalWReactIn), 0);

            uint256 remainingWReact = wReactOut;
            for (uint256 j = 0; j < wReactCount; j++) {
                address eligibleUser = wReactUsers[j];
                uint256 eligibleAmount = wReactAmounts[j];
                $.usdcBalance[eligibleUser] -= eligibleAmount;

                uint256 outAmt;
                if (j + 1 == wReactCount) {
                    outAmt = remainingWReact;
                } else {
                    outAmt = (wReactOut * eligibleAmount) / totalWReactIn;
                    remainingWReact -= outAmt;
                }
                $.wReactBalance[eligibleUser] += outAmt;
                $.plans[eligibleUser].nextExecutionTimestamp =
                    DcaPlanLib.catchUpNextExecution($.plans[eligibleUser], nowTs);
            }
        }

        emit CallbackProcessed(ethCount + wReactCount, totalIn, nativeOut, wReactOut);
    }

    // ============ View Getters ============

    function getTotalUsdc() external view returns (uint256) {
        return _getOsirisStorage().totalUsdc;
    }

    function getUserUsdc(address user) external view returns (uint256) {
        return _getOsirisStorage().usdcBalance[user];
    }

    function getUserNative(address user) external view returns (uint256) {
        return _getOsirisStorage().nativeBalance[user];
    }

    function getUserWReact(address user) external view returns (uint256) {
        return _getOsirisStorage().wReactBalance[user];
    }

    function getUserPlan(address user) external view returns (IOsiris.DcaPlan memory) {
        return _getOsirisStorage().plans[user];
    }

    /// @notice Get current ETH/USD price from Chainlink
    function getCurrentEthUsdPrice() external view returns (uint256) {
        return _getOsirisStorage().oracle.getEthUsdPrice();
    }

    /// @notice Get current volatility (state-mutating: updates price history)
    function getCurrentVolatility() external returns (uint256) {
        OsirisStorage storage $ = _getOsirisStorage();
        (, uint256 volatility) = $.oracle.volatilityCheck();
        return volatility;
    }

    /// @notice Get volatility threshold in basis points
    function getVolatilityThreshold() external view returns (uint256) {
        return _getOsirisStorage().oracle.volatilityThreshold();
    }

    /// @notice Override receive function to resolve inheritance conflict
    receive() external payable override(AbstractPayer, UniV4Swap) {}

    // ============ Internal ============

    /// @dev Returns true if the current price is within the user's budget.
    ///      Uses Chainlink for ETH plans and DIA Oracle for wReact plans.
    function _budgetCheck(address user) internal view returns (bool isWithinBudget) {
        OsirisStorage storage $ = _getOsirisStorage();
        IOsiris.DcaPlan storage plan = $.plans[user];

        if (plan.maxBudgetPerExecution == 0) return true;

        uint256 price;
        if (plan.targetToken == IOsiris.TargetToken.WREACT) {
            // Use DIA oracle for REACT/USD; skip execution if oracle not configured
            if (address($.diaOracle) == address(0)) return false;
            (uint128 reactPrice,) = $.diaOracle.getValue(DIA_REACT_USD_KEY);
            if (reactPrice == 0) return false;
            price = uint256(reactPrice);
        } else {
            price = $.oracle.getEthUsdPrice();
        }

        isWithinBudget = price <= plan.maxBudgetPerExecution;
    }

    function _getOsirisStorage() private pure returns (OsirisStorage storage $) {
        //slither-disable-start assembly
        assembly ("memory-safe") {
            $.slot := OSIRIS_STORAGE_LOCATION
        }
        //slither-disable-end assembly
    }
}
