#!/bin/bash
# Launch the lidar_localization_ros2 image with this repository mounted into
# the container's workspace, then build it there by hand.
# Usage (from repo root or docker/):
#   ./docker/container_run.sh <container_name> <image_name:tag>
# Example:
#   ./docker/container_run.sh lidar_localization lidar_localization_ros2:latest
#
# Build the image first, from the repo root, with the host user's ids:
#   docker build -f docker/Dockerfile -t lidar_localization_ros2:latest \
#     --build-arg USERNAME=$(whoami) --build-arg USER_UID=$(id -u) \
#     --build-arg USER_GID=$(id -g) .
#
# Inside the container (cwd is /ros2_ws):
#   colcon build --packages-select lidar_localization_ros2 && source install/setup.bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Repo root (parent of docker/)
PROJECT_DIR="$(dirname -- "$SCRIPT_DIR")"

WORKSPACE_IN_CONTAINER="/ros2_ws"
PACKAGE_IN_CONTAINER="${WORKSPACE_IN_CONTAINER}/src/lidar_localization_ros2"
# Host data logs (bags, maps), mounted at /datalogs
DATALOGS_DIR="${DATALOGS_DIR:-${HOME}/datalogs}"
DATALOGS_IN_CONTAINER="/datalogs"

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <container_name> <image_name:tag>"
  exit 1
fi

CONTAINER_NAME="$1"
IMAGE_NAME="$2"

echo "Host package:    $PROJECT_DIR"
echo "Container mount: $PACKAGE_IN_CONTAINER"
echo "Host datalogs:   $DATALOGS_DIR -> $DATALOGS_IN_CONTAINER"

if [ ! -d "$DATALOGS_DIR" ]; then
  echo "Datalogs directory not found: $DATALOGS_DIR"
  exit 1
fi

# Allow GUI apps (RViz) to use the host display
xhost +local:docker >/dev/null 2>&1 || true

docker run --privileged -it --rm \
  --network host \
  --ipc host \
  --shm-size=4gb \
  --name="$CONTAINER_NAME" \
  -e DISPLAY="${DISPLAY:-:0}" \
  -e ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "$PROJECT_DIR:$PACKAGE_IN_CONTAINER:rw" \
  -v "$DATALOGS_DIR:$DATALOGS_IN_CONTAINER:rw" \
  -w "$WORKSPACE_IN_CONTAINER" \
  "$IMAGE_NAME" \
  bash
