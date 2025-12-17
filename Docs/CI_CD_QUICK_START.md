# CI/CD Quick Start Guide

This is a quick reference guide to set up CI/CD for your Spring Boot backend. For detailed explanations, see [CI_CD_GUIDE.md](./CI_CD_GUIDE.md).

## 🚀 Quick Setup (5 Steps)

### Step 1: Generate SSH Key for Deployment

On your local machine:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# View the private key (you'll add this to GitHub Secrets)
cat ~/.ssh/github_actions_deploy

# View the public key (you'll add this to your server)
cat ~/.ssh/github_actions_deploy.pub
```

### Step 2: Add Public Key to Server

```bash
# Copy public key to server
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub user@your-server-ip

# Or manually add to ~/.ssh/authorized_keys on server
```

### Step 3: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

| Secret Name | Value | Example |
|------------|-------|---------|
| `SERVER_HOST` | Your server IP or domain | `192.168.1.100` or `api.yourdomain.com` |
| `SERVER_USER` | SSH username | `ubuntu` or `root` |
| `SERVER_SSH_KEY` | Private SSH key content | Content of `~/.ssh/github_actions_deploy` |
| `SERVER_DEPLOY_PATH` | Deployment path | `/opt/civildesk` |
| `SERVER_PORT` | SSH port (optional) | `22` |

### Step 4: Prepare Server

On your server:

```bash
# Create deployment directory
sudo mkdir -p /opt/civildesk
sudo chown $USER:$USER /opt/civildesk

# Clone repository (if not already done)
cd /opt/civildesk
git clone your-repository-url civildesk-backend

# Or if already cloned, ensure it's up to date
cd /opt/civildesk/civildesk-backend
git pull origin main

# Ensure Docker permissions
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect

# Create .env file if it doesn't exist
cd /opt/civildesk
nano .env
# Add your environment variables (see DEPLOYMENT_GUIDE.md)
```

### Step 5: Test the Pipeline

1. **Make a small change** to your code
2. **Commit and push:**
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```
3. **Check GitHub Actions:**
   - Go to your repository → **Actions** tab
   - Watch the workflows run
   - CI should run on push
   - CD should run on push to `main` branch

## 📋 Verification Checklist

- [ ] SSH key generated and added to GitHub Secrets
- [ ] Public key added to server's `~/.ssh/authorized_keys`
- [ ] GitHub Secrets configured
- [ ] Server directory created (`/opt/civildesk`)
- [ ] Repository cloned on server
- [ ] `.env` file created on server
- [ ] Docker and Docker Compose installed on server
- [ ] User has Docker permissions
- [ ] Test push triggers CI/CD pipeline

## 🔍 Testing Commands

### Test SSH Connection

```bash
ssh -i ~/.ssh/github_actions_deploy user@your-server-ip
```

### Test Manual Deployment

On server:
```bash
cd /opt/civildesk/civildesk-backend
./deploy.sh
```

### Check Application Health

```bash
curl http://localhost:8080/api/health
```

### View Logs

```bash
cd /opt/civildesk/civildesk-backend
docker compose logs -f backend
```

## 🐛 Common Issues

### Issue: SSH Connection Fails

**Solution:**
- Verify SSH key is correct in GitHub Secrets
- Check server firewall: `sudo ufw status`
- Test SSH manually: `ssh -i ~/.ssh/github_actions_deploy user@server-ip`

### Issue: Permission Denied

**Solution:**
```bash
# On server
sudo usermod -aG docker $USER
# Log out and log back in
```

### Issue: Health Check Fails

**Solution:**
```bash
# Check application logs
docker compose logs backend

# Check if port is accessible
curl http://localhost:8080/api/health

# Check container status
docker compose ps
```

### Issue: Docker Build Fails

**Solution:**
- Check Dockerfile syntax
- Ensure all required files are present
- Check disk space: `df -h`
- Check Docker daemon: `sudo systemctl status docker`

## 📚 Next Steps

1. **Monitor First Deployment**: Watch the GitHub Actions logs
2. **Verify Application**: Check that your app is running correctly
3. **Set Up Notifications**: Add Slack/Discord webhooks (optional)
4. **Add More Tests**: Improve your test coverage
5. **Set Up Staging**: Create a staging environment (optional)

## 🔗 Related Files

- **Detailed Guide**: [CI_CD_GUIDE.md](./CI_CD_GUIDE.md)
- **CI Workflow**: [.github/workflows/ci.yml](./.github/workflows/ci.yml)
- **CD Workflow**: [.github/workflows/deploy.yml](./.github/workflows/deploy.yml)
- **Deployment Script**: [civildesk-backend/deploy.sh](./civildesk-backend/deploy.sh)

## 💡 Tips

1. **Start Small**: Test with a small change first
2. **Monitor Logs**: Always check logs after deployment
3. **Keep Backups**: The deployment script creates backups automatically
4. **Test Locally**: Test the deployment script manually before relying on CI/CD
5. **Use Branches**: Use feature branches for development, only deploy from `main`

---

**Need Help?** Check the detailed guide: [CI_CD_GUIDE.md](./CI_CD_GUIDE.md)

