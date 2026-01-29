#!/bin/bash
# =============================================================================
# Deploy SimpleStorage Contract
# =============================================================================
# This script deploys a SimpleStorage contract that stores and retrieves
# a single uint256 value.
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

# SimpleStorage bytecode (compiled with solc 0.8.20)
# Functions: store(uint256) and retrieve()
BYTECODE="0x608060405234801561000f575f80fd5b506101438061001d5f395ff3fe608060405234801561000f575f80fd5b5060043610610034575f3560e01c80636057361d146100385780636d4ce63c14610054575b5f80fd5b610052600480360381019061004d91906100ba565b610072565b005b61005c61007b565b60405161006991906100f4565b60405180910390f35b805f8190555050565b5f8054905090565b5f80fd5b5f819050919050565b61009981610087565b81146100a3575f80fd5b50565b5f813590506100b481610090565b92915050565b5f602082840312156100cf576100ce610083565b5b5f6100dc848285016100a6565b91505092915050565b6100ee81610087565b82525050565b5f6020820190506101075f8301846100e5565b9291505056fea264697066735822122027"

echo "=============================================="
echo "Deploy SimpleStorage Contract"
echo "RPC Endpoint: $RPC_URL"
echo "=============================================="
echo ""

# Get coinbase
echo "=== 1. Getting Coinbase Address ==="
echo -e "${BLUE}Method: eth_coinbase${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_coinbase\",\"params\":[],\"id\":1}"
COINBASE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
    $RPC_URL | jq -r '.result')

if [ "$COINBASE" == "null" ] || [ -z "$COINBASE" ]; then
    echo -e "${RED}Error: Could not get coinbase. Is the node running?${NC}"
    exit 1
fi

echo -e "${GREEN}Response: Coinbase: $COINBASE${NC}"
echo ""
read -p "Press Enter to continue..."

# Estimate gas
echo "=== 2. Estimating Gas ==="
echo -e "${BLUE}Method: eth_estimateGas${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_estimateGas\",\"params\":[{\"from\":\"$COINBASE\",\"data\":\"$BYTECODE\"}],\"id\":1}"
GAS_ESTIMATE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_estimateGas\",\"params\":[{\"from\":\"$COINBASE\",\"data\":\"$BYTECODE\"}],\"id\":1}" \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Gas Estimate: $GAS_ESTIMATE${NC}"
echo ""
read -p "Press Enter to continue..."

# Deploy contract
echo "=== 3. Deploying Contract ==="
echo -e "${BLUE}Method: eth_sendTransaction${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$COINBASE\",\"data\":\"$BYTECODE\",\"gas\":\"0x100000\"}],\"id\":1}"
TX_HASH=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$COINBASE\",\"data\":\"$BYTECODE\",\"gas\":\"0x100000\"}],\"id\":1}" \
    $RPC_URL | jq -r '.result')

if [ "$TX_HASH" == "null" ] || [ -z "$TX_HASH" ]; then
    echo -e "${RED}Error: Transaction failed${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",\"params\":[{\"from\":\"$COINBASE\",\"data\":\"$BYTECODE\",\"gas\":\"0x100000\"}],\"id\":1}" \
        $RPC_URL | jq .
    exit 1
fi

echo -e "${GREEN}Response: Transaction Hash: $TX_HASH${NC}"
echo ""
echo "Waiting for mining (3 seconds)..."
sleep 3

# Get receipt
echo ""
echo "=== 4. Getting Transaction Receipt ==="
echo -e "${BLUE}Method: eth_getTransactionReceipt${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$TX_HASH\"],\"id\":1}"
RECEIPT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionReceipt\",\"params\":[\"$TX_HASH\"],\"id\":1}" \
    $RPC_URL)

echo -e "${GREEN}Response:${NC}"
echo "$RECEIPT" | jq .

CONTRACT_ADDRESS=$(echo "$RECEIPT" | jq -r '.result.contractAddress')
STATUS=$(echo "$RECEIPT" | jq -r '.result.status')

if [ "$STATUS" == "0x1" ]; then
    echo -e "${GREEN}✓ Contract deployed successfully!${NC}"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Contract Address: $CONTRACT_ADDRESS${NC}"

# Verify deployment
echo ""
echo "=== 5. Verifying Deployment (eth_getCode) ==="
echo -e "${BLUE}Method: eth_getCode${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$CONTRACT_ADDRESS\",\"latest\"],\"id\":1}"
CODE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$CONTRACT_ADDRESS\",\"latest\"],\"id\":1}" \
    $RPC_URL | jq -r '.result')

if [ "$CODE" != "0x" ] && [ -n "$CODE" ]; then
    echo -e "${GREEN}Response: ✓ Contract code verified (${#CODE} chars)${NC}"
else
    echo -e "${RED}Response: ✗ No code at address${NC}"
fi

# Save contract address
echo "$CONTRACT_ADDRESS" > /tmp/storage_contract.txt
echo ""
echo "Contract address saved to /tmp/storage_contract.txt"

echo ""
echo "=============================================="
echo "Deployment Complete!"
echo "=============================================="
echo ""
echo "Contract: SimpleStorage"
echo "Address: $CONTRACT_ADDRESS"
echo ""
echo "Functions:"
echo "  store(uint256): 0x6057361d"
echo "  retrieve():     0x6d4ce63c"
