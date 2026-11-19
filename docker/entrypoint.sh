#!/bin/bash
# Source ROS and the /ros2_ws workspace, then run the given command.
set -e
# shellcheck source=/dev/null
source "/opt/ros/${ROS_DISTRO}/setup.bash"
if [ -f /ros2_ws/install/setup.bash ]; then
  # shellcheck source=/dev/null
  source /ros2_ws/install/setup.bash
fi
exec "$@"
