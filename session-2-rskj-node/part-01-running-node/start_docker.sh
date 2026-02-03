#!/bin/bash
# =============================================================================
# RSKj Node with Docker - Step-by-Step Guide
# =============================================================================
# This script demonstrates two ways to run RSKj with Docker:
#   1. Using docker run (direct command)
#   2. Using docker compose (configuration file)
# =============================================================================

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

RPC_URL="http://localhost:4444"
CONTAINER_NAME="rskj-regtest"

echo "=============================================="
echo "RSKj Node with Docker - Step-by-Step Guide"
echo "=============================================="
echo ""

# Check Docker
echo "=== Checking Prerequisites ==="
echo "Running:"
echo -e "${BLUE}docker --version${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo "Please install Docker from https://www.docker.com/products/docker-desktop"
    exit 1
fi
docker --version
echo -e "${GREEN}✓ Docker is installed${NC}"
echo ""

echo "Running:"
echo -e "${BLUE}docker info${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon is not running${NC}"
    echo "Please start Docker Desktop"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon is running${NC}"
echo ""

# Cleanup any existing container
echo "=== Cleanup ==="
echo "Running:"
echo -e "${BLUE}docker ps -a | grep $CONTAINER_NAME${NC}"
if docker ps -a | grep -q $CONTAINER_NAME; then
    echo "Found existing container. Removing..."
    echo ""
    echo "Running:"
    echo -e "${BLUE}docker stop $CONTAINER_NAME${NC}"
    docker stop $CONTAINER_NAME 2>/dev/null
    echo ""
    echo "Running:"
    echo -e "${BLUE}docker rm $CONTAINER_NAME${NC}"
    docker rm $CONTAINER_NAME 2>/dev/null
    echo -e "${GREEN}✓ Cleaned up${NC}"
else
    echo "No existing container found."
fi
echo ""

# =============================================================================
# PART 1: Docker Run
# =============================================================================
echo "##############################################"
echo "# PART 1: Running RSKj with 'docker run'    #"
echo "##############################################"
echo ""
echo "The 'docker run' command lets you start a container directly from the"
echo "command line. This is useful for quick tests or one-off runs."
echo ""

read -p "Press Enter to continue..."
echo ""

echo "=== The Command ==="
echo ""
echo -e "${BLUE}docker run -d \\
  --name $CONTAINER_NAME \\
  -p 4444:4444 \\
  -p 4445:4445 \\
  -v rskj-regtest-data:/var/lib/rsk/database \\
  rsksmart/rskj:latest \\
  --regtest \\
  -Dlogging.stdout=INFO \\
  -Drpc.providers.web.http.cors=* \\
  -Drpc.providers.web.http.hosts=[localhost,127.0.0.1,0.0.0.0]${NC}"
echo ""
echo "Explanation:"
echo "  -d                    Run in detached mode (background)"
echo "  --name                Give the container a name"
echo "  -p 4444:4444          Map port 4444 (HTTP RPC)"
echo "  -p 4445:4445          Map port 4445 (WebSocket RPC)"
echo "  -v ...                Mount a volume for persistent data"
echo "  --regtest             Run in regtest mode (local development)"
echo "  -D...                 Java system properties for configuration"
echo ""

read -p "Press Enter to run the command..."
echo ""

echo "=== Starting Node with Docker Run ==="
docker run -d \
  --name $CONTAINER_NAME \
  -p 4444:4444 \
  -p 4445:4445 \
  -v rskj-regtest-data:/var/lib/rsk/database \
  rsksmart/rskj:latest \
  --regtest \
  -Dlogging.stdout=INFO \
  "-Drpc.providers.web.http.cors=*" \
  "-Drpc.providers.web.http.hosts=[localhost,127.0.0.1,0.0.0.0]"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to start node${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Container started${NC}"
echo ""

echo "=== Waiting for Node to Start ==="
echo "Waiting 10 seconds for initialization..."
sleep 10
echo ""

echo "=== Checking Node Status ==="
echo "Running:"
echo -e "${BLUE}docker ps --filter name=$CONTAINER_NAME${NC}"
docker ps --filter name=$CONTAINER_NAME
echo ""

echo "=== Recent Logs ==="
echo "Running:"
echo -e "${BLUE}docker logs $CONTAINER_NAME --tail 10${NC}"
docker logs $CONTAINER_NAME --tail 10
echo ""

echo "=== Verifying RPC ==="
echo "Running:"
echo -e "${BLUE}curl -s -X POST -H \"Content-Type: application/json\" \\
    --data '{\"jsonrpc\":\"2.0\",\"method\":\"web3_clientVersion\",\"params\":[],\"id\":1}' \\
    $RPC_URL${NC}"
echo ""
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
    $RPC_URL 2>/dev/null)

