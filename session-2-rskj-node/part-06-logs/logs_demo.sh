#!/bin/bash
# =============================================================================
# RSKj Logs & Events Demo
# =============================================================================
# This script demonstrates querying blockchain logs and using filters.
# =============================================================================

RPC_URL="http://localhost:4444"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Common event signatures
TRANSFER_TOPIC="0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

echo "=============================================="
echo "RSKj Logs & Events Demo"
echo "RPC Endpoint: $RPC_URL"
echo "=============================================="
echo ""

# Get current block
echo -e "${BLUE}Method: eth_blockNumber${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}"
CURRENT_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Current block: $CURRENT_BLOCK${NC}"
echo ""

# 1. Get all logs
echo "=== 1. Get All Logs (Last 100 Blocks) ==="
# Calculate fromBlock
BLOCK_DEC=$((16#${CURRENT_BLOCK:2}))
FROM_BLOCK=$((BLOCK_DEC - 100))
if [ $FROM_BLOCK -lt 0 ]; then FROM_BLOCK=0; fi
FROM_BLOCK_HEX=$(printf "0x%x" $FROM_BLOCK)

echo "Querying blocks $FROM_BLOCK_HEX to $CURRENT_BLOCK"
echo -e "${BLUE}Method: eth_getLogs${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_getLogs\",\"params\":[{\"fromBlock\":\"$FROM_BLOCK_HEX\",\"toBlock\":\"latest\"}],\"id\":1}"
LOGS=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getLogs\",\"params\":[{\"fromBlock\":\"$FROM_BLOCK_HEX\",\"toBlock\":\"latest\"}],\"id\":1}" \
    $RPC_URL)
LOG_COUNT=$(echo "$LOGS" | jq '.result | length')
echo -e "${GREEN}Response: Found $LOG_COUNT logs${NC}"
echo "$LOGS" | jq '.result[:3]'  # Show first 3
echo ""
read -p "Press Enter to continue..."

# 2. Create block filter
echo ""
echo "=== 2. Create Block Filter ==="
echo -e "${YELLOW}Block filters notify you of new blocks${NC}"
echo -e "${BLUE}Method: eth_newBlockFilter${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_newBlockFilter\",\"params\":[],\"id\":1}"
BLOCK_FILTER=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_newBlockFilter","params":[],"id":1}' \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Block Filter ID: $BLOCK_FILTER${NC}"
echo ""
read -p "Press Enter to continue..."

# 3. Create log filter
echo ""
echo "=== 3. Create Log Filter (Transfer Events) ==="
echo "Topic: $TRANSFER_TOPIC"
echo -e "${BLUE}Method: eth_newFilter${NC}"
echo -e "${GREEN}Request:${NC} {\"jsonrpc\":\"2.0\",\"method\":\"eth_newFilter\",\"params\":[{\"topics\":[\"$TRANSFER_TOPIC\"]}],\"id\":1}"
LOG_FILTER=$(curl -s -X POST -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_newFilter\",\"params\":[{\"topics\":[\"$TRANSFER_TOPIC\"]}],\"id\":1}" \
    $RPC_URL | jq -r '.result')
echo -e "${GREEN}Response: Log Filter ID: $LOG_FILTER${NC}"
echo ""
read -p "Press Enter to continue..."

# 4. Wait and poll for changes
echo ""
echo "=== 4. Poll for Filter Changes ==="
echo "Waiting 3 seconds for new blocks..."
sleep 3

echo -e "${YELLOW}Block filter changes:${NC}"
rpc_call "eth_getFilterChanges" "[\"$BLOCK_FILTER\"]"

echo -e "${YELLOW}Log filter changes:${NC}"
rpc_call "eth_getFilterChanges" "[\"$LOG_FILTER\"]"
read -p "Press Enter to continue..."

# 5. Transaction pool status
echo ""
echo "=== 5. Transaction Pool Status ==="
rpc_call "txpool_status" "[]"
read -p "Press Enter to continue..."

# 6. Transaction pool content
echo ""
echo "=== 6. Transaction Pool Content ==="
rpc_call "txpool_content" "[]"
read -p "Press Enter to continue..."

# 7. Uninstall filters
echo ""
echo "=== 7. Cleanup: Uninstall Filters ==="
echo "Uninstalling block filter..."
rpc_call "eth_uninstallFilter" "[\"$BLOCK_FILTER\"]"

echo "Uninstalling log filter..."
rpc_call "eth_uninstallFilter" "[\"$LOG_FILTER\"]"

echo ""
echo "=============================================="
echo "Logs & Events Demo Complete!"
echo "=============================================="
echo ""
echo "Common Event Topics:"
echo "  Transfer: $TRANSFER_TOPIC"
echo "  Approval: 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
