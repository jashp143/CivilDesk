# Civildesk AWS Deployment Guide

**Version:** 1.0  
**Last Updated:** December 2024  
**Target:** Production-ready AWS deployment

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [AWS Services Overview](#aws-services-overview)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Configuration Files](#configuration-files)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Security Best Practices](#security-best-practices)
8. [Scaling and Optimization](#scaling-and-optimization)
9. [Cost Optimization](#cost-optimization)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Internet / Users                               │
└──────────────────────────────┬──────────────────────────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   CloudFront CDN      │
                    │  (Static Assets)     │
                    └───────────┬───────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │  Application Load     │
                    │  Balancer (ALB)       │
                    │  - SSL Termination   │
                    │  - Health Checks      │
                    └───────────┬───────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
    ┌──────────────────┐ ┌──────────────┐ ┌──────────────┐
    │  EC2 Backend     │ │  EC2 Backend  │ │  EC2 GPU     │
    │  Service         │ │  (Standby)    │ │  Face Service│
    │  (Spring Boot)   │ │  (Spring Boot)│ │  (FastAPI)   │
    └──────────┬───────┘ └──────────────┘ └──────┬───────┘
               │                                  │
               │                                  │
    ┌──────────┼──────────┐          ┌──────────┼──────────┐
    │          │          │          │          │          │
    ▼          ▼          ▼          ▼          ▼          ▼
┌─────────┐ ┌──────┐ ┌────────┐ ┌─────────┐ ┌──────┐ ┌────────┐
│   RDS   │ │Redis │ │   S3   │ │   RDS   │ │Redis │ │   S3   │
│PostgreSQL│ │Elasti│ │ Bucket │ │PostgreSQL│ │Elasti│ │ Bucket │
│         │ │Cache │ │(Files) │ │         │ │Cache │ │(Videos)│
└─────────┘ └──────┘ └────────┘ └─────────┘ └──────┘ └────────┘
```

### Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS VPC                                 │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Public Subnets (ALB, NAT Gateway)           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           Private Subnets (EC2 Instances, RDS, Redis)    │  │
│  │                                                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ EC2 Backend  │  │  RDS         │  │  ElastiCache │   │  │
│  │  │ (t3.medium)  │──│  PostgreSQL  │  │  Redis       │   │  │
│  │  │ Spring Boot  │  │  (Multi-AZ)  │  │  (Cluster)   │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ EC2 GPU      │──│  RDS         │──│  ElastiCache │   │  │
│  │  │ Face Service │  │  PostgreSQL  │  │  Redis       │   │  │
│  │  │ (g4dn.xlarge)│  │  (Shared)     │  │  (Shared)     │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         S3 Buckets (Cross-Region Replication)             │  │
│  │  - civildesk-uploads (documents, images)                 │  │
│  │  - civildesk-videos (face recognition videos)             │  │
│  │  - civildesk-backups (automated backups)                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Request Flow:**
   - User → CloudFront → ALB → EC2 Backend → RDS/Redis
   - User → ALB → EC2 Face Service → RDS/Redis/S3

2. **Face Recognition Flow:**
   - Mobile App → ALB → EC2 Face Service → Process Video → Store Embeddings → Return Result

3. **File Upload Flow:**
   - Mobile App → ALB → EC2 Backend → S3 Bucket → Return URL

---

## Prerequisites

### AWS Account Requirements

- Active AWS Account with appropriate permissions
- AWS CLI v2 installed and configured
- Docker installed locally (for building images)
- Domain name (optional but recommended)
- Basic knowledge of AWS services

### Required AWS Permissions

Your IAM user/role needs permissions for:
- EC2 (Launch instances, Security Groups, VPC, Auto Scaling Groups)
- RDS (Create databases, manage instances)
- ElastiCache (Create clusters)
- S3 (Create buckets, manage objects)
- IAM (Create roles and policies)
- CloudWatch (Logs, Metrics, Alarms)
- Application Load Balancer (Create, configure)
- Secrets Manager (Store and retrieve secrets)
- Route 53 (DNS management, if using custom domain)
- ACM (SSL certificates)
- Systems Manager (Session Manager, Parameter Store)

### Estimated Monthly Costs

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| EC2 Backend | t3.medium (2 instances) | ~$60 |
| EC2 GPU | g4dn.xlarge (on-demand) | ~$150 |
| RDS PostgreSQL | db.t3.medium, Multi-AZ | ~$150 |
| ElastiCache Redis | cache.t3.medium | ~$50 |
| ALB | Standard | ~$20 |
| S3 | 100GB storage, 1M requests | ~$5 |
| CloudWatch | Logs and metrics | ~$10 |
| Data Transfer | 100GB | ~$10 |
| **Total** | | **~$455/month** |

*Note: Costs vary by region and usage. Use AWS Calculator for accurate estimates.*

---

## AWS Services Overview

### Core Services

1. **Amazon EC2 (Backend Instances)**
   - Spring Boot backend service
   - Instance type: t3.medium or t3.large
   - Auto-scaling with Auto Scaling Groups
   - Docker container deployment

2. **Amazon EC2 (GPU Instances)**
   - Face recognition service with GPU support
   - Instance type: g4dn.xlarge or g4dn.2xlarge

3. **Amazon RDS (PostgreSQL)**
   - Managed PostgreSQL database
   - Multi-AZ for high availability
   - Automated backups

4. **Amazon ElastiCache (Redis)**
   - Managed Redis cluster
   - Caching and session storage

5. **Application Load Balancer (ALB)**
   - Distributes traffic to services
   - SSL termination
   - Health checks

6. **Amazon S3**
   - File storage (documents, images, videos)
   - Versioning and lifecycle policies

7. **AWS Secrets Manager**
   - Secure storage of credentials
   - Automatic rotation (optional)

8. **Amazon CloudWatch**
   - Logging and monitoring
   - Alarms and metrics

9. **Amazon Route 53**
   - DNS management
   - Health checks

10. **AWS Certificate Manager (ACM)**
    - Free SSL certificates
    - Automatic renewal

---

## Step-by-Step Deployment

### Phase 1: AWS Infrastructure Setup

#### Step 1.1: Create VPC and Networking

1. **Create VPC:**
   ```bash
   aws ec2 create-vpc \
     --cidr-block 10.0.0.0/16 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=civildesk-vpc}]'
   ```
   Note the VPC ID from output.

2. **Create Internet Gateway:**
   ```bash
   aws ec2 create-internet-gateway \
     --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=civildesk-igw}]'
   ```
   Attach to VPC:
   ```bash
   aws ec2 attach-internet-gateway \
     --internet-gateway-id <igw-id> \
     --vpc-id <vpc-id>
   ```

3. **Create Public Subnets (for ALB):**
   ```bash
   # Subnet 1 (us-east-1a)
   aws ec2 create-subnet \
     --vpc-id <vpc-id> \
     --cidr-block 10.0.1.0/24 \
     --availability-zone us-east-1a \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-public-1a}]'
   
   # Subnet 2 (us-east-1b)
   aws ec2 create-subnet \
     --vpc-id <vpc-id> \
     --cidr-block 10.0.2.0/24 \
     --availability-zone us-east-1b \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-public-1b}]'
   ```

4. **Create Private Subnets (for EC2, RDS, Redis):**
   ```bash
   # Private Subnet 1
   aws ec2 create-subnet \
     --vpc-id <vpc-id> \
     --cidr-block 10.0.10.0/24 \
     --availability-zone us-east-1a \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-private-1a}]'
   
   # Private Subnet 2
   aws ec2 create-subnet \
     --vpc-id <vpc-id> \
     --cidr-block 10.0.11.0/24 \
     --availability-zone us-east-1b \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-private-1b}]'
   ```

5. **Create NAT Gateway (for private subnet internet access):**
   ```bash
   # Allocate Elastic IP
   aws ec2 allocate-address --domain vpc
   # Note the AllocationId
   
   # Create NAT Gateway in public subnet
   aws ec2 create-nat-gateway \
     --subnet-id <public-subnet-1-id> \
     --allocation-id <allocation-id> \
     --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=civildesk-nat}]'
   ```

6. **Create Route Tables:**
   ```bash
   # Public Route Table
   aws ec2 create-route-table \
     --vpc-id <vpc-id> \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=civildesk-public-rt}]'
   
   # Add route to Internet Gateway
   aws ec2 create-route \
     --route-table-id <public-rt-id> \
     --destination-cidr-block 0.0.0.0/0 \
     --gateway-id <igw-id>
   
   # Associate public subnets
   aws ec2 associate-route-table \
     --subnet-id <public-subnet-1-id> \
     --route-table-id <public-rt-id>
   
   # Private Route Table
   aws ec2 create-route-table \
     --vpc-id <vpc-id> \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=civildesk-private-rt}]'
   
   # Add route to NAT Gateway
   aws ec2 create-route \
     --route-table-id <private-rt-id> \
     --destination-cidr-block 0.0.0.0/0 \
     --nat-gateway-id <nat-gateway-id>
   
   # Associate private subnets
   aws ec2 associate-route-table \
     --subnet-id <private-subnet-1-id> \
     --route-table-id <private-rt-id>
   ```

#### Step 1.2: Create Security Groups

```bash
# ALB Security Group
aws ec2 create-security-group \
  --group-name civildesk-alb-sg \
  --description "Security group for Application Load Balancer" \
  --vpc-id <vpc-id>

