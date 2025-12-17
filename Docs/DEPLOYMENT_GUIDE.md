# Civildesk Deployment Guide (Docker)

This guide provides detailed step-by-step instructions for deploying the Civildesk application using Docker across multiple servers.

## Architecture Overview

- **Backend Server (Personal Ubuntu Server)**: Spring Boot application with PostgreSQL, Redis, and Nginx (all containerized with Docker)
- **Face Recognition Service (AWS)**: Python FastAPI service with GPU support deployed using Docker
- **Mobile Apps**: Flutter applications (Android) - deployed separately

---

## Part 1: Backend Deployment on Personal Ubuntu Server (Docker)

### Prerequisites

- Ubuntu Server 20.04 LTS or later
- Root or sudo access
- Minimum 4GB RAM, 2 CPU cores
- Static IP address or domain name
- Ports 80, 443, 8080, 5432, 6379 open in firewall

### Step 1: Initial Server Setup

#### 1.1 Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
```

#### 1.2 Install Essential Tools

```bash
sudo apt install -y curl wget git vim ufw software-properties-common
```

#### 1.3 Configure Firewall

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8080/tcp  # Spring Boot (internal)
sudo ufw enable
```

---

### Step 2: Install Docker and Docker Compose

#### 2.1 Install Docker

```bash
# Remove old versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (to run docker without sudo)
sudo usermod -aG docker $USER
newgrp docker
```

#### 2.2 Verify Docker Installation

```bash
docker --version
docker compose version
```

#### 2.3 Start and Enable Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

---

### Step 3: Install and Configure Nginx

#### 3.1 Install Nginx

```bash
sudo apt install -y nginx
```

