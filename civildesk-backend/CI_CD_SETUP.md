# CI/CD Setup Guide for Civildesk Backend

Complete guide for setting up automated CI/CD using GitHub Actions and Docker.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Server Setup](#server-setup)
4. [GitHub Configuration](#github-configuration)
5. [Environment Configuration](#environment-configuration)
6. [Testing the Pipeline](#testing-the-pipeline)
7. [Troubleshooting](#troubleshooting)

## Overview

The CI/CD pipeline automates:
- ✅ Building and testing the application
- ✅ Creating Docker images
- ✅ Deploying to your personal server
- ✅ Health checks and rollback on failure

## Prerequisites

### Server Requirements

- Ubuntu/Debian Linux server (or similar)
- Docker 20.10+ installed
- Docker Compose 2.0+ installed
- SSH access configured
- Ports available: 8080 (backend), 5432 (PostgreSQL), 6379 (Redis)

### Local Requirements

- Git
- SSH key pair for server access
- GitHub account with repository access

## Server Setup

### 1. Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group (replace $USER with your username)
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
# Or run: newgrp docker

# Verify installation
docker --version
docker compose version
```

### 2. Create Deployment Directory

```bash
# Create directories
sudo mkdir -p /opt/civildesk/civildesk-backend
sudo mkdir -p /opt/civildesk/backups

# Set ownership (replace 'youruser' with your username)
sudo chown -R $USER:$USER /opt/civildesk

# Verify
ls -la /opt/civildesk
```

### 3. Configure SSH Access

#### Option A: Generate New SSH Key (Recommended for CI/CD)

```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions-civildesk" -f ~/.ssh/civildesk_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/civildesk_deploy.pub user@your-server-ip

# Test connection
ssh -i ~/.ssh/civildesk_deploy user@your-server-ip
```

#### Option B: Use Existing SSH Key

```bash
# Copy your existing public key to server
ssh-copy-id user@your-server-ip

# Test connection
ssh user@your-server-ip
```

**Important**: You'll need the **private key** content for GitHub Secrets.

### 4. Create Environment File

```bash
# On your server
cd /opt/civildesk/civildesk-backend
nano .env
```

Add the following content (update with your values):

```env
# Database Configuration
DB_NAME=civildesk
DB_USERNAME=civildesk_user
DB_PASSWORD=your_secure_database_password_here

# JWT Configuration
# Generate with: openssl rand -base64 32
JWT_SECRET=your_jwt_secret_key_minimum_256_bits_long_here
JWT_EXPIRATION=86400000
JWT_REFRESH_EXPIRATION=604800000

# Server Configuration
SERVER_PORT=8080

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# Redis Configuration
REDIS_ENABLED=true
REDIS_PASSWORD=your_secure_redis_password_here

# Email Configuration (Optional)
EMAIL_ENABLED=true
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_FROM=noreply@civildesk.com

# Face Recognition Service (Optional)
FACE_SERVICE_URL=http://localhost:8000

# Spring Profile
SPRING_PROFILES_ACTIVE=prod
```

Save and set permissions:

```bash
chmod 600 .env
```

## GitHub Configuration

### 1. Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

#### SSH_PRIVATE_KEY

```bash
# On your local machine, display the private key
cat ~/.ssh/civildesk_deploy
# Or if using existing key:
cat ~/.ssh/id_ed25519
```

Copy the entire output (including `-----BEGIN` and `-----END` lines) and paste into the secret value.

#### SERVER_HOST

Your server's IP address or domain name:
```
192.168.1.100
```
or
```
server.example.com
```

#### SERVER_USER

The SSH username:
```
deploy
```
or
```
ubuntu
```

### 2. Verify Secrets

After adding secrets, they should appear in the list (values are hidden for security).

## Environment Configuration

### Generate Secure Passwords

```bash
# Generate database password
openssl rand -base64 24

# Generate JWT secret
openssl rand -base64 32

# Generate Redis password
openssl rand -base64 24
```

### Configure Firewall (if applicable)

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow application ports
sudo ufw allow 8080/tcp
sudo ufw allow 5432/tcp  # Only if accessing DB externally
sudo ufw allow 6379/tcp  # Only if accessing Redis externally

# Enable firewall
sudo ufw enable
sudo ufw status
```

## Testing the Pipeline

### 1. Test Manual Deployment First

SSH into your server and test the deployment script:

```bash
cd /opt/civildesk/civildesk-backend

# Make sure files are present (they'll be copied by CI/CD)
# For now, copy them manually:
# - docker-compose.yml
# - Dockerfile
# - deploy.sh

chmod +x deploy.sh
./deploy.sh
```

### 2. Test GitHub Actions Workflow

1. Make a small change to the code
2. Commit and push to `main` or `develop` branch:
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```
3. Go to GitHub → **Actions** tab
4. Watch the workflow run

### 3. Verify Deployment

```bash
# SSH into server
ssh user@your-server-ip

# Check containers
cd /opt/civildesk/civildesk-backend
docker compose ps

# Check logs
docker compose logs -f backend

# Test health endpoint
curl http://localhost:8080/api/health
```

## Troubleshooting

### Issue: SSH Connection Failed

**Symptoms**: Workflow fails at "Setup SSH" or "Copy files to server"

**Solutions**:
1. Verify SSH key is correct:
   ```bash
   # Test manually
   ssh -i ~/.ssh/civildesk_deploy user@server-ip
   ```

2. Check server SSH configuration:
   ```bash
   # On server
   sudo nano /etc/ssh/sshd_config
   # Ensure: PubkeyAuthentication yes
   # Restart: sudo systemctl restart sshd
   ```

3. Verify GitHub secret format:
   - Must include `-----BEGIN` and `-----END` lines
   - No extra spaces or newlines

### Issue: Docker Image Not Found

**Symptoms**: Deployment fails with "image not found"

**Solutions**:
1. Check if image was built in "Docker Build" job
2. Verify image transfer:
   ```bash
   # On server, check images
   docker images | grep civildesk-backend
   ```

3. Manually load image if needed:
   ```bash
   # On server
   docker load < /tmp/civildesk-backend-latest.tar.gz
   ```

### Issue: Health Check Failed

**Symptoms**: Deployment completes but health check fails

**Solutions**:
1. Check backend logs:
   ```bash
   docker compose logs backend
   ```

2. Verify database connection:
   ```bash
   docker compose logs postgres
   docker compose exec postgres psql -U civildesk_user -d civildesk -c "SELECT 1;"
   ```

3. Check environment variables:
   ```bash
   # On server
   cd /opt/civildesk/civildesk-backend
   cat .env
   ```

4. Verify port is accessible:
   ```bash
   curl http://localhost:8080/api/health
   netstat -tlnp | grep 8080
   ```

### Issue: Permission Denied

**Symptoms**: Script execution fails

**Solutions**:
```bash
# On server
chmod +x /opt/civildesk/civildesk-backend/deploy.sh
chmod 600 /opt/civildesk/civildesk-backend/.env
```

### Issue: Database Connection Failed

**Symptoms**: Backend can't connect to PostgreSQL

**Solutions**:
1. Check PostgreSQL is running:
   ```bash
   docker compose ps postgres
   ```

2. Verify database credentials in `.env`
3. Check network connectivity:
   ```bash
   docker compose exec backend ping postgres
   ```

### Viewing Workflow Logs

1. Go to GitHub repository
2. Click **Actions** tab
3. Select the workflow run
4. Click on failed job
5. Expand failed step to see error details

### Manual Rollback

If deployment fails:

```bash
# On server
cd /opt/civildesk/civildesk-backend

# List backups
ls -lh /opt/civildesk/backups/

# Restore from backup
tar -xzf /opt/civildesk/backups/deployment_YYYYMMDD_HHMMSS.tar.gz -C .

# Restart
docker compose down
docker compose up -d
```

## Security Checklist

- [ ] Strong passwords for database, Redis, and JWT
- [ ] SSH key-based authentication only
- [ ] `.env` file has correct permissions (600)
- [ ] Firewall configured properly
- [ ] Regular backups enabled
- [ ] GitHub Secrets configured (not hardcoded)
- [ ] Docker images regularly updated
- [ ] Logs monitored for suspicious activity

## Next Steps

1. Set up monitoring (optional):
   - Configure log aggregation
   - Set up alerts for failures
   - Monitor resource usage

2. Add notifications (optional):
   - Slack/Discord webhooks
   - Email notifications
   - SMS alerts

3. Implement blue-green deployment (advanced):
   - Zero-downtime deployments
   - Traffic switching
   - Automated rollback

## Support

For issues:
1. Check GitHub Actions logs
2. Review server logs: `docker compose logs`
3. Verify configuration files
4. Test SSH connection manually
5. Check Docker and Docker Compose versions

## Quick Reference

```bash
# Server status
cd /opt/civildesk/civildesk-backend && docker compose ps

# View logs
docker compose logs -f backend

# Restart services
docker compose restart backend

# Stop all services
docker compose down

# Start all services
docker compose up -d

# Health check
curl http://localhost:8080/api/health
```

