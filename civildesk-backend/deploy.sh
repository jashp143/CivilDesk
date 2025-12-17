#!/bin/bash

# Deployment script for Civildesk Backend
# This script can be used for manual deployments or called by CI/CD

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="/opt/civildesk"
BACKEND_DIR="$DEPLOY_DIR/civildesk-backend"
HEALTH_CHECK_URL="http://localhost:8080/api/health"
MAX_RETRIES=10
RETRY_DELAY=5

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed!"
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose is not installed!"
        exit 1
    fi
    
    # Check if deployment directory exists
    if [ ! -d "$BACKEND_DIR" ]; then
        log_error "Backend directory not found: $BACKEND_DIR"
        exit 1
    fi
    
    # Check if .env file exists
    if [ ! -f "$BACKEND_DIR/.env" ] && [ ! -f "$DEPLOY_DIR/.env" ]; then
        log_warn ".env file not found. Make sure environment variables are set."
    fi
    
    log_info "Prerequisites check passed!"
}

backup_current_deployment() {
    log_info "Creating backup of current deployment..."
    
    BACKUP_DIR="$DEPLOY_DIR/backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/deployment_$TIMESTAMP.tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup docker-compose.yml and .env if exists
    if [ -d "$BACKEND_DIR" ]; then
        cd "$BACKEND_DIR"
        tar -czf "$BACKUP_FILE" docker-compose.yml .env 2>/dev/null || true
        log_info "Backup created: $BACKUP_FILE"
        
        # Keep only last 5 backups
        ls -t "$BACKUP_DIR"/deployment_*.tar.gz | tail -n +6 | xargs rm -f 2>/dev/null || true
    fi
}

stop_containers() {
    log_info "Stopping existing containers..."
    
    cd "$BACKEND_DIR"
    
    # Gracefully stop containers
    docker compose down --timeout 30 || {
        log_warn "Some containers may not have stopped gracefully"
        docker compose kill || true
        docker compose down || true
    }
    
    log_info "Containers stopped"
}

build_and_start() {
    log_info "Building and starting containers..."
    
    cd "$BACKEND_DIR"
    
    # Pull latest images
    log_info "Pulling latest base images..."
    docker compose pull || true
    
    # Build application
    log_info "Building application Docker image..."
    docker compose build --no-cache --pull
    
    # Start containers
    log_info "Starting containers..."
    docker compose up -d
    
    log_info "Containers started"
}

wait_for_services() {
    log_info "Waiting for services to be ready..."
    
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if docker compose ps | grep -q "healthy\|Up"; then
            log_info "Services are starting..."
            sleep $RETRY_DELAY
        fi
        
        retry_count=$((retry_count + 1))
        sleep 2
    done
}

health_check() {
    log_info "Running health check..."
    
    local retry_count=0
    local http_code=000
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL" || echo "000")
        
        if [ "$http_code" = "200" ]; then
            log_info "✅ Health check passed! (HTTP $http_code)"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_warn "Health check attempt $retry_count/$MAX_RETRIES failed (HTTP $http_code), retrying..."
            sleep $RETRY_DELAY
        fi
    done
    
    log_error "Health check failed after $MAX_RETRIES attempts!"
    return 1
}

show_status() {
    log_info "Container status:"
    cd "$BACKEND_DIR"
    docker compose ps
    
    log_info "Recent logs:"
    docker compose logs --tail=20 backend
}

cleanup() {
    log_info "Cleaning up old Docker images..."
    docker image prune -f || true
}

rollback() {
    log_error "Deployment failed! Attempting rollback..."
    
    # This is a simple rollback - in production, you might want more sophisticated rollback
    cd "$BACKEND_DIR"
    
    # Try to restore from backup or previous git commit
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        log_info "Restoring from backup..."
        tar -xzf "$BACKUP_FILE" -C "$BACKEND_DIR" || true
    fi
    
    # Restart with previous configuration
    docker compose down
    docker compose up -d
    
    log_warn "Rollback completed. Please verify manually."
}

# Main deployment flow
main() {
    log_info "=========================================="
    log_info "🚀 Civildesk Backend Deployment"
    log_info "=========================================="
    log_info "Date: $(date)"
    log_info "Directory: $BACKEND_DIR"
    log_info "=========================================="
    
    # Trap errors for rollback
    trap 'rollback; exit 1' ERR
    
    # Run deployment steps
    check_prerequisites
    backup_current_deployment
    stop_containers
    build_and_start
    wait_for_services
    
    # Health check
    if health_check; then
        cleanup
        show_status
        log_info "=========================================="
        log_info "✅ Deployment completed successfully!"
        log_info "=========================================="
    else
        log_error "Health check failed!"
        show_status
        rollback
        exit 1
    fi
}

# Run main function
main "$@"

