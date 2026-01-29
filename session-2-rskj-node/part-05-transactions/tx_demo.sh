#!/bin/bash
# =============================================================================
# RSKj Transaction Demo
# =============================================================================
# This script demonstrates sending transactions and analyzing receipts.
# =============================================================================

RPC_URL="http://localhost:4444"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Helper function for RPC calls
rpc_call() {
    local method=$1
    local params=$2
    echo -e "${BLUE}Method: ${method}${NC}"
    echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params,\"id\":1}"
    echo -e "${GREEN}Response:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params,\"id\":1}" \
        $RPC_URL | jq .
    echo ""
}

echo "=============================================="
echo "RSKj Transaction Demo"
echo "RPC Endpoint: $RPC_URL"
echo "=============================================="
echo ""

# Get pre-funded account (cow account in regtest)
echo "=== 1. Get Sender Account ==="
# The cow account is pre-funded in RSKj regtest
SENDER="0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826"
echo -e "${GREEN}Sender (pre-funded cow account): $SENDER${NC}"
echo ""

# Create recipient account
echo "=== 2. Create Recipient Account ==="
echo -e "${BLUE}Method: personal_newAccount${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"personal_newAccount\",\"params\":[\"txdemo\"],\"id\":1}"
RECIPIENT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"personal_newAccount","params":["txdemo"],"id":1}' \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Recipient: $RECIPIENT${NC}"
echo ""
read -p "Press Enter to continue..."

# Check initial balances
echo "=== 3. Check Initial Balances ==="
echo -e "${YELLOW}Sender balance:${NC}"
rpc_call "eth_getBalance" "[\"$SENDER\",\"latest\"]"

echo -e "${YELLOW}Recipient balance:${NC}"
rpc_call "eth_getBalance" "[\"$RECIPIENT\",\"latest\"]"
read -p "Press Enter to continue..."

# Send transaction
echo ""
echo "=== 4. Send 1 RBTC Transaction ==="
echo -e "${CYAN}Transaction Parameters Being Used:${NC}"
echo -e "  ${MAGENTA}from${NC}:  $SENDER (sender, pays gas)"
echo -e "  ${MAGENTA}to${NC}:    $RECIPIENT (recipient)"
echo -e "  ${MAGENTA}value${NC}: 0xDE0B6B3A7640000 (1 RBTC = 10^18 wei)"
echo -e "  ${MAGENTA}gas${NC}:   (not specified - node will estimate)"
echo -e "  ${MAGENTA}data${NC}:  (not specified - simple value transfer)"
echo -e "  ${MAGENTA}nonce${NC}: (not specified - node uses next available)"
echo ""
echo -e "${BLUE}Method: eth_sendTransaction${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$SENDER\",\"to\":\"$RECIPIENT\",\"value\":\"0xDE0B6B3A7640000\"}],\"id\":1}"
TX_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$SENDER\",\"to\":\"$RECIPIENT\",\"value\":\"0xDE0B6B3A7640000\"}],\"id\":1}" \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Transaction Hash: $TX_HASH${NC}"
echo ""
echo -e "${YELLOW}The hash is returned immediately - but the tx is NOT yet mined!${NC}"
echo -e "${YELLOW}You must check the receipt to confirm success.${NC}"
echo ""
echo "Waiting for mining (2 seconds)..."
sleep 2
read -p "Press Enter to continue..."

# Get transaction details
echo ""
echo "=== 5. Get Transaction Details (eth_getTransactionByHash) ==="
echo -e "${BLUE}Method: eth_getTransactionByHash${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionByHash\",\"params\":[\"$TX_HASH\"],\"id\":1}"
TX_DETAILS=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionByHash\",\"params\":[\"$TX_HASH\"],\"id\":1}" \
    $RPC_URL)
echo -e "${GREEN}Response:${NC}"
echo "$TX_DETAILS" | jq .

echo ""
echo -e "${CYAN}=== Transaction Fields Explained ===${NC}"
echo -e "${MAGENTA}hash${NC}             - Unique transaction identifier (use this to track the tx)"
echo -e "${MAGENTA}nonce${NC}            - Sender's tx count when this was sent (prevents replay attacks)"
echo -e "${MAGENTA}blockHash${NC}        - Hash of block containing this tx (null if pending)"
echo -e "${MAGENTA}blockNumber${NC}      - Block number where tx was included (null if pending)"
echo -e "${MAGENTA}transactionIndex${NC} - Position in the block (0 = first tx in block)"
echo -e "${MAGENTA}from${NC}             - Sender address (who paid for gas)"
echo -e "${MAGENTA}to${NC}               - Recipient address (null for contract deployment)"
echo -e "${MAGENTA}value${NC}            - Amount transferred in wei (hex-encoded)"
echo -e "${MAGENTA}gas${NC}              - Gas limit set by sender"
echo -e "${MAGENTA}gasPrice${NC}         - Price per gas unit in wei"
echo -e "${MAGENTA}input${NC}            - Transaction data (0x for simple transfer, bytecode for contracts)"
echo ""

