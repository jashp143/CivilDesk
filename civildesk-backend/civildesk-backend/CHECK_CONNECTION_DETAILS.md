# How to Find Your PostgreSQL Connection Details in pgAdmin

Since you've created a server named "civildesk" in pgAdmin, follow these steps to get the connection details:

## Step 1: View Server Properties

1. **In pgAdmin**, right-click on the server named **"civildesk"** in the left sidebar
2. Select **"Properties"** from the context menu
3. Click on the **"Connection"** tab

## Step 2: Note Down the Connection Details

You'll see these fields - note them down:

- **Host name/address:** Usually `localhost` or `127.0.0.1`
- **Port:** Usually `5432` (default PostgreSQL port)
- **Maintenance database:** Usually `postgres`
- **Username:** Usually `postgres` or your custom username
- **Password:** The password you set (you'll need to enter it)

## Step 3: Update .env File

Once you have these details, update your `.env` file in `civildesk-backend/civildesk-backend/.env`:

```env
DB_HOST=localhost          # From "Host name/address"
DB_PORT=5432              # From "Port"
DB_NAME=civildesk         # Your database name (you already created this)
DB_USERNAME=postgres      # From "Username"
DB_PASSWORD=your_password # Your actual password
```

## Common Scenarios

### Scenario 1: Local PostgreSQL (Most Common)
If your server is running on the same machine:
```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
```

### Scenario 2: Different Port
If PostgreSQL is running on a different port (e.g., 5433):
```env
DB_HOST=localhost
DB_PORT=5433
```

### Scenario 3: Different Username
If you created a custom user:
```env
DB_USERNAME=your_custom_username
```

## Quick Test

After updating the `.env` file, you can test the connection:

1. In pgAdmin, try connecting to the "civildesk" server
2. If it connects successfully, use those same credentials in `.env`
3. The database name should be `civildesk` (which you already created)

## Verification Checklist

- ✅ Server "civildesk" exists in pgAdmin
- ✅ Database "civildesk" exists inside that server
- ✅ You can connect to the server in pgAdmin
- ✅ You know the connection password
- ✅ `.env` file is updated with correct values

## Next Step

After updating the `.env` file with the correct connection details, you can run the Spring Boot application and it will automatically:
- Connect to the database
- Create all necessary tables
- Be ready to use!

