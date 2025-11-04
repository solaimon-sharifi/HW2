#!/usr/bin/env bash
set -euo pipefail

echo "This script installs Docker Engine and the Compose plugin on Ubuntu/Debian systems."
echo "It requires sudo privileges."

if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo: sudo ./scripts/install_docker_ubuntu.sh"
  exit 1
fi

apt update
apt install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable --now docker

echo "Docker and compose plugin installed. Add your user to the docker group to run without sudo:"
echo "  sudo usermod -aG docker <your-user>"
echo "Then log out and log in again (or run 'newgrp docker')."

echo "Verify with: docker --version && docker compose version && docker run --rm hello-world"