# Extract and display key values
TX_BLOCK=$(echo "$TX_DETAILS" | jq -r '.result.blockNumber')
TX_VALUE=$(echo "$TX_DETAILS" | jq -r '.result.value')
TX_GAS=$(echo "$TX_DETAILS" | jq -r '.result.gas')
TX_NONCE=$(echo "$TX_DETAILS" | jq -r '.result.nonce')

echo -e "${YELLOW}Key Values (decoded):${NC}"
if [ "$TX_BLOCK" != "null" ]; then
    echo "  Block Number: $TX_BLOCK ($(printf "%d" $TX_BLOCK))"
else
    echo "  Block Number: pending (not yet mined)"
fi
echo "  Value: $TX_VALUE wei = $(echo "scale=4; $(printf "%d" $TX_VALUE) / 1000000000000000000" | bc) RBTC"
echo "  Gas Limit: $TX_GAS ($(printf "%d" $TX_GAS) units)"
echo "  Nonce: $TX_NONCE ($(printf "%d" $TX_NONCE))"
read -p "Press Enter to continue..."

# Get transaction receipt
echo ""
echo "=== 6. Get Transaction Receipt ==="
echo -e "${YELLOW}The receipt is only available AFTER a transaction is mined.${NC}"
echo -e "${YELLOW}It contains the execution results - crucial for dApp development!${NC}"
echo ""
echo -e "${BLUE}Method: eth_getTransactionReceipt${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$TX_HASH\"],\"id\":1}"
RECEIPT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$TX_HASH\"],\"id\":1}" \
    $RPC_URL)
echo -e "${GREEN}Response:${NC}"
echo "$RECEIPT" | jq .

echo ""
echo -e "${CYAN}=== Receipt Fields Explained ===${NC}"
echo -e "${MAGENTA}transactionHash${NC}    - Same hash used to query this receipt"
echo -e "${MAGENTA}transactionIndex${NC}   - Position of tx in the block"
echo -e "${MAGENTA}blockHash${NC}          - Block containing this transaction"
echo -e "${MAGENTA}blockNumber${NC}        - Block number where tx was included"
echo -e "${MAGENTA}from${NC}               - Sender address"
echo -e "${MAGENTA}to${NC}                 - Recipient (null for contract deployment)"
echo -e "${MAGENTA}contractAddress${NC}    - NEW CONTRACT ADDRESS if this was a deployment, else null"
echo -e "${MAGENTA}cumulativeGasUsed${NC}  - Total gas used in block up to this tx"
echo -e "${MAGENTA}gasUsed${NC}            - ACTUAL gas consumed by THIS transaction"
echo -e "${MAGENTA}logs${NC}               - Event logs emitted (critical for dApps!)"
echo -e "${MAGENTA}logsBloom${NC}          - Bloom filter for quick log searching"
echo -e "${MAGENTA}status${NC}             - 0x1 = SUCCESS, 0x0 = REVERTED/FAILED"
echo ""

# Extract and display key values
STATUS=$(echo "$RECEIPT" | jq -r '.result.status')
GAS_USED=$(echo "$RECEIPT" | jq -r '.result.gasUsed')
CONTRACT_ADDR=$(echo "$RECEIPT" | jq -r '.result.contractAddress')
LOGS_COUNT=$(echo "$RECEIPT" | jq '.result.logs | length')

echo -e "${YELLOW}Key Values for DApp Development:${NC}"
if [ "$STATUS" == "0x1" ]; then
    echo -e "  Status: ${GREEN}0x1 (SUCCESS)${NC} - Transaction executed without reverting"
else
    echo -e "  Status: ${RED}0x0 (FAILED)${NC} - Transaction reverted, state changes rolled back"
fi
echo "  Gas Used: $GAS_USED ($(printf "%d" $GAS_USED) units) - This is what you actually paid for"
if [ "$CONTRACT_ADDR" != "null" ]; then
    echo -e "  Contract Address: ${GREEN}$CONTRACT_ADDR${NC} - Your new contract lives here!"
else
    echo "  Contract Address: null (this was not a contract deployment)"
fi
echo "  Logs Count: $LOGS_COUNT event(s) emitted"

if [ "$LOGS_COUNT" -gt 0 ]; then
    echo ""
    echo -e "${CYAN}Events emitted:${NC}"
    echo "$RECEIPT" | jq -r '.result.logs[] | "  Topic[0]: \(.topics[0])\n  Address: \(.address)"'
