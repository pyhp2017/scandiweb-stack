#!/bin/sh

# Install Docker and dependencies
sudo apt-get update -y &&
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
sudo apt-get update -y &&
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose &&
sudo systemctl start docker &&
sudo systemctl enable docker &&
sudo groupadd docker &&
sudo usermod -aG docker ubuntu

# Set MAGENTO_BASE_URL environment variable
sudo echo "MAGENTO_BASE_URL=${MAGENTO_BASE_URL}" >> /etc/environment

# Run Docker Compose
sudo docker-compose -f /home/ubuntu/docker-compose.yaml up -d &&
touch /home/ubuntu/docker-installation-complete