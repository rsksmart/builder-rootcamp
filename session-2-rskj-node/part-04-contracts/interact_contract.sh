#!/bin/bash
# =============================================================================
# Interact with SimpleStorage Contract
# =============================================================================
# This script demonstrates reading and writing to a deployed contract.
# Run deploy_storage.sh first!
# =============================================================================

RPC_URL="http://localhost:4444"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Function selectors
STORE_SELECTOR="6057361d"
RETRIEVE_SELECTOR="6d4ce63c"

echo "=============================================="
echo "Interact with SimpleStorage Contract"
echo "RPC Endpoint: $RPC_URL"
echo "=============================================="
echo ""

# Check for contract address
if [ -f /tmp/storage_contract.txt ]; then
    CONTRACT=$(cat /tmp/storage_contract.txt)
    echo -e "${GREEN}Found contract: $CONTRACT${NC}"
else
    echo -e "${YELLOW}No saved contract found. Enter contract address:${NC}"
    read CONTRACT
fi

# Get coinbase
echo -e "${BLUE}Method: eth_coinbase${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_coinbase\",\"params\":[],\"id\":1}"
COINBASE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
    $RPC_URL | jq -r '.result')

echo -e "${GREEN}Response: Coinbase: $COINBASE${NC}"
echo ""

# 1. Read current value
echo "=== 1. Read Current Value (eth_call) ==="
echo -e "${YELLOW}This is a read-only call - no gas required${NC}"
echo -e "${BLUE}Method: eth_call${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$CONTRACT\",\"data\":\"0x$RETRIEVE_SELECTOR\"},\"latest\"],\"id\":1}"
RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$CONTRACT\",\"data\":\"0x$RETRIEVE_SELECTOR\"},\"latest\"],\"id\":1}" \
    $RPC_URL | jq -r '.result')

echo -e "${GREEN}Response:${NC}"
if [ "$RESULT" == "0x" ] || [ -z "$RESULT" ]; then
    echo "Current value: 0 (not initialized)"
else
    # Convert hex to decimal
    VALUE_DEC=$((16#${RESULT:2}))
    echo "Current value (hex): $RESULT"
    echo "Current value (dec): $VALUE_DEC"
fi
echo ""
read -p "Press Enter to continue..."

# 2. Store a value
echo "=== 2. Store Value 42 (eth_sendTransaction) ==="
echo -e "${YELLOW}This modifies state - requires gas${NC}"

# Encode: store(42) = 0x6057361d + 42 padded to 32 bytes
# 42 in hex = 0x2a
DATA="0x${STORE_SELECTOR}000000000000000000000000000000000000000000000000000000000000002a"
echo "Call data: $DATA"
echo ""

echo -e "${BLUE}Method: eth_sendTransaction${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$COINBASE\",\"to\":\"$CONTRACT\",\"data\":\"$DATA\",\"gas\":\"0x50000\"}],\"id\":1}"
TX_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$COINBASE\",\"to\":\"$CONTRACT\",\"data\":\"$DATA\",\"gas\":\"0x50000\"}],\"id\":1}" \
    $RPC_URL | jq -r '.result')

echo -e "${GREEN}Response: Transaction Hash: $TX_HASH${NC}"
echo ""
echo "Waiting for mining (2 seconds)..."
sleep 2

# Get receipt
echo ""
echo "=== 3. Transaction Receipt ==="
rpc_call "eth_getTransactionReceipt" "[\"$TX_HASH\"]"
read -p "Press Enter to continue..."

# 4. Read updated value
echo ""
echo "=== 4. Read Updated Value ==="
echo -e "${BLUE}Method: eth_call${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$CONTRACT\",\"data\":\"0x$RETRIEVE_SELECTOR\"},\"latest\"],\"id\":1}"
RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$CONTRACT\",\"data\":\"0x$RETRIEVE_SELECTOR\"},\"latest\"],\"id\":1}" \
    $RPC_URL | jq -r '.result')

echo -e "${GREEN}Response:${NC}"
VALUE_DEC=$((16#${RESULT:2}))
echo "Retrieved value (hex): $RESULT"
echo -e "${GREEN}Retrieved value (dec): $VALUE_DEC${NC}"
echo ""

# 5. Store another value
echo "=== 5. Store Value 100 ==="
# 100 in hex = 0x64
DATA="0x${STORE_SELECTOR}0000000000000000000000000000000000000000000000000000000000000064"

echo -e "${BLUE}Method: eth_sendTransaction${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$COINBASE\",\"to\":\"$CONTRACT\",\"data\":\"$DATA\",\"gas\":\"0x50000\"}],\"id\":1}"
TX_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$COINBASE\",\"to\":\"$CONTRACT\",\"data\":\"$DATA\",\"gas\":\"0x50000\"}],\"id\":1}" \
    $RPC_URL | jq -r '.result')

echo -e "${GREEN}Response: Transaction Hash: $TX_HASH${NC}"
sleep 2

echo -e "${BLUE}Method: eth_call${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$CONTRACT\",\"data\":\"0x$RETRIEVE_SELECTOR\"},\"latest\"],\"id\":1}"
RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$CONTRACT\",\"data\":\"0x$RETRIEVE_SELECTOR\"},\"latest\"],\"id\":1}" \
    $RPC_URL | jq -r '.result')

VALUE_DEC=$((16#${RESULT:2}))
echo -e "${GREEN}Response: New value: $VALUE_DEC${NC}"

echo ""
echo "=============================================="
echo "Interaction Complete!"
echo "=============================================="
