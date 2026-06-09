# How to Change Maps in MAPF Unified

## Overview

To change the active map used by the MAPF system, you need to:
1. Ensure the map file exists in both service directories
2. Update the `BUILDING_NAME` environment variable
3. Restart the container

## Prerequisites

The map `.yaml` file must exist in **both** locations:
- `/home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_service/mapf/mapf_service/mapf_service/maps/`
- `/home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/fiware_map/fiware_map/maps/`

## Available Maps

| Map Name | Grid Spacing | Vertices | Robots | Dimensions |
|----------|--------------|----------|--------|------------|
| warehouse_os_setup | 1.75m | 714 (P0-P713) | 25 (Manufacturer_2-25) | 34 rows x 21 cols |
| warehouse_v2 | 2.5m | 336 (P0-P335) | 24 (BP_AMR_C_16-39) | 14 rows x 24 cols |
| ue5_new_setup | 2.5m | 460 (P0-P459) | 25 (AMR_0-24) | - |

## Step-by-Step Instructions

### Step 1: Verify Map File Exists

```bash
# Check if map exists in both locations
ls -la /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_service/mapf/mapf_service/mapf_service/maps/<MAP_NAME>.yaml
ls -la /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/fiware_map/fiware_map/maps/<MAP_NAME>.yaml
```

### Step 2: Verify Map Name Field

The `name:` field inside the yaml file must match the filename (without .yaml):

```bash
head -5 /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_service/mapf/mapf_service/mapf_service/maps/<MAP_NAME>.yaml | grep "^name:"
```

Expected output: `name: <MAP_NAME>`

### Step 3: Update Environment Variables (TWO files!)

You must update `BUILDING_NAME` in **both** .env files:

**File 1: mapf_unified/.env**
```bash
sed -i 's/BUILDING_NAME=.*/BUILDING_NAME="<MAP_NAME>"/' \
  /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_unified/.env
```

**File 2: rmf2_broker/.env**
```bash
sed -i 's/BUILDING_NAME=.*/BUILDING_NAME="<MAP_NAME>"/' \
  /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/fiware_demo/compose_files/rmf2_broker/.env
```

Or edit both manually:
```bash
nano /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_unified/.env
nano /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/fiware_demo/compose_files/rmf2_broker/.env
```

Change this line in both files:
```
BUILDING_NAME="<MAP_NAME>"
```

### Step 4: Restart Container

```bash
cd /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_unified
docker compose down && docker compose up -d
```

### Step 5: Initialize Robot Start Positions

Each map has its own init script that tells the MAPF system where robots start:

```bash
# For warehouse_os_setup
bash /home/rosi/IHI_PHASE2_FINAL_DEMO/send_init_warehouse_os_setup.sh

# For warehouse_v2
bash /home/rosi/IHI_PHASE2_FINAL_DEMO/send_init_warehouse_v2.sh
```

### Step 6: (Optional) Visualize Waypoints & Reposition Robots in UE5