if echo "$RESPONSE" | grep -q "result"; then
    echo -e "${GREEN}✓ Node is running and RPC is responding!${NC}"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${YELLOW}Node may still be starting...${NC}"
fi
echo ""

echo "=== Useful Commands for docker run ==="
echo "  View logs:     docker logs -f $CONTAINER_NAME"
echo "  Stop node:     docker stop $CONTAINER_NAME"
echo "  Remove:        docker rm $CONTAINER_NAME"
echo "  Remove data:   docker volume rm rskj-regtest-data"
echo ""

read -p "Press Enter to stop the container and continue to Part 2..."
echo ""

echo "=== Stopping Container ==="
echo "Running:"
echo -e "${BLUE}docker stop $CONTAINER_NAME${NC}"
docker stop $CONTAINER_NAME
echo ""
echo "Running:"
echo -e "${BLUE}docker rm $CONTAINER_NAME${NC}"
docker rm $CONTAINER_NAME
echo -e "${GREEN}✓ Container stopped and removed${NC}"
echo ""

# =============================================================================
# PART 2: Docker Compose
# =============================================================================
echo "##############################################"
echo "# PART 2: Running RSKj with 'docker compose' #"
echo "##############################################"
echo ""
echo "Docker Compose uses a YAML configuration file to define the container."
echo "This is better for:"
echo "  - Reproducible setups"
echo "  - Version-controlled configurations"
echo "  - Complex multi-container deployments"
echo ""

read -p "Press Enter to continue..."
echo ""

echo "=== The docker-compose.yml file ==="
echo "Running:"
echo -e "${BLUE}cat docker-compose.yml${NC}"
echo ""
cat docker-compose.yml
echo ""

read -p "Press Enter to run 'docker compose up -d'..."
echo ""

echo "=== Starting Node with Docker Compose ==="
echo "Running:"
echo -e "${BLUE}docker compose up -d${NC}"
docker compose up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to start node${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Container started${NC}"
echo ""

echo "=== Waiting for Node to Start ==="
echo "Waiting 10 seconds for initialization..."
sleep 10
echo ""

echo "=== Checking Node Status ==="
echo "Running:"
echo -e "${BLUE}docker ps --filter name=$CONTAINER_NAME${NC}"
docker ps --filter name=$CONTAINER_NAME
echo ""

echo "=== Recent Logs ==="
echo "Running:"
echo -e "${BLUE}docker logs $CONTAINER_NAME --tail 10${NC}"
docker logs $CONTAINER_NAME --tail 10
echo ""

echo "=== Verifying RPC ==="
echo "Running:"
echo -e "${BLUE}curl -s -X POST -H \"Content-Type: application/json\" \\
    --data '{\"jsonrpc\":\"2.0\",\"method\":\"web3_clientVersion\",\"params\":[],\"id\":1}' \\
    $RPC_URL${NC}"
echo ""
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
    $RPC_URL 2>/dev/null)

if echo "$RESPONSE" | grep -q "result"; then
    echo -e "${GREEN}✓ Node is running and RPC is responding!${NC}"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
else
    echo -e "${YELLOW}Node may still be starting...${NC}"
fi
echo ""

echo "=============================================="
echo -e "${GREEN}Guide Complete!${NC}"
echo "=============================================="
echo ""
echo "You've learned two ways to run RSKj with Docker:"
echo "  1. docker run    - Quick, command-line based"
echo "  2. docker compose - Configuration file based"
echo ""
echo "The node is now running. Useful commands:"
echo "  View logs:    docker logs -f $CONTAINER_NAME"
echo "  Stop node:    docker compose down"
echo "  Remove data:  docker compose down -v"
echo ""
echo "RPC Endpoint:   http://localhost:4444"
echo "WebSocket:      ws://localhost:4445"
