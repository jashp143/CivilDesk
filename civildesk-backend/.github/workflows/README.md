# CI/CD Pipeline Documentation

This directory contains GitHub Actions workflows for automated CI/CD of the Civildesk Backend.

## Workflow Overview

The CI/CD pipeline consists of three main stages:

1. **Build and Test** - Compiles the application, runs tests, and packages the JAR
2. **Docker Build** - Builds the Docker image for deployment
3. **Deploy** - Deploys the application to your personal server

## Setup Instructions

### 1. Server Prerequisites

On your deployment server, ensure you have:

- Docker installed and running
- Docker Compose installed
- SSH access configured
- Required ports open (8080 for backend, 5432 for PostgreSQL, 6379 for Redis)

### 2. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add:

   - **`SSH_PRIVATE_KEY`**: Your SSH private key for server access
     ```bash
     # Generate if you don't have one:
     ssh-keygen -t ed25519 -C "github-actions"
     # Copy the private key content:
     cat ~/.ssh/id_ed25519
     ```

   - **`SERVER_HOST`**: Your server's IP address or domain name
     ```
     Example: 192.168.1.100 or server.example.com
     ```

   - **`SERVER_USER`**: SSH username for server access
     ```
     Example: deploy or ubuntu
     ```

### 3. Server Setup

#### Initial Server Configuration

SSH into your server and run:

```bash
# Create deployment directory
sudo mkdir -p /opt/civildesk/civildesk-backend
sudo mkdir -p /opt/civildesk/backups

# Set permissions (adjust user as needed)
sudo chown -R $USER:$USER /opt/civildesk

# Install Docker (if not installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose (if not installed)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add your user to docker group
sudo usermod -aG docker $USER
```

#### Configure SSH Access

1. **On your server**, add the public key to `~/.ssh/authorized_keys`:

```bash
# On server, add the public key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

2. **On your local machine**, generate SSH key pair if needed:

```bash
ssh-keygen -t ed25519 -C "github-actions"
# Copy public key to server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-server
```

#### Create Environment File

Create `.env` file on the server:

```bash
cd /opt/civildesk/civildesk-backend
nano .env
```

Add your environment variables (see `.env.example` for template):

```env
# Database
DB_NAME=civildesk
DB_USERNAME=civildesk_user
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_jwt_secret_key_min_256_bits
JWT_EXPIRATION=86400000

# Redis
REDIS_PASSWORD=your_redis_password

# Server
SERVER_PORT=8080

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# Email (optional)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_FROM=noreply@civildesk.com
EMAIL_ENABLED=true

# Face Recognition Service (optional)
FACE_SERVICE_URL=http://localhost:8000

# Spring Profile
SPRING_PROFILES_ACTIVE=prod
```

### 4. Workflow Triggers

The pipeline runs automatically on:

- **Push to `main` or `develop` branches** (full CI/CD)
- **Pull requests to `main` or `develop`** (CI only, no deployment)
- **Manual trigger** via GitHub Actions UI (workflow_dispatch)

### 5. Manual Deployment

You can also deploy manually using the deployment script:

```bash
# On your server
cd /opt/civildesk/civildesk-backend
./deploy.sh
```

## Workflow Details

### CI Stage: Build and Test

- Checks out code
- Sets up JDK 17
- Caches Maven dependencies
- Compiles the application
- Runs unit tests
- Packages the JAR file
- Uploads artifacts

### CI Stage: Docker Build

- Builds Docker image using the Dockerfile
- Tags image with commit SHA and `latest`
- Tests the Docker image
- Saves and uploads the image as artifact

### CD Stage: Deploy

- Downloads the Docker image artifact
- Sets up SSH connection to server
- Transfers files (docker-compose.yml, Dockerfile, deploy.sh)
- Transfers and loads Docker image on server
- Runs deployment script on server
- Performs health checks
- Shows deployment summary

## Monitoring and Troubleshooting

### View Workflow Logs

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select the workflow run
4. Click on individual jobs to see logs

### Check Server Status

SSH into your server and run:

```bash
# Check container status
cd /opt/civildesk/civildesk-backend
docker compose ps

# View logs
docker compose logs -f backend

# Check health endpoint
curl http://localhost:8080/api/health
```

### Common Issues

#### 1. SSH Connection Failed

- Verify `SSH_PRIVATE_KEY` secret is correct
- Check `SERVER_HOST` and `SERVER_USER` are correct
- Ensure SSH key is added to server's `authorized_keys`
- Test SSH connection manually: `ssh user@host`

#### 2. Docker Image Not Found

- Check if image was built successfully in Docker Build job
- Verify image was transferred to server
- Check Docker images on server: `docker images | grep civildesk-backend`

#### 3. Health Check Failed

- Check backend logs: `docker compose logs backend`
- Verify database and Redis are running: `docker compose ps`
- Check application configuration in `.env` file
- Ensure port 8080 is accessible

#### 4. Deployment Script Permission Denied

```bash
# On server, make script executable
chmod +x /opt/civildesk/civildesk-backend/deploy.sh
```

## Security Best Practices

1. **Never commit secrets** - Always use GitHub Secrets
2. **Use strong passwords** - For database, Redis, and JWT
3. **Restrict SSH access** - Use key-based authentication only
4. **Keep dependencies updated** - Regularly update Docker images
5. **Monitor logs** - Set up log monitoring for production
6. **Backup regularly** - The deployment script creates backups automatically

## Rollback Procedure

If deployment fails, the script automatically attempts rollback. Manual rollback:

```bash
# On server
cd /opt/civildesk/civildesk-backend

# List backups
ls -lh /opt/civildesk/backups/

# Restore from backup
tar -xzf /opt/civildesk/backups/deployment_YYYYMMDD_HHMMSS.tar.gz -C .

# Restart services
docker compose down
docker compose up -d
```

## Customization

### Change Deployment Directory

Edit the workflow file and update:

```yaml
DEPLOY_DIR="/opt/civildesk"  # Change this path
```

### Add Notifications

Add notification steps to the workflow (Slack, Discord, Email, etc.):

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Environment-Specific Deployments

Modify the workflow to support multiple environments:

```yaml
if: github.ref == 'refs/heads/main'  # Production
if: github.ref == 'refs/heads/develop'  # Staging
```

## Support

For issues or questions:
1. Check workflow logs in GitHub Actions
2. Review server logs: `docker compose logs`
3. Verify configuration files
4. Check GitHub Secrets are set correctly

