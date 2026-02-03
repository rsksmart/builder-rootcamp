# Part 02: RPC Basics

## Objective

Learn the essential JSON-RPC methods to interact with an RSKj node.

## What is JSON-RPC?

JSON-RPC is a stateless, lightweight protocol for remote procedure calls:

- Transport: HTTP or WebSocket
- Format: JSON
- RSK implements Ethereum-compatible methods (eth*\*, web3*\_, net\_\_)

---

## Run the Demo

```bash
chmod +x rpc_demo.sh
./rpc_demo.sh
```

---

## Manual Examples

### 1. Get Client Version

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "RskJ/6.4.0/Linux/Java17"
}
```

---

### 2. Get Current Block Number

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x1a4"
}
```

**Convert hex to decimal:**

```bash
echo $((16#1a4))
# Output: 420
```

---

### 3. Get Network Version

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "7771"
}
```

Network IDs:

- `775` = Mainnet
- `8100` = Testnet
- `7771` = Regtest

---

### 4. Check Sync Status

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

**Response (not syncing):**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": false
}
```

---

### 5. List Available RPC Modules

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"rpc_modules","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "eth": "1.0",
    "net": "1.0",
    "rpc": "1.0",
    "web3": "1.0",
    "evm": "1.0",
    "txpool": "1.0",
    "personal": "1.0",
    "rsk": "1.0"
  }
}
```

---

## JSON-RPC Request Structure

```json
{
  "jsonrpc": "2.0", // Protocol version (always "2.0")
  "method": "eth_blockNumber", // Method name
  "params": [], // Method parameters (array)
  "id": 1 // Request ID (for matching responses)
}
```

---

## Common RPC Methods Reference

| Method               | Description                 |
| -------------------- | --------------------------- |
| `web3_clientVersion` | Node software version       |
| `net_version`        | Network ID                  |
| `net_peerCount`      | Number of connected peers   |
| `eth_chainId`        | Chain ID (hex)              |
| `eth_blockNumber`    | Current block height (hex)  |
| `eth_gasPrice`       | Current gas price (hex wei) |
| `eth_syncing`        | Sync status                 |
| `eth_mining`         | Mining status               |
| `eth_coinbase`       | Coinbase address            |
| `rpc_modules`        | Available RPC modules       |

---
