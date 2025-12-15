#!/bin/bash

# Civildesk AWS Secrets Creation Script
# This script helps create secrets in AWS Secrets Manager

set -e

REGION="us-east-1"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Civildesk Secrets Manager Setup${NC}"
echo ""

# Function to generate random password
generate_password() {
    openssl rand -base64 24 | tr -d "=+/" | cut -c1-24
}

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -hex 32
}

# Check if secrets already exist
check_secret() {
    aws secretsmanager describe-secret --secret-id "$1" --region $REGION > /dev/null 2>&1
}

# Create or update secret
create_or_update_secret() {
    SECRET_NAME=$1
    SECRET_VALUE=$2
    
    if check_secret "$SECRET_NAME"; then
        echo -e "${YELLOW}Secret $SECRET_NAME already exists. Updating...${NC}"
        aws secretsmanager update-secret \
            --secret-id "$SECRET_NAME" \
            --secret-string "$SECRET_VALUE" \
            --region $REGION > /dev/null
        echo -e "${GREEN}Updated: $SECRET_NAME${NC}"
    else
        echo -e "${YELLOW}Creating secret: $SECRET_NAME${NC}"
        aws secretsmanager create-secret \
            --name "$SECRET_NAME" \
            --secret-string "$SECRET_VALUE" \
            --region $REGION > /dev/null
        echo -e "${GREEN}Created: $SECRET_NAME${NC}"
    fi
}

# Step 1: Database Credentials
echo -e "${YELLOW}Step 1: Database Credentials${NC}"
read -p "Enter database username [civildesk_admin]: " DB_USERNAME
DB_USERNAME=${DB_USERNAME:-civildesk_admin}

read -p "Enter database password (or press Enter to generate): " DB_PASSWORD
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password: $DB_PASSWORD${NC}"
fi

read -p "Enter RDS endpoint (or press Enter to set later): " DB_HOST
DB_HOST=${DB_HOST:-"civildesk-db.xxxxx.us-east-1.rds.amazonaws.com"}

DB_SECRET=$(cat <<EOF
{
  "username": "$DB_USERNAME",
  "password": "$DB_PASSWORD",
  "engine": "postgres",
  "host": "$DB_HOST",
  "port": 5432,
  "dbname": "civildesk"
}
EOF
)

create_or_update_secret "civildesk/db-credentials" "$DB_SECRET"
echo ""

# Step 2: Redis Credentials
echo -e "${YELLOW}Step 2: Redis Credentials${NC}"
read -p "Enter Redis password (or press Enter to generate): " REDIS_PASSWORD
if [ -z "$REDIS_PASSWORD" ]; then
    REDIS_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password: $REDIS_PASSWORD${NC}"
fi

REDIS_SECRET=$(cat <<EOF
{
  "password": "$REDIS_PASSWORD"
}
EOF
)

create_or_update_secret "civildesk/redis-credentials" "$REDIS_SECRET"
echo ""

# Step 3: JWT Secret
echo -e "${YELLOW}Step 3: JWT Secret${NC}"
read -p "Enter JWT secret (or press Enter to generate): " JWT_SECRET
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(generate_jwt_secret)
    echo -e "${GREEN}Generated JWT secret: $JWT_SECRET${NC}"
fi

create_or_update_secret "civildesk/jwt-secret" "$JWT_SECRET"
echo ""

# Step 4: Email Credentials
echo -e "${YELLOW}Step 4: Email Credentials${NC}"
read -p "Enter SMTP host [smtp.gmail.com]: " MAIL_HOST
MAIL_HOST=${MAIL_HOST:-smtp.gmail.com}

read -p "Enter SMTP port [587]: " MAIL_PORT
MAIL_PORT=${MAIL_PORT:-587}

read -p "Enter email username: " MAIL_USERNAME
read -p "Enter email password/app-password: " MAIL_PASSWORD

MAIL_SECRET=$(cat <<EOF
{
  "host": "$MAIL_HOST",
  "port": "$MAIL_PORT",
  "username": "$MAIL_USERNAME",
  "password": "$MAIL_PASSWORD"
}
EOF
)

create_or_update_secret "civildesk/email-credentials" "$MAIL_SECRET"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Secrets Creation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Important: Save these credentials securely!${NC}"
echo ""
echo "Database Password: $DB_PASSWORD"
echo "Redis Password: $REDIS_PASSWORD"
echo "JWT Secret: $JWT_SECRET"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update RDS instance with the database password"
echo "2. Update ElastiCache with the Redis password"
echo "3. Reference these secrets in your ECS task definitions"

