#!/usr/bin/env bash
set -ex

# Create a container
CONTAINER=$(buildah from scratch)

# Mount the container filesystem
MOUNTPOINT=$(buildah mount $CONTAINER)

# Install a basic filesystem and minimal set of packages, and httpd
dnf install -y --installroot $MOUNTPOINT  --disablerepo=Webmin --releasever 36 \
	glibc-langpack-en \
	glibc-locale-source \
	jq \
	xorg-x11-server-Xvfb \
        winehq-devel \
        wine-mono \
        mcrcon \
        unzip \
        bsdtar \
        util-linux \
        procps-ng \
	bash \
	samba-winbind \
	findutils \
	--nodocs --setopt=install_weak_deps=False --setopt=override_install_langs=en_US.utf8
dnf install -y --installroot $MOUNTPOINT  --releasever 36 https://github.com/dshearer/jobber/releases/download/v1.4.4/jobber-1.4.4-1.el8.x86_64.rpm --nodocs --setopt=install_weak_deps=False --setopt=override_install_langs=en_US.utf8
dnf clean all -y --installroot $MOUNTPOINT --releasever 36

# Cleanup
buildah unmount $CONTAINER

buildah config --label maintainer="Nodens- <info@abnormalfreq.com>" $CONTAINER

# Expose necessary ports
buildah config --port 9876/udp $CONTAINER
buildah config --port 9877/udp $CONTAINER
buildah config --port 9878/tcp $CONTAINER

# Set Locale
buildah run $CONTAINER localedef -f UTF-8 -i en_US en_US.UTF-8

# UID/GID variables to allow changing from compose.
buildah config --env UID=1000 $CONTAINER
buildah config --env GID=1000 $CONTAINER


# Add non-root user
buildah run $CONTAINER groupadd -g $GID vrserver
buildah run $CONTAINER useradd -ms /bin/bash -u $UID -g vrserver vrserver
#buildah run $CONTAINER

# Add update job
buildah copy $CONTAINER scripts/jobber /home/vrserver/.jobber

# Copy scripts
buildah copy $CONTAINER scripts/rcon.sh /usr/bin/rcon
buildah copy $CONTAINER scripts/start_vrising.sh /app/start.sh
buildah copy $CONTAINER scripts/shutdown.sh /app/shutdown.sh
buildah copy $CONTAINER scripts/update_check.sh /app/update_check.sh
buildah copy $CONTAINER scripts/install.txt /app/install.txt

# Create directories and fix permissions
buildah run $CONTAINER mkdir -p /steamcmd/vrising /app/vrising /home/vrserver/.wine /var/jobber/$UID
buildah run $CONTAINER chown -R vrserver:vrserver \
	/steamcmd \
	/app \
	/home/vrserver \
	/var/jobber/$UID \
	/dev/stdout \
	/dev/stderr
buildah run $CONTAINER chmod 755 /usr/bin/rcon
buildah run $CONTAINER chmod -R 775 /home/vrserver/.wine

# Further cleaning
buildah run $CONTAINER rm -f /etc/udev/hwdb.bin
buildah run $CONTAINER rm -rf /usr/lib/udev/hwdb.d/
buildah run $CONTAINER rm -rf /boot
buildah run $CONTAINER rm -rf /var/lib/dnf/history.*
buildah run $CONTAINER rm -rf /usr/lib/locale/locale-archive*
buildah run $CONTAINER rm -rf /var/cache/*
buildah run $CONTAINER rm -rf /var/lib/rpm


# Switch to vrserver user
buildah config --env USER_ID=1000 $CONTAINER
buildah config --env GROUP_ID=1000 $CONTAINER
buildah config --env USER_NAME=vrserver $CONTAINER
buildah config --env GROUP_NAME=vrserver $CONTAINER
buildah config --user vrserver:vrserver $CONTAINER

# Setup environment variables for configuring the server
buildah config --env V_RISING_SERVER_PERSISTENT_DATA_PATH="/app/vrising" $CONTAINER
buildah config --env V_RISING_SERVER_BRANCH="public" $CONTAINER
buildah config --env V_RISING_SERVER_START_MODE="0" $CONTAINER
buildah config --env V_RISING_SERVER_AUTO_UPDATE="0" $CONTAINER
buildah config --env V_RISING_APPLY_CUSTOM_SETTINGS="1" $CONTAINER

# Setup environment variables for customizing the server
buildah config --env V_RISING_SERVER_NAME="V Rising Container Server" $CONTAINER
buildah config --env V_RISING_SERVER_DESCRIPTION="V Rising server running inside a container." $CONTAINER
buildah config --env V_RISING_SERVER_BIND_IP="127.0.0.1" $CONTAINER
buildah config --env V_RISING_SERVER_GAME_PORT=9876 $CONTAINER
buildah config --env V_RISING_SERVER_QUERY_PORT=9877 $CONTAINER
buildah config --env V_RISING_SERVER_RCON_PORT=9878 $CONTAINER
buildah config --env V_RISING_SERVER_RCON_ENABLED=true $CONTAINER
buildah config --env V_RISING_SERVER_RCON_PASSWORD="s3cr3t_rc0n_p455w0rd" $CONTAINER
buildah config --env V_RISING_SERVER_MAX_CONNECTED_USERS=40 $CONTAINER
buildah config --env V_RISING_SERVER_MAX_CONNECTED_ADMINS=4 $CONTAINER
buildah config --env V_RISING_SERVER_SAVE_NAME="docker" $CONTAINER
buildah config --env V_RISING_SERVER_PASSWORD="" $CONTAINER
buildah config --env V_RISING_SERVER_LIST_ON_MNASTER_SERVER=true $CONTAINER
buildah config --env V_RISING_SERVER_AUTO_SAVE_COUNT=50 $CONTAINER
buildah config --env V_RISING_SERVER_AUTO_SAVE_INTERVAL=600 $CONTAINER
buildah config --env V_RISING_SERVER_GAME_SETTINGS_PRESET="StandardPvE" $CONTAINER

# Expose the volumes
buildah config --volume /steamcmd/vrising $CONTAINER
buildah config --volume /app/vrising $CONTAINER
buildah config --volume /home/vrserver/.wine $CONTAINER

# Start the server
buildah config --cmd "bash /app/start.sh" $CONTAINER

buildah commit --squash $CONTAINER vrising-cutting-edge
buildah rm $CONTAINER
