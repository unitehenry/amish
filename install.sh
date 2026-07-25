#!/usr/bin/env bash

set -e

apt-get update

# Install Docker
if ! command -v docker >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt update

  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# Build xpod
apt-get install -y git

rm -rf /var/lib/xpod && git clone https://github.com/unitehenry/xpod /var/lib/xpod

docker build -t xpod-base -f /var/lib/xpod/base/Containerfile /var/lib/xpod/base
docker build -t xpod-chromium -f /var/lib/xpod/apps/chromium/Containerfile /var/lib/xpod/apps/chromium

# Amish network
docker network inspect amish >/dev/null 2>&1 || docker network create amish
docker rm -f guacd guacamole xpod-chromium agent-browser-mcp 2>/dev/null || true

# Build agent browser mcp
git clone https://github.com/unitehenry/agent-browser-mcp /var/lib/agent-browser-mcp

podman build -t agent-browser-mcp -f /var/lib/agent-browser-mcp/Containerfile /var/lib/agent-browser-mcp

# Run guacd
docker run -d --network amish --name guacd docker.io/guacamole/guacd

# Run guacamole
mkdir -p /var/lib/guacamole/config

curl https://raw.githubusercontent.com/unitehenry/amish/refs/heads/master/guacamole/config/user-mapping.xml -o /var/lib/guacamole/config/user-mapping.xml

# TODO: sed guacamole username / password

docker run -d \
  --network amish \
  -v /var/lib/guacamole/config:/etc/guacamole \
  -e GUACD_HOSTNAME="guacd" \
  --name guacamole \
  -p 127.0.0.1:8080:8080 \
  docker.io/guacamole/guacamole

# Run xpod-chromium
docker run -d \
  --cap-add=SYS_ADMIN \
  --network amish \
  --name xpod-chromium \
  xpod-chromium

# Run agent browser mcp
docker run -d \
  --network=amish \
  -e CDP_PORT="http://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' xpod-chromium):9222" \
  -p 127.0.0.1:8000:8000 \
  --name agent-browser-mcp \
  agent-browser-mcp

# Install nginx
sudo apt-get install -y nginx

curl https://raw.githubusercontent.com/unitehenry/amish/refs/heads/master/nginx/nginx.conf -o /etc/nginx/nginx.conf

# Reload nginx
sudo systemctl restart nginx
