# AWS Deployment Quick Reference

Quick reference guide for common AWS deployment tasks.

---

## Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI v2 installed and configured
- [ ] Docker installed locally
- [ ] Domain name (optional)
- [ ] SSH key pair for EC2

---

## Quick Start Commands

### 1. Setup Infrastructure

```bash
cd aws-deployment-scripts
./setup-infrastructure.sh
```

This creates:
- VPC with public/private subnets
- Internet Gateway and NAT Gateway
- Security Groups
- Route Tables

### 2. Create Secrets

```bash
./create-secrets.sh
```

This creates secrets in AWS Secrets Manager:
- Database credentials
- Redis credentials
- JWT secret
- Email credentials

### 3. Build and Push Docker Images

```bash
./build-and-push-images.sh
```

This builds and pushes:
- Backend image to ECR
- Face service image to ECR

---

## Essential AWS CLI Commands

### Get Resource IDs

```bash
# Get VPC ID
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=civildesk-vpc" --query 'Vpcs[0].VpcId' --output text

# Get Subnet IDs
aws ec2 describe-subnets --filters "Name=tag:Name,Values=civildesk-*" --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0]]' --output table

# Get Security Group IDs
aws ec2 describe-security-groups --filters "Name=group-name,Values=civildesk-*" --query 'SecurityGroups[*].[GroupId,GroupName]' --output table
```

### Check Service Status

```bash
# EC2 Backend Auto Scaling Group Status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names civildesk-backend-asg \
  --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize,Instances[*].[InstanceId,HealthStatus,LifecycleState]]' \
  --output table

# RDS Status
aws rds describe-db-instances \
  --db-instance-identifier civildesk-db \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
  --output table

# ElastiCache Status
aws elasticache describe-cache-clusters \
  --cache-cluster-id civildesk-redis \
  --show-cache-node-info \
  --query 'CacheClusters[0].[CacheClusterStatus,CacheNodes[0].Endpoint.Address]' \
  --output table
```

### View Logs

```bash
# EC2 Backend Logs
aws logs tail /ec2/civildesk-backend --follow

# EC2 Face Service Logs (SSH into instance first)
docker logs -f face-recognition-service
```

---

## Common Tasks

### Update EC2 Backend Instances

```bash
# Update launch template (create new version)
aws ec2 create-launch-template-version \
  --launch-template-name civildesk-backend-template \
  --source-version $Latest \
  --launch-template-data file://updated-launch-template.json

# Start instance refresh to update running instances
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name civildesk-backend-asg \
  --preferences '{"MinHealthyPercentage": 90,"InstanceWarmup": 300}'
```

### Scale EC2 Backend Service

```bash
# Scale to 4 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name civildesk-backend-asg \
  --desired-capacity 4
```

### Restart EC2 Instances

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=civildesk-backend" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table

# Reboot specific instance
aws ec2 reboot-instances --instance-ids <instance-id>

# Terminate and let ASG replace
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <instance-id> \
  --should-decrement-desired-capacity
```

### Update Secrets

```bash
# Update database password
aws secretsmanager update-secret \
  --secret-id civildesk/db-credentials \
  --secret-string '{"username":"civildesk_admin","password":"NEW_PASSWORD","engine":"postgres","host":"...","port":5432,"dbname":"civildesk"}'
```

### Backup Database

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-snapshot-identifier civildesk-db-manual-$(date +%Y%m%d) \
  --db-instance-identifier civildesk-db
```

### Check Costs

```bash
# Get cost and usage (requires Cost Explorer API)
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

---

## Troubleshooting Commands

### EC2 Backend Issues

```bash
# Check launch template
aws ec2 describe-launch-templates --launch-template-names civildesk-backend-template

# Check instance status
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=civildesk-backend" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table

# Check Auto Scaling Group events
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name civildesk-backend-asg \
  --max-records 10
```

### Network Issues

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Test connectivity from EC2 instance (SSH into instance)
ssh -i <key.pem> ubuntu@<instance-ip>
curl http://<rds-endpoint>:5432
telnet <rds-endpoint> 5432

# Or use Systems Manager Session Manager
aws ssm start-session --target <instance-id>
```

### Database Issues

```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier civildesk-db

# Check RDS logs
aws rds describe-db-log-files \
  --db-instance-identifier civildesk-db \
  --query 'DescribeDBLogFiles[*].[LogFileName,LastWritten]' \
  --output table
```

---

## Environment Variables Reference

### Backend (ECS Task Definition)

```json
{
  "SPRING_PROFILES_ACTIVE": "prod",
  "SERVER_PORT": "8080",
  "DB_HOST": "<from-secrets-manager>",
  "DB_PORT": "5432",
  "DB_NAME": "civildesk",
  "DB_USERNAME": "<from-secrets-manager>",
  "DB_PASSWORD": "<from-secrets-manager>",
  "REDIS_HOST": "<redis-endpoint>",
  "REDIS_PORT": "6379",
  "REDIS_PASSWORD": "<from-secrets-manager>",
  "JWT_SECRET": "<from-secrets-manager>",
  "FACE_SERVICE_URL": "http://<ec2-private-ip>:8000",
  "CORS_ALLOWED_ORIGINS": "https://your-domain.com"
}
```

### Face Service (EC2)

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

---

## Cost Optimization Tips

1. **Use Reserved Instances** for RDS and EC2 (save up to 75%)
2. **Use Spot Instances** for non-critical workloads
3. **Right-size instances** based on CloudWatch metrics
4. **Enable S3 Lifecycle Policies** to move old files to Glacier
5. **Use CloudWatch Insights** to identify unused resources
6. **Schedule scaling** to scale down during off-hours

---

## Security Checklist

- [ ] Security groups follow least privilege principle
- [ ] All secrets in AWS Secrets Manager
- [ ] RDS encryption at rest enabled
- [ ] S3 bucket encryption enabled
- [ ] SSL/TLS certificates from ACM
- [ ] CloudTrail enabled for audit logging
- [ ] VPC Flow Logs enabled
- [ ] Regular security updates
- [ ] IAM roles with least privilege
- [ ] No hardcoded credentials

---

## Monitoring Checklist

- [ ] CloudWatch log groups created
- [ ] CloudWatch alarms configured
- [ ] CloudWatch dashboard created
- [ ] SNS notifications set up
- [ ] Cost alerts configured
- [ ] Performance metrics tracked

---

## Backup Checklist

- [ ] RDS automated backups enabled (7-day retention)
- [ ] RDS manual snapshots scheduled
- [ ] S3 versioning enabled
- [ ] S3 cross-region replication configured
- [ ] EC2 launch templates backed up
- [ ] Configuration files in version control

---

## Useful Links

- [AWS EC2 Auto Scaling Documentation](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS ElastiCache Documentation](https://docs.aws.amazon.com/elasticache/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**Last Updated**: December 2024

