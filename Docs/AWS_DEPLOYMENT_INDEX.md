# Civildesk AWS Deployment Documentation Index

Complete guide to deploying Civildesk on AWS with step-by-step instructions, architecture diagrams, and automation scripts.

---

## 📚 Documentation Overview

### 1. [AWS Deployment Guide](./AWS_DEPLOYMENT_GUIDE.md) ⭐ **START HERE**
**Complete step-by-step deployment guide**

This is your main deployment guide with:
- Architecture overview and diagrams
- Prerequisites and cost estimates
- Phase-by-phase deployment instructions (10 phases)
- Configuration files and examples
- Monitoring and logging setup
- Security best practices
- Scaling and optimization
- Troubleshooting guide
- Deployment checklist

**Use this for:** Complete deployment from scratch

---

### 2. [Architecture Diagrams](./AWS_ARCHITECTURE_DIAGRAM.md)
**Visual architecture representations**

Contains:
- High-level architecture (Mermaid diagrams)
- Network architecture
- Data flow diagrams
- Security architecture
- High availability architecture
- Scaling architecture
- Disaster recovery architecture

**Use this for:** Understanding system architecture and design

---

### 3. [Quick Reference Guide](./AWS_DEPLOYMENT_QUICK_REFERENCE.md)
**Common commands and tasks**

Quick reference for:
- Essential AWS CLI commands
- Common deployment tasks
- Troubleshooting commands
- Environment variables reference
- Cost optimization tips
- Security and monitoring checklists

**Use this for:** Day-to-day operations and quick lookups

---

### 4. [Deployment Scripts](./aws-deployment-scripts/)
**Automation scripts for deployment**

Scripts directory contains:
- `setup-infrastructure.sh` - Automates VPC, subnets, security groups
- `create-secrets.sh` - Creates secrets in AWS Secrets Manager
- `build-and-push-images.sh` - Builds and pushes Docker images to ECR
- `README.md` - Scripts documentation

**Use this for:** Automating repetitive deployment tasks

---

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

```bash
# 1. Setup infrastructure
cd aws-deployment-scripts
./setup-infrastructure.sh

# 2. Create secrets
./create-secrets.sh

# 3. Build and push images
./build-and-push-images.sh

# 4. Follow main guide for remaining steps
# (RDS, ElastiCache, EC2, ALB setup)
```

### Option 2: Manual Deployment

Follow the [AWS Deployment Guide](./AWS_DEPLOYMENT_GUIDE.md) step by step.

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] AWS account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] Docker installed locally
- [ ] Domain name registered (optional)
- [ ] SSH key pair for EC2

### Infrastructure Setup
- [ ] VPC and subnets created
- [ ] Internet Gateway and NAT Gateway configured
- [ ] Security groups created
- [ ] Route tables configured
- [ ] S3 buckets created

### Services Setup
- [ ] RDS PostgreSQL instance created
- [ ] ElastiCache Redis cluster created
- [ ] ECR repositories created
- [ ] Docker images built and pushed
- [ ] Secrets stored in Secrets Manager

### Application Deployment
- [ ] EC2 backend launch template created
- [ ] Auto Scaling Group created
- [ ] EC2 backend instances running
- [ ] EC2 instance launched and configured
- [ ] Face service container running

### Load Balancer & DNS
- [ ] Application Load Balancer created
- [ ] Target groups configured
- [ ] SSL certificate requested and validated
- [ ] DNS records configured
- [ ] Health checks passing

### Post-Deployment
- [ ] Database migrations executed
- [ ] All endpoints tested
- [ ] Monitoring configured
- [ ] Backups configured
- [ ] Mobile apps updated with new URLs

---

## 🏗️ Architecture Summary

### Components

| Component | AWS Service | Purpose |
|-----------|-------------|---------|
| **Load Balancer** | Application Load Balancer | Traffic distribution, SSL termination |
| **Backend API** | EC2 (t3.medium) | Spring Boot application |
| **Face Recognition** | EC2 GPU (g4dn.xlarge) | FastAPI service with GPU |
| **Database** | RDS PostgreSQL | Primary data store |
| **Cache** | ElastiCache Redis | Session storage, caching |
| **File Storage** | S3 | Documents, images, videos |
| **Secrets** | Secrets Manager | Credential storage |
| **Monitoring** | CloudWatch | Logs, metrics, alarms |
| **DNS** | Route 53 | Domain management |
| **SSL/TLS** | Certificate Manager | Certificate management |

### Network Architecture

```
Internet → CloudFront → ALB → [EC2 Backend Instances / EC2 Face Service]
                              ↓
                    [RDS / Redis / S3]
```

### High Availability

- **Multi-AZ Deployment**: RDS, ElastiCache, EC2 instances across availability zones
- **Auto Scaling**: EC2 instances scale based on CPU via Auto Scaling Groups
- **Load Balancing**: ALB distributes traffic across multiple tasks
- **Automated Backups**: RDS automated backups with 7-day retention

---

## 💰 Cost Estimate