# Allow HTTP and HTTPS from internet
aws ec2 authorize-security-group-ingress \
  --group-id <alb-sg-id> \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id <alb-sg-id> \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# EC2 Backend Security Group
aws ec2 create-security-group \
  --group-name civildesk-ec2-backend-sg \
  --description "Security group for EC2 backend instances" \
  --vpc-id <vpc-id>

# Allow traffic from ALB only
aws ec2 authorize-security-group-ingress \
  --group-id <ec2-backend-sg-id> \
  --protocol tcp \
  --port 8080 \
  --source-group <alb-sg-id>

# Allow SSH from your IP (for management)
aws ec2 authorize-security-group-ingress \
  --group-id <ec2-backend-sg-id> \
  --protocol tcp \
  --port 22 \
  --cidr <your-ip>/32

# EC2 Face Service Security Group
aws ec2 create-security-group \
  --group-name civildesk-face-service-sg \
  --description "Security group for face recognition service" \
  --vpc-id <vpc-id>

# Allow traffic from ALB
aws ec2 authorize-security-group-ingress \
  --group-id <face-service-sg-id> \
  --protocol tcp \
  --port 8000 \
  --source-group <alb-sg-id>

# Allow SSH from your IP (for management)
aws ec2 authorize-security-group-ingress \
  --group-id <face-service-sg-id> \
  --protocol tcp \
  --port 22 \
  --cidr <your-ip>/32

