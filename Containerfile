# Use Fedora minimal 36 as base image
FROM registry.fedoraproject.org/fedora-minimal:36

LABEL maintainer="Nodens- <info@abnormalfreq.com>"

# Add WineHQ repo
ADD winehq.repo /etc/yum.repos.d/winehq.repo

# Update and install packages
RUN microdnf update -y --nodocs --setopt=install_weak_deps=0 \
	&& microdnf install -y \
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
	samba-winbind \
	--nodocs --setopt=install_weak_deps=0 \
	&& microdnf clean all -y

# Create directories
RUN mkdir -p /steamcmd/vrising /app/vrising

# Install jobber
RUN curl -L -o /app/jobber-1.4.4-1.el8.x86_64.rpm https://github.com/dshearer/jobber/releases/download/v1.4.4/jobber-1.4.4-1.el8.x86_64.rpm \
	&& rpm -i /app/jobber-1.4.4-1.el8.x86_64.rpm && rm -f /app/jobber-1.4.4-1.el8.x86_64.rpm

# Set locale
RUN localedef -f UTF-8 -i en_US en_US.UTF-8

# Further cleaning
RUN rm -f /etc/udev/hwdb.bin \
	&& rm -rf /usr/lib/udev/hwdb.d/ \
	&& rm -rf /boot \
	&& rm -rf /var/lib/dnf/history.* \
	&& rm -rf /usr/lib/locale/locale-archive* \
	&& rm -rf /var/cache/* \
	&& rm -rf /var/lib/rpm

# Expose necessary ports
EXPOSE 9876/udp
EXPOSE 9877/udp
EXPOSE 9878/tcp

# Add non-root user
RUN groupadd -g 1000 vrserver \
	&& useradd -ms /bin/bash -u 1000 -g vrserver vrserver \
	&& mkdir -p /home/vrserver/.wine /var/jobber/1000 \
	&& echo -e "LANG="en_US.utf8"\nexport LANG" > /home/vrserver/.bashrc


# Add update job
ADD scripts/jobber /home/vrserver/.jobber

# Copy scripts
ADD scripts/rcon.sh /usr/bin/rcon
ADD scripts/start_vrising.sh /app/start.sh
ADD scripts/shutdown.sh /app/shutdown.sh
ADD scripts/update_check.sh /app/update_check.sh
ADD scripts/install.txt /app/install.txt

# Fix permissions
RUN chown -R vrserver:vrserver \
	/steamcmd \
	/app \
	/home/vrserver \
	/home/vrserver/.wine \
	/dev/stdout \
	/dev/stderr \
	/var/jobber/1000 \
	&& chmod 755 /usr/bin/rcon \
	&& chmod -R 775 /home/vrserver/.wine

# Switch to vrserver user
ENV USER_ID=1000
ENV GROUP_ID=1000
ENV USER_NAME=vrserver
ENV GROUP_NAME=vrserver
USER vrserver:vrserver

# Setup environment variables for configuring the server
ENV V_RISING_SERVER_PERSISTENT_DATA_PATH	"/app/vrising"
ENV V_RISING_SERVER_BRANCH			"public"
ENV V_RISING_SERVER_START_MODE			"0"
ENV V_RISING_SERVER_AUTO_UPDATE			"0"
ENV V_RISING_APPLY_CUSTOM_SETTINGS:		"1"

# Setup environment variables for customizing the server
ENV V_RISING_SERVER_NAME			"V Rising Container Server"
ENV V_RISING_SERVER_DESCRIPTION			"V Rising server running inside a container."
ENV V_RISING_SERVER_BIND_IP			"127.0.0.1"
ENV V_RISING_SERVER_GAME_PORT			9876
ENV V_RISING_SERVER_QUERY_PORT			9877
ENV V_RISING_SERVER_RCON_PORT			9878
ENV V_RISING_SERVER_RCON_ENABLED		true
ENV V_RISING_SERVER_RCON_PASSWORD		"s3cr3t_rc0n_p455w0rd"
ENV V_RISING_SERVER_MAX_CONNECTED_USERS		40
ENV V_RISING_SERVER_MAX_CONNECTED_ADMINS	4
ENV V_RISING_SERVER_SAVE_NAME			"docker"
ENV V_RISING_SERVER_PASSWORD			""
ENV V_RISING_SERVER_LIST_ON_MNASTER_SERVER	true
ENV V_RISING_SERVER_AUTO_SAVE_COUNT		50
ENV V_RISING_SERVER_AUTO_SAVE_INTERVAL		600
ENV V_RISING_SERVER_GAME_SETTINGS_PRESET	"StandardPvE"

# Expose the volumes
VOLUME [ "/steamcmd/vrising", "/app/vrising", "/home/vrserver/.wine" ]

# Start the server
CMD [ "bash", "/app/start.sh" ]
