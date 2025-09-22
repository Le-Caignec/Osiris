# DCA Vault

DCA Vault is a pooled smart contract that executes Dollar-Cost Averaging (DCA) plans from USDC to the native token via Uniswap v4.  
Users deposit USDC, configure a plan (frequency + amount per period), and an on-chain job called CronReactive, deployed on the Reactive Network, periodically triggers the callback function of the vault deployed on Ethereum.

The callback aggregates eligible users, executes a single swap, and distributes the native output pro-rata into internal balances. Users can later claim their accumulated native tokens.

---

## Overview

- Deposit: Each user credits their internal USDC balance.  
- Plan: Defines frequency (Daily / Weekly / Monthly) and amount per period.  
- Execution: The callback() aggregates eligible users, performs a single USDC → Native swap, and distributes the output pro-rata.  
- Claim: Users call claimNative(amount) to receive their native tokens.  
- Pause/Resume: Users can suspend or resume their plan without losing history or balances.

---

## Networks

- Reactive Mainnet: Runs CronReactive to periodically trigger the vault callback.  
- Ethereum Mainnet: Hosts DcaVault, Uniswap v4 Router, Permit2, USDC, and ETH.

---

## Main API (DcaVault contract)

- `depositUsdc(amount)`: Deposit USDC (requires prior approval).  
- `withdrawUsdc(amount)`: Withdraw USDC from internal balance.  
- `setPlan(freq, amountPerPeriod)`: Create or update a DCA plan.  
- `pausePlan()`: Pause a plan (disables execution).  
- `resumePlan()`: Resume a plan (reschedules next execution).  
- `claimNative(amount)`: Claim accumulated native tokens.  
- `callback()`: Aggregates eligible users, executes the swap, distributes pro-rata.

---

## Developer Commands (Foundry)

```bash
curl -L <https://foundry.paradigm.xyz> | bash
foundryup
```

- Install dependencies:

```bash
forge install
```

- Build:

```bash
forge build
```

- Run tests (unit + fuzz):

```bash
forge test -vv
```

- Coverage:

```bash
forge coverage
```

- Gas report:

```bash
forge test --gas-report
```

If a Makefile is provided:

- Run unit tests:

```bash
make test-unit
```

Useful variables (e.g., in scripts): addresses for Uniswap v4 Router, Permit2, USDC per network.

---

## Flow Chart

```mermaid
flowchart LR
    subgraph R[Reactive Mainnet]
        CR[CronReactive]
    end

    subgraph E[Ethereum Mainnet]
        V[DcaVault]
        U4[Uniswap v4 Router]
        P2[Permit2]
        T[USDC ERC20]
    end

    U[User] -->|approve + deposit USDC| V
    U -->|setPlan| V

    CR -- trigger callback --> V

    V -->|approve via Permit2| P2
    V -->|swap USDC → Native| U4
    U4 -->|send Native| V

    V -->|distribute pro-rata| V
    U -->|claimNative| V -->|transfer Native| U
```

---

## Execution Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant CR as CronReactive (Reactive Mainnet)
    participant V as DcaVault (Ethereum)
    participant P2 as Permit2 (Ethereum)
    participant U4 as Uniswap v4 Router (Ethereum)

    U->>V: depositUsdc(amount)
    U->>V: setPlan(freq, amountPerPeriod)

    rect rgb(245,245,245)
    Note over CR,V: Periodic trigger
    CR-->>V: call callback()
    V->>P2: approve via Permit2 for USDC
    V->>U4: swap USDC → Native
    U4-->>V: transfer Native back to Vault
    V->>V: distribute pro-rata & update schedule
    end

    U->>V: claimNative(amount)
    V-->>U: transfer Native
```