# RDS Security Group
aws ec2 create-security-group \
  --group-name civildesk-rds-sg \
  --description "Security group for RDS PostgreSQL" \
  --vpc-id <vpc-id>

# Allow PostgreSQL from EC2 Backend and EC2 Face Service
aws ec2 authorize-security-group-ingress \
  --group-id <rds-sg-id> \
  --protocol tcp \
  --port 5432 \
  --source-group <ec2-backend-sg-id>

aws ec2 authorize-security-group-ingress \
  --group-id <rds-sg-id> \
  --protocol tcp \
  --port 5432 \
  --source-group <face-service-sg-id>

# Redis Security Group
aws ec2 create-security-group \
  --group-name civildesk-redis-sg \
  --description "Security group for ElastiCache Redis" \
  --vpc-id <vpc-id>

# Allow Redis from EC2 Backend and EC2 Face Service
aws ec2 authorize-security-group-ingress \
  --group-id <redis-sg-id> \
  --protocol tcp \
  --port 6379 \
  --source-group <ec2-backend-sg-id>

aws ec2 authorize-security-group-ingress \
  --group-id <redis-sg-id> \
  --protocol tcp \
  --port 6379 \
  --source-group <face-service-sg-id>
```

#### Step 1.3: Create S3 Buckets

```bash
# Create buckets
aws s3 mb s3://civildesk-uploads-<your-account-id> --region us-east-1
aws s3 mb s3://civildesk-videos-<your-account-id> --region us-east-1
aws s3 mb s3://civildesk-backups-<your-account-id> --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket civildesk-uploads-<your-account-id> \
  --versioning-configuration Status=Enabled

# Set lifecycle policies (optional - move old files to Glacier)
aws s3api put-bucket-lifecycle-configuration \
  --bucket civildesk-uploads-<your-account-id> \
  --lifecycle-configuration file://lifecycle-policy.json
