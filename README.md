markdown
# 🐳 Docker Load Balancer Project
## Enterprise-grade web infrastructure with high availability

### 📋 Project Overview
A production-ready load balancing setup demonstrating:
- **Containerization** with Docker
- **Load balancing** with Nginx reverse proxy  
- **High availability** with automatic failover
- **Automation** with Bash scripts
- **Security** hardening on Rocky Linux

### 🏗️ Architecture
User → Nginx (Port 80) → Docker Container 1 (8081)
↘ → Docker Container 2 (8082)


### 🚀 Quick Start
```bash
# 1. Clone repository
git clone https://github.com/inrayzex/docker-load-balancer.git
cd docker-load-balancer

# 2. Run setup
./scripts/setup.sh
📁 Project Structure

docker-load-balancer/
├── dockerfiles/          # Docker configurations
├── html/                # Web content  
├── scripts/             # Management scripts
├── configs/             # Nginx configurations
└── README.md
🛠️ Technologies
Docker & Containerd

Nginx 1.20+

Rocky Linux 9 / RHEL

Bash scripting

Systemd, Firewalld, SELinux
