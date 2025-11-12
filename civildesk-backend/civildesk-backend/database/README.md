# PostgreSQL Database Setup Guide

This guide will help you set up the PostgreSQL database for Civildesk using pgAdmin.

## Prerequisites

- PostgreSQL installed and running
- pgAdmin installed and accessible
- Admin access to PostgreSQL

## Step-by-Step Setup

### Method 1: Using pgAdmin (GUI)

1. **Open pgAdmin**
   - Launch pgAdmin from your applications
   - Connect to your PostgreSQL server (usually `localhost`)

2. **Create the Database**
   - Right-click on "Databases" in the left sidebar
   - Select "Create" → "Database..."
   - In the "Database" field, enter: `civildesk`
   - Set the owner to `postgres` (or your preferred user)
   - Click "Save"

3. **Verify Database Creation**
   - Expand "Databases" in the left sidebar
   - You should see `civildesk` listed

4. **Create .env File**
   - Navigate to the `civildesk-backend/civildesk-backend/` directory
   - Create a `.env` file (copy from `.env.example` if it exists)
   - Update the database credentials:

   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=civildesk
   DB_USERNAME=postgres
   DB_PASSWORD=your_postgres_password
   ```

5. **Configure Connection**
   - Update the `.env` file with your PostgreSQL credentials
   - Make sure the password matches your PostgreSQL server password

### Method 2: Using SQL Script

1. **Open pgAdmin Query Tool**
   - In pgAdmin, click on "Tools" → "Query Tool"
   - Or right-click on your server → "Query Tool"

2. **Run the Setup Script**
   - Open the `database/setup.sql` file
   - Copy and paste the contents into the Query Tool
   - Execute the script (F5 or click the Execute button)

3. **Verify**
   - Check that the `civildesk` database appears in the database list

### Method 3: Using psql Command Line

1. **Open Command Prompt/Terminal**
   - Navigate to your PostgreSQL bin directory (if needed)

2. **Connect to PostgreSQL**
   ```bash
   psql -U postgres
   ```

3. **Create Database**
   ```sql
   CREATE DATABASE civildesk;
   ```

4. **Verify**
   ```sql
   \l
   ```
   - You should see `civildesk` in the list

5. **Exit psql**
   ```sql
   \q
   ```

## Environment Variables (.env file)

Create a `.env` file in the `civildesk-backend/civildesk-backend/` directory with the following content:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=civildesk
DB_USERNAME=postgres
DB_PASSWORD=your_actual_password_here

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_at_least_256_bits_long
JWT_EXPIRATION=86400000

# Server Configuration
SERVER_PORT=8080

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081

# Face Recognition Service
FACE_SERVICE_URL=http://localhost:8000
```

**Important:** Replace `your_actual_password_here` with your actual PostgreSQL password.

## Auto Table Creation

The Spring Boot application will automatically create all necessary tables when you run it for the first time. This is configured via:

```properties
spring.jpa.hibernate.ddl-auto=update
```

This means:
- Tables will be created automatically if they don't exist
- Tables will be updated if schema changes are detected
- **No manual table creation needed!**

## Troubleshooting

### Connection Refused
- Make sure PostgreSQL service is running
- Check if the port (5432) is correct
- Verify firewall settings

### Authentication Failed
- Double-check username and password in `.env` file
- Verify PostgreSQL authentication settings in `pg_hba.conf`

### Database Already Exists
- That's fine! The application will use the existing database
- Tables will be created/updated automatically

### Permission Denied
- Make sure the database user has proper permissions
- Try connecting as `postgres` superuser first

## Next Steps

After setting up the database:

1. Verify `.env` file is in the correct location
2. Start the Spring Boot application
3. Check the console logs for database connection messages
4. Tables will be created automatically on first run

## Testing Connection

You can test the database connection by:

1. Starting the Spring Boot application
2. Checking the console for successful connection messages
3. Looking for: `Hibernate: create table...` messages (if `show-sql=true`)

