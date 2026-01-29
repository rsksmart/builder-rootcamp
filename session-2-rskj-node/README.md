# Session 2: RSKj Node - Hands-on Bootcamp

This session covers practical exercises for running and interacting with the Rootstock (RSK) node.

## Prerequisites

- Docker installed and running (Option A) **OR** Java 17 JDK (Option B)
- `curl` and `jq` installed (for JSON formatting)
- Terminal/shell access

## Session Structure

| Part | Topic                          | Duration |
| ---- | ------------------------------ | -------- |
| 01   | Running the Node (Docker/Java) | 10 min   |
| 02   | RPC Basics                     | 5 min    |
| 03   | Account Management             | 5 min    |
| 04   | Smart Contracts                | 10 min   |
| 05   | Transactions                   | 5 min    |
| 06   | Logs & Events                  | 5 min    |
| 07   | Node Configuration             | 5 min    |

## Quick Start

### Option A: Docker (Recommended)

```bash
# 1. Start the node with Docker
cd part-01-running-node
docker compose up -d

# 2. Verify it's running
docker logs -f rskj-regtest
```

### Option B: Java Command Line

```bash
# 1. Download JAR (or build from source)
mkdir -p ~/rskj-node && cd ~/rskj-node
curl -L -o rskj-core-all.jar \
  https://github.com/rsksmart/rskj/releases/download/REED-8.1.0/rskj-core-8.1.0-REED-all.jar

# 2. Run the node
java -Dlogging.stdout=INFO -cp rskj-core-all.jar co.rsk.Start --regtest
```

### Then run demos

```bash
cd part-02-rpc-basics
./rpc_demo.sh
```

## RPC Endpoint

All scripts use the local RPC endpoint:

- **HTTP**: `http://localhost:4444`
- **WebSocket**: `ws://localhost:4445`

## Network Details

| Network | Chain ID | Network ID | RPC Port |
| ------- | -------- | ---------- | -------- |
| Mainnet | 30       | 775        | 4444     |
| Testnet | 31       | 8100       | 4444     |
| Regtest | 33       | 7771       | 4444     |

## Useful Links

- [RSKj GitHub](https://github.com/rsksmart/rskj)
- [RSK Developer Portal](https://dev.rootstock.io/)
- [RSK Explorer (Mainnet)](https://explorer.rsk.co/)
- [RSK Explorer (Testnet)](https://explorer.testnet.rsk.co/)
