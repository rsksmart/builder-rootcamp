# Part 04: Smart Contracts

## Objective

Deploy and interact with smart contracts on RSKj using JSON-RPC.

## Contracts Included

1. **SimpleStorage.sol** - Store and retrieve a number

---

## Run the Demos

```bash
chmod +x deploy_storage.sh
./deploy_storage.sh

chmod +x interact_contract.sh
./interact_contract.sh
```

---

## Contract Deployment Flow

```
1. Compile contract → bytecode
2. Send transaction with bytecode (to: null)
3. Get transaction receipt
4. Extract contract address from receipt
5. Interact using contract address
```

---

## SimpleStorage Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 private value;

    function store(uint256 _value) public {
        value = _value;
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}
```

**Function Signatures:**

- `store(uint256)`: `0x6057361d`
- `retrieve()`: `0x6d4ce63c`

---

## Deploying a Contract

### 1. Estimate Gas

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_estimateGas",
    "params":[{
      "from":"0xCOINBASE",
      "data":"0xBYTECODE"
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

### 2. Send Deployment Transaction

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_sendTransaction",
    "params":[{
      "from":"0xCOINBASE",
      "data":"0xBYTECODE",
      "gas":"0x100000"
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

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

**Response (extract contractAddress):**

```json
{
  "result": {
    "contractAddress": "0x1234...",
    "status": "0x1",
    "gasUsed": "0x..."
  }
}
```

---

## Calling Contract Functions

### Read (eth_call) - No Gas, No Transaction

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_call",
    "params":[{
      "to":"0xCONTRACT_ADDRESS",
      "data":"0x6d4ce63c"
    },"latest"],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

### Write (eth_sendTransaction) - Requires Gas

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_sendTransaction",
    "params":[{
      "from":"0xCOINBASE",
      "to":"0xCONTRACT_ADDRESS",
      "data":"0x6057361d000000000000000000000000000000000000000000000000000000000000002a",
      "gas":"0x50000"
    }],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

---

## Encoding Function Calls

### Function Selector

First 4 bytes of keccak256 hash of function signature:

```
keccak256("store(uint256)") → 0x6057361d...
keccak256("retrieve()") → 0x6d4ce63c...
```

### Parameter Encoding

Parameters are ABI-encoded (32 bytes each):

```
store(42) = 0x6057361d + 000000000000000000000000000000000000000000000000000000000000002a
             ^^^^^^^^     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
             selector     42 in hex, padded to 32 bytes
```

---

## Get Contract Code

Verify contract is deployed:

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc":"2.0",
    "method":"eth_getCode",
    "params":["0xCONTRACT_ADDRESS","latest"],
    "id":1
  }' \
  http://localhost:4444 | jq .
```

---

## Contract Methods Reference

| Method                      | Description                     |
| --------------------------- | ------------------------------- |
| `eth_estimateGas`           | Estimate gas for transaction    |
| `eth_sendTransaction`       | Deploy or call contract         |
| `eth_call`                  | Read contract (no state change) |
| `eth_getTransactionReceipt` | Get deployment receipt          |
| `eth_getCode`               | Get contract bytecode           |

---

## Next Step

Proceed to [Part 05: Transactions](../part-05-transactions/README.md)
