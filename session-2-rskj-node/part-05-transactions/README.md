# Part 05: Transactions

## Objective

Learn how to send transactions and analyze transaction data.

## Transaction Types

1. **Value Transfer**: Send RBTC between accounts
2. **Contract Deployment**: Create new contract (to = null)
3. **Contract Call**: Interact with contract

---

## Run the Demo

```bash
chmod +x tx_demo.sh
./tx_demo.sh
```

---

## Transaction Structure (Input Parameters)

When sending a transaction, you provide these parameters:

```json
{
  "from": "0x...",
  "to": "0x...",
  "value": "0x...",
  "data": "0x...",
  "gas": "0x...",
  "gasPrice": "0x...",
  "nonce": "0x..."
}
```

### Field-by-Field Explanation

| Field | Required | Description |
| ----- | -------- | ----------- |
| `from` | Yes | The address sending the transaction. Must be unlocked on the node or signed client-side. |
| `to` | No | The recipient address. Set to `null` or omit for contract deployment. |
| `value` | No | Amount of RBTC to send (in wei, hex-encoded). Defaults to `0x0`. |
| `data` | No | For contract deployment: compiled bytecode. For contract calls: encoded function signature + arguments. |
| `gas` | No | Maximum gas units allowed. If omitted, the node estimates it. |
| `gasPrice` | No | Price per gas unit (in wei). If omitted, uses node's suggested price. |
| `nonce` | No | Transaction sequence number for the sender. If omitted, node uses next available nonce. |

### Understanding Each Field for DApp Development

**`from` - Sender Address**
- This is the account paying for gas and signing the transaction
- In a dApp, this comes from the user's wallet (e.g., MetaMask provides this)
- The account must have enough balance for `value + (gas × gasPrice)`

**`to` - Recipient Address**
- For **value transfers**: the address receiving RBTC
- For **contract calls**: the contract address you're interacting with
- For **contract deployment**: must be `null` or omitted (the contract address is generated)

**`value` - Transfer Amount**
- Always in wei (1 RBTC = 10^18 wei)
- Must be hex-encoded (e.g., `"0xDE0B6B3A7640000"` = 1 RBTC)
- For non-payable contract functions, set to `"0x0"` or omit

**`data` - Transaction Payload**
- **Empty (`"0x"`)**: Simple RBTC transfer
- **Contract deployment**: Full contract bytecode + constructor arguments (ABI-encoded)
- **Contract call**: Function selector (4 bytes) + ABI-encoded arguments

```
Example data for transfer(address,uint256):
0xa9059cbb                                                         <- function selector
000000000000000000000000recipient_address_here_padded_to_32_bytes  <- address arg
0000000000000000000000000000000000000000000000000de0b6b3a7640000   <- uint256 arg
```

**`gas` - Gas Limit**
- Maximum gas units the transaction can consume
- Unused gas is refunded; if exceeded, transaction reverts (you still pay)
- Simple transfer: 21,000 gas. Contract calls: varies (use `eth_estimateGas`)

**`gasPrice` - Gas Price**
- How much you pay per gas unit (in wei)
- Higher price = faster inclusion in a block
- On RSK, typically much lower than Ethereum mainnet

**`nonce` - Transaction Counter**
- Prevents replay attacks and ensures transaction ordering
- Must be sequential (0, 1, 2...) per account
- If you skip a nonce, subsequent transactions won't be mined until the gap is filled

---

## Send RBTC Transfer

