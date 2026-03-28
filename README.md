# builder-rootcamp
Builder Rootcamp is a hands-on bootcamp for learning to build smart contracts and dApps on Rootstock (Bitcoin’s smart contract layer).

## Getting started

This repo currently includes a Foundry-based Solidity demo under `vaults-demo/`.

### Prerequisites
- [Foundry](https://getfoundry.sh) (`forge`, `cast`, `anvil`)
- (Optional) Node.js if you prefer `npm run ...` over `make ...`

### Install

```bash
git clone <this-repo>
cd builder-rootcamp/vaults-demo

# Install Solidity dependencies (downloads into ./dependencies)
forge soldeer install
```

## Basic commands (vaults-demo)

Run everything from `vaults-demo/`:

```bash
cd vaults-demo
```

### Build

```bash
forge build
# or: make build
# or: npm run build
```

### Test (unit)

```bash
forge test -vvv
# or: make test
# or: npm run test
```

### Format

```bash
forge fmt
# or: make fmt
# or: npm run fmt
```

### Clean

```bash
rm -rf out cache
# or: make clean
# or: npm run clean
```

### Fork tests (requires RPC_URL)

```bash
cd vaults-demo
cp env.example .env
# edit .env and set RPC_URL=...

make test-fork
# or: npm run test:fork
```
