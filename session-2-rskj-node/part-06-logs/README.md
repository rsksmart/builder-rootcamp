# Part 06: Logs & Events

## Objective

Learn how to query and filter blockchain logs (events emitted by contracts).

## What are Logs?

Logs are events emitted by smart contracts:

- Indexed for efficient querying
- Stored in transaction receipts
- Used for off-chain notifications
- Cheaper than storage

---

## Run the Demo

```bash
chmod +x logs_demo.sh
./logs_demo.sh
```

---

## Event Structure

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```

- **Event Signature**: `keccak256("Transfer(address,address,uint256)")`
- **Topics[0]**: Event signature hash
- **Topics[1]**: First indexed parameter (`from`)
- **Topics[2]**: Second indexed parameter (`to`)
- **Data**: Non-indexed parameters (`value`)

---

## Common Event Signatures

| Event                                 | Signature (keccak256)                                                |
| ------------------------------------- | -------------------------------------------------------------------- |
| Transfer(address,address,uint256)     | `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef` |
| Approval(address,address,uint256)     | `0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925` |
| OwnershipTransferred(address,address) | `0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0` |

---

## Get Logs

### Basic Query (Last N Blocks)

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getLogs",
    "params":[{
      "fromBlock":"0x0",
      "toBlock":"latest"
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

### Filter by Contract Address

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getLogs",
    "params":[{
      "address":"0xCONTRACT_ADDRESS",
      "fromBlock":"0x0",
      "toBlock":"latest"
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

### Filter by Topic (Event Type)

```bash
# Get all Transfer events
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getLogs",
    "params":[{
      "topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"],
      "fromBlock":"0x0",
      "toBlock":"latest"
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

---

## Log Filters (Real-time)

### 1. Create Block Filter

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_newBlockFilter","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

### 2. Create Log Filter

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_newFilter",
    "params":[{
      "topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"]
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

### 3. Poll for Changes

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getFilterChanges","params":["0xFILTER_ID"],"id":1}' \
  http://localhost:4444 | jq .
```

### 4. Uninstall Filter

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_uninstallFilter","params":["0xFILTER_ID"],"id":1}' \
  http://localhost:4444 | jq .
```

---

## Transaction Pool

### Get Pool Status

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "result": {
    "pending": "0x0",
    "queued": "0x0"
  }
}
```

### Get Pool Content

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"txpool_content","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

---

## Log Response Structure

```json
{
  "address": "0x...", // Contract address
  "topics": [
    // Indexed parameters
    "0x...", // Event signature
    "0x...", // Indexed param 1
    "0x..." // Indexed param 2
  ],
  "data": "0x...", // Non-indexed parameters
  "blockNumber": "0x10",
  "transactionHash": "0x...",
  "transactionIndex": "0x0",
  "blockHash": "0x...",
  "logIndex": "0x0",
  "removed": false
}
```

---

## Log Methods Reference

| Method                            | Description              |
| --------------------------------- | ------------------------ |
| `eth_getLogs`                     | Query historical logs    |
| `eth_newFilter`                   | Create log filter        |
| `eth_newBlockFilter`              | Create block filter      |
| `eth_newPendingTransactionFilter` | Create pending tx filter |
| `eth_getFilterChanges`            | Poll filter for changes  |
| `eth_getFilterLogs`               | Get all logs for filter  |
| `eth_uninstallFilter`             | Remove filter            |

---

## Next Step

Proceed to [Part 07: Node Configuration](../part-07-configuration/README.md)
