# Part 01: Running the Node

## Objective

Start a local RSKj node for development using either Docker or Java command line.

## Two Options

| Method     | Best For                                  | Requirements     |
| ---------- | ----------------------------------------- | ---------------- |
| **Docker** | Quick setup, consistent environment       | Docker installed |
| **Java**   | Learning the build process, customization | Java 17 JDK      |

---

## What is Regtest?

Regtest (Regression Test) is a local development network where:

- Blocks are mined automatically every second
- No real RBTC is needed
- Perfect for testing and development
- Network ID: `7771`

---

# Option A: Docker (Recommended for Bootcamp)

## Run the Script

```bash
./start_docker.sh
```

This script will:

1. Check Docker is installed and running
2. Start the node with docker compose
3. Wait for initialization
4. Verify the RPC endpoint is responding

---

## Manual Docker Commands

### Start with Docker Compose

```bash
docker compose up -d
```

### View Logs

```bash
docker logs -f rskj-regtest
```

### Stop the Node

```bash
docker compose down
```

### Stop and Remove Data

```bash
docker compose down -v
```

---

### Alternative: Docker Run (Single Command)

```bash
docker run -d --name rskj-regtest \
  -p 4444:4444 \
  -p 4445:4445 \
  -v rskj-data:/var/lib/rsk/database \
  rsksmart/rskj:latest --regtest
```

---

# Option B: Java Command Line

## Prerequisites

**Java 17 JDK** - Download from:

- [Adoptium](https://adoptium.net/)
- [Azul Zulu](https://www.azul.com/downloads/?version=java-17-lts)

Verify installation:

```bash
java -version
# Expected: openjdk version "17.x.x" or similar
```

---

## Option B1: Run Pre-built JAR

### Run the Script

```bash
./start_java.sh
```

This script will:

1. Check Java is installed
2. Download the JAR if not present
3. Start the node with console logging

---

### Manual Steps

#### 1. Download the JAR

```bash
mkdir -p ~/rskj-node
cd ~/rskj-node

# Download latest release
curl -L -o rskj-core-8.1.0-REED-all.jar \
  https://github.com/rsksmart/rskj/releases/download/REED-8.1.0/rskj-core-8.1.0-REED-all.jar
```

#### 2. Run the Node

**Regtest (Development):**

```bash
java -Xms4G -Dlogging.stdout=INFO \
  -cp rskj-core-8.1.0-REED-all.jar \
  co.rsk.Start --regtest
```

**Testnet:**

```bash
java -Xms4G -Dlogging.stdout=INFO \
  -cp rskj-core-8.1.0-REED-all.jar \
  co.rsk.Start --testnet
```

**Mainnet:**

```bash
java -Xms4G -Dlogging.stdout=INFO \
  -cp rskj-core-8.1.0-REED-all.jar \
  co.rsk.Start
```

---

## Option B2: Build from Source

### Run the Script

```bash
./build_and_run.sh
```

This script will:

1. Clone the RSKj repository (if not present)
2. Run `./configure.sh`
3. Build with Gradle
4. Start the node

---

### Manual Steps

#### 1. Clone the Repository

```bash
git clone https://github.com/rsksmart/rskj.git ~/rskj-source
cd ~/rskj-source
```

#### 2. Configure and Build

```bash
# Verify dependencies and signatures
./configure.sh

# Build (skip tests for faster build)
./gradlew clean build -x test
```

Build takes approximately 2-5 minutes.

#### 3. Run the Node

```bash
java -Xms4G -Dlogging.stdout=INFO \
  -cp rskj-core/build/libs/rskj-core-*-all.jar \
  co.rsk.Start --regtest
```

---

# Verify the Node is Running

In a **new terminal**, test the RPC endpoint:

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
  http://localhost:4444
```

Expected response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "RskJ/8.1.0/..."
}
```

---

## Command Line Options

| Flag        | Description                   |
| ----------- | ----------------------------- |
| `--regtest` | Local development network     |
| `--testnet` | RSK Testnet                   |
| (none)      | RSK Mainnet                   |
| `--import`  | Fast sync from trusted source |
| `--reset`   | Reset database                |

## JVM Options

| Option                            | Description        |
| --------------------------------- | ------------------ |
| `-Xms4G`                          | Initial heap size  |
| `-Xmx4G`                          | Maximum heap size  |
| `-Dlogging.stdout=INFO`           | Console log level  |
| `-Drsk.conf.file=/path/node.conf` | Custom config file |

---

## Log Messages to Look For

| Message             | Meaning                  |
| ------------------- | ------------------------ |
| `IMPORTED_BEST`     | New block mined/imported |
| `block.number=X`    | Current block height     |
| `Starting JSON-RPC` | RPC server ready         |

---

## Troubleshooting

### Port Already in Use

```bash
# Check if port 4444 is in use
lsof -i :4444

# Kill existing process
kill -9 <PID>
```

### Java Version Issues

```bash
# On Mac with multiple Java versions
/usr/libexec/java_home -V
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

### Memory Issues

Increase heap size:

```bash
java -Xms4G -Xmx8G -cp rskj-core-all.jar co.rsk.Start --regtest
```

---

## Scripts Summary

| Script             | Description                    |
| ------------------ | ------------------------------ |
| `start_docker.sh`  | Start node with Docker Compose |
| `start_java.sh`    | Download JAR and run with Java |
| `build_and_run.sh` | Build from source and run      |

---

## Next Step

Once the node is running, proceed to [Part 02: RPC Basics](../part-02-rpc-basics/README.md)