fi
read -p "Press Enter to continue..."

# Check updated balances
echo ""
echo "=== 7. Check Updated Balances ==="
echo -e "${YELLOW}Recipient balance:${NC}"
echo -e "${BLUE}Method: eth_getBalance${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$RECIPIENT\",\"latest\"],\"id\":1}"
BALANCE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$RECIPIENT\",\"latest\"],\"id\":1}" \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response:${NC}"
echo "Balance (hex): $BALANCE"
BALANCE_DEC=$((16#${BALANCE:2}))
echo -e "${GREEN}Balance (wei): $BALANCE_DEC${NC}"
echo ""
read -p "Press Enter to continue..."

# Get block with transaction
echo ""
echo "=== 8. Get Block with Transaction ==="
BLOCK_NUM=$(echo "$RECEIPT" | jq -r '.result.blockNumber')
echo "Block number: $BLOCK_NUM"
echo -e "${BLUE}Method: eth_getBlockByNumber${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"$BLOCK_NUM\",true],\"id\":1}"
echo -e "${GREEN}Response:${NC}"
curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"$BLOCK_NUM\",true],\"id\":1}" \
    $RPC_URL | jq '.result | {number, hash, transactions: [.transactions[].hash]}'
read -p "Press Enter to continue..."

# Send another transaction
echo ""
echo "=== 9. Send 0.5 RBTC Transaction ==="
echo -e "${BLUE}Method: eth_sendTransaction${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$SENDER\",\"to\":\"$RECIPIENT\",\"value\":\"0x6F05B59D3B20000\"}],\"id\":1}"
TX_HASH2=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$SENDER\",\"to\":\"$RECIPIENT\",\"value\":\"0x6F05B59D3B20000\"}],\"id\":1}" \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Transaction Hash: $TX_HASH2${NC}"
sleep 2

# Get transaction count
echo ""
echo "=== 10. Get Transaction Count (Nonce) ==="
echo -e "${CYAN}The nonce is critical for transaction ordering and preventing replays.${NC}"
echo ""
echo -e "${BLUE}Method: eth_getTransactionCount${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionCount\",\"params\":[\"$SENDER\",\"latest\"],\"id\":1}"
NONCE_RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionCount\",\"params\":[\"$SENDER\",\"latest\"],\"id\":1}" \
    $RPC_URL)
echo -e "${GREEN}Response:${NC}"
echo "$NONCE_RESULT" | jq .

CURRENT_NONCE=$(echo "$NONCE_RESULT" | jq -r '.result')
echo ""
echo -e "${YELLOW}Understanding the Nonce:${NC}"
echo "  Current nonce: $CURRENT_NONCE ($(printf "%d" $CURRENT_NONCE) in decimal)"
echo "  This means the sender has sent $(printf "%d" $CURRENT_NONCE) transactions"
echo "  Next transaction must use nonce $(printf "%d" $CURRENT_NONCE)"
echo ""
echo -e "${CYAN}Why it matters for dApps:${NC}"
echo "  - If you skip a nonce, subsequent txs won't be mined"
echo "  - If you reuse a nonce, the tx will be rejected (or replace the previous)"
echo "  - Use 'pending' instead of 'latest' to include pending txs in count"

echo ""
echo "=============================================="
echo "Transaction Demo Complete!"
echo "=============================================="
echo ""
echo "Summary:"
echo "  Sender: $SENDER"
echo "  Recipient: $RECIPIENT"
echo "  TX 1: $TX_HASH"
echo "  TX 2: $TX_HASH2"
echo ""
echo -e "${CYAN}=== Key Takeaways for DApp Development ===${NC}"
echo ""
echo "1. SENDING TRANSACTIONS:"
echo "   - Use eth_sendTransaction (node signs) or eth_sendRawTransaction (pre-signed)"
echo "   - Returns tx hash immediately, but tx is NOT confirmed yet"
echo ""
echo "2. CHECKING TRANSACTION STATUS:"
echo "   - eth_getTransactionByHash: Check if mined (blockNumber != null)"
echo "   - eth_getTransactionReceipt: Check success (status = 0x1)"
echo ""
echo "3. IMPORTANT RECEIPT FIELDS:"
echo "   - status: 0x1 = success, 0x0 = reverted"
echo "   - gasUsed: Actual gas consumed (for cost calculation)"
echo "   - contractAddress: New contract address (for deployments)"
echo "   - logs: Events emitted (critical for dApp state updates!)"
echo ""
echo "4. NONCE MANAGEMENT:"
echo "   - Must be sequential per account"
echo "   - Use eth_getTransactionCount to get next nonce"
echo ""
