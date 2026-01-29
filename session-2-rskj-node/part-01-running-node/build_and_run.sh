#!/bin/bash
# =============================================================================
# Build RSKj from Source and Run
# =============================================================================
# This script clones, builds, and runs RSKj from source code.
# Use this to learn the build process or contribute to RSKj.
# =============================================================================

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
RSKJ_DIR="$HOME/rskj-source"

echo "=============================================="
echo "Build RSKj from Source"
echo "=============================================="
echo ""

# Check Java
echo "=== Checking Prerequisites ==="
echo "Running:"
echo -e "${BLUE}java -version${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java is not installed${NC}"
    echo "Please install Java 17 JDK"
    exit 1
fi
java -version 2>&1 | head -n 1
echo -e "${GREEN}✓ Java is installed${NC}"
echo ""

echo "Running:"
echo -e "${BLUE}git --version${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git is not installed${NC}"
    exit 1
fi
git --version
echo -e "${GREEN}✓ Git is installed${NC}"
echo ""

# Clone or update repository
echo "=== Setting Up Repository ==="
if [ -d "$RSKJ_DIR" ]; then
    echo "Repository exists at: $RSKJ_DIR"
    read -p "Update repository? [Y/n]: " UPDATE
    if [[ ! "$UPDATE" =~ ^[Nn]$ ]]; then
        cd "$RSKJ_DIR"
        echo "Pulling latest changes..."
        echo "Running:"
        echo -e "${BLUE}git pull${NC}"
        git pull
    fi
else
    echo "Cloning RSKj repository..."
    echo "Target: $RSKJ_DIR"
    echo ""
    echo "Running:"
    echo -e "${BLUE}git clone https://github.com/rsksmart/rskj.git $RSKJ_DIR${NC}"
    echo ""
    git clone https://github.com/rsksmart/rskj.git "$RSKJ_DIR"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to clone repository${NC}"
        exit 1
    fi
fi

cd "$RSKJ_DIR"
echo -e "${GREEN}✓ Repository ready${NC}"
echo ""

# Run configure
echo "=== Running Configure Script ==="
echo "This verifies dependencies and signatures..."
echo ""
echo "Running:"
echo -e "${BLUE}./configure.sh${NC}"
echo ""
./configure.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}Configure failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Configure complete${NC}"
echo ""

# Build
echo "=== Building RSKj ==="
echo "This may take 2-5 minutes..."
echo ""
echo "Running:"
echo -e "${BLUE}./gradlew clean build -x test${NC}"
echo ""
./gradlew clean build -x test

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed${NC}"
    exit 1
fi
echo ""
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Find JAR
JAR_PATH=$(ls rskj-core/build/libs/rskj-core-*-all.jar 2>/dev/null | head -1)

if [ -z "$JAR_PATH" ]; then
    echo -e "${RED}Could not find built JAR${NC}"
    exit 1
fi

echo "Built JAR: $JAR_PATH"
JAR_SIZE=$(ls -lh "$JAR_PATH" | awk '{print $5}')
echo "JAR size: $JAR_SIZE"
echo ""

# Run
echo "=== Starting RSKj Node ==="
echo ""
echo "Command:"
echo -e "${BLUE}java -Xms4G -Dlogging.stdout=INFO -cp $JAR_PATH co.rsk.Start --regtest${NC}"
echo ""
echo -e "${YELLOW}Note: The node will run in the foreground.${NC}"
echo -e "${YELLOW}      Open a NEW terminal to run RPC commands.${NC}"
echo -e "${YELLOW}      Press Ctrl+C to stop the node.${NC}"
echo ""
read -p "Press Enter to start the node..."
echo ""
echo "=============================================="
echo "Starting RSKj Node (built from source)..."
echo "=============================================="
echo ""

java -Xms4G -Dlogging.stdout=INFO -cp "$JAR_PATH" co.rsk.Start --regtest
