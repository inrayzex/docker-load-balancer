#!/bin/bash
# Management of our web service (Nginx + 2 containers)
# Usage: ./web-service.sh [command]

# Colors for terminal output
RED='\033[0;31m'      # Red for errors
GREEN='\033[0;32m'    # Green for success
YELLOW='\033[1;33m'   # Yellow for warnings
BLUE='\033[0;34m'     # Blue for information
NC='\033[0m'          # No color (reset)

# Function to display info messages
show_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to display success messages
show_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Function to display error messages
show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display warning messages
show_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function: SHOW HELP
show_help() {
    echo "Web service management (Nginx + Docker containers)"
    echo ""
    echo "Usage: $0 {command}"
    echo ""
    echo "Commands:"
    echo "  start     - Start entire service"
    echo "  stop      - Stop entire service"
    echo "  restart   - Restart entire service"
    echo "  status    - Show status of all components"
    echo "  logs      - Show logs (Nginx and containers)"
    echo "  test      - Test functionality"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./web-service.sh start   # Start everything"
    echo "  ./web-service.sh status  # Check status"
}

# Function: START ENTIRE SERVICE
start_service() {
    show_info "Starting web service..."
    
    # 1. Check and start first container
    show_info "Checking container webserver1..."
    if docker ps -a | grep -q webserver1; then
        # Container exists, start it
        docker start webserver1
        show_success "Container webserver1 started"
    else
        # Container doesn't exist, create new one
        show_warning "Container webserver1 not found, creating new..."
        docker run -d --name webserver1 -p 8081:80 web_docker_server
        show_success "Container webserver1 created and started"
    fi
    
    # 2. Check and start second container
    show_info "Checking container webserver2..."
    if docker ps -a | grep -q webserver2; then
        docker start webserver2
        show_success "Container webserver2 started"
    else
        show_warning "Container webserver2 not found, creating new..."
        docker run -d --name webserver2 -p 8082:80 web_docker_server2
        show_success "Container webserver2 created and started"
    fi
    
    # 3. Start Nginx (load balancer)
    show_info "Starting Nginx load balancer..."
    sudo systemctl start nginx
    
    # 4. Wait 2 seconds for everything to start
    sleep 2
    
    # 5. Check that everything works
    show_info "Checking startup..."
    check_connectivity
    
    show_success "Web service started successfully!"
    echo "Available at: http://$(hostname -I | awk '{print $1}')"
    echo "or: http://localhost"
}

# Function: STOP ENTIRE SERVICE
stop_service() {
    show_info "Stopping web service..."
    
    # 1. Stop containers
    show_info "Stopping containers..."
    docker stop webserver1 webserver2 2>/dev/null
    show_success "Containers stopped"
    
    # 2. Stop Nginx
    show_info "Stopping Nginx..."
    sudo systemctl stop nginx
    show_success "Nginx stopped"
    
    show_success "Web service stopped"
}

# Function: RESTART ENTIRE SERVICE
restart_service() {
    show_info "Restarting web service..."
    stop_service
    sleep 2  # Wait 2 seconds
    start_service
}

# Function: CHECK CONNECTIVITY
check_connectivity() {
    show_info "Checking component connectivity..."
    
    # Check container 1
    if timeout 2 curl -s http://localhost:8081 >/dev/null; then
        show_success "Container 1 (port 8081) responds"
    else
        show_error "Container 1 (port 8081) does NOT respond"
    fi
    
    # Check container 2
    if timeout 2 curl -s http://localhost:8082 >/dev/null; then
        show_success "Container 2 (port 8082) responds"
    else
        show_error "Container 2 (port 8082) does NOT respond"
    fi
    
    # Check load balancer
    if timeout 2 curl -s http://localhost >/dev/null; then
        show_success "Load balancer (port 80) responds"
    else
        show_error "Load balancer (port 80) does NOT respond"
    fi
}

# Function: SHOW STATUS
show_status() {
    echo -e "${BLUE}====== WEB SERVICE STATUS ======${NC}"
    echo ""
    
    # 1. Nginx status
    echo -n "Nginx load balancer: "
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}RUNNING${NC}"
        echo "   Port: 80"
        echo "   Config: /etc/nginx/conf.d/load-balancer.conf"
    else
        echo -e "${RED}STOPPED${NC}"
    fi
    
    echo ""
    
    # 2. Container status
    echo "Docker containers:"
    docker ps -a --filter "name=webserver" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "   No containers"
    
    echo ""
    
    # 3. Connectivity check
    echo "Connectivity check:"
    check_connectivity
    
    echo ""
    
    # 4. Server IP address
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "Service available at:"
    echo "   http://$SERVER_IP"
    echo "   http://localhost"
    echo "Containers directly:"
    echo "   http://$SERVER_IP:8081  (Server 1)"
    echo "   http://$SERVER_IP:8082  (Server 2)"
}

# Function: SHOW LOGS
show_logs() {
    echo -e "${BLUE}====== WEB SERVICE LOGS ======${NC}"
    echo ""
    
    # 1. Nginx logs
    echo -e "${GREEN}--- Nginx logs (last 5 lines) ---${NC}"
    sudo tail -5 /var/log/nginx/access.log 2>/dev/null || echo "   Nginx logs not available"
    echo ""
    
    # 2. Nginx error logs
    echo -e "${YELLOW}--- Nginx error logs ---${NC}"
    sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "   Error logs not available"
    echo ""
    
    # 3. Container logs
    for container in webserver1 webserver2; do
        if docker ps -a | grep -q $container; then
            echo -e "${BLUE}--- Container $container logs ---${NC}"
            docker logs --tail 3 $container 2>/dev/null || echo "   Logs not available"
            echo ""
        fi
    done
}

# Function: TEST FUNCTIONALITY
test_service() {
    show_info "Testing service functionality..."
    echo ""
    
    # Load balancing test
    echo "Load balancing test (5 requests):"
    for i in {1..5}; do
        RESPONSE=$(curl -s http://localhost | grep -o "Server [0-9]" | head -1)
        echo "   Request $i: $RESPONSE"
        sleep 0.5
    done
    
    echo ""
    
    # Failover test
    echo "Failover test:"
    echo "   Stopping container webserver1..."
    docker stop webserver1 >/dev/null 2>&1
    sleep 2
    
    echo "   Making request (should go to Server 2):"
    RESPONSE=$(curl -s http://localhost | grep -o "Server [0-9]" | head -1)
    echo "   Result: $RESPONSE"
    
    echo "   Starting container webserver1 again..."
    docker start webserver1 >/dev/null 2>&1
    sleep 2
    
    show_success "Testing completed!"
}

# MAIN SCRIPT LOGIC
# Check which command is passed
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    test)
        test_service
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        show_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
EOF
