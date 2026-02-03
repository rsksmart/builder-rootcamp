# Part 03: Account Management

## Objective

Learn how to create, manage, and query accounts on the RSKj node.

## Account Types

1. **Externally Owned Accounts (EOA)**: Controlled by private keys
2. **Contract Accounts**: Controlled by smart contract code

---

## Run the Demo

```bash
chmod +x account_demo.sh
./account_demo.sh
```

---

## Manual Examples

### 1. Create a New Account

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"personal_newAccount","params":["mypassword123"],"id":1}' \
  http://localhost:4444 | jq .
```

**Response:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x1234567890abcdef1234567890abcdef12345678"
}
```

---

### 2. List All Accounts

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"personal_listAccounts","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

**Alternative (eth module):**

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

---

### 3. Get Account Balance

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xYOUR_ADDRESS","latest"],"id":1}' \
  http://localhost:4444 | jq .
```

**Response (hex wei):**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0"
}
```

**Convert wei to RBTC:**

```bash
# 1 RBTC = 10^18 wei
# Example: 0xDE0B6B3A7640000 = 1000000000000000000 wei = 1 RBTC
```

---

### 4. Get Transaction Count (Nonce)

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["0xYOUR_ADDRESS","latest"],"id":1}' \
  http://localhost:4444 | jq .
```

The nonce is the number of transactions sent from this address.

---

### 5. Unlock Account

Before sending transactions, unlock the account:

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"personal_unlockAccount","params":["0xYOUR_ADDRESS","mypassword123",300],"id":1}' \
  http://localhost:4444 | jq .
```

Parameters:

- Address
- Password
- Duration in seconds (300 = 5 minutes)

---

### 6. Lock Account

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"personal_lockAccount","params":["0xYOUR_ADDRESS"],"id":1}' \
  http://localhost:4444 | jq .
```

---

### 7. Get Coinbase (Miner Address)

On Regtest, the coinbase has RBTC from mining:

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
  http://localhost:4444 | jq .
```

---

## Account Methods Reference

| Method                    | Description             |
| ------------------------- | ----------------------- |
| `personal_newAccount`     | Create new account      |
| `personal_listAccounts`   | List all accounts       |
| `personal_unlockAccount`  | Unlock for transactions |
| `personal_lockAccount`    | Lock account            |
| `personal_importRawKey`   | Import private key      |
| `eth_accounts`            | List unlocked accounts  |
| `eth_getBalance`          | Get account balance     |
| `eth_getTransactionCount` | Get nonce               |

---

## Important Notes

- **Regtest Coinbase**: Has unlimited funds from mining
- **Password Security**: In production, never use weak passwords
- **Wallet Location**: Stored in `~/.rsk/regtest/wallet/`

---

## Next Step

Proceed to [Part 04: Smart Contracts](../part-04-contracts/README.md)
