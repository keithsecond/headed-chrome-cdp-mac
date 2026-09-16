# Adapted from unmaintained jess/chrome to run CDP on a Mac. Original Dockerfile at:
# https://github.com/jessfraz/dockerfiles/blob/master/chrome/stable/Dockerfile

# You will want the custom seccomp profile:
# 	wget https://raw.githubusercontent.com/keithsecond/headed-chrome-cdp-mac/refs/heads/main/seccomp/chrome.json -O ~/chrome.json
#
# Run Chrome in a container. See cdprun for my usage.
#
# docker run -d \
#	--net host \ # may as well YOLO
#	--cpuset-cpus 0 \ # control the cpu
#	--memory 512mb \ # max memory it can use
#       -p 127.0.0.1:9222:9222 \
#       -e DISPLAY=host.docker.internal:0 \
#       -v /tmp/.X11-unix:/tmp/.X11-unix \
#       -v "$HOME/chrome-cdp-profile:/data"
#	-v $HOME/Downloads:/home/chrome/Downloads \
#       --shm-size=2g \
#	--security-opt seccomp=$HOME/chrome.json \
#	--device /dev/snd \ # so we have sound
#       --device /dev/dri \
#	-v /dev/shm:/dev/shm \
#       --name chrome-cdp \
#       chrome-cdp:local

FROM debian:trixie-slim
LABEL maintainer="terminaltrillness@gmail.com"

# Install Chrome (unchanged from jess/chrome) + supervisor + socat
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    hicolor-icon-theme \
    libcanberra-gtk* \
    libgl1-mesa-dri \
    libgl1 \
    libpulse0 \
    libv4l-0 \
    fonts-symbola \
    supervisor \
    socat \
    --no-install-recommends \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt-get update && apt-get install -y \
    google-chrome-stable \
    --no-install-recommends \
    && apt-get purge --auto-remove -y curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/supervisor

# Chrome user
RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome \
    && mkdir -p /home/chrome/Downloads /data \
    && chown -R chrome:chrome /home/chrome /data

COPY local.conf /etc/fonts/local.conf
COPY start-chrome.sh /usr/local/bin/start-chrome.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /usr/local/bin/start-chrome.sh

EXPOSE 9222

ENTRYPOINT []
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
