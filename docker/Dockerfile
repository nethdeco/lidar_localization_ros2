# ROS 2 image with the dependencies of lidar_localization_ros2 and ndt_omp_ros2
# built in /ros2_ws. lidar_localization_ros2 is mounted into /ros2_ws/src at
# runtime and built by hand in the container.
#
# The container runs as a non-root user with passwordless sudo. Build with the
# host user's name, uid and gid so files written to mounts belong to you:
#
#   docker build -f docker/Dockerfile -t lidar_localization_ros2:latest \
#     --build-arg USERNAME=$(whoami) --build-arg USER_UID=$(id -u) \
#     --build-arg USER_GID=$(id -g) .
#   ./docker/container_run.sh lidar_localization lidar_localization_ros2:latest
#   colcon build --packages-select lidar_localization_ros2 \
#     --cmake-args -DCMAKE_BUILD_TYPE=Release && source install/setup.bash
#
# ROS_DISTRO=humble also works (ros:humble):  --build-arg ROS_DISTRO=humble
ARG ROS_DISTRO=jazzy
FROM ros:${ROS_DISTRO}-ros-base

ARG ROS_DISTRO
# ndt_omp_ros2 has no jazzy branch; CI builds humble on both distros.
ARG NDT_OMP_BRANCH=humble
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# rviz2 for visualisation; Xvfb to run it headless when there is no display.
RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      libomp-dev \
      net-tools \
      python3-colcon-common-extensions \
      python3-pytest \
      python3-rosdep \
      ros-${ROS_DISTRO}-rviz2 \
      sudo \
      xvfb \
    && rm -rf /var/lib/apt/lists/*

# Non-root user with passwordless sudo. Ubuntu 24.04 images (jazzy) ship an
# "ubuntu" user with uid/gid 1000; remove it so the host's ids can be reused.
RUN if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi \
    && if ! getent group ${USER_GID} >/dev/null; then \
         groupadd --gid ${USER_GID} ${USERNAME}; \
       fi \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && mkdir -p /ros2_ws/src \
    && chown -R ${USER_UID}:${USER_GID} /ros2_ws

WORKDIR /ros2_ws/src
RUN git clone --depth 1 -b ${NDT_OMP_BRANCH} \
      https://github.com/rsasaki0109/ndt_omp_ros2.git

# Install dependencies from package.xml alone; the package source is not
# copied into the image. It is placed in /ros2_ws/src and built at runtime.
COPY package.xml /tmp/deps/lidar_localization_ros2/package.xml
RUN apt-get update \
    && (rosdep init 2>/dev/null || true) \
    && rosdep update --rosdistro ${ROS_DISTRO} \
    && rosdep install -y --rosdistro ${ROS_DISTRO} \
         --from-paths /ros2_ws/src /tmp/deps --ignore-src \
    && rm -rf /var/lib/apt/lists/* /tmp/deps \
    && chown -R ${USER_UID}:${USER_GID} /ros2_ws

USER ${USERNAME}
WORKDIR /ros2_ws

# Build ndt_omp_ros2 before the cheap user-setup layers below, so editing those
# does not recompile it. build/ is kept so a later colcon build in the
# container sees ndt_omp_ros2 as up to date.
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
    && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release \
    && rm -rf log

# rosdep's cache is per user; refresh it for the runtime user.
RUN rosdep update --rosdistro ${ROS_DISTRO}
# Coloured prompt: user@host cwd $
RUN echo 'export PS1="\[\e[01;32m\]\u\[\e[0m\]\[\e[00;37m\]@\[\e[0m\]\[\e[01;36m\]\h\[\e[0m\]\[\e[00;37m\] \[\e[0m\]\[\e[01;35m\]\w\[\e[0m\]\[\e[01;37m\] $ \[\e[0m\]"' >> ~/.bashrc
# Source ROS in every interactive shell, plus the workspace once it is built.
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && echo '[ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash' >> ~/.bashrc

COPY docker/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
