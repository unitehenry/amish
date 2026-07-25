#!/usr/bin/env bash

set -e

apt-get update

# Install deps
apt-get install -y sudo curl git coreutils

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

# Start docker
sudo systemctl start docker

# Build xpod
rm -rf /var/lib/xpod && git clone https://github.com/unitehenry/xpod /var/lib/xpod

docker buildx build --load -t xpod-base -f /var/lib/xpod/base/Containerfile /var/lib/xpod/base
docker buildx build --load -t xpod-chromium -f /var/lib/xpod/apps/chromium/Containerfile /var/lib/xpod/apps/chromium

# Amish network
docker network inspect amish >/dev/null 2>&1 || docker network create amish
docker rm -f guacd guacamole xpod-chromium agent-browser-mcp 2>/dev/null || true

# Build agent browser mcp
rm -rf /var/lib/agent-browser-mcp && git clone https://github.com/unitehenry/agent-browser-mcp /var/lib/agent-browser-mcp

docker buildx build --load -t agent-browser-mcp -f /var/lib/agent-browser-mcp/Containerfile /var/lib/agent-browser-mcp

# Run guacd
docker run -d --network amish --name guacd docker.io/guacamole/guacd

# Run guacamole
mkdir -p /var/lib/guacamole/config

curl https://raw.githubusercontent.com/unitehenry/amish/refs/heads/master/guacamole/config/user-mapping.xml -o /var/lib/guacamole/config/user-mapping.xml

if [ "${WIZARD}" = "0" ]; then
  GUAC_USERNAME="admin"
  GUAC_PASSWORD="password"
else
  read -rp "Enter guacamole username: " GUAC_USERNAME
  read -rsp "Enter guacamole password: " GUAC_PASSWORD
  echo
fi

GUAC_PASSWORD_HASH=$(echo -n "${GUAC_PASSWORD}" | md5sum | awk '{print $1}')

sed -i "s/__USERNAME__/${GUAC_USERNAME}/g" /var/lib/guacamole/config/user-mapping.xml
sed -i "s/__PASSWORD__/${GUAC_PASSWORD_HASH}/g" /var/lib/guacamole/config/user-mapping.xml

docker run -d \
  --network amish \
  -v /var/lib/guacamole/config:/etc/guacamole \
  -e GUACD_HOSTNAME="guacd" \
  --name guacamole \
  -p 127.0.0.1:8080:8080 \
  docker.io/guacamole/guacamole

# Run xpod-chromium
docker run -d --pull=never \
  --cap-add=SYS_ADMIN \
  --network amish \
  --name xpod-chromium \
  xpod-chromium

# Run agent browser mcp
if [ "${WIZARD}" = "0" ]; then
  docker run -d --pull=never \
    --network=amish \
    -e CDP_PORT="http://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' xpod-chromium):9222" \
    -p 127.0.0.1:8000:8000 \
    --name agent-browser-mcp \
    agent-browser-mcp
else
  read -rp "Enter GitHub OAuth App client ID: " GITHUB_CLIENT_ID
  read -rsp "Enter GitHub OAuth App client secret: " GITHUB_CLIENT_SECRET
  echo
  read -rp "Enter GitHub username to grant access: " GITHUB_USERNAME
  read -rp "Enter public base URL of the server (for OAuth redirects): " BASE_URL
  docker run -d --pull=never \
    --network=amish \
    -e CDP_PORT="http://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' xpod-chromium):9222" \
    -e GITHUB_CLIENT_ID="${GITHUB_CLIENT_ID}" \
    -e GITHUB_CLIENT_SECRET="${GITHUB_CLIENT_SECRET}" \
    -e GITHUB_USERNAME="${GITHUB_USERNAME}" \
    -e BASE_URL="${BASE_URL}" \
    -p 127.0.0.1:8000:8000 \
    --name agent-browser-mcp \
    agent-browser-mcp
fi

# Install nginx
sudo apt-get install -y nginx

if [ "${WIZARD}" = "0" ]; then SERVER_NAME="example.com"; else read -rp "Enter server name for nginx (e.g. example.com): " SERVER_NAME; fi
curl https://raw.githubusercontent.com/unitehenry/amish/refs/heads/master/nginx/nginx.conf -o /etc/nginx/nginx.conf
sed -i "s/__SERVER_NAME__/${SERVER_NAME}/g" /etc/nginx/nginx.conf

# Reload nginx
sudo systemctl restart nginx
