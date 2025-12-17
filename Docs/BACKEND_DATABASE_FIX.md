# Backend Database Schema Fix

## Problem
The backend is failing to start with error:
```
Schema-validation: missing table [attendance]
```

## Root Cause
The production profile (`application-prod.properties`) has:
```properties
spring.jpa.hibernate.ddl-auto=validate
```

This setting tells Hibernate to **validate** that the database schema matches the entities, but **NOT** to create or update tables. Since your database is empty or missing tables, validation fails.

## Solution Applied

I've updated `application-prod.properties` to use `update` instead of `validate`:
```properties
spring.jpa.hibernate.ddl-auto=update
```

This will automatically create/update database tables based on your JPA entities when the backend starts.

## Next Steps

### Option 1: Rebuild and Restart (Recommended for Fresh Deployment)

On your server:

```bash
cd /opt/civildesk/civildesk-backend

# Rebuild the backend with the updated configuration
docker compose build backend

# Restart the backend
docker compose restart backend

# Or restart all services
docker compose restart
```

The backend should now start successfully and create all required tables automatically.

### Option 2: Run Database Migrations Manually (If You Have SQL Scripts)

If you prefer to use SQL migration scripts instead:

1. **Change back to validate** (after tables are created):
   ```properties
   spring.jpa.hibernate.ddl-auto=validate
   ```

2. **Run your migration scripts**:
   ```bash
   # Copy migration file to postgres container
   docker cp database/setup.sql civildesk-postgres:/tmp/setup.sql
   
   # Execute migrations
   docker exec -i civildesk-postgres psql -U civildesk_user -d civildesk < /tmp/setup.sql
   ```

3. **Restart backend**:
   ```bash
   docker compose restart backend
   ```

### Option 3: Use Docker Volume Mount for Initial Setup

If you have a `setup.sql` file, you can mount it to run automatically on first database start:

1. **Uncomment the volume mount** in `docker-compose.yml`:
   ```yaml
   postgres:
     volumes:
       - postgres_data:/var/lib/postgresql/data
       - ./civildesk-backend/database/setup.sql:/docker-entrypoint-initdb.d/01-setup.sql:ro
   ```

2. **Remove the existing postgres volume** (WARNING: This deletes all data):
   ```bash
   docker compose down -v
   docker compose up -d
   ```

## Verify the Fix

After restarting, check the logs:

```bash
docker compose logs backend -f
```

You should see:
- ✅ Application started successfully
- ✅ No schema validation errors
- ✅ Tables created automatically

Test the health endpoint:
```bash
curl http://localhost:8080/api/health
```

Or from your frontend URL:
```bash
curl https://civildesk-api.devopsinfos.live/api/health
```

## After Tables Are Created

Once your database has all the tables, you can optionally change back to `validate` for stricter schema validation:

1. **Edit** `application-prod.properties`:
   ```properties
   spring.jpa.hibernate.ddl-auto=validate
   ```

2. **Rebuild and restart**:
   ```bash
   docker compose build backend
   docker compose restart backend
   ```

**Note**: Using `validate` is safer in production as it prevents accidental schema changes, but requires manual migrations for schema updates.

## Current Configuration

- **ddl-auto**: `update` (will create/update tables automatically)
- **show-sql**: `false` (disabled in production for performance)
- **Database**: PostgreSQL (running in Docker)

## Tables That Will Be Created

Hibernate will automatically create these tables based on your entities:
- `users`
- `employees`
- `attendance`
- `gps_attendance_log`
- `leave_requests`
- `salary`
- And any other JPA entities in your application

## Troubleshooting

If you still see errors:

1. **Check database connection**:
   ```bash
   docker exec -it civildesk-postgres psql -U civildesk_user -d civildesk -c "\dt"
   ```
   This lists all tables. If empty, the backend hasn't created them yet.

2. **Check backend logs**:
   ```bash
   docker compose logs backend --tail=100
   ```

3. **Verify database credentials** in `.env` file match docker-compose.yml

4. **Check if postgres is healthy**:
   ```bash
   docker compose ps
   ```

## Summary

✅ **Fixed**: Changed `ddl-auto` from `validate` to `update` in production profile
✅ **Action Required**: Rebuild and restart the backend container
✅ **Result**: Tables will be created automatically on startup

