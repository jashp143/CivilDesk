# PostgreSQL Database Setup Guide for Civildesk

This guide will walk you through setting up the PostgreSQL database using pgAdmin.

## Quick Setup (3 Steps)

### Step 1: Create Database in pgAdmin

1. **Open pgAdmin**
   - Launch pgAdmin from your Start Menu or desktop shortcut
   - Enter your master password when prompted

2. **Connect to Server**
   - In the left sidebar, expand "Servers"
   - Click on your PostgreSQL server (usually "PostgreSQL 15" or similar)
   - Enter your PostgreSQL password if prompted

3. **Create Database**
   - Right-click on "Databases" in the left sidebar
   - Select **"Create"** → **"Database..."**
   - In the "General" tab:
     - **Database name:** `civildesk`
   - In the "Security" tab (optional):
     - **Owner:** `postgres` (or leave default)
   - Click **"Save"** button

4. **Verify**
   - Expand "Databases" in the left sidebar
   - You should see `civildesk` database listed ✅

### Step 2: Create .env File

1. **Navigate to Backend Directory**
   - Go to: `civildesk-backend/civildesk-backend/`

2. **Create .env File**
   - Create a new file named `.env` (note the dot at the beginning)
   - If you're using Windows, you might need to:
     - Open Command Prompt in that directory
     - Run: `type nul > .env`
     - Or use a text editor like VS Code or Notepad++

3. **Add Configuration**
   Copy and paste this into your `.env` file:

   ```env
   # Database Configuration
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=civildesk
   DB_USERNAME=postgres
   DB_PASSWORD=your_postgres_password_here
   
   # JWT Configuration
   JWT_SECRET=mySecretKeyForJWTTokenGenerationMustBeAtLeast256BitsLongForSecurity
   JWT_EXPIRATION=86400000
   
   # Server Configuration
   SERVER_PORT=8080
   
   # CORS Configuration
   CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081
   
   # Face Recognition Service
   FACE_SERVICE_URL=http://localhost:8000
   ```

4. **Update Password**
   - Replace `your_postgres_password_here` with your actual PostgreSQL password
   - This is the password you set when installing PostgreSQL

### Step 3: Verify Setup

1. **Test Database Connection**
   - In pgAdmin, right-click on `civildesk` database
   - Select **"Query Tool"**
   - Run: `SELECT version();`
   - You should see PostgreSQL version information

2. **Check .env File Location**
   - Make sure `.env` file is in: `civildesk-backend/civildesk-backend/.env`
   - The file should be at the same level as `pom.xml`

## Alternative: Using SQL Query Tool

If you prefer using SQL:

1. **Open Query Tool**
   - In pgAdmin, click on "Tools" → "Query Tool"
   - Or right-click on your server → "Query Tool"

2. **Run SQL Command**
   ```sql
   CREATE DATABASE civildesk;
   ```

3. **Verify**
   ```sql
   \l
   ```
   - You should see `civildesk` in the list

## Important Notes

### About Password
- The password in `.env` file must match your PostgreSQL server password
- If you forgot your password, you may need to reset it or check PostgreSQL documentation

### Auto Table Creation
- **You don't need to create tables manually!**
- When you run the Spring Boot application, it will automatically create all tables
- This is configured via `spring.jpa.hibernate.ddl-auto=update`

### File Location
```
civildesk-backend/
└── civildesk-backend/
    ├── .env              ← Create this file here
    ├── pom.xml
    └── src/
```

## Troubleshooting

### "Connection Refused" Error
- **Solution:** Make sure PostgreSQL service is running
  - Windows: Open Services, find "postgresql-x64-XX", start if stopped
  - Check if port 5432 is available

### "Authentication Failed" Error
- **Solution:** 
  - Double-check password in `.env` file
  - Verify username is `postgres` (or your actual username)
  - Make sure you can connect to PostgreSQL in pgAdmin

### "Database Does Not Exist" Error
- **Solution:** 
  - Make sure you created the database named exactly `civildesk`
  - Check database name spelling in `.env` file

### ".env File Not Found" Warning
- **Solution:**
  - Verify file is named `.env` (with dot, not `env`)
  - Check file location (should be in `civildesk-backend/civildesk-backend/`)
  - Make sure file is not hidden (Windows may hide files starting with dot)

## Next Steps

After completing the setup:

1. ✅ Database `civildesk` created
2. ✅ `.env` file created with correct credentials
3. 🚀 Run the Spring Boot application
4. 📊 Tables will be created automatically on first run

## Testing the Connection

When you run the Spring Boot application:

1. Look for these log messages:
   ```
   HikariPool-1 - Starting...
   HikariPool-1 - Start completed.
   ```

2. If you see connection errors, check:
   - Database name in `.env`
   - Password in `.env`
   - PostgreSQL service is running

3. On successful connection, you'll see:
   ```
   Hibernate: create table ...
   ```
   (Tables being created automatically)

## Visual Guide (pgAdmin)

```
pgAdmin
└── Servers
    └── PostgreSQL 15 (or your version)
        └── Databases
            ├── postgres (default)
            ├── template0
            ├── template1
            └── civildesk ← You create this!
```

## Need Help?

- Check PostgreSQL is running: `services.msc` (Windows) → find PostgreSQL service
- Test connection: In pgAdmin, try connecting to the server
- Check logs: Spring Boot console will show connection errors
- Verify credentials: Try connecting manually in pgAdmin first

