#!/bin/bash
echo "=== Docker Load Balancer Setup ==="
echo "1. Installing Docker..."
sudo dnf install -y docker

echo "2. Starting Docker service..."
sudo systemctl enable --now docker

echo "3. Building Docker images..."
docker build -t web_docker_server -f dockerfiles/server1.Dockerfile .
docker build -t web_docker_server2 -f dockerfiles/server2.Dockerfile .

echo "4. Setup complete!"
echo "Run './scripts/web-service.sh start' to start the service"
