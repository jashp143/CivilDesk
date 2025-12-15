#!/bin/bash

# Civildesk Docker Image Build and Push Script
# This script builds and pushes Docker images to AWS ECR

set -e

# Configuration
REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_BACKEND_REPO="civildesk-backend"
ECR_FACE_SERVICE_REPO="civildesk-face-service"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Civildesk Docker Image Build and Push${NC}"
echo ""

# Check if AWS CLI is configured
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}Error: AWS CLI not configured. Please run 'aws configure'${NC}"
    exit 1
fi

echo -e "${YELLOW}AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo -e "${YELLOW}Region: $REGION${NC}"
echo ""

# Authenticate Docker to ECR
echo -e "${YELLOW}Authenticating Docker to ECR...${NC}"
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo -e "${GREEN}Authentication successful${NC}"
echo ""

# Function to create ECR repository if it doesn't exist
create_ecr_repo() {
    REPO_NAME=$1
    echo -e "${YELLOW}Checking ECR repository: $REPO_NAME${NC}"
    
    if aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1; then
        echo -e "${GREEN}Repository $REPO_NAME already exists${NC}"
    else
        echo -e "${YELLOW}Creating repository: $REPO_NAME${NC}"
        aws ecr create-repository \
            --repository-name $REPO_NAME \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256 \
            --region $REGION > /dev/null
        echo -e "${GREEN}Repository $REPO_NAME created${NC}"
    fi
}

# Create repositories
create_ecr_repo $ECR_BACKEND_REPO
create_ecr_repo $ECR_FACE_SERVICE_REPO
echo ""

# Build and push backend image
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Building Backend Image${NC}"
echo -e "${YELLOW}========================================${NC}"

cd civildesk-backend

echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t $ECR_BACKEND_REPO:latest -f Dockerfile .

echo -e "${YELLOW}Tagging image for ECR...${NC}"
docker tag $ECR_BACKEND_REPO:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_BACKEND_REPO:latest

echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_BACKEND_REPO:latest

echo -e "${GREEN}Backend image pushed successfully${NC}"
echo ""

# Build and push face service image
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Building Face Service Image${NC}"
echo -e "${YELLOW}========================================${NC}"

cd ../face-recognition-service

echo -e "${YELLOW}Building Docker image (this may take a while)...${NC}"
docker build -t $ECR_FACE_SERVICE_REPO:latest -f Dockerfile .

echo -e "${YELLOW}Tagging image for ECR...${NC}"
docker tag $ECR_FACE_SERVICE_REPO:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_FACE_SERVICE_REPO:latest

echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_FACE_SERVICE_REPO:latest

echo -e "${GREEN}Face service image pushed successfully${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build and Push Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Backend Image:"
echo "  $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_BACKEND_REPO:latest"
echo ""
echo "Face Service Image:"
echo "  $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_FACE_SERVICE_REPO:latest"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Create ECS task definitions using these images"
echo "2. Create ECS services"
echo "3. Configure load balancer"

