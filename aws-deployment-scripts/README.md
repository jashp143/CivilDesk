# AWS Deployment Scripts

This directory contains helper scripts to automate the AWS deployment process for Civildesk.

## Scripts Overview

### 1. `setup-infrastructure.sh`
Automates the creation of AWS infrastructure components:
- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Route Tables
- Security Groups (ALB, ECS, EC2, RDS, Redis)

**Usage:**
```bash
chmod +x setup-infrastructure.sh
./setup-infrastructure.sh
```

**Output:**
- Creates all infrastructure components
- Saves configuration to `infrastructure-config.json`

**Prerequisites:**
- AWS CLI configured
- Appropriate IAM permissions

---

### 2. `create-secrets.sh`
Interactive script to create secrets in AWS Secrets Manager:
- Database credentials
- Redis credentials
- JWT secret
- Email credentials

**Usage:**
```bash
chmod +x create-secrets.sh
./create-secrets.sh
```

**Features:**
- Generates secure random passwords if not provided
- Updates existing secrets if they already exist
- Saves generated credentials for reference

**Prerequisites:**
- AWS CLI configured
- IAM permissions for Secrets Manager

---

### 3. `build-and-push-images.sh`
Builds Docker images and pushes them to AWS ECR:
- Backend (Spring Boot) image
- Face Recognition Service (FastAPI) image

**Usage:**
```bash
chmod +x build-and-push-images.sh
./build-and-push-images.sh
```

**Features:**
- Creates ECR repositories if they don't exist
- Authenticates Docker to ECR
- Builds images from Dockerfiles
- Tags and pushes images

**Prerequisites:**
- Docker installed and running
- AWS CLI configured
- IAM permissions for ECR
- Project structure:
  ```
  .
  ├── civildesk-backend/
  │   └── Dockerfile
  └── face-recognition-service/
      └── Dockerfile
  ```

---

## Deployment Workflow

### Step 1: Setup Infrastructure
```bash
./setup-infrastructure.sh
```

This creates the network foundation. Save the output `infrastructure-config.json` for reference.

### Step 2: Create Secrets
```bash
./create-secrets.sh
```

Follow the prompts to create all required secrets. Save the generated passwords securely.

### Step 3: Create RDS and ElastiCache
Use the AWS Console or CLI to create:
- RDS PostgreSQL instance (use password from secrets)
- ElastiCache Redis cluster (use password from secrets)

Update the secrets with actual endpoints after creation.

### Step 4: Build and Push Images
```bash
./build-and-push-images.sh
```

This may take 15-30 minutes depending on your internet connection and system.

### Step 5: Create ECS Resources
Follow the main deployment guide to create:
- ECS Cluster
- Task Definitions
- ECS Services
- Application Load Balancer

---

## Configuration

All scripts use the following default configuration:
- **Region**: `us-east-1`
- **VPC CIDR**: `10.0.0.0/16`
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24`
- **Private Subnets**: `10.0.10.0/24`, `10.0.11.0/24`

To change these, edit the variables at the top of each script.

---

## Troubleshooting

### Script Fails with Permission Denied
```bash
chmod +x *.sh
```

### AWS CLI Not Configured
```bash
aws configure
```

### Docker Not Running
```bash
# Check Docker status
docker ps

# Start Docker (Linux)
sudo systemctl start docker

# Start Docker Desktop (Mac/Windows)
# Open Docker Desktop application
```

### ECR Authentication Fails
```bash
# Manually authenticate
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Infrastructure Already Exists
The scripts check for existing resources and will:
- Skip creation if resource exists (infrastructure script)
- Update if secret exists (secrets script)
- Create repository if it doesn't exist (build script)

To start fresh, delete resources manually via AWS Console or CLI.

---

## Manual Steps Required

These scripts automate most of the setup, but you still need to:

1. **Create RDS Instance**
   - Use the database password from secrets
   - Update the secret with actual RDS endpoint

2. **Create ElastiCache Cluster**
   - Use the Redis password from secrets
   - Update the secret with actual Redis endpoint

3. **Create ECS Cluster and Services**
   - Use the task definition templates from the main guide
   - Reference the ECR images pushed by the build script

4. **Create Application Load Balancer**
   - Use the security groups created by infrastructure script
   - Configure target groups and listeners

5. **Setup SSL Certificate**
   - Request certificate in ACM
   - Validate via DNS
   - Attach to ALB listener

6. **Configure DNS**
   - Point domain to ALB
   - Use Route 53 or your DNS provider

---

## Security Notes

- **Never commit secrets** to version control
- **Use IAM roles** instead of access keys when possible
- **Rotate secrets regularly**
- **Review security groups** after setup
- **Enable CloudTrail** for audit logging

---

## Cost Considerations

Running these scripts will create AWS resources that incur costs:
- VPC: Free
- NAT Gateway: ~$32/month + data transfer
- ECR: Storage costs (minimal)
- Secrets Manager: ~$0.40/secret/month

The main costs come from:
- RDS: ~$150/month
- EC2: ~$150/month
- ECS Fargate: ~$60/month
- ElastiCache: ~$50/month
- ALB: ~$20/month

**Total estimated**: ~$455/month

See the main deployment guide for detailed cost breakdown.

---

## Next Steps

After running these scripts:

1. Review the main deployment guide: `../AWS_DEPLOYMENT_GUIDE.md`
2. Follow Phase 2-10 for complete deployment
3. Use the quick reference: `../AWS_DEPLOYMENT_QUICK_REFERENCE.md`
4. Review architecture diagrams: `../AWS_ARCHITECTURE_DIAGRAM.md`

---

## Support

For issues or questions:
1. Check the main deployment guide
2. Review AWS documentation
3. Check CloudWatch logs
4. Verify IAM permissions

---

**Last Updated**: December 2024

