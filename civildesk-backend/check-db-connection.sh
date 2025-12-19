#!/bin/bash
# Database Connection Diagnostic Script

echo "=== Database Connection Diagnostics ==="
echo ""

echo "1. Checking if containers are running..."
docker compose ps
echo ""

echo "2. Checking backend environment variables..."
docker exec civildesk-backend env | grep -E "DB_|SPRING_PROFILES_ACTIVE" | sort
echo ""

echo "3. Testing network connectivity from backend to postgres..."
docker exec civildesk-backend ping -c 3 postgres 2>&1 || echo "Ping failed - network issue"
echo ""

echo "4. Testing PostgreSQL port connectivity..."
docker exec civildesk-backend sh -c "timeout 5 bash -c '</dev/tcp/postgres/5432' && echo 'Port 5432 is open' || echo 'Port 5432 is closed'" 2>&1
echo ""

echo "5. Testing database connection with psql (if available)..."
docker exec civildesk-backend sh -c "which psql > /dev/null 2>&1 && echo 'psql found' || echo 'psql not installed (this is OK)'"
echo ""

echo "6. Checking PostgreSQL container status..."
docker exec civildesk-postgres pg_isready -U civildesk_user -d civildesk 2>&1
echo ""

echo "7. Testing direct database connection from postgres container..."
docker exec civildesk-postgres psql -U civildesk_user -d civildesk -c "SELECT version();" 2>&1 | head -3
echo ""

echo "8. Checking database credentials match..."
echo "Postgres container user: $(docker exec civildesk-postgres psql -U postgres -tAc \"SELECT current_user;\")"
echo "Backend trying to connect as: $(docker exec civildesk-backend env | grep DB_USERNAME | cut -d= -f2)"
echo ""

echo "=== Diagnostic Complete ==="
echo ""
echo "If all checks pass, the issue might be:"
echo "- Backend starting before database is fully ready"
echo "- Connection timeout too short"
echo "- HikariCP connection pool configuration"

