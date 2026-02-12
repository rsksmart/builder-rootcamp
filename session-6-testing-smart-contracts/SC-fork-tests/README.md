# 🧪 Layer 2 – Fork-Based Integration Test (Rootstock)

This example demonstrates **Protocol & Integration Testing** using a local fork of Rootstock mainnet.

We validate real interactions between:
- A deployed `ERC20Vault`
- The real USDRIF token contract
- A real token holder (impersonated)
- Live Rootstock mainnet state (forked locally)

---

# 🚀 Run Everything

## 1️⃣ Start Rootstock Mainnet Fork

* We need to install foundry beforehand

```bash
anvil --fork-url https://public-node.rsk.co --port 8540
```

## 2️⃣ Deploy Vault (Foundry)

```
export ANVIL_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80


forge create session-6-testing-smart-contracts/SC-fork-tests/src/ERC20Vault.sol:ERC20Vault \
  --rpc-url http://127.0.0.1:8540 \
  --private-key $ANVIL_PK \
  --chain-id 30 \
  --broadcast
```

Copy the Deployed to: address and paste it into:

```const VAULT = "0x...";```

inside fork-test.ts.


3️⃣ Run Integration Test

npm install
npm run test:fork