| Service | Monthly Cost (USD) |
|---------|-------------------|
| RDS PostgreSQL (db.t3.medium, Multi-AZ) | ~$150 |
| EC2 GPU (g4dn.xlarge) | ~$150 |
| EC2 Backend (2 instances, t3.medium) | ~$60 |
| ElastiCache Redis (cache.t3.medium) | ~$50 |
| Application Load Balancer | ~$20 |
| Data Transfer (100GB) | ~$10 |
| CloudWatch | ~$10 |
| S3 Storage (100GB) | ~$5 |
| **Total** | **~$455/month** |

*Note: Costs vary by region and usage. Use AWS Calculator for accurate estimates.*

---

## 🔒 Security Features

- ✅ All services in private subnets (except ALB)
- ✅ Security groups with least privilege
- ✅ All credentials in AWS Secrets Manager
- ✅ Encryption at rest (RDS, S3, EBS)
- ✅ Encryption in transit (SSL/TLS)
- ✅ IAM roles with least privilege
- ✅ CloudTrail for audit logging
- ✅ VPC Flow Logs enabled

---

## 📊 Monitoring & Logging

### CloudWatch Logs
- EC2 Backend: `/ec2/civildesk-backend`
- EC2 Face Service: Configure CloudWatch agent

### Key Metrics
- EC2: CPUUtilization, NetworkIn/Out, StatusCheckFailed
- RDS: CPUUtilization, DatabaseConnections, FreeableMemory
- ElastiCache: CPUUtilization, NetworkBytesIn/Out
- ALB: RequestCount, TargetResponseTime, HealthyHostCount

### Alarms
- High CPU utilization
- Database connection limits
- Service health checks
- Cost anomalies

---

## 🛠️ Troubleshooting

### Common Issues

1. **EC2 Backend Instances Not Starting**
   - Check task definition
   - Verify secrets are accessible
   - Check CloudWatch logs

2. **Database Connection Issues**
   - Verify security group rules
   - Check RDS endpoint
   - Verify credentials in Secrets Manager

3. **Face Service GPU Not Working**
   - Verify NVIDIA drivers
   - Check Docker GPU support
   - Review container logs

4. **High Costs**
   - Review CloudWatch metrics
   - Identify unused resources
   - Consider Reserved Instances

See [Quick Reference Guide](./AWS_DEPLOYMENT_QUICK_REFERENCE.md) for troubleshooting commands.

---

## 📖 Additional Resources

### AWS Documentation
- [EC2 Auto Scaling Best Practices](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html)
- [RDS User Guide](https://docs.aws.amazon.com/rds/)
- [ElastiCache User Guide](https://docs.aws.amazon.com/elasticache/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Project Documentation
- [Main Deployment Guide](./DEPLOYMENT_GUIDE.md) - Docker-based deployment
- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md)
- [Code Review Report](./CODE_REVIEW_REPORT.md)

---

## 🎯 Deployment Phases

1. **Phase 1**: AWS Infrastructure Setup (VPC, Subnets, Security Groups)
2. **Phase 2**: Database Setup (RDS PostgreSQL)
3. **Phase 3**: Redis Setup (ElastiCache)
4. **Phase 4**: Build and Push Docker Images (ECR)
5. **Phase 5**: Deploy Backend to EC2
6. **Phase 6**: Deploy Face Service to EC2
7. **Phase 7**: Setup Application Load Balancer
8. **Phase 8**: SSL Certificate (ACM)
9. **Phase 9**: DNS Configuration (Route 53)
10. **Phase 10**: Auto-Scaling Configuration

---

## 📝 Notes

- Replace all placeholder values (`<account-id>`, `<vpc-id>`, etc.) with actual values
- Adjust instance types and sizes based on your workload
- Monitor costs regularly using AWS Cost Explorer
- Keep Docker images updated with security patches
- Regularly review and update security groups
- Test disaster recovery procedures
- Keep documentation updated as infrastructure changes

---

## 🆘 Getting Help

1. **Review Documentation**: Start with the main deployment guide
2. **Check Logs**: CloudWatch logs for EC2 backend, EC2 logs for face service
3. **Verify Configuration**: Check task definitions, security groups, IAM roles
4. **AWS Support**: Use AWS Support for infrastructure issues
5. **Community**: AWS forums and Stack Overflow

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Status**: Production Ready

---

## 📄 Document Structure

```
.
├── AWS_DEPLOYMENT_GUIDE.md          # Main deployment guide
├── AWS_ARCHITECTURE_DIAGRAM.md      # Architecture diagrams
├── AWS_DEPLOYMENT_QUICK_REFERENCE.md # Quick reference
├── AWS_DEPLOYMENT_INDEX.md          # This file
└── aws-deployment-scripts/
    ├── README.md
    ├── setup-infrastructure.sh
    ├── create-secrets.sh
    └── build-and-push-images.sh
```

---

**Ready to deploy?** Start with the [AWS Deployment Guide](./AWS_DEPLOYMENT_GUIDE.md)!

