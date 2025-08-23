#!/bin/bash

set -e

echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 1. Install Miniconda (recommended over full Anaconda for most server use cases)
echo "Installing Miniconda..."
curl -O https://repo.anaconda.com/archive/Anaconda3-2025.06-0-Linux-x86_64.sh
shasum -a 256 ~/Anaconda3-2025.06-0-Linux-x86_64.sh
bash ~/Anaconda3-2025.06-0-Linux-x86_64.sh
source ~/.bashrc
conda config --set auto_activate_base True
eval "$($HOME/miniconda/bin/conda shell.bash hook)"


# Refresh bash profile to add conda
source ~/.bashrc

# 2. Install Docker
echo "Installing Docker..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group (requires logout/login to take effect)
sudo usermod -aG docker $USER

# 3. Install Docker Compose v2 (standalone, optional)
echo "Installing Docker Compose (standalone)..."
DOCKER_COMPOSE_VERSION="2.24.7"
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Install JupyterLab via conda
echo "Installing JupyterLab..."
conda install -y jupyterlab

# 5. Install pgcli (Postgres CLI) via conda
echo "Installing pgcli..."
conda install -y -c conda-forge pgcli

echo "All done! Please log out and back in for Docker group changes to take effect."
echo "Test your installation:"
echo "  - conda --version"
echo "  - docker --version"
echo "  - docker-compose --version"
echo "  - jupyter lab --version"
echo "  - pgcli --version"
