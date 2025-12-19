# CI/CD Quick Start Guide

Quick reference for setting up and using the CI/CD pipeline.

## 🚀 Quick Setup (5 Minutes)

### 1. Server Setup (One-time)

```bash
# SSH into your server
ssh user@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directories
sudo mkdir -p /opt/civildesk/civildesk-backend /opt/civildesk/backups
sudo chown -R $USER:$USER /opt/civildesk

# Create .env file
cd /opt/civildesk/civildesk-backend
nano .env
# (Add your environment variables - see CI_CD_SETUP.md)
```

### 2. Generate SSH Key

```bash
# On your local machine
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/civildesk_deploy

# Copy public key to server
ssh-copy-id -i ~/.ssh/civildesk_deploy.pub user@your-server-ip

# Test connection
ssh -i ~/.ssh/civildesk_deploy user@your-server-ip
```

### 3. Configure GitHub Secrets

Go to: **Repository → Settings → Secrets and variables → Actions**

Add these secrets:

| Secret Name | Value | How to Get |
|------------|-------|------------|
| `SSH_PRIVATE_KEY` | Private key content | `cat ~/.ssh/civildesk_deploy` |
| `SERVER_HOST` | Server IP/domain | Your server address |
| `SERVER_USER` | SSH username | Your SSH user (e.g., `ubuntu`, `deploy`) |

### 4. Test the Pipeline

```bash
# Make a small change and push
git add .
git commit -m "Test CI/CD"
git push origin main

# Watch in GitHub → Actions tab
```

## 📋 Environment Variables Template

Create `/opt/civildesk/civildesk-backend/.env` on server:

```env
DB_NAME=civildesk
DB_USERNAME=civildesk_user
DB_PASSWORD=<generate-with-openssl-rand-base64-24>
JWT_SECRET=<generate-with-openssl-rand-base64-32>
REDIS_PASSWORD=<generate-with-openssl-rand-base64-24>
SERVER_PORT=8080
CORS_ALLOWED_ORIGINS=http://localhost:3000
REDIS_ENABLED=true
SPRING_PROFILES_ACTIVE=prod
```

## 🔍 Quick Troubleshooting

### Pipeline Fails at SSH Step
```bash
# Test SSH manually
ssh -i ~/.ssh/civildesk_deploy user@server-ip
```

### Health Check Fails
```bash
# On server
cd /opt/civildesk/civildesk-backend
docker compose logs backend
curl http://localhost:8080/api/health
```

### Container Not Starting
```bash
# Check status
docker compose ps

# View logs
docker compose logs -f

# Restart
docker compose restart
```

## 📝 Common Commands

```bash
# Server status
cd /opt/civildesk/civildesk-backend && docker compose ps

# View logs
docker compose logs -f backend

# Manual deployment
./deploy.sh

# Restart services
docker compose restart

# Stop all
docker compose down

# Start all
docker compose up -d
```

## ✅ Verification Checklist

- [ ] Docker installed on server
- [ ] Docker Compose installed on server
- [ ] Directories created: `/opt/civildesk/civildesk-backend`
- [ ] `.env` file created with correct values
- [ ] SSH key generated and added to server
- [ ] GitHub Secrets configured
- [ ] Test push triggers workflow
- [ ] Deployment succeeds
- [ ] Health check passes

## 🆘 Need Help?

1. Check full guide: `CI_CD_SETUP.md`
2. View workflow logs: GitHub → Actions
3. Check server logs: `docker compose logs`
4. Verify secrets: GitHub → Settings → Secrets

## 🎯 What Happens on Push?

1. **Build** - Compiles and tests code
2. **Docker** - Builds Docker image
3. **Deploy** - Transfers to server and deploys
4. **Health Check** - Verifies deployment
5. **Done** - Application is live! 🎉

---

**Next**: See `CI_CD_SETUP.md` for detailed documentation.

