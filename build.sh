#!/bin/bash
#==============================================================================
# Build script for MAPF Unified Container
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_MODULES_DIR="$(dirname "$SCRIPT_DIR")"

IMAGE_NAME="${IMAGE_NAME:-mapf_unified}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=============================================="
echo "Building MAPF Unified Container"
echo "=============================================="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Context: ${DOCKER_MODULES_DIR}"
echo "Dockerfile: mapf_unified/Dockerfile"
echo "=============================================="

cd "$DOCKER_MODULES_DIR"

docker build \
    --no-cache \
    -f mapf_unified/Dockerfile \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

echo ""
echo "=============================================="
echo "Build complete!"
echo "=============================================="
echo ""
echo "To run:"
echo "  cd ${SCRIPT_DIR}"
echo "  docker compose up -d"
echo ""
echo "Or manually:"
echo "  docker run --rm -it --env-file .env --network rmf2_broker_rmf-network -p 8888:8888 -p 6333:6333 -p 1932:1932 -p 1933:1933 -p 8009:8009 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
