## vaults-demo

Minimal ERC-4626 vault demo meant for presentations.

### What’s included
- **`MinimalVault`**: a minimal **idle** ERC-4626 vault (assets stay in the vault).
- **Tests**:
  - 1 unit test (mock token + deposit → redeem)

### Demo path (checkpoint 1)
This first checkpoint keeps everything intentionally minimal:
- `src/MinimalVault.sol` (ERC-4626 vault + `totalAssets()`)
- `test/MinimalVault.t.sol` (deposit → redeem roundtrip)

### Commands

Unit tests:

```bash
cd vaults-demo && forge test -vvv
```
