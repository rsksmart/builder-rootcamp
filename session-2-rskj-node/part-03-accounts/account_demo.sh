#!/bin/bash
# =============================================================================
# RSKj Account Management Demo
# =============================================================================
# This script demonstrates account creation and management on RSKj.
# =============================================================================

RPC_URL="http://localhost:4444"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
echo "RSKj Account Management Demo"
echo "RPC Endpoint: $RPC_URL"
echo "=============================================="
echo ""

echo "=== 1. Get Coinbase (Miner Address) ==="
echo "The coinbase has RBTC from mining rewards"
echo -e "${BLUE}Method: eth_coinbase${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_coinbase\",\"params\":[],\"id\":1}"
COINBASE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Coinbase: $COINBASE${NC}"
echo ""
read -p "Press Enter to continue..."

echo "=== 2. Check Coinbase Balance ==="
rpc_call "eth_getBalance" "[\"$COINBASE\",\"latest\"]"
BALANCE_HEX=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$COINBASE\",\"latest\"],\"id\":1}" \
    $RPC_URL | jq -r '.result')
echo -e "${YELLOW}Balance (hex): $BALANCE_HEX${NC}"
echo ""
read -p "Press Enter to continue..."

echo "=== 3. Create New Account ==="
echo "Creating account with password 'bootcamp123'"
echo -e "${BLUE}Method: personal_newAccount${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"personal_newAccount\",\"params\":[\"bootcamp123\"],\"id\":1}"
NEW_ACCOUNT=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"personal_newAccount","params":["bootcamp123"],"id":1}' \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: New Account Created: $NEW_ACCOUNT${NC}"
echo ""
read -p "Press Enter to continue..."

echo "=== 4. List All Accounts ==="
rpc_call "personal_listAccounts" "[]"
read -p "Press Enter to continue..."

echo "=== 5. Check New Account Balance ==="
echo "New accounts start with 0 balance"
rpc_call "eth_getBalance" "[\"$NEW_ACCOUNT\",\"latest\"]"
read -p "Press Enter to continue..."

echo "=== 6. Get Transaction Count (Nonce) ==="
echo "Nonce = number of transactions sent from this address"
rpc_call "eth_getTransactionCount" "[\"$NEW_ACCOUNT\",\"latest\"]"
read -p "Press Enter to continue..."

echo "=== 7. Unlock Account ==="
echo "Unlocking account for 300 seconds (5 minutes)"
rpc_call "personal_unlockAccount" "[\"$NEW_ACCOUNT\",\"bootcamp123\",\"0x12c\"]"
read -p "Press Enter to continue..."

echo "=== 8. List Unlocked Accounts (eth_accounts) ==="
rpc_call "eth_accounts" "[]"

echo "=============================================="
echo "Demo Complete!"
echo "=============================================="
echo ""
echo -e "${YELLOW}Account Information:${NC}"
echo "  Coinbase: $COINBASE"
echo "  New Account: $NEW_ACCOUNT"
echo "  Password: bootcamp123"
echo ""

# Save for later use
echo "$NEW_ACCOUNT" > /tmp/bootcamp_account.txt
echo "Account saved to /tmp/bootcamp_account.txt"
