#!/usr/bin/env bash

set -e

[ -z "$1" ] && { echo "Usage: $0 <host>"; exit 1; }

HOST=$1

# Update Dependencies
ssh $HOST 'apt-get update'

# Install Docker
ssh $HOST '
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
'

# Build and Load Xpod
ssh $HOST 'apt-get install -y git'

ssh $HOST 'rm -rf /var/lib/xpod && git clone https://github.com/unitehenry/xpod /var/lib/xpod'

ssh $HOST 'docker build -t xpod-base -f /var/lib/xpod/Containerfile /var/lib/xpod'
ssh $HOST 'docker build -t xpod-chromium -f /var/lib/xpod/apps/chromium/Containerfile /var/lib/xpod'

# Build and Load Agentx (Opencode + Agent-Browser)
scp ./opencode/Containerfile $HOST:/tmp/Containerfile

ssh $HOST 'docker build -t agentx-opencode -f /tmp/Containerfile .'

# Agentx network
ssh $HOST 'docker network inspect agentx >/dev/null 2>&1 || docker network create agentx'
ssh $HOST 'docker rm -f guacd guacamole xpod-chromium agentx-opencode 2>/dev/null || true'

# Run guacd
ssh $HOST 'docker run -d --network agentx --name guacd docker.io/guacamole/guacd'

# Run guacamole
scp -r ./guacamole $HOST:/var/lib

ssh $HOST 'docker run -d \
  --network agentx \
  -v /var/lib/guacamole/config:/etc/guacamole \
  -e GUACD_HOSTNAME="guacd" \
  --name guacamole \
  -p 127.0.0.1:8080:8080 \
  docker.io/guacamole/guacamole'

# Run xpod-chromium
ssh $HOST 'docker run -d \
  --cap-add=SYS_ADMIN \
  --network agentx \
  --name xpod-chromium \
  xpod-chromium'

# Run opencode
scp -r ./opencode $HOST:/var/lib

ssh $HOST "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' xpod-chromium > /tmp/cdp_hostname"

ssh $HOST 'docker run -d \
  --network agentx \
  -v /var/lib/opencode/.opencode:/etc/opencode \
  --name agentx-opencode \
  -p 127.0.0.1:4096:4096 \
  -e CDP_HOSTNAME="$(cat /tmp/cdp_hostname):9222" \
  agentx-opencode'

# Install Nginx
ssh $HOST 'sudo apt-get install -y nginx'

scp ./nginx/nginx.conf $HOST:/etc/nginx/nginx.conf

# Create htpasswd
ssh -t $HOST '
apt-get install -y apache2-utils
read -p "Username: " USERNAME
read -s -p "Password: " PASSWORD
echo
htpasswd -c -b /etc/nginx/.htpasswd "$USERNAME" "$PASSWORD"
'

# Reload nginx
ssh $HOST 'systemctl restart nginx'
