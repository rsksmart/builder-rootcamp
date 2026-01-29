#!/bin/bash
# =============================================================================
# Start RSKj Node with Java
# =============================================================================
# This script downloads (if needed) and runs RSKj using Java.
# =============================================================================

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
RSKJ_VERSION="8.1.0"
RSKJ_RELEASE="REED-8.1.0"
JAR_NAME="rskj-core-${RSKJ_VERSION}-REED-all.jar"
JAR_DIR="$HOME/rskj-node"
JAR_PATH="$JAR_DIR/$JAR_NAME"
DOWNLOAD_URL="https://github.com/rsksmart/rskj/releases/download/${RSKJ_RELEASE}/${JAR_NAME}"

echo "=============================================="
echo "Start RSKj Node with Java"
echo "=============================================="
echo ""

# Check Java
echo "=== Checking Prerequisites ==="
echo "Running:"
echo -e "${BLUE}java -version${NC}"
echo ""
if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java is not installed${NC}"
    echo ""
    echo "Please install Java 17 JDK from:"
    echo "  - Adoptium: https://adoptium.net/"
    echo "  - Azul Zulu: https://www.azul.com/downloads/?version=java-17-lts"
    echo "  - SDKMAN: https://sdkman.io/"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1)
echo -e "${GREEN}✓ Java is installed: $JAVA_VERSION${NC}"

# Check Java version is 17+
if ! java -version 2>&1 | grep -q "version \"17\|version \"18\|version \"19\|version \"20\|version \"21"; then
    echo -e "${YELLOW}Warning: Java 17+ is recommended. You have: $JAVA_VERSION${NC}"
fi
echo ""

# Check/Download JAR
echo "=== Checking RSKj JAR ==="
if [ -f "$JAR_PATH" ]; then
    echo -e "${GREEN}✓ JAR found: $JAR_PATH${NC}"
else
    echo "JAR not found. Downloading..."
    echo ""
    
    # Create directory
    echo "Running:"
    echo -e "${BLUE}mkdir -p $JAR_DIR${NC}"
    mkdir -p "$JAR_DIR"
    cd "$JAR_DIR"
    
    echo ""
    echo "Downloading from: $DOWNLOAD_URL"
    echo "This may take a minute..."
    echo ""
    echo "Running:"
    echo -e "${BLUE}curl -L -o $JAR_NAME $DOWNLOAD_URL${NC}"
    echo ""
    
    curl -L -o "$JAR_NAME" "$DOWNLOAD_URL"
    
    if [ $? -ne 0 ] || [ ! -f "$JAR_PATH" ]; then
        echo -e "${RED}Failed to download JAR${NC}"
        echo "Please download manually from:"
        echo "  https://github.com/rsksmart/rskj/releases"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Download complete${NC}"
fi

JAR_SIZE=$(ls -lh "$JAR_PATH" | awk '{print $5}')
echo "JAR size: $JAR_SIZE"
echo ""

# Show run command
echo "=== Starting RSKj Node ==="
echo ""
echo "Command:"
echo -e "${BLUE}java -Xms4G -Dlogging.stdout=INFO  -Ddatabase.dir=/var/lib/rsk/regtest/database -cp "$JAR_PATH" co.rsk.Start --regtest${NC}"
echo ""
echo -e "${YELLOW}Note: The node will run in the foreground.${NC}"
echo -e "${YELLOW}      Open a NEW terminal to run RPC commands.${NC}"
echo -e "${YELLOW}      Press Ctrl+C to stop the node.${NC}"
echo ""
read -p "Press Enter to start the node..."
echo ""
echo "=============================================="
echo "Starting RSKj Node..."
echo "=============================================="
echo ""

# Run the node
java -Xms4G -Dlogging.stdout=INFO  -Ddatabase.dir=/var/lib/rsk/regtest/database -cp "$JAR_PATH" co.rsk.Start --regtest