```

Create `lifecycle-policy.json`:
```json
{
  "Rules": [
    {
      "Id": "MoveOldFilesToGlacier",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

#### Step 1.4: Store Secrets in AWS Secrets Manager

```bash
# Database credentials
aws secretsmanager create-secret \
  --name civildesk/db-credentials \
  --secret-string '{
    "username": "civildesk_admin",
    "password": "YOUR_SECURE_PASSWORD_HERE",
    "engine": "postgres",
    "host": "civildesk-db.xxxxx.us-east-1.rds.amazonaws.com",
    "port": 5432,
    "dbname": "civildesk"
  }'

# Redis credentials
aws secretsmanager create-secret \
  --name civildesk/redis-credentials \
  --secret-string '{
    "password": "YOUR_REDIS_PASSWORD_HERE"
  }'

# JWT Secret
aws secretsmanager create-secret \
  --name civildesk/jwt-secret \
  --secret-string 'YOUR_JWT_SECRET_KEY_HERE'

# Email credentials
aws secretsmanager create-secret \
  --name civildesk/email-credentials \
  --secret-string '{
    "host": "smtp.gmail.com",
    "port": "587",
    "username": "your-email@gmail.com",
    "password": "your-app-password"
  }'
```

**Generate secure passwords:**
```bash
# Generate JWT secret (256 bits)
openssl rand -hex 32

# Generate database password
openssl rand -base64 24

# Generate Redis password
openssl rand -base64 24
```

### Phase 2: Database Setup (RDS PostgreSQL)

#### Step 2.1: Create DB Subnet Group

```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name civildesk-db-subnet-group \
  --db-subnet-group-description "Subnet group for Civildesk RDS" \
  --subnet-ids <private-subnet-1-id> <private-subnet-2-id> \
  --tags Key=Name,Value=civildesk-db-subnet-group
```

#### Step 2.2: Create RDS PostgreSQL Instance

```bash
aws rds create-db-instance \
  --db-instance-identifier civildesk-db \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --engine-version 15.4 \
  --master-username civildesk_admin \
  --master-user-password YOUR_SECURE_PASSWORD \
  --allocated-storage 100 \
  --storage-type gp3 \
  --storage-encrypted \
  --vpc-security-group-ids <rds-sg-id> \
  --db-subnet-group-name civildesk-db-subnet-group \
  --backup-retention-period 7 \
  --multi-az \
  --publicly-accessible \
  --no-publicly-accessible \
  --tags Key=Name,Value=civildesk-db
```

**Note:** Wait 10-15 minutes for RDS to be available. Get endpoint:
```bash
aws rds describe-db-instances \
  --db-instance-identifier civildesk-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

#### Step 2.3: Initialize Database Schema

Once RDS is available, connect and run migrations:

```bash
# From your local machine or EC2 instance
psql -h <rds-endpoint> -U civildesk_admin -d postgres

# Create database
CREATE DATABASE civildesk;

# Connect to civildesk database
\c civildesk

# Run your setup.sql file
\i /path/to/database/setup.sql
```

Or use AWS Systems Manager Session Manager to connect via EC2 instance.

### Phase 3: Redis Setup (ElastiCache)

#### Step 3.1: Create Redis Subnet Group

```bash
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name civildesk-redis-subnet-group \
  --cache-subnet-group-description "Subnet group for Civildesk Redis" \
  --subnet-ids <private-subnet-1-id> <private-subnet-2-id>
```

#### Step 3.2: Create Redis Cluster

```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id civildesk-redis \
  --cache-node-type cache.t3.medium \
  --engine redis \
  --num-cache-nodes 1 \
  --cache-subnet-group-name civildesk-redis-subnet-group \
  --security-group-ids <redis-sg-id> \
  --auth-token YOUR_REDIS_PASSWORD \
  --tags Key=Name,Value=civildesk-redis
```

Get Redis endpoint:
```bash
aws elasticache describe-cache-clusters \
  --cache-cluster-id civildesk-redis \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text
```

### Phase 4: Build and Push Docker Images

#### Step 4.1: Create ECR Repositories

```bash
# Backend repository
aws ecr create-repository \
  --repository-name civildesk-backend \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

# Face service repository
aws ecr create-repository \
  --repository-name civildesk-face-service \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256
```

#### Step 4.2: Authenticate Docker to ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

#### Step 4.3: Build and Push Backend Image

```bash
cd civildesk-backend

# Build image
docker build -t civildesk-backend:latest -f Dockerfile .

# Tag for ECR
docker tag civildesk-backend:latest \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/civildesk-backend:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/civildesk-backend:latest
```

#### Step 4.4: Build and Push Face Service Image

```bash
cd face-recognition-service

# Build image (with GPU support)
docker build -t civildesk-face-service:latest -f Dockerfile .

# Tag for ECR
docker tag civildesk-face-service:latest \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/civildesk-face-service:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/civildesk-face-service:latest
```

### Phase 5: Deploy Backend to EC2

#### Step 5.1: Create IAM Role for EC2 Backend

Create file `ec2-backend-role-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:*:secret:civildesk/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::civildesk-uploads-*/*",
        "arn:aws:s3:::civildesk-videos-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

```bash
# Create IAM role for EC2 backend
aws iam create-role \
  --role-name civildesk-ec2-backend-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach managed policy for ECR access
aws iam attach-role-policy \
  --role-name civildesk-ec2-backend-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Create and attach custom policy
aws iam put-role-policy \
  --role-name civildesk-ec2-backend-role \
  --policy-name CivildeskSecretsAndS3Access \
  --policy-document file://ec2-backend-role-policy.json

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name civildesk-ec2-backend-role

aws iam add-role-to-instance-profile \
  --instance-profile-name civildesk-ec2-backend-role \
  --role-name civildesk-ec2-backend-role
```

#### Step 5.2: Create Launch Template

Create file `backend-launch-template.json`:
```json
{
  "LaunchTemplateName": "civildesk-backend-template",
  "LaunchTemplateData": {
    "ImageId": "ami-0c55b159cbfafe1f0",
    "InstanceType": "t3.medium",
    "KeyName": "<your-key-pair>",
    "SecurityGroupIds": ["<ec2-backend-sg-id>"],
    "IamInstanceProfile": {
      "Name": "civildesk-ec2-backend-role"
    },
    "UserData": "<base64-encoded-user-data>",
    "BlockDeviceMappings": [
      {
        "DeviceName": "/dev/sda1",
        "Ebs": {
          "VolumeSize": 30,
          "VolumeType": "gp3",
          "DeleteOnTermination": true
        }
      }
    ],
    "TagSpecifications": [
      {
        "ResourceType": "instance",
        "Tags": [
          {"Key": "Name", "Value": "civildesk-backend"},
          {"Key": "Environment", "Value": "production"}
        ]
      }
    ]
  }
}
```

Create user data script `backend-user-data.sh`:
```bash
#!/bin/bash
# Backend EC2 User Data Script

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install AWS CLI (if not present)
apt-get install -y awscli

# Install jq for JSON parsing
apt-get install -y jq

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create application directory
mkdir -p /opt/civildesk-backend
cd /opt/civildesk-backend

# Authenticate to ECR
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Get secrets from Secrets Manager
DB_HOST=$(aws secretsmanager get-secret-value --secret-id civildesk/db-credentials --region $REGION --query SecretString --output text | jq -r .host)
DB_PORT=$(aws secretsmanager get-secret-value --secret-id civildesk/db-credentials --region $REGION --query SecretString --output text | jq -r .port)
DB_NAME=$(aws secretsmanager get-secret-value --secret-id civildesk/db-credentials --region $REGION --query SecretString --output text | jq -r .dbname)
DB_USERNAME=$(aws secretsmanager get-secret-value --secret-id civildesk/db-credentials --region $REGION --query SecretString --output text | jq -r .username)
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id civildesk/db-credentials --region $REGION --query SecretString --output text | jq -r .password)
REDIS_HOST="<redis-endpoint>"
REDIS_PASSWORD=$(aws secretsmanager get-secret-value --secret-id civildesk/redis-credentials --region $REGION --query SecretString --output text | jq -r .password)
JWT_SECRET=$(aws secretsmanager get-secret-value --secret-id civildesk/jwt-secret --region $REGION --query SecretString --output text)
FACE_SERVICE_URL="http://<face-service-private-ip>:8000"

# Create .env file
cat > .env <<EOF
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
REDIS_HOST=$REDIS_HOST
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_ENABLED=true
JWT_SECRET=$JWT_SECRET
JWT_EXPIRATION=86400000
FACE_SERVICE_URL=$FACE_SERVICE_URL
CORS_ALLOWED_ORIGINS=https://your-domain.com
EOF

# Pull and run Docker container
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/civildesk-backend:latest

docker run -d \
  --name civildesk-backend \
  -p 8080:8080 \
  --env-file .env \
  --restart unless-stopped \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/civildesk-backend:latest

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/civildesk-backend.log",
            "log_group_name": "/ec2/civildesk-backend",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWEOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
```

Encode user data script:
```bash
base64 -i backend-user-data.sh > backend-user-data-base64.txt
```

Create launch template:
```bash
# Get latest Ubuntu 22.04 LTS AMI
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

# Read base64 encoded user data
USER_DATA=$(cat backend-user-data-base64.txt)

# Create launch template
aws ec2 create-launch-template \
  --launch-template-name civildesk-backend-template \
  --launch-template-data "ImageId=$AMI_ID,InstanceType=t3.medium,KeyName=<your-key-pair>,SecurityGroupIds=[<ec2-backend-sg-id>],IamInstanceProfile={Name=civildesk-ec2-backend-role},UserData=$USER_DATA,TagSpecifications=[{ResourceType=instance,Tags=[{Key=Name,Value=civildesk-backend}]}]"
```

#### Step 5.3: Create Auto Scaling Group

```bash
# Create Auto Scaling Group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name civildesk-backend-asg \
  --launch-template LaunchTemplateName=civildesk-backend-template,Version='$Latest' \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 2 \
  --vpc-zone-identifier "<private-subnet-1-id>,<private-subnet-2-id>" \
  --target-group-arns <backend-target-group-arn> \
  --health-check-type ELB \
  --health-check-grace-period 300
```

#### Step 5.4: Create CloudWatch Log Group

```bash
aws logs create-log-group --log-group-name /ec2/civildesk-backend
```

#### Step 5.5: Configure Auto Scaling Policies

```bash
# Create scaling policy (CPU-based)
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name civildesk-backend-asg \
  --policy-name civildesk-backend-cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "ScaleInCooldown": 300,
    "ScaleOutCooldown": 60
  }'
```

### Phase 6: Deploy Face Service to EC2

#### Step 6.1: Launch EC2 GPU Instance

```bash
# Get latest Deep Learning AMI
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=Deep Learning AMI GPU*" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1]' \
  --output json

# Launch instance
aws ec2 run-instances \
  --image-id <ami-id> \
  --instance-type g4dn.xlarge \
  --key-name <your-key-pair> \
  --security-group-ids <face-service-sg-id> \
  --subnet-id <private-subnet-1-id> \
  --iam-instance-profile Name=civildesk-ec2-role \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=civildesk-face-service}]'
```

#### Step 6.2: Create IAM Role for EC2

```bash
# Create role
aws iam create-role \
  --role-name civildesk-ec2-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policies
aws iam attach-role-policy \
  --role-name civildesk-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws iam put-role-policy \
  --role-name civildesk-ec2-role \
  --policy-name CivildeskSecretsAndS3Access \
  --policy-document file://ec2-backend-role-policy.json

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name civildesk-ec2-role

aws iam add-role-to-instance-profile \
  --instance-profile-name civildesk-ec2-role \
  --role-name civildesk-ec2-role
```

#### Step 6.3: Configure EC2 Instance

SSH into the instance:
```bash
ssh -i <your-key.pem> ubuntu@<ec2-public-ip>
```

Install Docker and NVIDIA Container Toolkit:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPU
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

#### Step 6.4: Deploy Face Service Container

Create `.env` file:
```bash
nano /opt/face-service/.env
```

```env
SERVICE_PORT=8000
SERVICE_HOST=0.0.0.0
DB_HOST=<rds-endpoint>
DB_PORT=5432
DB_NAME=civildesk
DB_USER=civildesk_admin
DB_PASSWORD=<from-secrets-manager>
REDIS_HOST=<redis-endpoint>
REDIS_PORT=6379
REDIS_PASSWORD=<from-secrets-manager>
USE_GPU=True
GPU_DEVICE_ID=0
```

Authenticate to ECR:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Run container:
```bash
docker run -d \
  --name face-recognition-service \
  --gpus all \
  -p 8000:8000 \
  --env-file /opt/face-service/.env \
  -v /opt/face-service/data:/app/data \
  -v /opt/face-service/logs:/app/logs \
  --restart unless-stopped \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/civildesk-face-service:latest
```

### Phase 7: Setup Application Load Balancer

#### Step 7.1: Create Target Groups

```bash
# Backend target group
aws elbv2 create-target-group \
  --name civildesk-backend-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id <vpc-id> \
  --target-type instance \
  --health-check-path /api/health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3

# Face service target group
aws elbv2 create-target-group \
  --name civildesk-face-service-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id <vpc-id> \
  --target-type instance \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 10 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3
```

#### Step 7.2: Register Targets

```bash
# Register EC2 backend instances (automatic with Auto Scaling Group)
# The Auto Scaling Group will automatically register instances to the target group

# Register EC2 face service instance manually (if not using Auto Scaling)
aws elbv2 register-targets \
  --target-group-arn <face-service-tg-arn> \
  --targets Id=<ec2-instance-id>
```

#### Step 7.3: Create Load Balancer

```bash
aws elbv2 create-load-balancer \
  --name civildesk-alb \
  --subnets <public-subnet-1-id> <public-subnet-2-id> \
  --security-groups <alb-sg-id> \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4
```

#### Step 7.4: Create Listeners

```bash
# HTTP listener (redirect to HTTPS)
aws elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'

# HTTPS listener
aws elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=<acm-cert-arn> \
  --default-actions Type=forward,TargetGroupArn=<backend-tg-arn>
```

#### Step 7.5: Create Listener Rules

```bash
# Rule for face service (path-based routing)
aws elbv2 create-rule \
  --listener-arn <https-listener-arn> \
  --priority 1 \
  --conditions Field=path-pattern,Values='/api/face-recognition/*' \
  --actions Type=forward,TargetGroupArn=<face-service-tg-arn>

# Default rule for backend
aws elbv2 create-rule \
  --listener-arn <https-listener-arn> \
  --priority 100 \
  --conditions Field=path-pattern,Values='/*' \
  --actions Type=forward,TargetGroupArn=<backend-tg-arn>
```

### Phase 8: SSL Certificate (ACM)

#### Step 8.1: Request Certificate

```bash
aws acm request-certificate \
  --domain-name your-domain.com \
  --subject-alternative-names www.your-domain.com \
  --validation-method DNS \
  --region us-east-1
```

#### Step 8.2: Validate Certificate

Follow DNS validation instructions from AWS Console or CLI output. Add CNAME records to your DNS provider.

### Phase 9: DNS Configuration (Route 53)

#### Step 9.1: Create Hosted Zone (if using Route 53)

```bash
aws route53 create-hosted-zone \
  --name your-domain.com \
  --caller-reference $(date +%s)
```

#### Step 9.2: Create A Record

```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "your-domain.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "<alb-zone-id>",
          "DNSName": "<alb-dns-name>",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
```

### Phase 10: Auto-Scaling Configuration

Auto-scaling for the backend is already configured in Phase 5 (Step 5.5) when creating the Auto Scaling Group. The scaling policy is automatically applied.

#### Step 10.1: Verify Auto-Scaling Configuration

```bash
# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names civildesk-backend-asg

# Check scaling policies
aws autoscaling describe-policies \
  --auto-scaling-group-name civildesk-backend-asg

# View scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name civildesk-backend-asg \
  --max-records 10
```

#### Step 10.2: Configure Auto-Scaling for Face Service (Optional)

If you want to deploy multiple face service instances behind ALB:

```bash
# Create launch template for face service
# (Similar to backend, but with GPU instance type)

# Create Auto Scaling Group for face service
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name civildesk-face-service-asg \
  --launch-template LaunchTemplateName=civildesk-face-service-template,Version='$Latest' \
  --min-size 1 \
  --max-size 3 \
  --desired-capacity 1 \
  --vpc-zone-identifier "<private-subnet-1-id>,<private-subnet-2-id>" \
  --target-group-arns <face-service-tg-arn> \
  --health-check-type ELB \
  --health-check-grace-period 300
```

---

## Configuration Files

### Environment Variables Reference

#### Backend (EC2 Instances)
- `SPRING_PROFILES_ACTIVE=prod`
- `SERVER_PORT=8080`
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` (from Secrets Manager)
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` (from Secrets Manager)
- `JWT_SECRET` (from Secrets Manager)
- `FACE_SERVICE_URL` (internal EC2 IP)
- `CORS_ALLOWED_ORIGINS` (your domain)
- `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD` (from Secrets Manager)

#### Face Service (EC2)
- `SERVICE_PORT=8000`
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
- `USE_GPU=True`
- `GPU_DEVICE_ID=0`

---

## Monitoring and Logging

### CloudWatch Logs

All logs are automatically sent to CloudWatch:
- EC2 Backend: `/ec2/civildesk-backend` (via CloudWatch agent)
- EC2 Face Service: Configure CloudWatch agent

### CloudWatch Metrics

Key metrics to monitor:
- EC2: CPUUtilization, NetworkIn/Out, StatusCheckFailed
- Auto Scaling: GroupDesiredCapacity, GroupInServiceInstances
- RDS: CPUUtilization, DatabaseConnections, FreeableMemory
- ElastiCache: CPUUtilization, NetworkBytesIn/Out
- ALB: RequestCount, TargetResponseTime, HealthyHostCount

### CloudWatch Alarms

Create alarms for:
```bash
# High CPU on EC2 Backend
aws cloudwatch put-metric-alarm \
  --alarm-name civildesk-ec2-backend-high-cpu \
  --alarm-description "Alert when EC2 Backend CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=AutoScalingGroupName,Value=civildesk-backend-asg

# Database connections
aws cloudwatch put-metric-alarm \
  --alarm-name civildesk-rds-high-connections \
  --alarm-description "Alert when RDS connections exceed 80" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

---

## Security Best Practices

### 1. Network Security
- ✅ All services in private subnets (except ALB)
- ✅ Security groups with least privilege
- ✅ No public access to RDS/Redis
- ✅ VPC Flow Logs enabled

### 2. Secrets Management
- ✅ All credentials in AWS Secrets Manager
- ✅ IAM roles for service access (no hardcoded keys)
- ✅ Secrets rotation (optional but recommended)

### 3. Encryption
- ✅ RDS encryption at rest
- ✅ S3 encryption enabled
- ✅ SSL/TLS for all traffic (ALB)
- ✅ Secrets Manager encryption

### 4. Access Control
- ✅ IAM roles with least privilege
- ✅ Security groups restrict traffic
- ✅ SSH access restricted to specific IPs only
- ✅ EC2 SSH only from specific IPs

### 5. Compliance
- ✅ Enable CloudTrail for audit logging
- ✅ Enable GuardDuty for threat detection
- ✅ Regular security updates
- ✅ Backup and disaster recovery

---

## Scaling and Optimization

### Horizontal Scaling

1. **EC2 Auto Scaling Groups**: Already configured for backend (2-10 instances)
2. **Multiple EC2 Instances**: Deploy face service behind ALB with Auto Scaling
3. **Read Replicas**: Add RDS read replicas for read-heavy workloads
4. **Redis Cluster**: Upgrade to Redis cluster mode for high availability

### Vertical Scaling

1. **EC2 Backend**: Upgrade instance type (t3.large, t3.xlarge, or m5.large)
2. **EC2 Face Service**: Upgrade to g4dn.2xlarge or g4dn.4xlarge
3. **RDS**: Upgrade instance class (db.t3.large, db.r5.xlarge)
4. **Redis**: Upgrade node type (cache.r6g.large)

### Performance Optimization

1. **CDN**: Use CloudFront for static assets
2. **Caching**: Implement Redis caching strategies
3. **Database**: Add indexes, connection pooling
4. **GPU**: Optimize face recognition batch processing

---

## Cost Optimization

### 1. Use Reserved Instances
- Reserve RDS instances (1-3 year terms)
- Reserve EC2 GPU instances

### 2. Use Spot Instances
- EC2 Spot for backend (with interruption handling)
- EC2 Spot for face service (with interruption handling)

### 3. Right-Sizing
- Monitor and adjust instance sizes
- Use CloudWatch metrics to identify over-provisioned resources

### 4. S3 Lifecycle Policies
- Move old files to Glacier/Deep Archive
- Delete unnecessary versions

### 5. Scheduled Scaling
- Scale down during off-hours
- Use AWS Auto Scaling scheduled actions

---

## Troubleshooting

### Common Issues

#### 1. EC2 Backend Instances Not Starting
```bash
# Check instance status
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=civildesk-backend" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names civildesk-backend-asg

# Check logs via SSH
ssh -i <key.pem> ubuntu@<instance-ip>
docker logs civildesk-backend

# Or check CloudWatch logs
aws logs tail /ec2/civildesk-backend --follow
```

#### 2. Database Connection Issues
- Verify security group rules
- Check RDS endpoint and credentials
- Test connection from EC2 instance (SSH into instance)

#### 3. Face Service GPU Not Working
```bash
# SSH into EC2
ssh -i key.pem ubuntu@<ec2-ip>

# Check GPU
nvidia-smi

# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

#### 4. ALB Health Check Failures
- Verify target group health check path
- Check security group allows ALB traffic
- Verify application is listening on correct port

#### 5. High Costs
- Review CloudWatch metrics
- Identify unused resources
- Consider Reserved Instances
- Use Cost Explorer for analysis

---

## Deployment Checklist

### Pre-Deployment
- [ ] AWS account configured with appropriate permissions
- [ ] Domain name registered (if using custom domain)
- [ ] All secrets generated and stored in Secrets Manager
- [ ] Docker images built and tested locally
- [ ] Database schema ready

### Infrastructure
- [ ] VPC and subnets created
- [ ] Security groups configured
- [ ] Internet Gateway and NAT Gateway set up
- [ ] Route tables configured
- [ ] S3 buckets created with appropriate policies

### Services
- [ ] RDS PostgreSQL instance created and accessible
- [ ] ElastiCache Redis cluster created
- [ ] ECR repositories created
- [ ] Docker images pushed to ECR
- [ ] EC2 backend launch template created
- [ ] Auto Scaling Group created
- [ ] EC2 backend instances running
- [ ] EC2 instance launched and configured
- [ ] Face service container running

### Load Balancer
- [ ] ALB created
- [ ] Target groups created
- [ ] Targets registered
- [ ] Listeners configured
- [ ] SSL certificate validated and attached
- [ ] Health checks passing

### DNS and Access
- [ ] Route 53 records configured (or DNS provider)
- [ ] SSL certificate active
- [ ] Application accessible via domain
- [ ] Mobile apps configured with correct API endpoints

### Monitoring
- [ ] CloudWatch log groups created
- [ ] CloudWatch alarms configured
- [ ] Monitoring dashboard created
- [ ] Alert notifications set up

### Security
- [ ] Security groups reviewed
- [ ] IAM roles with least privilege
- [ ] Secrets in Secrets Manager
- [ ] Encryption enabled
- [ ] Backup strategy implemented

---

## Post-Deployment Tasks

1. **Run Database Migrations**
   ```bash
   # Connect to RDS and run migrations
   psql -h <rds-endpoint> -U civildesk_admin -d civildesk -f setup.sql
   ```

2. **Test All Endpoints**
   - Health checks
   - Authentication
   - Face recognition
   - File uploads

3. **Configure Backups**
   - RDS automated backups (already enabled)
   - S3 bucket versioning
   - Manual backup scripts

4. **Set Up Monitoring Dashboard**
   - Create CloudWatch dashboard
   - Configure SNS notifications
   - Set up PagerDuty/OpsGenie (optional)

5. **Update Mobile Apps**
   - Update API base URL
   - Update face service URL
   - Test all features

---

## Maintenance

### Regular Tasks

1. **Weekly**
   - Review CloudWatch metrics
   - Check security group rules
   - Review costs

2. **Monthly**
   - Update Docker images
   - Review and rotate secrets
   - Database maintenance (VACUUM, ANALYZE)
   - Review and update security patches

3. **Quarterly**
   - Review and optimize costs
   - Performance testing
   - Disaster recovery testing
   - Security audit

---

## Support and Resources

- **AWS Documentation**: https://docs.aws.amazon.com/
- **EC2 Auto Scaling Best Practices**: https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html
- **RDS Documentation**: https://docs.aws.amazon.com/rds/
- **AWS Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected/

---

## Notes

1. Replace all placeholder values (`<account-id>`, `<vpc-id>`, etc.) with actual values
2. Adjust instance types and sizes based on your workload
3. Monitor costs regularly using AWS Cost Explorer
4. Keep Docker images updated with security patches
5. Regularly review and update security groups
6. Test disaster recovery procedures
7. Keep documentation updated as infrastructure changes

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Author**: Civildesk Deployment Team

