# Fixing .env File Issues

## Current Problem

Your `.env` file has malformed content that's preventing it from loading properly. The error message shows:
```
Could not load .env file: Malformed entry "type": "service_account",
```

This indicates that JSON content (likely from a Firebase service account) was accidentally pasted into the `.env` file.

## Solution

### Step 1: Locate your .env file
The `.env` file should be located at:
```
civildesk-backend/civildesk-backend/.env
```

### Step 2: Fix the .env file format
Replace the entire contents of your `.env` file with the following (update the password with your actual PostgreSQL password):

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=civildesk
DB_USERNAME=postgres
DB_PASSWORD=your_actual_postgres_password_here

# JWT Configuration
JWT_SECRET=mySecretKeyForJWTTokenGenerationMustBeAtLeast256BitsLong
JWT_EXPIRATION=86400000
JWT_REFRESH_EXPIRATION=1296000000

# Server Configuration
SERVER_PORT=8080

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081

# Face Recognition Service
FACE_SERVICE_URL=http://localhost:8000

# Email Configuration (Optional)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_FROM=noreply@civildesk.com
EMAIL_ENABLED=true

# Redis Configuration (Optional)
REDIS_ENABLED=false
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Firebase Configuration
# DO NOT paste JSON directly into this file!
# Option 1: Set FIREBASE_CREDENTIALS_JSON with the full JSON as a single line (escaped)
# Option 2: Place firebase-service-account.json in src/main/resources/
FIREBASE_CREDENTIALS_JSON=
FIREBASE_CREDENTIALS_FILE=firebase-service-account.json
```

### Step 3: Important Notes

1. **Database Password**: Replace `your_actual_postgres_password_here` with your actual PostgreSQL password for the `postgres` user.

2. **Firebase Credentials**: 
   - **DO NOT** paste the Firebase service account JSON directly into the `.env` file
   - Instead, either:
     - Place the JSON file at `src/main/resources/firebase-service-account.json`, OR
     - Set `FIREBASE_CREDENTIALS_JSON` as a single-line escaped JSON string

3. **File Format**: 
   - Each line should be in the format: `KEY=value`
   - No quotes around values (unless the value itself contains spaces)
   - No JSON syntax (no curly braces, colons, commas)
   - Comments start with `#`

### Step 4: Verify
After fixing the `.env` file, restart your Spring Boot application. You should see:
- No more "Malformed entry" warnings
- Successful database connection
- Application starting on port 8080

## Finding Your PostgreSQL Password

If you don't know your PostgreSQL password:

1. **Windows**: Check if you set it during PostgreSQL installation
2. **Reset password**: 
   ```sql
   -- Connect as postgres user (may require admin access)
   ALTER USER postgres WITH PASSWORD 'your_new_password';
   ```
3. **Check pg_hba.conf**: Make sure password authentication is enabled

## Still Having Issues?

If you continue to have problems:
1. Verify PostgreSQL is running: `psql -U postgres -h localhost`
2. Check that the database `civildesk` exists
3. Verify the password works by connecting manually
4. Check the application logs for more detailed error messages

