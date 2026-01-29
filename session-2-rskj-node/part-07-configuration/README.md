# Part 07: Node Configuration

## Objective

Understand how to configure the RSKj node for different use cases.

## Configuration Hierarchy

RSKj uses a layered configuration system (highest priority first):

1. **Command Line Arguments** (`-Dkey=value`)
2. **Environment Variables**
3. **System Properties**
4. **User Config File** (`-Drsk.conf.file=/path/to/node.conf`)
5. **Installer Config** (`/etc/rsk/node.conf`)
6. **Network Defaults** (mainnet.conf, testnet.conf, regtest.conf)
7. **Reference Defaults** (reference.conf)

---

## Network Selection

```bash
# Command line
java -jar rsk.jar --mainnet
java -jar rsk.jar --testnet
java -jar rsk.jar --regtest

# Docker
docker run rsksmart/rskj:latest --regtest
```

---

## Key Configuration Sections

### 1. Database Configuration

```hocon
database {
    dir = "/var/lib/rsk/database"
    reset = false
}
```

### 2. RPC Configuration

```hocon
rpc {
    providers.web {
        http {
            enabled = true
            bind_address = "0.0.0.0"  # Listen on all interfaces
            port = 4444
            hosts = ["*"]  # Allowed hosts
        }
        ws {
            enabled = true
            bind_address = "0.0.0.0"
            port = 4445
        }
        cors = "*"  # CORS origin
    }
}
```

### 3. RPC Modules

```hocon
rpc.modules {
    eth { enabled = true }
    net { enabled = true }
    web3 { enabled = true }
    personal { enabled = true }
    evm { enabled = true }
    txpool { enabled = true }
    debug { enabled = false }  # Enable for development
    trace { enabled = false }  # Enable for tracing
}
```

### 4. Miner Configuration (Regtest)

```hocon
miner {
    server.enabled = true
    client {
        enabled = true
        delayBetweenBlocks = 1 second
    }
    coinbase.secret = "my_secret_key"
}
```

### 5. Peer Configuration

```hocon
peer {
    discovery.enabled = true
    port = 5050
    maxActivePeers = 30
}
```

### 6. Wallet Configuration

```hocon
wallet {
    enabled = true
    accounts = []
}
```

---

## Example Configuration Files

### Development (Regtest)

See: `node-regtest.conf`

### Production (Mainnet)

See: `node-mainnet.conf`

---

## Docker Environment Variables

```bash
# Log level
-e RSKJ_LOG_PROPS="-Dlogging.stdout=DEBUG"

# System properties
-e RSKJ_SYS_PROPS="-Drpc.providers.web.http.bind_address=0.0.0.0"

# JVM options
-e DEFAULT_JVM_OPTS="-Xms4G -Xmx8G"
```

---

## Logging Configuration

### Log Levels

- `OFF` - No logging
- `ERROR` - Errors only
- `WARN` - Warnings and errors
- `INFO` - General information
- `DEBUG` - Detailed debugging
- `TRACE` - Very detailed tracing

### Enable Console Logging

```bash
# Docker
docker run -e RSKJ_LOG_PROPS="-Dlogging.stdout=INFO" rsksmart/rskj:latest --regtest

# Java
java -Dlogging.stdout=INFO -jar rsk.jar --regtest
```

### Log File Location

Default: `./logs/rsk.log`

Configure: `-Dlogging.dir=/path/to/logs`

---

## Important Ports

| Port  | Service       | Description             |
| ----- | ------------- | ----------------------- |
| 4444  | HTTP RPC      | JSON-RPC over HTTP      |
| 4445  | WebSocket     | JSON-RPC over WebSocket |
| 5050  | P2P (Mainnet) | Peer discovery          |
| 50505 | P2P (Testnet) | Peer discovery          |
| 50501 | P2P (Regtest) | Peer discovery          |

---

## Configuration Tips

1. **Production**: Never expose RPC to internet without authentication
2. **Development**: Enable debug/trace modules for detailed info
3. **Syncing**: Use `database.import` for fast sync
4. **Memory**: Adjust `-Xms` and `-Xmx` based on network

---

## Workshop Complete!

Congratulations! You've completed the RSKj Node Hands-on Workshop.

### What You Learned

- Running an RSKj node (Docker & Java)
- JSON-RPC basics
- Account management
- Smart contract deployment and interaction
- Transaction handling
- Logs and events
- Node configuration

### Next Steps

- Explore the [RSK Developer Portal](https://dev.rootstock.io/)
- Build your first dApp on Rootstock
- Join the [Rootstock Discord](https://discord.gg/rootstock)
