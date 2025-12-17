# CI/CD Guide for Spring Boot Backend

## 📚 Table of Contents
1. [What is CI/CD?](#what-is-cicd)
2. [CI/CD Concepts Explained](#cicd-concepts-explained)
3. [CI/CD Flow Diagram](#cicd-flow-diagram)
4. [Implementation Steps](#implementation-steps)
5. [GitHub Actions Setup](#github-actions-setup)
6. [Server Configuration](#server-configuration)
7. [Testing the Pipeline](#testing-the-pipeline)
8. [Troubleshooting](#troubleshooting)

---

## What is CI/CD?

**CI/CD** stands for **Continuous Integration** and **Continuous Deployment/Delivery**. It automates the process of building, testing, and deploying your application.

### Key Terms:

- **CI (Continuous Integration)**: Automatically builds and tests your code whenever you push changes
- **CD (Continuous Deployment)**: Automatically deploys your code to production after successful tests
- **CD (Continuous Delivery)**: Prepares code for deployment but requires manual approval

### Why Use CI/CD?

✅ **Automation**: No manual deployment steps  
✅ **Consistency**: Same process every time  
✅ **Speed**: Faster deployments  
✅ **Quality**: Catches bugs before production  
✅ **Rollback**: Easy to revert if something breaks  
✅ **Documentation**: Pipeline serves as deployment documentation  

---

## CI/CD Concepts Explained

### 1. **Continuous Integration (CI)**

**What it does:**
- Runs automatically when code is pushed to a repository
- Builds the application
- Runs tests
- Checks code quality
- Creates artifacts (JAR files, Docker images)

**Benefits:**
- Early bug detection
- Prevents broken code from reaching production
- Maintains code quality standards

**Example Flow:**
```
Developer pushes code → CI Pipeline triggers → Build → Run Tests → Report Results
```

### 2. **Continuous Deployment (CD)**

**What it does:**
- Automatically deploys code after successful CI
- Updates the running application
- Can include health checks and rollback mechanisms

**Benefits:**
- Faster time to market
- Reduced manual errors
- Consistent deployments

**Example Flow:**
```
CI Passes → Build Docker Image → Push to Registry → Deploy to Server → Health Check
```

### 3. **Pipeline Stages**

A typical CI/CD pipeline has these stages:

1. **Source**: Code repository (GitHub, GitLab, etc.)
2. **Build**: Compile code, create artifacts
3. **Test**: Run unit tests, integration tests
4. **Package**: Create Docker images, JAR files
5. **Deploy**: Push to server, update containers
6. **Verify**: Health checks, smoke tests

---

## CI/CD Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Developer Workflow                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Push to GitHub │
                    │  (git push)     │
                    └────────┬────────┘
                             │
                             ▼
        ┌────────────────────────────────────────────┐
        │         CI Pipeline (GitHub Actions)      │
        ├────────────────────────────────────────────┤
        │  1. Checkout Code                          │
        │  2. Setup Java 17                          │
        │  3. Cache Maven Dependencies               │
        │  4. Build Application (mvn clean package)  │
        │  5. Run Tests                              │
        │  6. Build Docker Image                     │
        │  7. Push Image to Registry (optional)      │
        └────────────┬───────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────────┐
        │         CD Pipeline (Deployment)           │
        ├────────────────────────────────────────────┤
        │  1. Connect to Server via SSH              │
        │  2. Pull Latest Code                       │
        │  3. Build Docker Image on Server           │
        │  4. Stop Old Containers                    │
        │  5. Start New Containers                  │
        │  6. Run Health Checks                      │
        │  7. Rollback if Health Check Fails        │
        └────────────┬───────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────────┐
        │         Production Server                   │
        ├────────────────────────────────────────────┤
        │  - Spring Boot App Running                 │
        │  - PostgreSQL Database                     │
        │  - Redis Cache                             │
        │  - Nginx Reverse Proxy                     │
        └────────────────────────────────────────────┘
```

---

## Implementation Steps

### Step 1: Prepare Your Repository

1. **Ensure your code is in a Git repository** (GitHub, GitLab, etc.)
2. **Create necessary directories:**
   ```bash
   mkdir -p .github/workflows
   ```

### Step 2: Set Up GitHub Secrets

You'll need to store sensitive information securely:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:

   - `SERVER_HOST`: Your server IP or domain (e.g., `192.168.1.100` or `api.yourdomain.com`)
   - `SERVER_USER`: SSH username (e.g., `ubuntu` or `root`)
   - `SERVER_SSH_KEY`: Your private SSH key for server access
   - `SERVER_DEPLOY_PATH`: Path where app is deployed (e.g., `/opt/civildesk`)
   - `SERVER_PORT`: SSH port (usually `22`)

### Step 3: Configure GitHub Actions Workflows

We'll create two workflow files:
- **CI Workflow**: Builds and tests on every push
- **CD Workflow**: Deploys to server on push to `main` branch

### Step 4: Set Up Server for Automated Deployment

The server needs:
- SSH access configured
- Docker and Docker Compose installed
- Git installed
- Proper permissions

---

## GitHub Actions Setup

### Workflow Files Location

All workflow files go in: `.github/workflows/`

### Workflow 1: CI Pipeline

**File**: `.github/workflows/ci.yml`

This workflow:
- Triggers on every push and pull request
- Builds the application
- Runs tests
- Creates build artifacts

### Workflow 2: CD Pipeline

**File**: `.github/workflows/deploy.yml`

This workflow:
- Triggers on push to `main` branch (after CI passes)
- Connects to your server via SSH
- Pulls latest code
- Rebuilds and restarts containers
- Performs health checks

---

## Server Configuration

### 1. Generate SSH Key Pair

On your local machine:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# This creates:
# - ~/.ssh/github_actions_deploy (private key - add to GitHub Secrets)
# - ~/.ssh/github_actions_deploy.pub (public key - add to server)
```

### 2. Add Public Key to Server

```bash
# Copy public key to server
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub user@your-server-ip

# Or manually:
# 1. Copy the public key content
cat ~/.ssh/github_actions_deploy.pub

# 2. On server, add to authorized_keys:
ssh user@your-server-ip
mkdir -p ~/.ssh
echo "YOUR_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 3. Test SSH Connection

```bash
# Test connection
ssh -i ~/.ssh/github_actions_deploy user@your-server-ip
```

### 4. Prepare Server Directory

On your server:

```bash
# Create deployment directory
sudo mkdir -p /opt/civildesk
sudo chown $USER:$USER /opt/civildesk

# Ensure Docker is accessible
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### 5. Create Deployment Script on Server

The deployment script will be created automatically, but you can also create it manually:

```bash
# On server
nano /opt/civildesk/deploy.sh
```

Add:
```bash
#!/bin/bash
set -e  # Exit on error

cd /opt/civildesk/civildesk-backend

# Pull latest changes
git pull origin main

# Rebuild and restart containers
docker compose down
docker compose build --no-cache
docker compose up -d

# Wait for services to be healthy
sleep 10

# Health check
if curl -f http://localhost:8080/api/health; then
    echo "✅ Deployment successful!"
    exit 0
else
    echo "❌ Health check failed!"
    exit 1
fi
```

Make it executable:
```bash
chmod +x /opt/civildesk/deploy.sh
```

---

## Testing the Pipeline

### Test CI Pipeline

1. **Make a small change** to your code
2. **Commit and push:**
   ```bash
   git add .
   git commit -m "Test CI pipeline"
   git push
   ```
3. **Check GitHub Actions:**
   - Go to your repository on GitHub
   - Click **Actions** tab
   - You should see the workflow running
   - Wait for it to complete

### Test CD Pipeline

1. **Merge to main branch** (or push directly to main)
2. **Check GitHub Actions** - CD workflow should trigger
3. **Check server logs:**
   ```bash
   ssh user@your-server-ip
   cd /opt/civildesk/civildesk-backend
   docker compose logs -f backend
   ```
4. **Verify deployment:**
   ```bash
   curl http://localhost:8080/api/health
   ```

---

## Troubleshooting

### CI Pipeline Fails

**Problem**: Build fails
- **Solution**: Check Maven dependencies, Java version compatibility

**Problem**: Tests fail
- **Solution**: Fix failing tests or temporarily skip with `-DskipTests` (not recommended)

**Problem**: Docker build fails
- **Solution**: Check Dockerfile syntax, ensure all files are present

### CD Pipeline Fails

**Problem**: SSH connection fails
- **Solution**: 
  - Verify SSH key is correct in GitHub Secrets
  - Check server firewall allows SSH
  - Test SSH connection manually

**Problem**: Permission denied on server
- **Solution**: 
  - Ensure user has Docker permissions: `sudo usermod -aG docker $USER`
  - Check directory permissions: `chmod 755 /opt/civildesk`

**Problem**: Docker compose fails
- **Solution**: 
  - Check `.env` file exists and has correct values
  - Verify Docker and Docker Compose are installed
  - Check disk space: `df -h`

**Problem**: Health check fails
- **Solution**: 
  - Check application logs: `docker compose logs backend`
  - Verify database connection
  - Check if port 8080 is accessible

### Viewing Logs

**GitHub Actions Logs:**
- Go to repository → Actions → Click on workflow run → View logs

**Server Logs:**
```bash
# Application logs
docker compose logs -f backend

# All services
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100 backend
```

---

## Best Practices

### 1. **Branch Strategy**

- **main/master**: Production-ready code (triggers CD)
- **develop**: Development branch (CI only)
- **feature/***: Feature branches (CI only)

### 2. **Environment Variables**

- Never commit `.env` files
- Use GitHub Secrets for sensitive data
- Use different secrets for different environments

### 3. **Testing**

- Always run tests in CI
- Don't skip tests unless absolutely necessary
- Add integration tests for critical paths

### 4. **Deployment**

- Deploy during low-traffic hours
- Monitor logs after deployment
- Have a rollback plan ready
- Use blue-green deployment for zero downtime (advanced)

### 5. **Security**

- Rotate SSH keys regularly
- Use least-privilege access
- Enable 2FA on GitHub
- Review GitHub Actions logs regularly

---

## Advanced Topics (Future Learning)

### 1. **Docker Image Registry**

Instead of building on server, you can:
- Build Docker image in CI
- Push to Docker Hub / GitHub Container Registry
- Pull and deploy on server

### 2. **Blue-Green Deployment**

- Run two identical environments
- Deploy to inactive environment
- Switch traffic when ready
- Zero downtime deployments

### 3. **Canary Deployments**

- Deploy to small percentage of users first
- Monitor metrics
- Gradually roll out to all users

### 4. **Automated Rollback**

- Monitor application health
- Automatically rollback if metrics degrade
- Use health check endpoints

### 5. **Multi-Environment**

- **Development**: Auto-deploy on push to `develop`
- **Staging**: Auto-deploy on push to `staging`
- **Production**: Manual approval or auto-deploy on `main`

---

## Quick Reference

### GitHub Actions Commands

```bash
# View workflow status
gh workflow list
gh run list
gh run watch

# Rerun failed workflow
gh run rerun <run-id>
```

### Server Commands

```bash
# Check deployment status
cd /opt/civildesk/civildesk-backend
docker compose ps

# View logs
docker compose logs -f backend

# Manual deployment
./deploy.sh

# Rollback (if needed)
git checkout <previous-commit>
./deploy.sh
```

---

## Summary

You now have:
✅ Understanding of CI/CD concepts  
✅ Automated build and test pipeline  
✅ Automated deployment to your server  
✅ Health checks and monitoring  
✅ Rollback capability  

**Next Steps:**
1. Set up GitHub Secrets
2. Create workflow files
3. Test the pipeline
4. Monitor and improve

---

**Questions?** Check the workflow files for detailed comments, or review GitHub Actions documentation: https://docs.github.com/en/actions

