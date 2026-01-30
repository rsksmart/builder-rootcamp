## vaults-demo

Minimal ERC-4626 vault demo meant for presentations.

### What’s included
- **`MinimalVault`**: a minimal ERC-4626 vault with a **single pluggable strategy**.
- **`IStrategy`**: tiny interface the vault depends on (strategy pattern).
- **Tests**:
  - 1 unit test (mock token + mock strategy + simulated yield)

### Demo path (checkpoint 2)
This checkpoint introduces a single strategy and shows how yield accrues through:
`vault.totalAssets()` = `idle assets` + `strategy.balanceOf()`.

Focus files:
- `src/MinimalVault.sol` (ERC-4626 vault + strategy wiring)
- `src/interfaces/IStrategy.sol` (the abstraction boundary)
- `test/mocks/MockStrategy.sol` and `test/MinimalVault.t.sol` (deposit → simulate yield → redeem)

### Commands

Unit tests:

```bash
cd vaults-demo && forge test -vvv
```
