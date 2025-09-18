// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {UniV4Swap} from "./UniV4Swap.sol";
import {IDcaVault} from "./interfaces/IDcaVault.sol";
import {IUniV4Swap} from "./interfaces/IUniV4Swap.sol";

contract DcaVault is UniV4Swap, IDcaVault {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    // Roles/config
    address public immutable owner;
    address public immutable callbackSender; // authorized CronReactive sender
    IERC20 public immutable USDC;

    struct Plan {
        IDcaVault.Frequency freq;
        uint128 amountPerPeriod;
        uint64 nextExec;
        bool active;
    }

    // User accounting
    mapping(address => uint256) public usdcBalance;
    mapping(address => uint256) public nativeBalance;
    mapping(address => Plan) public plans;

    // Round-robin bounded processing
    address[] public users;
    mapping(address => bool) private inSet;
    uint256 public cursor;
    uint256 public batchSize;

    // Swap route (must output native)
    PoolKey public swapPool;
    bool public zeroForOne;
    uint128 public minOutAbsolute; // optional absolute min-out (0 to disable)

    /// @notice Initialize vault config and dependencies.
    /// @param _router UniversalRouter address.
    /// @param _permit2 Permit2 address.
    /// @param _usdc USDC token address (input asset).
    /// @param _callbackSender authorized CronReactive contract sender.
    /// @param _batchSize max users processed per callback (bounded loop).
    constructor(address _router, address _permit2, address _usdc, address _callbackSender, uint256 _batchSize)
        UniV4Swap(_router, _permit2)
    {
        owner = msg.sender;
        if (_callbackSender == address(0)) revert NotCallbackSender();
        callbackSender = _callbackSender;

        if (_usdc == address(0)) revert InvalidSwapRoute();
        USDC = IERC20(_usdc);

        batchSize = _batchSize == 0 ? 32 : _batchSize;
    }

    /// @notice Deposit USDC to the vault to fund your DCA.
    /// @param amount amount of USDC to deposit.
    function depositUSDC(uint256 amount) external {
        if (amount == 0) revert AmountZero();
        USDC.safeTransferFrom(msg.sender, address(this), amount);
        usdcBalance[msg.sender] += amount;
        emit DepositedUSDC(msg.sender, amount);
    }

    /// @notice Withdraw USDC from your vault balance.
    /// @param amount amount of USDC to withdraw.
    function withdrawUSDC(uint256 amount) external {
        if (amount == 0) revert AmountZero();
        uint256 bal = usdcBalance[msg.sender];
        if (bal < amount) revert InsufficientUSDC();
        usdcBalance[msg.sender] = bal - amount;
        USDC.safeTransfer(msg.sender, amount);
        emit WithdrawnUSDC(msg.sender, amount);
    }

    /// @notice Claim accumulated native output from executed DCA swaps.
    /// @param amount amount of native token to claim.
    function claimNative(uint256 amount) external {
        if (amount == 0) revert AmountZero();
        uint256 bal = nativeBalance[msg.sender];
        require(bal >= amount, "insufficient native");
        nativeBalance[msg.sender] = bal - amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert NativeTransferFailed();
        emit ClaimedNative(msg.sender, amount);
    }

    /// @notice Create or update your DCA plan.
    /// @param freq execution frequency (Daily, Weekly, Monthly).
    /// @param amountPerPeriod USDC amount to DCA each period.
    /// @param active whether the plan is active.
    function setPlan(IDcaVault.Frequency freq, uint256 amountPerPeriod, bool active) external {
        if (amountPerPeriod == 0 && active) revert AmountZero();
        Plan storage p = plans[msg.sender];
        p.freq = freq;
        p.amountPerPeriod = uint128(amountPerPeriod);
        p.active = active;
        if (p.nextExec == 0 || active) {
            p.nextExec = _nextAfter(block.timestamp, freq);
        }
        _ensureListed(msg.sender);
        emit PlanUpdated(msg.sender, freq, amountPerPeriod, active, p.nextExec);
    }

    /// @notice Pause your DCA plan (keeps schedule and balances).
    function pausePlan() external {
        Plan storage p = plans[msg.sender];
        p.active = false;
        emit PlanUpdated(msg.sender, p.freq, p.amountPerPeriod, false, p.nextExec);
    }

    /// @notice Resume your DCA plan. If overdue, schedules the next period from now.
    function resumePlan() external {
        Plan storage p = plans[msg.sender];
        p.active = true;
        if (p.nextExec < block.timestamp) {
            p.nextExec = _nextAfter(block.timestamp, p.freq);
        }
        _ensureListed(msg.sender);
        emit PlanUpdated(msg.sender, p.freq, p.amountPerPeriod, true, p.nextExec);
    }

    /// @notice Set the maximum number of users processed per callback tick.
    /// @param _batchSize new batch size (1..256).
    function setBatchSize(uint256 _batchSize) external {
        if (msg.sender != owner) revert NotOwner();
        require(_batchSize > 0 && _batchSize <= 256, "bad batch");
        batchSize = _batchSize;
    }

    /// @notice Configure the swap route (must be USDC-in, native-out).
    /// @param key Uniswap v4 PoolKey to use.
    /// @param _zeroForOne true for currency0->currency1, false for currency1->currency0.
    function setSwapRoute(PoolKey calldata key, bool _zeroForOne) external {
        if (msg.sender != owner) revert NotOwner();
        _validateSwapRoute(key, _zeroForOne);
        swapPool = key;
        zeroForOne = _zeroForOne;
    }

    /// @notice Set an absolute minimum acceptable output for aggregated swaps.
    /// @param _minOutAbsolute minimum amount of native output (0 disables).
    function setMinOutAbsolute(uint128 _minOutAbsolute) external {
        if (msg.sender != owner) revert NotOwner();
        minOutAbsolute = _minOutAbsolute;
    }

    /// @notice CronReactive tick entrypoint. Aggregates eligible users, swaps once, and distributes output.
    /// @param /*sender*/ CronReactive sender id (not used on-chain, reserved for off-chain correlation).
    function callback(address /*sender*/ ) external {
        if (msg.sender != callbackSender) revert NotCallbackSender();

        uint256 n = users.length;
        if (n == 0) return;

        address[] memory bufUsers = new address[](batchSize);
        uint256[] memory bufAmounts = new uint256[](batchSize);

        uint256 totalIn = 0;
        uint256 m = 0;
        uint256 nowTs = block.timestamp;

        uint256 i = 0;
        uint256 idx = cursor;
        while (i < n && m < batchSize) {
            address u = users[idx];
            Plan storage p = plans[u];

            if (p.active && p.nextExec != 0 && p.nextExec <= nowTs) {
                uint256 amt = uint256(p.amountPerPeriod);
                if (amt > 0 && usdcBalance[u] >= amt) {
                    bufUsers[m] = u;
                    bufAmounts[m] = amt;
                    totalIn += amt;
                    m++;
                }
            }

            idx = (idx + 1) % n;
            i++;
        }
        cursor = idx;

        if (totalIn == 0) {
            return;
        }

        // Single swap USDC -> Native, keep proceeds in vault (copy PoolKey to memory to satisfy calldata requirement)
        PoolKey memory key = swapPool;
        uint256 nativeOut = swapExactInputSingle(key, zeroForOne, uint128(totalIn), minOutAbsolute);
        if (minOutAbsolute > 0 && nativeOut < minOutAbsolute) {
            revert IUniV4Swap.InsufficientOutput(nativeOut, minOutAbsolute);
        }

        // Distribute pro-rata and reschedule nextExec with catch-up
        uint256 remainingOut = nativeOut;
        for (uint256 j = 0; j < m; j++) {
            address u2 = bufUsers[j];
            uint256 inAmt = bufAmounts[j];

            usdcBalance[u2] -= inAmt;

            uint256 outAmt;
            if (j + 1 == m) {
                outAmt = remainingOut;
            } else {
                outAmt = (nativeOut * inAmt) / totalIn;
                remainingOut -= outAmt;
            }
            nativeBalance[u2] += outAmt;

            plans[u2].nextExec = _catchupNext(plans[u2].nextExec, plans[u2].freq, nowTs);
        }

        emit CallbackProcessed(m, totalIn, nativeOut);
    }

    // ---------- Internals ----------
    function _ensureListed(address u) internal {
        if (!inSet[u]) {
            inSet[u] = true;
            users.push(u);
        }
    }

    function _period(IDcaVault.Frequency f) internal pure returns (uint64) {
        if (f == IDcaVault.Frequency.Daily) return 1 days;
        if (f == IDcaVault.Frequency.Weekly) return 7 days;
        return 30 days;
    }

    function _nextAfter(uint256 fromTs, IDcaVault.Frequency f) internal pure returns (uint64) {
        return uint64(fromTs + _period(f));
    }

    function _catchupNext(uint64 prevNext, IDcaVault.Frequency f, uint256 nowTs) internal pure returns (uint64) {
        uint64 period = _period(f);
        uint64 next = prevNext == 0 ? uint64(nowTs) + period : prevNext;
        if (next > nowTs) return next;
        uint256 delta = nowTs - next;
        uint256 missed = (delta / period) + 1;
        return next + uint64(missed) * period;
    }

    // Route validator: enforce USDC-in, native-out
    function _validateSwapRoute(PoolKey memory key, bool _zeroForOne) internal view {
        Currency inCurrency = _zeroForOne ? key.currency0 : key.currency1;
        Currency outCurrency = _zeroForOne ? key.currency1 : key.currency0;
        if (!outCurrency.isAddressZero()) revert InvalidSwapRoute();
        if (inCurrency.isAddressZero() || Currency.unwrap(inCurrency) != address(USDC)) revert InvalidSwapRoute();
    }
}
