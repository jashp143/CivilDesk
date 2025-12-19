#!/bin/bash
# Test database connection with different passwords

echo "=== Testing Database Connection ==="
echo ""

# Test 1: Try connecting with default password "change_me"
echo "1. Testing with password 'change_me'..."
PGPASSWORD=change_me docker exec -i civildesk-postgres psql -U civildesk_user -d civildesk -c "SELECT 'Connection successful!' as status;" 2>&1

echo ""
echo "2. Testing connection from backend container network..."
docker exec civildesk-backend sh -c "timeout 3 bash -c 'cat < /dev/null > /dev/tcp/postgres/5432' 2>&1 && echo 'Port 5432 is accessible' || echo 'Port 5432 is NOT accessible'"

echo ""
echo "3. Checking if backend can resolve 'postgres' hostname..."
docker exec civildesk-backend getent hosts postgres 2>&1 || echo "Cannot resolve 'postgres' hostname"

echo ""
echo "=== Test Complete ==="

