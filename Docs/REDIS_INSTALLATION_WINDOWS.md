# Redis Installation Guide for Windows

Redis is not officially supported on Windows, but you have several options to run it on Windows:

## Option 1: Using Docker (Recommended - Easiest) 🐳

Docker is the easiest way to run Redis on Windows.

### Prerequisites:
1. Install Docker Desktop for Windows: https://www.docker.com/products/docker-desktop/

### Steps:
1. **Start Docker Desktop**

2. **Run Redis container:**
   ```powershell
   docker run -d --name redis-server -p 6379:6379 redis:latest
   ```

3. **Verify Redis is running:**
   ```powershell
   docker ps
   ```
   You should see `redis-server` in the list.

4. **Test Redis connection:**
   ```powershell
   docker exec -it redis-server redis-cli ping
   ```
   Should return: `PONG`

5. **To stop Redis:**
   ```powershell
   docker stop redis-server
   ```

6. **To start Redis again:**
   ```powershell
   docker start redis-server
   ```

### Update your `.env` file:
```env
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```

---

## Option 2: Using WSL (Windows Subsystem for Linux) 🐧

If you prefer a native Linux installation:

### Prerequisites:
1. Enable WSL on Windows

### Steps:

1. **Install WSL (if not already installed):**
   ```powershell
   # Run PowerShell as Administrator
   wsl --install
   ```
   Restart your computer if prompted.

2. **Open Ubuntu terminal** (from Start menu)

3. **Update package list:**
   ```bash
   sudo apt-get update
   ```

4. **Install Redis:**
   ```bash
   sudo apt-get install redis-server
   ```

5. **Start Redis:**
   ```bash
   sudo service redis-server start
   ```

6. **Verify installation:**
   ```bash
   redis-cli ping
   ```
   Should return: `PONG`

7. **Configure Redis to start automatically:**
   ```bash
   sudo systemctl enable redis-server
   ```

### Update your `.env` file:
```env
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```

---

## Option 3: Using Memurai (Redis-compatible for Windows) 🪟

Memurai is a Redis-compatible server for Windows.

### Steps:

1. **Download Memurai:**
   - Visit: https://www.memurai.com/get-memurai
   - Download the free Developer Edition

2. **Install Memurai:**
   - Run the installer
   - Follow the installation wizard
   - Memurai will install as a Windows service

3. **Start Memurai:**
   - It should start automatically as a service
   - Or start it from Services (services.msc)

4. **Verify installation:**
   ```powershell
   # Install redis-cli for Windows or use Memurai's tools
   ```

### Update your `.env` file:
```env
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```

---

## Option 4: Use In-Memory Cache (No Installation Required) 💾

If you don't want to install Redis, the application is already configured to use in-memory caching by default.

### Steps:

1. **Ensure Redis is disabled in your `.env` file:**
   ```env
   REDIS_ENABLED=false
   ```

2. **That's it!** The application will use in-memory caching automatically.

**Note:** In-memory cache works fine for development, but:
- Cache is lost when the application restarts
- Not shared between multiple application instances
- Uses application memory (not ideal for production)

---

## Recommended Setup for Development

For local development, **Docker is the easiest option**:

```powershell
# One-time setup
docker run -d --name redis-server -p 6379:6379 redis:latest

# Your .env file
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379
```

---

## Verifying Redis Connection from Your Application

After installing Redis, restart your Spring Boot application. You should see in the logs:

```
Redis connection established successfully at localhost:6379
```

If you see connection errors, check:
1. Redis is running (`docker ps` or `redis-cli ping`)
2. Port 6379 is not blocked by firewall
3. `REDIS_HOST` and `REDIS_PORT` in `.env` are correct

---

## Troubleshooting

### Redis connection failed error:
- Make sure Redis is running
- Check if port 6379 is available: `netstat -an | findstr 6379`
- Verify firewall settings
- Try `REDIS_ENABLED=false` to use in-memory cache instead

### Docker issues:
- Make sure Docker Desktop is running
- Check if port 6379 is already in use
- Try: `docker logs redis-server` to see Redis logs

### WSL issues:
- Make sure WSL is properly installed
- Check Redis service: `sudo service redis-server status`
- Restart Redis: `sudo service redis-server restart`

