# Civildesk Backend

Spring Boot backend application for the Civildesk Employee Management System.

## Prerequisites

- Java 17 or higher
- Maven 3.6+
- PostgreSQL 12+
- pgAdmin (optional, for database management)

## Setup Instructions

### 1. Database Setup

Follow the instructions in `database/README.md` to set up PostgreSQL database.

**Quick Setup:**
1. Create a database named `civildesk` in PostgreSQL
2. Create a `.env` file in the root directory (copy from `.env.example`)
3. Update database credentials in `.env` file

### 2. Environment Configuration

Create a `.env` file in the `civildesk-backend/` directory:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=civildesk
DB_USERNAME=postgres
DB_PASSWORD=your_password

JWT_SECRET=your_secret_key_at_least_256_bits
JWT_EXPIRATION=86400000

SERVER_PORT=8080
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081
FACE_SERVICE_URL=http://localhost:8000
```

### 3. Build and Run

```bash
# Build the project
mvn clean install

# Run the application
mvn spring-boot:run
```

Or use your IDE to run `CivildeskBackendApplication.java`

### 4. Verify

- Application should start on `http://localhost:8080`
- Database tables will be created automatically
- Check console logs for successful database connection

## API Endpoints

The API will be available at: `http://localhost:8080/api`

## Configuration

All configuration is loaded from:
1. `.env` file (highest priority)
2. `application.properties` (defaults)

## Troubleshooting

See `database/README.md` for database-related issues.