#### 3.2 Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/civildesk
```

Add the following configuration:

```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL Certificate paths (use Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Client body size (for file uploads)
    client_max_body_size 10M;
    
    # Proxy to Spring Boot (Docker container)
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # API endpoints
    location /api {
        proxy_pass http://localhost:8080/api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 3.3 Enable Site and Test Configuration

```bash
sudo ln -s /etc/nginx/sites-available/civildesk /etc/nginx/sites-enabled/
sudo nginx -t
```

#### 3.4 Install SSL Certificate with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain certificate (replace with your domain)
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Auto-renewal is set up automatically
```

#### 3.5 Start Nginx

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

### Step 4: Deploy Backend with Docker Compose

#### 4.1 Create Application Directory

```bash
sudo mkdir -p /opt/civildesk
sudo chown $USER:$USER /opt/civildesk
cd /opt/civildesk
```

#### 4.2 Upload Application Files

Transfer your backend files to the server:

```bash
# From your local machine (use SCP, SFTP, or Git)
scp -r civildesk-backend user@your-server:/opt/civildesk/
```

Or clone from Git repository:
```bash
git clone your-repository-url /opt/civildesk/civildesk-backend
```

#### 4.3 Create Environment File

```bash
cd /opt/civildesk
nano .env
```

Add the following (replace with your actual values):

```env
# Database Configuration
DB_NAME=civildesk
DB_USERNAME=civildesk_user
DB_PASSWORD=your_secure_password_here

# JWT Configuration
JWT_SECRET=your_very_long_secret_key_at_least_256_bits_long_use_openssl_rand_hex_32
JWT_EXPIRATION=86400000

# Server Configuration
SERVER_PORT=8080

# CORS Configuration (add your Flutter app URLs)
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com

# Face Recognition Service (AWS URL - will configure later)
FACE_SERVICE_URL=https://your-aws-face-service-url.com

# Email Configuration
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=noreply@civildesk.com
EMAIL_ENABLED=true

# Redis Configuration
REDIS_ENABLED=true
REDIS_PASSWORD=your_redis_password_here

# Spring Profile
SPRING_PROFILES_ACTIVE=prod
```

**Generate secure passwords:**
```bash
# Generate JWT secret
openssl rand -hex 32

# Generate database password
openssl rand -base64 24

# Generate Redis password
openssl rand -base64 24
```

#### 4.4 Review Docker Compose Configuration

The `docker-compose.yml` file should be in `/opt/civildesk/civildesk-backend/`. Verify it's configured correctly:

```bash
cd /opt/civildesk/civildesk-backend
cat docker-compose.yml
```

#### 4.5 Build and Start Services

```bash
cd /opt/civildesk/civildesk-backend

# Build and start all services
docker compose up -d --build

# View logs
docker compose logs -f

# Check service status
docker compose ps
```

#### 4.6 Run Database Migrations

If you have SQL migration files, run them:

```bash
# Copy migration files to the postgres container
docker cp database/setup.sql civildesk-postgres:/tmp/setup.sql

# Execute migrations
docker exec -i civildesk-postgres psql -U civildesk_user -d civildesk < database/setup.sql

# Or if migrations are in docker-entrypoint-initdb.d, they run automatically on first start
```

#### 4.7 Verify Services

```bash
# Check all containers are running
docker compose ps

# Check backend logs
docker compose logs backend

# Check database connection
docker exec -it civildesk-postgres psql -U civildesk_user -d civildesk -c "SELECT version();"

# Check Redis connection
docker exec -it civildesk-redis redis-cli -a your_redis_password_here PING

# Test backend health endpoint
curl http://localhost:8080/api/health
```

#### 4.8 Set Up Auto-restart on Reboot

Docker Compose services automatically restart if the Docker daemon restarts. To ensure Docker starts on boot:

```bash
sudo systemctl enable docker
```

---

### Step 5: Docker Compose Management Commands

#### Useful Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose stop

# Stop and remove containers
docker compose down

# View logs
docker compose logs -f [service_name]

# Restart a specific service
docker compose restart backend

# Rebuild and restart
docker compose up -d --build

# View resource usage
docker stats

# Execute commands in containers
docker exec -it civildesk-backend sh
docker exec -it civildesk-postgres psql -U civildesk_user -d civildesk
```

---

## Part 2: Face Recognition Service Deployment on AWS (Docker)

### Prerequisites

- AWS Account
- AWS CLI installed and configured (optional)
- Domain name (optional, for custom domain)
- Basic knowledge of EC2 and Docker

### Option A: Deploy on AWS EC2 with GPU using Docker (Recommended)

#### Step 1: Launch EC2 Instance with GPU

##### 1.1 Choose Instance Type

- **Recommended**: `g4dn.xlarge` or `g4dn.2xlarge` (NVIDIA T4 GPU)
- **Budget Option**: `g4dn.xlarge` (1 GPU, 4 vCPU, 16 GB RAM)
- **Performance Option**: `g4dn.2xlarge` (1 GPU, 8 vCPU, 32 GB RAM)

##### 1.2 Launch Instance

1. Go to AWS Console → EC2 → Launch Instance
2. Name: `civildesk-face-recognition`
3. AMI: **Deep Learning AMI (Ubuntu)** or **Ubuntu 22.04 LTS**
   - Search for: "Deep Learning AMI GPU" or "Ubuntu Server 22.04 LTS"
4. Instance Type: `g4dn.xlarge` or `g4dn.2xlarge`
5. Key Pair: Create or select existing
6. Network Settings:
   - Allow HTTP (port 80)
   - Allow HTTPS (port 443)
   - Allow Custom TCP (port 8000) - from your backend server IP only
7. Storage: 30 GB minimum (GP3 SSD)
8. Launch Instance

##### 1.3 Configure Security Group

Edit Security Group inbound rules:
- SSH (22): Your IP only
- HTTP (80): 0.0.0.0/0 (for Let's Encrypt)
- HTTPS (443): 0.0.0.0/0
- Custom TCP (8000): Your backend server IP only

#### Step 2: Connect to EC2 Instance

```bash
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

#### Step 3: Install Docker and NVIDIA Container Toolkit

##### 3.1 Update System

```bash
sudo apt update
sudo apt upgrade -y
```

##### 3.2 Install Docker

```bash
# Remove old versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

##### 3.3 Install NVIDIA Container Toolkit (for GPU support)

```bash
# Configure the production repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-container-toolkit
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPU access in Docker
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

##### 3.4 Verify GPU

```bash
nvidia-smi
# Should show GPU information
```

#### Step 4: Deploy Face Recognition Service

##### 4.1 Create Application Directory

```bash
mkdir -p /opt/face-recognition-service
cd /opt/face-recognition-service
```

##### 4.2 Upload Application Files

Transfer files from your local machine:

```bash
# From local machine
scp -r face-recognition-service/* ubuntu@your-ec2-ip:/opt/face-recognition-service/
```

Or clone from Git:
```bash
git clone your-repository-url /opt/face-recognition-service
```

##### 4.3 Create Environment File

```bash
cd /opt/face-recognition-service
nano .env
```

Add the following:

```env
# Service Configuration
SERVICE_PORT=8000
SERVICE_HOST=0.0.0.0

# Database Configuration (point to your backend server's PostgreSQL)
DB_HOST=your-backend-server-ip
DB_PORT=5432
DB_NAME=civildesk
DB_USER=civildesk_user
DB_PASSWORD=your_secure_password_here

# Face Recognition Settings
FACE_DETECTION_THRESHOLD=0.65
FACE_MATCHING_THRESHOLD=0.6
VIDEO_CAPTURE_DURATION=15
MAX_FACES_PER_FRAME=1
MIN_FACE_SAMPLES=10

# Live Video Stream Settings
STREAM_CACHE_DURATION=2.0
FAST_MODE_DETECTION_SIZE=416
ENABLE_FACE_TRACKING=True

# Storage Paths
EMBEDDINGS_PATH=./data/embeddings.pkl
TEMP_VIDEO_PATH=./data/temp_videos
LOGS_PATH=./logs

# CUDA/GPU Settings
USE_GPU=True
GPU_DEVICE_ID=0

# Redis Configuration (if using Redis on backend server)
REDIS_HOST=your-backend-server-ip
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here
REDIS_DB=0
REDIS_ENABLED=True
```

**Important**: Configure PostgreSQL on backend server to allow connections from AWS EC2 IP.

On backend server:
```bash
# Connect to postgres container
docker exec -it civildesk-postgres psql -U civildesk_user -d civildesk

# In PostgreSQL prompt, run:
CREATE USER civildesk_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE civildesk TO civildesk_user;
\q
```

Edit PostgreSQL configuration to allow remote connections:
```bash
# Edit pg_hba.conf in the container
docker exec -it civildesk-postgres bash
# Inside container:
echo "host    civildesk    civildesk_user    your-aws-ec2-ip/32    md5" >> /var/lib/postgresql/data/pg_hba.conf
exit

# Restart postgres container
docker compose restart postgres
```

##### 4.4 Build and Run Docker Container

```bash
cd /opt/face-recognition-service

# Build the Docker image
docker build -t civildesk-face-recognition:latest .

# Run the container with GPU support
docker run -d \
  --name face-recognition-service \
  --gpus all \
  -p 8000:8000 \
  --env-file .env \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  civildesk-face-recognition:latest

# Or use docker-compose (recommended)
docker compose up -d --build
```

##### 4.5 Verify Deployment

```bash
# Check container status
docker ps

# Check logs
docker logs face-recognition-service -f

# Test health endpoint
curl http://localhost:8000/health

# Verify GPU is being used
docker exec face-recognition-service python3 -c "import onnxruntime; print(onnxruntime.get_available_providers())"
# Should show: ['CUDAExecutionProvider', 'CPUExecutionProvider']
```

#### Step 5: Install and Configure Nginx (Optional but Recommended)

##### 5.1 Install Nginx

```bash
sudo apt install -y nginx
```

##### 5.2 Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/face-recognition
```

Add:

```nginx
server {
    listen 80;
    server_name your-face-service-domain.com;
    
    client_max_body_size 50M;  # For video uploads
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts for long-running requests
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

##### 5.3 Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/face-recognition /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

##### 5.4 Install SSL Certificate

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-face-service-domain.com
```

---

### Option B: Deploy on AWS ECS with GPU (Alternative)

If you prefer managed container orchestration:

#### Step 1: Build and Push Docker Image to ECR

```bash
# Create ECR repository
aws ecr create-repository --repository-name civildesk-face-recognition --region your-region

# Get login token
aws ecr get-login-password --region your-region | docker login --username AWS --password-stdin your-account.dkr.ecr.your-region.amazonaws.com

# Build image
docker build -t civildesk-face-recognition .

# Tag image
docker tag civildesk-face-recognition:latest your-account.dkr.ecr.your-region.amazonaws.com/civildesk-face-recognition:latest

# Push image
docker push your-account.dkr.ecr.your-region.amazonaws.com/civildesk-face-recognition:latest
```

#### Step 2: Create ECS Task Definition

Create task definition with:
- GPU support enabled (requires EC2 launch type, not Fargate)
- Environment variables from Secrets Manager or Parameter Store
- Network configuration
- Resource limits

#### Step 3: Create ECS Service

- Use EC2 launch type with GPU-enabled instances
- Configure Application Load Balancer
- Set up auto-scaling

---

## Part 3: Configuration and Testing

### Step 1: Update Backend Configuration

On your backend server, update `.env`:

```env
FACE_SERVICE_URL=https://your-aws-face-service-url.com
```

Restart backend:
```bash
cd /opt/civildesk/civildesk-backend
docker compose restart backend
```

### Step 2: Test Integration

#### 2.1 Test Face Service Health

```bash
curl https://your-aws-face-service-url.com/health
```

#### 2.2 Test from Backend

The backend should be able to reach the face service. Test an endpoint that uses face recognition.

### Step 3: Configure Flutter Apps

Update API endpoints in Flutter apps:

- Backend URL: `https://your-domain.com`
- Face Service URL: `https://your-aws-face-service-url.com`

---

## Part 4: Monitoring and Maintenance

### Step 1: Set Up Logging

#### Backend Logs

```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f postgres
docker compose logs -f redis

# View last 100 lines
docker compose logs --tail=100 backend
```

#### Face Service Logs

```bash
# View logs
docker logs face-recognition-service -f

# View last 100 lines
docker logs --tail=100 face-recognition-service

# Application logs (inside container)
docker exec face-recognition-service tail -f /app/logs/face_service.log
```

### Step 2: Set Up Monitoring

#### 2.1 Docker Stats

```bash
# Monitor resource usage
docker stats

# Monitor specific container
docker stats face-recognition-service
```

#### 2.2 Set Up CloudWatch (AWS)

- Configure CloudWatch agent on EC2
- Set up alarms for CPU, memory, GPU utilization
- Monitor application logs

### Step 3: Backup Strategy

#### 3.1 Database Backups

Create backup script on backend server:

```bash
sudo nano /opt/civildesk/backup-db.sh
```

Add:

```bash
#!/bin/bash
BACKUP_DIR="/opt/civildesk/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup database using docker exec
docker exec civildesk-postgres pg_dump -U civildesk_user -d civildesk > $BACKUP_DIR/civildesk_$DATE.sql

# Compress
gzip $BACKUP_DIR/civildesk_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
```

Make executable:
```bash
chmod +x /opt/civildesk/backup-db.sh
```

Add to crontab:
```bash
crontab -e
# Add: 0 2 * * * /opt/civildesk/backup-db.sh
```

#### 3.2 Docker Volume Backups

```bash
# Backup postgres volume
docker run --rm -v civildesk-backend_postgres_data:/data -v $(pwd)/backups:/backup ubuntu tar czf /backup/postgres_$(date +%Y%m%d_%H%M%S).tar.gz /data

# Backup redis volume
docker run --rm -v civildesk-backend_redis_data:/data -v $(pwd)/backups:/backup ubuntu tar czf /backup/redis_$(date +%Y%m%d_%H%M%S).tar.gz /data
```

#### 3.3 Face Embeddings Backup

On AWS EC2, backup embeddings:

```bash
# Create backup script
nano /opt/face-recognition-service/backup-embeddings.sh
```

Add:

```bash
#!/bin/bash
BACKUP_DIR="/opt/face-recognition-service/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Copy embeddings from container
docker cp face-recognition-service:/app/data/embeddings.pkl $BACKUP_DIR/embeddings_$DATE.pkl

# Upload to S3 (optional)
# aws s3 cp $BACKUP_DIR/embeddings_$DATE.pkl s3://your-bucket/backups/
```

### Step 4: Security Hardening

#### 4.1 Update System

```bash
# Regular updates
sudo apt update && sudo apt upgrade -y

# Configure automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 4.2 Configure Fail2Ban

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

#### 4.3 Docker Security

```bash
# Keep Docker updated
sudo apt update && sudo apt upgrade docker-ce

# Use non-root user in containers (already configured)
# Limit container resources
# Use secrets for sensitive data
```

---

## Part 5: Troubleshooting

### Common Issues

#### Backend Container Won't Start

1. Check logs: `docker compose logs backend`
2. Verify environment variables: `docker compose config`
3. Check database connection: `docker compose logs postgres`
4. Verify port availability: `sudo netstat -tulpn | grep 8080`

#### Face Service GPU Not Detected

1. Verify GPU: `nvidia-smi`
2. Check NVIDIA Container Toolkit: `docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi`
3. Verify in container: `docker exec face-recognition-service python3 -c "import onnxruntime; print(onnxruntime.get_available_providers())"`
4. Check logs: `docker logs face-recognition-service`

#### Database Connection Issues

1. Verify PostgreSQL container is running: `docker compose ps postgres`
2. Check connection from remote: `docker exec -it civildesk-postgres psql -U civildesk_user -d civildesk`
3. Verify firewall rules
4. Check `pg_hba.conf` configuration in container

#### Nginx 502 Bad Gateway

1. Check backend container is running: `docker compose ps backend`
2. Verify backend is listening: `curl http://localhost:8080/api/health`
3. Check Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
4. Verify proxy_pass URL matches container port

#### Docker Compose Services Not Starting

1. Check Docker daemon: `sudo systemctl status docker`
2. Check disk space: `df -h`
3. Check Docker logs: `sudo journalctl -u docker.service`
4. Verify docker-compose.yml syntax: `docker compose config`

---

## Part 6: Performance Optimization

### Backend Server

1. **Database Optimization**
   - Enable connection pooling (already configured)
   - Add indexes for frequently queried columns
   - Regular VACUUM and ANALYZE

2. **Redis Caching**
   - Monitor Redis memory usage: `docker stats civildesk-redis`
   - Configure eviction policies
   - Set appropriate TTL values

3. **Docker Resource Limits**

   Add to `docker-compose.yml`:

   ```yaml
   services:
     backend:
       deploy:
         resources:
           limits:
             cpus: '2'
             memory: 2G
           reservations:
             cpus: '1'
             memory: 1G
   ```

### Face Recognition Service

1. **GPU Optimization**
   - Monitor GPU utilization: `nvidia-smi -l 1`
   - Adjust batch sizes if needed
   - Use TensorRT for faster inference (advanced)

2. **Container Resource Limits**

   ```yaml
   services:
     face-recognition:
       deploy:
         resources:
           limits:
             cpus: '4'
             memory: 8G
           reservations:
             devices:
               - driver: nvidia
                 count: 1
                 capabilities: [gpu]
   ```

---

## Part 7: Scaling Considerations

### Horizontal Scaling

- **Backend**: Use load balancer with multiple Docker containers
- **Face Service**: Deploy multiple containers behind load balancer
- **Database**: Consider read replicas for read-heavy workloads

### Vertical Scaling

- Increase instance sizes based on monitoring metrics
- Add more RAM for database
- Upgrade GPU instances for face recognition

### Docker Swarm or Kubernetes

For production at scale, consider:
- Docker Swarm (simpler)
- Kubernetes (more features, more complex)

---

## Summary Checklist

### Backend Server (Ubuntu)
- [ ] Docker and Docker Compose installed
- [ ] Nginx installed and configured with SSL
- [ ] Application files uploaded
- [ ] Environment variables configured
- [ ] Docker Compose services running
- [ ] Database migrations executed
- [ ] Firewall configured
- [ ] Backups configured

### Face Recognition Service (AWS)
- [ ] EC2 instance with GPU launched
- [ ] Docker and NVIDIA Container Toolkit installed
- [ ] Application files uploaded
- [ ] Environment variables configured
- [ ] Docker container running with GPU support
- [ ] Nginx configured (optional)
- [ ] Security groups configured
- [ ] Database connection from AWS to backend configured

### Integration
- [ ] Backend can reach face service
- [ ] Face service can reach database
- [ ] Flutter apps configured with correct URLs
- [ ] SSL certificates installed
- [ ] Monitoring set up
- [ ] Backups configured

---

## Docker Quick Reference

### Backend Server

```bash
# Start all services
cd /opt/civildesk/civildesk-backend
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Restart a service
docker compose restart backend

# Rebuild and restart
docker compose up -d --build

# Execute command in container
docker exec -it civildesk-backend sh
docker exec -it civildesk-postgres psql -U civildesk_user -d civildesk
```

### Face Recognition Service

```bash
# Build image
docker build -t civildesk-face-recognition .

# Run container
docker run -d --name face-recognition-service --gpus all -p 8000:8000 --env-file .env civildesk-face-recognition

# View logs
docker logs -f face-recognition-service

# Stop container
docker stop face-recognition-service

# Remove container
docker rm face-recognition-service

# Restart container
docker restart face-recognition-service
```

---

## Support and Resources

- **Backend Documentation**: See `civildesk-backend/README.md`
- **Face Service Documentation**: See `face-recognition-service/README.md`
- **Database Setup**: See `civildesk-backend/database/README.md`
- **Docker Documentation**: https://docs.docker.com/

---

## Notes

1. Replace all placeholder values (passwords, domains, IPs) with your actual values
2. Keep `.env` files secure and never commit them to version control
3. Regularly update Docker images and system packages
4. Monitor resource usage and adjust instance sizes accordingly
5. Test all endpoints after deployment
6. Keep backups of database and embeddings regularly
7. Use Docker secrets or environment files for sensitive data
8. Consider using Docker Compose for easier management

---

**Last Updated**: 2024
**Version**: 2.0 (Docker Edition)
