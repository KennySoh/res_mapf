# MAPF Unified Container

This container combines 6 MAPF-related services into a single container:

| Service | Original Container | Port(s) | Purpose |
|---------|-------------------|---------|---------|
| **fiware_map_server** | fiware_map | 7073 | Map server - uploads maps to Context Broker |
| **load_maps** | fiware_map (one-shot) | - | Loads YAML maps at startup |
| **mapf_solver** | mapf_service | 8888 | MAPF path planning solver |
| **adg_executor** | mapf_execution | 6333, 1932 | ADG execution engine |
| **mapf_mrs** | mapf_fiware | 1933 | Movement request server (FIWARE) |
| **movement_request_server** | movement_request_server | 8009 | REST API for movement requests |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    mapf_unified container                    │
├─────────────────────────────────────────────────────────────┤
│  supervisord (process manager)                               │
│  ├── fiware_map_server     → :7073 (HTTP/Flask)             │
│  ├── load_maps             → (one-shot at startup)          │
│  ├── mapf_solver           → :8888 (HTTP)                   │
│  ├── adg_executor          → :6333 (HTTP), :1932 (MQTT)     │
│  ├── mapf_mrs              → :1933 (MQTT)                   │
│  └── movement_request_svr  → :8009 (HTTP/FastAPI)           │
├─────────────────────────────────────────────────────────────┤
│  Internal: services communicate via localhost               │
│  External: connects to mosquitto, redis, scorpio, rabbitmq  │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url> mapf_unified
cd mapf_unified
```

### 2. Build the Docker Image

```bash
# From repo root (self-contained build)
docker build -t mapf_unified:latest .
```

Build time: ~10-15 minutes (first build)

### 3. Create Docker Network

```bash
docker network create rmf2_broker_rmf-network
```

### 4. Run with Docker Compose

```bash
docker compose up -d
```

### Run Standalone

```bash
docker run --rm -it \
  --env-file .env \
  --network rmf2_broker_rmf-network \
  -p 7073:7073 \
  -p 8888:8888 \
  -p 6333:6333 \
  -p 1932:1932 \
  -p 1933:1933 \
  -p 8009:8009 \
  mapf_unified:latest
```

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build combining all services |
| `supervisord.conf` | Process manager configuration |
| `startup.sh` | Entrypoint script with health checks |
| `compose.yml` | Docker Compose configuration |
| `.env` | Environment variables |
| `build.sh` | Build helper script |

## Environment Variables

Key variables (see `.env` for full list):

| Variable | Default | Description |
|----------|---------|-------------|
| `MQTT_SERVER_HOST` | mosquitto | MQTT broker hostname |
| `REDIS_HOST` | redis | Redis hostname |
| `CONTEXT_BROKER_HOST` | scorpio | FIWARE context broker |
| `AMQP_HOST` | rmf2_broker-rabbitmq-1 | RabbitMQ hostname |
| `BUILDING_NAME` | warehouse_v2 | Map/building name |
| `MAP_SERVER_PORT` | 7073 | FIWARE map server port |

## Deploying a New Map

To deploy a new map (e.g., `my_warehouse.yaml`):

### Step 1: Copy map to both source directories

```bash
# MAPF Solver (path planning)
cp /path/to/my_warehouse.yaml src/mapf/mapf_service/mapf_service/maps/

# Fiware Map (context broker)
cp /path/to/my_warehouse.yaml src/fiware_map/maps/
```

### Step 2: Update environment variable

Edit `.env`:
```
BUILDING_NAME="my_warehouse"
```

### Step 3: Rebuild the container

```bash
docker build -t mapf_unified:latest --no-cache .
```

### Step 4: Restart the container

```bash
docker compose down
docker compose up -d
```

### Step 5: Verify deployment

```bash
# Check map loaded
docker exec mapf_unified cat /var/log/supervisor/load_maps.log | grep -i my_warehouse

# Check all services running
docker exec mapf_unified supervisorctl status
```

---

## Current Map: warehouse_v2

| Parameter | Value |
|-----------|-------|
| **Map name** | warehouse_v2 |
| **Grid spacing** | 250cm (2.5m) |
| **Grid dimensions** | 14 cols x 24 rows |
| **Total vertices** | 336 (110 obstacles, 226 navigable) |
| **Total lanes** | 385 bidirectional |
| **Robot fleet** | 24 robots (BP_AMR_C_16 to BP_AMR_C_39) |
| **Robot layout** | 5x5 grid |
| **Rack obstacles** | 12 (4x3 grid at P168-P230) |

---

## Logs

Logs are written to `/var/log/supervisor/` inside the container:

```bash
# View all logs
docker exec mapf_unified tail -f /var/log/supervisor/*.log

# View specific service
docker exec mapf_unified tail -f /var/log/supervisor/fiware_map_server.log
docker exec mapf_unified tail -f /var/log/supervisor/load_maps.log
docker exec mapf_unified tail -f /var/log/supervisor/mapf_solver.log
docker exec mapf_unified tail -f /var/log/supervisor/adg_executor.log
docker exec mapf_unified tail -f /var/log/supervisor/mapf_mrs.log
docker exec mapf_unified tail -f /var/log/supervisor/movement_request_server.log
```

Or mount the logs directory:
```yaml
volumes:
  - ./logs:/var/log/supervisor
```

## Troubleshooting

### Check service status
```bash
docker exec mapf_unified supervisorctl status
```

### Restart a specific service
```bash
docker exec mapf_unified supervisorctl restart mapf_solver
docker exec mapf_unified supervisorctl restart adg_executor
```

### Check if ports are listening
```bash
docker exec mapf_unified netstat -tlnp
```

## Comparison: Before vs After

### Before (5+ containers)
```
fiware_map         - rmf-network (map server)
load_map           - rmf-network (one-shot map loader)
mapf_solver        - isolated on mapf-net
adg_executor       - bridges rmf-network + mapf-net
mapf_mrs           - rmf-network
movement_request   - rmf-network
```

### After (1 container)
```
mapf_unified       - rmf-network only (internal localhost communication)
                   - includes fiware_map_server + load_maps + all MAPF services
```

**Benefits:**
- Simpler deployment (1 container instead of 5+)
- Faster inter-service communication (localhost vs network)
- Single container to monitor
- Reduced resource overhead
- Map server internal - no external dependency

**Trade-offs:**
- Less granular scaling
- If one service crashes, may need to restart all