To see the waypoints and move robots to their start positions in Unreal Engine 5, run these Python scripts in the UE5 Python console (press backtick `):

```python
# For warehouse_os_setup
py "/home/rosi/IHI_PHASE2_FINAL_DEMO/ue5_scripts/01_spawn_waypoint_markers.py"
py "/home/rosi/IHI_PHASE2_FINAL_DEMO/ue5_scripts/02_recolor_waypoints.py"
py "/home/rosi/IHI_PHASE2_FINAL_DEMO/ue5_scripts/03_reposition_robots.py"

# For warehouse_v2
py "/home/rosi/IHI_PHASE2_FINAL_DEMO/ue5_scripts/01_spawn_waypoint_markers_v2.py"
py "/home/rosi/IHI_PHASE2_FINAL_DEMO/ue5_scripts/02_recolor_waypoints_v2.py"
py "/home/rosi/IHI_PHASE2_FINAL_DEMO/ue5_scripts/03_reposition_robots_v2.py"
```

The recolor script marks:
- **Green**: Navigable waypoints (connected)
- **Red**: Isolated/obstacle waypoints

The reposition script moves robots to their correct starting waypoints for the map.

### Step 7: Verify Map Loaded

Wait ~10 seconds for services to start, then verify:

```bash
# Check environment variable is set correctly
docker exec mapf_unified printenv | grep BUILDING

# Check map loading logs
docker exec mapf_unified cat /var/log/supervisor/load_maps.log | tail -20

# Check solver is using correct map
docker exec mapf_unified cat /var/log/supervisor/mapf_solver.log | grep "mapfile:"
```

## Quick Change Commands

### Switch to warehouse_os_setup
```bash
# Update both .env files
sed -i 's/BUILDING_NAME=.*/BUILDING_NAME="warehouse_os_setup"/' \
  /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_unified/.env
sed -i 's/BUILDING_NAME=.*/BUILDING_NAME="warehouse_os_setup"/' \
  /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/fiware_demo/compose_files/rmf2_broker/.env

# Restart container
cd /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_unified
docker compose down && docker compose up -d
sleep 10

# Initialize robots
bash /home/rosi/IHI_PHASE2_FINAL_DEMO/send_init_warehouse_os_setup.sh
```

### Switch to warehouse_v2
```bash
# Update both .env files
sed -i 's/BUILDING_NAME=.*/BUILDING_NAME="warehouse_v2"/' \
  /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_unified/.env
sed -i 's/BUILDING_NAME=.*/BUILDING_NAME="warehouse_v2"/' \
  /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/fiware_demo/compose_files/rmf2_broker/.env

# Restart container
cd /home/rosi/IHI_PHASE2_FINAL_DEMO/docker_modules/mapf_unified
docker compose down && docker compose up -d
sleep 10

# Initialize robots
bash /home/rosi/IHI_PHASE2_FINAL_DEMO/send_init_warehouse_v2.sh
```

## Important Notes

1. **Name Consistency**: The map name must be consistent in three places:
   - Filename: `<MAP_NAME>.yaml`
   - Inside yaml: `name: <MAP_NAME>`
   - Environment: `BUILDING_NAME="<MAP_NAME>"`

2. **The .map file is auto-generated**: The MAPF solver automatically generates the `.map` file from the `.yaml` when it starts. You don't need to create it manually.

3. **Volume Mounts**: The `compose.yml` has volume mounts so map file changes take effect without rebuilding the Docker image.

4. **Robot Initialization**: After changing maps, you may need to reinitialize robots with the appropriate init script for that map.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Map not loading | Verify `BUILDING_NAME` in **both** `.env` files matches filename exactly |
| .env files out of sync | Update both: `mapf_unified/.env` AND `fiware_demo/compose_files/rmf2_broker/.env` |
| Solver using wrong map | Restart container: `docker compose down && docker compose up -d` |
| "Map not found" error | Check map exists in both mapf_service and fiware_map directories |
| Rows/columns mismatch | Verify yaml file has correct `rows:` and `columns:` values |
| Robots not at correct positions | Run the appropriate `send_init_<map>.sh` script |
| Waypoints not visible in UE5 | Run the spawn waypoint script in UE5 Python console |
| Wrong robot IDs | Each map uses different robot naming (see Available Maps table) |

## File Locations Reference

```
/home/rosi/IHI_PHASE2_FINAL_DEMO/
├── send_init_warehouse_os_setup.sh    # Robot init for warehouse_os_setup
├── send_init_warehouse_v2.sh          # Robot init for warehouse_v2
├── ue5_scripts/
│   ├── 01_spawn_waypoint_markers.py   # Spawn waypoints (warehouse_os_setup)
│   ├── 02_recolor_waypoints.py        # Recolor waypoints (warehouse_os_setup)
│   ├── 03_reposition_robots.py        # Move robots to start (warehouse_os_setup)
│   ├── 01_spawn_waypoint_markers_v2.py # Spawn waypoints (warehouse_v2)
│   ├── 02_recolor_waypoints_v2.py     # Recolor waypoints (warehouse_v2)
│   └── 03_reposition_robots_v2.py     # Move robots to start (warehouse_v2)
└── docker_modules/
    ├── mapf_unified/
    │   ├── .env                       # BUILDING_NAME (file 1 of 2)
    │   └── compose.yml                # Volume mounts for maps
    ├── fiware_demo/compose_files/rmf2_broker/
    │   └── .env                       # BUILDING_NAME (file 2 of 2)
    ├── mapf_service/mapf/mapf_service/mapf_service/maps/
    │   └── <MAP_NAME>.yaml            # MAPF solver map
    └── fiware_map/fiware_map/maps/
        └── <MAP_NAME>.yaml            # Fiware context broker map
```
