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

contract DcaVault is UniV4Swap, IDcaVault, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using CurrencyLibrary for Currency;

    // Roles/config
    address public immutable OWNER;
    address public immutable CALLBACK_SENDER; // authorized CronReactive sender
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

    /// @notice Initialize vault config and dependencies.
    /// @param _router UniversalRouter address.
    /// @param _permit2 Permit2 address.
    /// @param _usdc USDC token address (input asset).
    /// @param _callbackSender authorized CronReactive contract sender.
    /// @param _batchSize max users processed per callback (bounded loop).
    constructor(address _router, address _permit2, address _usdc, address _callbackSender, uint256 _batchSize)
        UniV4Swap(_router, _permit2)
    {
        OWNER = msg.sender;
        if (_callbackSender == address(0)) revert IDcaVault.NotCallbackSender();
        CALLBACK_SENDER = _callbackSender;

        if (_usdc == address(0)) revert IDcaVault.InvalidSwapRoute();
        USDC = IERC20(_usdc);

        batchSize = _batchSize == 0 ? 32 : _batchSize;
    }

    /// @notice Deposit USDC to the vault to fund your DCA.
    /// This function requires prior USDC approval.
    /// @param amount amount of USDC to deposit.
    function depositUsdc(uint256 amount) external {
        if (amount == 0) revert IDcaVault.AmountZero();
        USDC.safeTransferFrom(msg.sender, address(this), amount);
        usdcBalance[msg.sender] += amount;
        emit DepositedUSDC(msg.sender, amount);
    }

    /// @notice Withdraw USDC from your vault balance.
    /// @param amount amount of USDC to withdraw.
    function withdrawUsdc(uint256 amount) external {
        if (amount == 0) revert IDcaVault.AmountZero();
        uint256 bal = usdcBalance[msg.sender];
        if (bal < amount) revert IDcaVault.InsufficientUSDC();
        usdcBalance[msg.sender] = bal - amount;
        USDC.safeTransfer(msg.sender, amount);
        emit WithdrawnUSDC(msg.sender, amount);
    }

    /// @notice Claim accumulated native output from executed DCA swaps.
    /// @param amount amount of native token to claim.
    function claimNative(uint256 amount) external nonReentrant {
        if (amount == 0) revert IDcaVault.AmountZero();
        uint256 bal = nativeBalance[msg.sender];
        require(bal >= amount, "insufficient native");
        nativeBalance[msg.sender] = bal - amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert IUniV4Swap.NativeTransferFailed();
        emit ClaimedNative(msg.sender, amount);
    }

    /// @notice Create or update your DCA plan.
    /// @param freq execution frequency (Daily, Weekly, Monthly).
    /// @param amountPerPeriod USDC amount to DCA each period.
    /// @param active whether the plan is active.
    function setPlan(IDcaVault.Frequency freq, uint256 amountPerPeriod, bool active) external {
        if (amountPerPeriod == 0 && active) revert IDcaVault.AmountZero();
        if (amountPerPeriod > type(uint128).max) revert IDcaVault.AmountTooLarge(); // bound cast
        Plan storage p = plans[msg.sender];
        p.freq = freq;
        // casting to 'uint128' is safe because we bounded amountPerPeriod above
        // forge-lint: disable-next-line(unsafe-typecast)
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
        if (msg.sender != OWNER) revert IDcaVault.NotOwner();
        require(_batchSize > 0 && _batchSize <= 256, "bad batch");
        batchSize = _batchSize;
    }

    /// @notice CronReactive tick entrypoint. Aggregates eligible users, swaps once, and distributes output.
    /// @param /*sender*/ CronReactive sender id (not used on-chain, reserved for off-chain correlation).
    function callback(address /*sender*/ ) external {
        if (msg.sender != CALLBACK_SENDER) revert IDcaVault.NotCallbackSender();

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
        if (totalIn > type(uint128).max) revert IDcaVault.AmountTooLarge(); // bound cast

        // Single swap USDC -> Native, keep proceeds in vault
        PoolKey memory key = swapPool; // copy storage to memory for internal call
        // casting to 'uint128' is safe because 'totalIn' was bounded above
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 nativeOut = swapExactInputSingle(key, zeroForOne, uint128(totalIn), 0);

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
        // casting to 'uint64' is safe because block timestamps and periods fit well within 2^64
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint64(fromTs + _period(f));
    }

    function _catchupNext(uint64 prevNext, IDcaVault.Frequency f, uint256 nowTs) internal pure returns (uint64) {
        uint64 period = _period(f);
        // casting to 'uint64' is safe because block timestamps fit within 2^64
        // forge-lint: disable-next-line(unsafe-typecast)
        uint64 next = prevNext == 0 ? uint64(nowTs) + period : prevNext;
        if (next > nowTs) return next;
        uint256 delta = nowTs - next;
        uint256 missed = (delta / period) + 1;
        // casting to 'uint64' is safe because 'missed' is a count of periods and fits within 2^64 for practical horizons
        // forge-lint: disable-next-line(unsafe-typecast)
        return next + uint64(missed) * period;
    }
}
