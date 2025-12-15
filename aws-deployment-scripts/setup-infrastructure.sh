#!/bin/bash

# Civildesk AWS Infrastructure Setup Script
# This script automates the creation of VPC, subnets, security groups, and basic infrastructure

set -e

# Configuration
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_1_CIDR="10.0.1.0/24"
PUBLIC_SUBNET_2_CIDR="10.0.2.0/24"
PRIVATE_SUBNET_1_CIDR="10.0.10.0/24"
PRIVATE_SUBNET_2_CIDR="10.0.11.0/24"
AZ1="us-east-1a"
AZ2="us-east-1b"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Civildesk AWS Infrastructure Setup...${NC}"

# Step 1: Create VPC
echo -e "${YELLOW}Step 1: Creating VPC...${NC}"
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=civildesk-vpc}]" \
  --query 'Vpc.VpcId' \
  --output text)

echo -e "${GREEN}VPC Created: $VPC_ID${NC}"

# Step 2: Create Internet Gateway
echo -e "${YELLOW}Step 2: Creating Internet Gateway...${NC}"
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=civildesk-igw}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID \
  --region $REGION

echo -e "${GREEN}Internet Gateway Created and Attached: $IGW_ID${NC}"

# Step 3: Create Subnets
echo -e "${YELLOW}Step 3: Creating Subnets...${NC}"

PUBLIC_SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_1_CIDR \
  --availability-zone $AZ1 \
  --region $REGION \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-public-1a}]" \
  --query 'Subnet.SubnetId' \
  --output text)

PUBLIC_SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_2_CIDR \
  --availability-zone $AZ2 \
  --region $REGION \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-public-1b}]" \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_1_CIDR \
  --availability-zone $AZ1 \
  --region $REGION \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-private-1a}]" \
  --query 'Subnet.SubnetId' \
  --output text)

PRIVATE_SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_2_CIDR \
  --availability-zone $AZ2 \
  --region $REGION \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=civildesk-private-1b}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo -e "${GREEN}Subnets Created:${NC}"
echo "  Public Subnet 1: $PUBLIC_SUBNET_1_ID"
echo "  Public Subnet 2: $PUBLIC_SUBNET_2_ID"
echo "  Private Subnet 1: $PRIVATE_SUBNET_1_ID"
echo "  Private Subnet 2: $PRIVATE_SUBNET_2_ID"

# Step 4: Create NAT Gateway
echo -e "${YELLOW}Step 4: Creating NAT Gateway...${NC}"

# Allocate Elastic IP
EIP_ALLOCATION_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --region $REGION \
  --query 'AllocationId' \
  --output text)

# Wait a bit for EIP to be ready
sleep 5

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_1_ID \
  --allocation-id $EIP_ALLOCATION_ID \
  --region $REGION \
  --tag-specifications "ResourceType=nat-gateway,Tags=[{Key=Name,Value=civildesk-nat}]" \
  --query 'NatGateway.NatGatewayId' \
  --output text)

echo -e "${GREEN}NAT Gateway Created: $NAT_GW_ID (waiting for available state...)${NC}"

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available \
  --nat-gateway-ids $NAT_GW_ID \
  --region $REGION

echo -e "${GREEN}NAT Gateway is now available${NC}"

# Step 5: Create Route Tables
echo -e "${YELLOW}Step 5: Creating Route Tables...${NC}"

# Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=civildesk-public-rt}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION > /dev/null

aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_1_ID \
  --route-table-id $PUBLIC_RT_ID \
  --region $REGION > /dev/null

aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_2_ID \
  --route-table-id $PUBLIC_RT_ID \
  --region $REGION > /dev/null

# Private Route Table
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=civildesk-private-rt}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID \
  --region $REGION > /dev/null

aws ec2 associate-route-table \
  --subnet-id $PRIVATE_SUBNET_1_ID \
  --route-table-id $PRIVATE_RT_ID \
  --region $REGION > /dev/null

aws ec2 associate-route-table \
  --subnet-id $PRIVATE_SUBNET_2_ID \
  --route-table-id $PRIVATE_RT_ID \
  --region $REGION > /dev/null

echo -e "${GREEN}Route Tables Created and Configured${NC}"

# Step 6: Create Security Groups
echo -e "${YELLOW}Step 6: Creating Security Groups...${NC}"

# ALB Security Group
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name civildesk-alb-sg \
  --description "Security group for Application Load Balancer" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region $REGION > /dev/null

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --region $REGION > /dev/null

# ECS Backend Security Group
ECS_BACKEND_SG_ID=$(aws ec2 create-security-group \
  --group-name civildesk-ecs-backend-sg \
  --description "Security group for ECS backend tasks" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ECS_BACKEND_SG_ID \
  --protocol tcp \
  --port 8080 \
  --source-group $ALB_SG_ID \
  --region $REGION > /dev/null

# EC2 Face Service Security Group
FACE_SERVICE_SG_ID=$(aws ec2 create-security-group \
  --group-name civildesk-face-service-sg \
  --description "Security group for face recognition service" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $FACE_SERVICE_SG_ID \
  --protocol tcp \
  --port 8000 \
  --source-group $ALB_SG_ID \
  --region $REGION > /dev/null

# RDS Security Group
RDS_SG_ID=$(aws ec2 create-security-group \
  --group-name civildesk-rds-sg \
  --description "Security group for RDS PostgreSQL" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_BACKEND_SG_ID \
  --region $REGION > /dev/null

aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $FACE_SERVICE_SG_ID \
  --region $REGION > /dev/null

# Redis Security Group
REDIS_SG_ID=$(aws ec2 create-security-group \
  --group-name civildesk-redis-sg \
  --description "Security group for ElastiCache Redis" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $REDIS_SG_ID \
  --protocol tcp \
  --port 6379 \
  --source-group $ECS_BACKEND_SG_ID \
  --region $REGION > /dev/null

aws ec2 authorize-security-group-ingress \
  --group-id $REDIS_SG_ID \
  --protocol tcp \
  --port 6379 \
  --source-group $FACE_SERVICE_SG_ID \
  --region $REGION > /dev/null

echo -e "${GREEN}Security Groups Created${NC}"

# Save configuration to file
cat > infrastructure-config.json <<EOF
{
  "region": "$REGION",
  "vpc_id": "$VPC_ID",
  "internet_gateway_id": "$IGW_ID",
  "nat_gateway_id": "$NAT_GW_ID",
  "elastic_ip_allocation_id": "$EIP_ALLOCATION_ID",
  "subnets": {
    "public_1a": "$PUBLIC_SUBNET_1_ID",
    "public_1b": "$PUBLIC_SUBNET_2_ID",
    "private_1a": "$PRIVATE_SUBNET_1_ID",
    "private_1b": "$PRIVATE_SUBNET_2_ID"
  },
  "route_tables": {
    "public": "$PUBLIC_RT_ID",
    "private": "$PRIVATE_RT_ID"
  },
  "security_groups": {
    "alb": "$ALB_SG_ID",
    "ecs_backend": "$ECS_BACKEND_SG_ID",
    "face_service": "$FACE_SERVICE_SG_ID",
    "rds": "$RDS_SG_ID",
    "redis": "$REDIS_SG_ID"
  }
}
EOF

echo -e "${GREEN}Infrastructure setup complete!${NC}"
echo -e "${YELLOW}Configuration saved to: infrastructure-config.json${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Create S3 buckets"
echo "2. Create RDS instance"
echo "3. Create ElastiCache Redis cluster"
echo "4. Create ECR repositories"
echo "5. Build and push Docker images"
echo "6. Create ECS cluster and services"
echo "7. Create Application Load Balancer"

