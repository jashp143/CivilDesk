# Docker Deployment Guide for Civildesk Backend

This guide provides quick reference for deploying the backend using Docker Compose.

## Quick Start

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

2. **Start all services:**
   ```bash
   docker compose up -d --build
   ```

3. **Check status:**
   ```bash
   docker compose ps
   docker compose logs -f
   ```

## Environment Variables

Create a `.env` file in the `civildesk-backend` directory with the following variables:

```env
DB_NAME=civildesk
DB_USERNAME=civildesk_user
DB_PASSWORD=your_secure_password
JWT_SECRET=your_jwt_secret_key
REDIS_PASSWORD=your_redis_password
# ... see deployment guide for full list
```

## Important Notes

1. **Database Migrations**: SQL files in `database/setup.sql` will run automatically on first start if mounted to `/docker-entrypoint-initdb.d/`

2. **Redis Healthcheck**: The Redis healthcheck may need adjustment if you use a strong password. You can modify it in `docker-compose.yml` if needed.

3. **Volume Persistence**: Data is stored in Docker volumes:
   - `postgres_data`: Database data
   - `redis_data`: Redis data
   - `uploads_data`: File uploads

4. **Network**: All services communicate on the `civildesk-network` bridge network.

## Common Commands

```bash
# View logs
docker compose logs -f [service_name]

# Restart a service
docker compose restart backend

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v

# Execute commands in containers
docker exec -it civildesk-backend sh
docker exec -it civildesk-postgres psql -U civildesk_user -d civildesk
```

## Troubleshooting

- **Backend won't start**: Check logs with `docker compose logs backend`
- **Database connection issues**: Verify postgres container is healthy with `docker compose ps`
- **Port conflicts**: Change port mappings in `docker-compose.yml` if ports are already in use