### 1. Send Transaction

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_sendTransaction",
    "params":[{
      "from":"0xCOINBASE",
      "to":"0xRECIPIENT",
      "value":"0xDE0B6B3A7640000"
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

**Value Examples:**

- `0xDE0B6B3A7640000` = 1 RBTC (10^18 wei)
- `0x16345785D8A0000` = 0.1 RBTC
- `0x2386F26FC10000` = 0.01 RBTC

---

### 2. Get Transaction by Hash

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getTransactionByHash",
    "params":["0xTX_HASH"],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "result": {
    "hash": "0x...",
    "nonce": "0x0",
    "blockHash": "0x...",
    "blockNumber": "0x10",
    "transactionIndex": "0x0",
    "from": "0x...",
    "to": "0x...",
    "value": "0xDE0B6B3A7640000",
    "gas": "0x5208",
    "gasPrice": "0x...",
    "input": "0x"
  }
}
```

### Transaction Object Fields Explained

| Field | Description |
| ----- | ----------- |
| `hash` | Unique 32-byte transaction identifier. Use this to track the transaction. |
| `nonce` | The sender's transaction count at the time this tx was sent. |
| `blockHash` | Hash of the block containing this transaction. `null` if pending. |
| `blockNumber` | Block number where this tx was included. `null` if pending. |
| `transactionIndex` | Position of this tx within the block (0-indexed). `null` if pending. |
| `from` | Address of the sender. |
| `to` | Address of the recipient. `null` for contract creation. |
| `value` | Amount of wei transferred. |
| `gas` | Gas limit set by the sender. |
| `gasPrice` | Gas price in wei set by the sender. |
| `input` | The `data` field from the original transaction (bytecode or call data). |

### How to Use This in Your DApp

**Check if transaction is mined:**
```javascript
const tx = await provider.getTransaction(txHash);
if (tx.blockNumber === null) {
  console.log("Transaction is still pending");
} else {
  console.log(`Mined in block ${parseInt(tx.blockNumber, 16)}`);
}
```

**Decode transaction input:**
- The `input` field contains the raw data. Use ABI decoders to interpret it.
- First 4 bytes = function selector, remaining bytes = encoded arguments.

---

### 3. Get Transaction Receipt

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getTransactionReceipt",
    "params":["0xTX_HASH"],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "result": {
    "transactionHash": "0x...",
    "transactionIndex": "0x0",
    "blockHash": "0x...",
    "blockNumber": "0x10",
    "from": "0x...",
    "to": "0x...",
    "contractAddress": null,
    "cumulativeGasUsed": "0x5208",
    "gasUsed": "0x5208",
    "logs": [],
    "logsBloom": "0x...",
    "status": "0x1"
  }
}
```

### Transaction Receipt Fields Explained

The receipt is only available **after** a transaction is mined. It contains the execution results.

| Field | Description |
| ----- | ----------- |
| `transactionHash` | The transaction's unique identifier. |
| `transactionIndex` | Position in the block (0-indexed). |
| `blockHash` | Hash of the block containing this transaction. |
| `blockNumber` | Block number where this transaction was included. |
| `from` | Sender address. |
| `to` | Recipient address (`null` for contract deployment). |
| `contractAddress` | If this was a deployment, the new contract's address. Otherwise `null`. |
| `cumulativeGasUsed` | Total gas used in the block up to and including this transaction. |
| `gasUsed` | **Actual gas consumed** by this specific transaction. |
| `logs` | Array of event logs emitted during execution. |
| `logsBloom` | Bloom filter for quick log searching (used by nodes). |
| `status` | `0x1` = success, `0x0` = reverted/failed. |

### Key Fields for DApp Developers

**`status` - Did It Succeed?**
```javascript
const receipt = await provider.getTransactionReceipt(txHash);
if (receipt.status === "0x1") {
  console.log("Transaction succeeded!");
} else {
  console.log("Transaction failed/reverted");
}
```
- `0x1` (or `1`): Transaction executed successfully
- `0x0` (or `0`): Transaction reverted (state changes rolled back, gas still consumed)

**`gasUsed` - Actual Cost**
```javascript
// Calculate actual transaction cost
const gasUsed = parseInt(receipt.gasUsed, 16);
const gasPrice = parseInt(tx.gasPrice, 16);
const actualCost = gasUsed * gasPrice; // in wei
console.log(`Transaction cost: ${actualCost / 1e18} RBTC`);
```
- Always ≤ the gas limit you set
- Simple transfers: exactly 21,000 (0x5208)
- Contract interactions: varies based on operations performed

**`contractAddress` - New Contract Location**
```javascript
if (receipt.contractAddress) {
  console.log(`Contract deployed at: ${receipt.contractAddress}`);
  // You can now interact with this address
}
```
- Only populated for contract deployment transactions
- This is where your new contract lives on the blockchain

**`logs` - Event Data (Critical for DApps!)**
```javascript
// Example: ERC-20 Transfer event log
{
  "address": "0xContractAddress",     // Contract that emitted the event
  "topics": [
    "0xddf252ad...",                  // Event signature hash (Transfer)
    "0x000...sender",                 // Indexed param: from
    "0x000...recipient"               // Indexed param: to  
  ],
  "data": "0x000...amount",           // Non-indexed params (ABI-encoded)
  "blockNumber": "0x10",
  "transactionHash": "0x...",
  "logIndex": "0x0"                   // Position in block's logs
}
```

### Understanding Event Logs

Logs are how smart contracts communicate results to your frontend:

| Log Field | Description |
| --------- | ----------- |
| `address` | The contract that emitted this event. |
| `topics[0]` | Keccak256 hash of the event signature (e.g., `Transfer(address,address,uint256)`). |
| `topics[1-3]` | Indexed event parameters (up to 3). Useful for filtering. |
| `data` | Non-indexed parameters, ABI-encoded. Must be decoded to read. |
| `logIndex` | Position of this log in the block's log list. |
| `removed` | `true` if log was removed due to chain reorganization. |

**Example: Parsing a Transfer Event**
```javascript
// Event: Transfer(address indexed from, address indexed to, uint256 value)
const log = receipt.logs[0];
const from = "0x" + log.topics[1].slice(26);  // Remove padding
const to = "0x" + log.topics[2].slice(26);
const value = parseInt(log.data, 16);         // Decode data
console.log(`Transfer: ${from} -> ${to}: ${value} tokens`);
```

### Receipt vs Transaction: When to Use Each

| Need to Know | Use This |
| ------------ | -------- |
| Was tx mined? | `eth_getTransactionByHash` (check `blockNumber !== null`) |
| Did tx succeed? | `eth_getTransactionReceipt` (check `status`) |
| How much gas used? | `eth_getTransactionReceipt` (`gasUsed`) |
| What events emitted? | `eth_getTransactionReceipt` (`logs`) |
| New contract address? | `eth_getTransactionReceipt` (`contractAddress`) |
| Original tx parameters? | `eth_getTransactionByHash` (`value`, `input`, etc.) |

---

## Get Block with Transactions

```bash
# Get block by number with full transactions
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getBlockByNumber",
    "params":["latest", true],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

The second parameter:

- `true` = Include full transaction objects
- `false` = Include only transaction hashes

---

## Get Transaction by Block

```bash
# Get transaction at index 0 in block
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getTransactionByBlockNumberAndIndex",
    "params":["0x10", "0x0"],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

---

## Pending Transactions

```bash
# Get pending transactions
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_pendingTransactions","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

---

## Transaction Methods Reference

| Method                                    | Description                 |
| ----------------------------------------- | --------------------------- |
| `eth_sendTransaction`                     | Send transaction            |
| `eth_sendRawTransaction`                  | Send signed transaction     |
| `eth_getTransactionByHash`                | Get transaction by hash     |
| `eth_getTransactionReceipt`               | Get transaction receipt     |
| `eth_getTransactionByBlockNumberAndIndex` | Get tx by block position    |
| `eth_getTransactionByBlockHashAndIndex`   | Get tx by block hash        |
| `eth_pendingTransactions`                 | List pending transactions   |
| `eth_getBlockTransactionCountByNumber`    | Count transactions in block |

---

## Value Conversions

| RBTC  | Wei (Decimal)       | Wei (Hex)         |
| ----- | ------------------- | ----------------- |
| 1     | 1000000000000000000 | 0xDE0B6B3A7640000 |
| 0.1   | 100000000000000000  | 0x16345785D8A0000 |
| 0.01  | 10000000000000000   | 0x2386F26FC10000  |
| 0.001 | 1000000000000000    | 0x38D7EA4C68000   |

---

## Common DApp Patterns

### Pattern 1: Wait for Transaction Confirmation

```javascript
async function waitForTransaction(txHash, confirmations = 1) {
  // Poll until receipt is available
  let receipt = null;
  while (!receipt) {
    receipt = await provider.send("eth_getTransactionReceipt", [txHash]);
    if (!receipt) await sleep(1000); // Wait 1 second
  }
  
  // Check success
  if (receipt.status !== "0x1") {
    throw new Error("Transaction reverted");
  }
  
  return receipt;
}
```

### Pattern 2: Estimate Gas Before Sending

```javascript
// Always estimate gas for contract calls
const estimatedGas = await provider.send("eth_estimateGas", [{
  from: userAddress,
  to: contractAddress,
  data: encodedFunctionCall
}]);

// Add 20% buffer for safety
const gasLimit = Math.floor(parseInt(estimatedGas, 16) * 1.2);
```

### Pattern 3: Handle Pending Transactions

```javascript
// Transaction might not have receipt yet
const receipt = await provider.getTransactionReceipt(txHash);
if (receipt === null) {
  // Check if tx exists but is pending
  const tx = await provider.getTransaction(txHash);
  if (tx === null) {
    console.log("Transaction not found - may have been dropped");
  } else {
    console.log("Transaction pending, waiting for mining...");
  }
}
```

---

## Next Step

Proceed to [Part 06: Logs & Events](../part-06-logs/README.md)
