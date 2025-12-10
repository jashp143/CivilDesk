-- =============================================================================
-- VACUUM AND MAINTENANCE SCHEDULE
-- Civildesk Employee Management System
-- Phase 3 Optimization - Database Maintenance
-- Generated: December 2025
-- =============================================================================
-- 
-- PREREQUISITES:
-- 1. Enable pg_cron extension (requires superuser):
--    CREATE EXTENSION IF NOT EXISTS pg_cron;
--
-- 2. In postgresql.conf, add:
--    shared_preload_libraries = 'pg_cron'
--    cron.database_name = 'civildesk'
--
-- 3. Restart PostgreSQL after configuration changes
--
-- Expected improvement: Maintain consistent performance over time
-- =============================================================================

-- =============================================================================
-- ENABLE REQUIRED EXTENSIONS
-- =============================================================================

-- Enable pg_cron for scheduled jobs (requires superuser)
-- Run this as superuser:
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- =============================================================================
-- SCHEDULED VACUUM JOBS
-- =============================================================================

-- Schedule VACUUM jobs (only if pg_cron is available)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Weekly VACUUM ANALYZE for all frequently updated tables
        -- Runs every Sunday at 2 AM (low traffic time)
        IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'weekly-vacuum-analyze') THEN
            PERFORM cron.schedule(
                'weekly-vacuum-analyze',
                '0 2 * * 0',  -- Every Sunday at 2 AM
                $sql$VACUUM ANALYZE 
                    attendance, 
                    gps_attendance_logs, 
                    employees, 
                    tasks, 
                    task_assignments,
                    leaves, 
                    expenses, 
                    overtimes$sql$
            );
            RAISE NOTICE 'Scheduled weekly VACUUM ANALYZE job';
        END IF;
        
        -- Daily ANALYZE for frequently updated tables
        -- Runs every day at 3 AM
        IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'daily-analyze') THEN
            PERFORM cron.schedule(
                'daily-analyze',
                '0 3 * * *',  -- Every day at 3 AM
                $sql$ANALYZE 
                    attendance, 
                    gps_attendance_logs,
                    leaves,
                    tasks$sql$
            );
            RAISE NOTICE 'Scheduled daily ANALYZE job';
        END IF;
        
        -- Monthly VACUUM FULL for large tables
        -- Runs on the first day of each month at 1 AM
        -- WARNING: This locks tables during operation
        IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'monthly-vacuum-full') THEN
            PERFORM cron.schedule(
                'monthly-vacuum-full',
                '0 1 1 * *',  -- First day of month at 1 AM
                $sql$VACUUM FULL VERBOSE attendance$sql$
            );
            RAISE NOTICE 'Scheduled monthly VACUUM FULL job';
        END IF;
        
        -- Monthly VACUUM FULL for GPS logs (separate job to avoid long locks)
        IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'monthly-vacuum-full-gps') THEN
            PERFORM cron.schedule(
                'monthly-vacuum-full-gps',
                '0 1 2 * *',  -- Second day of month at 1 AM
                $sql$VACUUM FULL VERBOSE gps_attendance_logs$sql$
            );
            RAISE NOTICE 'Scheduled monthly VACUUM FULL GPS job';
        END IF;
    ELSE
        RAISE NOTICE 'pg_cron extension not available. Use system cron instead (see comments below)';
    END IF;
END $$;

-- =============================================================================
-- VERIFY SCHEDULED JOBS
-- =============================================================================

-- View all scheduled jobs
SELECT * FROM cron.job;

-- View job execution history
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;

-- =============================================================================
-- MANUAL MAINTENANCE COMMANDS
-- Run these periodically or when performance degrades
-- =============================================================================

-- Check table bloat (run to identify tables needing VACUUM)
/*
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                   pg_relation_size(schemaname||'.'||tablename)) AS bloat_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
*/

-- Check last vacuum/analyze times
/*
SELECT 
    schemaname,
    relname,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    n_dead_tup,
    n_live_tup
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;
*/

-- Manual VACUUM ANALYZE (run if performance degrades)
-- VACUUM ANALYZE attendance;
-- VACUUM ANALYZE gps_attendance_logs;
-- VACUUM ANALYZE employees;

-- Full VACUUM (run during maintenance window - locks table)
-- VACUUM FULL VERBOSE attendance;

-- Reindex tables (run if indexes become bloated)
-- REINDEX TABLE attendance;
-- REINDEX TABLE employees;

-- =============================================================================
-- REMOVE SCHEDULED JOBS (if needed)
-- =============================================================================

-- To remove a scheduled job:
-- SELECT cron.unschedule('weekly-vacuum-analyze');
-- SELECT cron.unschedule('daily-analyze');
-- SELECT cron.unschedule('monthly-vacuum-full');
-- SELECT cron.unschedule('monthly-vacuum-full-gps');

-- =============================================================================
-- AUTOVACUUM CONFIGURATION (for postgresql.conf)
-- =============================================================================

/*
Add to postgresql.conf for better autovacuum behavior:

# Enable autovacuum
autovacuum = on

# Run autovacuum more frequently
autovacuum_naptime = 60
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
autovacuum_vacuum_scale_factor = 0.1
autovacuum_analyze_scale_factor = 0.05

# Allow more autovacuum workers for parallel processing
autovacuum_max_workers = 3

# Memory for autovacuum operations
autovacuum_work_mem = 256MB
*/

-- =============================================================================
-- ALTERNATIVE: WITHOUT pg_cron (using system cron)
-- =============================================================================

/*
If pg_cron is not available, use system cron instead.
Add these to crontab (crontab -e):

# Weekly VACUUM ANALYZE - Sunday 2 AM
0 2 * * 0 psql -U postgres -d civildesk -c "VACUUM ANALYZE attendance, gps_attendance_logs, employees, tasks, leaves, expenses, overtimes;"

# Daily ANALYZE - 3 AM
0 3 * * * psql -U postgres -d civildesk -c "ANALYZE attendance, gps_attendance_logs, leaves, tasks;"

# Monthly VACUUM FULL - 1st of month 1 AM
0 1 1 * * psql -U postgres -d civildesk -c "VACUUM FULL attendance;"

# Monthly VACUUM FULL GPS logs - 2nd of month 1 AM  
0 1 2 * * psql -U postgres -d civildesk -c "VACUUM FULL gps_attendance_logs;"
*/

