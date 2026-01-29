#!/bin/bash
# =============================================================================
# RSKj RPC Basics Demo
# =============================================================================
# This script demonstrates essential JSON-RPC methods for interacting with
# an RSKj node. Run this after starting the node with Docker.
# =============================================================================

RPC_URL="http://localhost:4444"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function for RPC calls
rpc_call() {
    local method=$1
    local params=$2
    echo -e "${BLUE}Method: ${method}${NC}"
    echo -e "${GREEN}Request:${NC} {\"method\":\"$method\",\"params\":$params}"
    echo -e "${GREEN}Response:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params,\"id\":1}" \
        $RPC_URL | jq .
    echo ""
}

echo "=============================================="
echo "RSKj RPC Basics Demo"
echo "RPC Endpoint: $RPC_URL"
echo "=============================================="
echo ""

echo "=== 1. Client Version (web3_clientVersion) ==="
rpc_call "web3_clientVersion" "[]"
read -p "Press Enter to continue..."

echo "=== 2. Network Version (net_version) ==="
rpc_call "net_version" "[]"
echo "Network IDs: 30=Mainnet, 31=Testnet, 33=Regtest"
echo ""
read -p "Press Enter to continue..."

echo "=== 3. Chain ID (eth_chainId) ==="
rpc_call "eth_chainId" "[]"
echo "Chain IDs: 0x1e (30)=Mainnet, 0x1f (31)=Testnet, 0x21 (33)=Regtest"
echo ""
read -p "Press Enter to continue..."

echo "=== 4. Current Block Number (eth_blockNumber) ==="
rpc_call "eth_blockNumber" "[]"
BLOCK_HEX=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    $RPC_URL | jq -r '.result')
BLOCK_DEC=$((16#${BLOCK_HEX:2}))
echo "Decimal: $BLOCK_DEC blocks"
echo ""
read -p "Press Enter to continue..."

echo "=== 5. Sync Status (eth_syncing) ==="
rpc_call "eth_syncing" "[]"
echo "false = fully synced"
echo ""
read -p "Press Enter to continue..."

echo "=== 6. Gas Price (eth_gasPrice) ==="
rpc_call "eth_gasPrice" "[]"
read -p "Press Enter to continue..."

echo "=== 7. Peer Count (net_peerCount) ==="
rpc_call "net_peerCount" "[]"
echo "Regtest typically shows 0 peers (local only)"
echo ""
read -p "Press Enter to continue..."

echo "=== 8. Mining Status (eth_mining) ==="
rpc_call "eth_mining" "[]"
read -p "Press Enter to continue..."

echo "=== 9. Coinbase Address (eth_coinbase) ==="
rpc_call "eth_coinbase" "[]"
echo "This is the miner's address that receives block rewards"
echo ""
read -p "Press Enter to continue..."

echo "=== 10. Available RPC Modules (rpc_modules) ==="
rpc_call "rpc_modules" "[]"

echo "=============================================="
echo "Demo Complete!"
echo "=============================================="
