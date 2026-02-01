## vaults-demo

Minimal ERC-4626 vault demo meant for presentations.

### What’s included
- **`MinimalVault`**: a minimal **UUPS-upgradeable** ERC-4626 vault with **multiple strategies** + `rebalance()`.
- **`IStrategy`**: tiny interface the vault depends on (strategy pattern).
- **`TropykusStrategy`**: Compound-like adapter used in the fork test.
- **Tests**:
  - 1 unit test (two mock strategies + rebalance/sort)
  - 1 fork test (vault ↔ strategy ↔ live protocol)

### Demo path (checkpoint 2)
This checkpoint introduces a single strategy and shows how yield accrues through:
`vault.totalAssets()` = `idle assets` + `strategy.balanceOf()`.

Focus files:
- `src/MinimalVault.sol` (ERC-4626 vault + strategy wiring)
- `src/interfaces/IStrategy.sol` (the abstraction boundary)
- `test/mocks/MockStrategy.sol` and `test/MinimalVault.t.sol` (deposit → simulate yield → redeem)

### Demo path (checkpoint 3: fork test)
The fork test proves the adapter works against live contracts:
- `src/strategies/TropykusStrategy.sol`
- `test/fork/MinimalVaultTropykusFork.t.sol`

### Demo path (checkpoint 5: rebalance)
This checkpoint moves APY sorting + allocation off the user path:
- user `deposit/withdraw` stays simple (no APY scanning)
- `rebalance()` sorts strategies and allocates funds

### Demo path (checkpoint 6: upgradeability)
This checkpoint makes the vault **upgradeable (UUPS)**.
In tests we deploy the vault behind an `ERC1967Proxy` and call `initialize(...)` instead of using a constructor.

### Commands

Unit tests:

```bash
cd vaults-demo && forge test -vvv
```

Upgrade script (UUPS; requires env vars):

```bash
cd vaults-demo && \
RPC_URL="..." \
PRIVATE_KEY="..." \
PROXY="0x..." \
forge script -vvv script/UpgradeMinimalVault.s.sol:UpgradeMinimalVault --rpc-url "$RPC_URL" --broadcast
```

Tropykus fork test (requires env vars):

```bash
cd vaults-demo && \
RPC_URL="..." \
FORK_BLOCK_NUMBER="..." \
USDRIF_ADDRESS="0x..." \
TROPYKUS_TOKEN="0x..." \
forge test -vvv --match-path "test/fork/MinimalVaultTropykusFork.t.sol"
```
