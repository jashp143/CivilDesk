# Installing pg_cron Extension

This guide explains how to install and configure the `pg_cron` extension for automated database maintenance tasks.

## What is pg_cron?

`pg_cron` is a PostgreSQL extension that allows you to schedule jobs (like VACUUM, ANALYZE, or custom functions) directly from within PostgreSQL, without needing external cron jobs.

## Installation Methods

### Method 1: Linux (Ubuntu/Debian)

#### Step 1: Install PostgreSQL and pg_cron package

```bash
# For PostgreSQL 15
sudo apt-get update
sudo apt-get install postgresql-15-cron

# For PostgreSQL 14
sudo apt-get install postgresql-14-cron

# For PostgreSQL 13
sudo apt-get install postgresql-13-cron

# Check your PostgreSQL version first:
psql --version
```

#### Step 2: Configure PostgreSQL

Edit `postgresql.conf` (usually located at `/etc/postgresql/[version]/main/postgresql.conf`):

```bash
sudo nano /etc/postgresql/15/main/postgresql.conf
```

Add or modify these lines:

```conf
# Add pg_cron to shared_preload_libraries
shared_preload_libraries = 'pg_cron'

# Specify the database where cron jobs will be stored
cron.database_name = 'civildesk'
```

**Note:** If `shared_preload_libraries` already has other extensions, separate them with commas:
```conf
shared_preload_libraries = 'pg_stat_statements,pg_cron'
```

#### Step 3: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
# or
sudo service postgresql restart
```

#### Step 4: Enable the extension in your database

Connect to PostgreSQL as superuser:

```bash
sudo -u postgres psql -d civildesk
```

Then run:

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

Verify installation:

```sql
SELECT * FROM pg_extension WHERE extname = 'pg_cron';
```

---

### Method 2: Linux (RHEL/CentOS/Fedora)

#### Step 1: Install from PostgreSQL YUM repository

```bash
# For PostgreSQL 15
sudo yum install pg_cron_15

# For PostgreSQL 14
sudo yum install pg_cron_14
```

#### Step 2-4: Same as Ubuntu (configure postgresql.conf, restart, enable extension)

---

### Method 3: Docker/Container

If you're using Docker, you need to:

#### Step 1: Use a PostgreSQL image with pg_cron

Option A: Use official PostgreSQL image and install manually:

```dockerfile
FROM postgres:15

# Install pg_cron
RUN apt-get update && \
    apt-get install -y postgresql-15-cron && \
    rm -rf /var/lib/apt/lists/*

# Add to postgresql.conf
RUN echo "shared_preload_libraries = 'pg_cron'" >> /usr/share/postgresql/postgresql.conf.sample && \
    echo "cron.database_name = 'civildesk'" >> /usr/share/postgresql/postgresql.conf.sample
```

Option B: Use a pre-built image with pg_cron:

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: civildesk
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: yourpassword
    volumes:
      - ./postgresql.conf:/etc/postgresql/postgresql.conf
      - postgres_data:/var/lib/postgresql/data
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

Create `postgresql.conf`:

```conf
shared_preload_libraries = 'pg_cron'
cron.database_name = 'civildesk'
```

#### Step 2: Enable extension after container starts

```bash
docker exec -it <container_name> psql -U postgres -d civildesk -c "CREATE EXTENSION IF NOT EXISTS pg_cron;"
```

---

### Method 4: Windows

**Note:** pg_cron is primarily designed for Linux/Unix systems. On Windows, you have two options:

#### Option A: Use WSL (Windows Subsystem for Linux)

1. Install WSL and PostgreSQL in WSL
2. Follow Linux installation instructions above

#### Option B: Use system Task Scheduler (Recommended for Windows)

Since pg_cron may not work reliably on Windows, use Windows Task Scheduler instead:

1. Open Task Scheduler (`taskschd.msc`)
2. Create a new task
3. Set trigger (e.g., daily at 3 AM)
4. Set action: `psql.exe -U postgres -d civildesk -c "SELECT archive_old_data();"`

Or use the system cron alternative documented in the migration files.

---

### Method 5: Compile from Source

If packages aren't available for your system:

```bash
# Clone the repository
git clone https://github.com/citusdata/pg_cron.git
cd pg_cron

# Build and install
make
sudo make install

# Then configure postgresql.conf and restart PostgreSQL
```

---

## Verification

After installation, verify it's working:

```sql
-- Check if extension is installed
SELECT * FROM pg_extension WHERE extname = 'pg_cron';

-- View all scheduled jobs
SELECT * FROM cron.job;

-- Test by scheduling a simple job
SELECT cron.schedule('test-job', '0 12 * * *', 'SELECT NOW()');

-- View job execution history
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
```

---

## Troubleshooting

### Error: "pg_cron extension not found"

1. **Check if package is installed:**
   ```bash
   dpkg -l | grep pg_cron  # Ubuntu/Debian
   rpm -qa | grep pg_cron  # RHEL/CentOS
   ```

2. **Check PostgreSQL version compatibility:**
   ```bash
   psql --version
   ```
   Make sure you installed the matching version (e.g., `postgresql-15-cron` for PostgreSQL 15)

3. **Verify shared_preload_libraries:**
   ```sql
   SHOW shared_preload_libraries;
   ```
   Should include `pg_cron`

### Error: "cron schema does not exist"

The extension wasn't created. Run:
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

### Jobs not running

1. **Check if cron background worker is running:**
   ```sql
   SELECT * FROM pg_stat_activity WHERE application_name = 'pg_cron';
   ```

2. **Check job run details:**
   ```sql
   SELECT * FROM cron.job_run_details 
   WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'your-job-name')
   ORDER BY start_time DESC;
   ```

3. **Check PostgreSQL logs:**
   ```bash
   tail -f /var/log/postgresql/postgresql-15-main.log
   ```

### Permission Issues

pg_cron requires superuser privileges to:
- Create the extension
- Schedule jobs
- Run jobs (jobs run with the privileges of the user who scheduled them)

---

## Alternative: System Cron (If pg_cron Not Available)

If you can't install pg_cron, use system cron instead. See the comments in:
- `setup_data_archival.sql` (lines 311-323)
- `setup_vacuum_schedule.sql` (lines 172-190)

Example crontab entry:

```bash
# Edit crontab
crontab -e

# Add these lines:
# Monthly archival - 1st of month at 4 AM
0 4 1 * * psql -U postgres -d civildesk -c "SELECT archive_old_data();"

# Weekly VACUUM ANALYZE - Sunday 2 AM
0 2 * * 0 psql -U postgres -d civildesk -c "VACUUM ANALYZE attendance, gps_attendance_logs, employees, tasks, leaves, expenses, overtimes;"
```

---

## Security Considerations

1. **Database Access:** pg_cron jobs run with the privileges of the user who scheduled them. Use a dedicated user with minimal privileges for scheduled jobs.

2. **Network Access:** If using remote PostgreSQL, ensure proper authentication.

3. **Logging:** Monitor cron job execution logs regularly.

---

## Next Steps

After installing pg_cron:

1. Re-run the migration files:
   ```bash
   psql -U postgres -d civildesk -f setup_data_archival.sql
   psql -U postgres -d civildesk -f setup_vacuum_schedule.sql
   ```

2. Verify jobs are scheduled:
   ```sql
   SELECT * FROM cron.job;
   ```

3. Monitor job execution:
   ```sql
   SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;
   ```

---

## References

- Official pg_cron GitHub: https://github.com/citusdata/pg_cron
- PostgreSQL Extensions: https://www.postgresql.org/docs/current/contrib.html

