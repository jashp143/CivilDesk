-- =============================================================================
-- DATA ARCHIVAL STRATEGY
-- Civildesk Employee Management System
-- Phase 4 Optimization - Long-term Database Management
-- Generated: December 2025
-- =============================================================================
--
-- PURPOSE:
-- Archive old data to control database growth and maintain performance.
-- Archival Policy:
-- - Attendance: Archive after 2 years
-- - GPS logs: Archive after 1 year
-- - Salary slips: Archive after 5 years
-- - Keep active data: Last 2 years
--
-- Expected improvement: 60% reduction in active database size
-- =============================================================================

-- =============================================================================
-- STEP 1: CREATE ARCHIVAL TABLES
-- =============================================================================

-- Attendance archive table
CREATE TABLE IF NOT EXISTS attendance_archive (
    LIKE attendance INCLUDING ALL
);

-- GPS attendance logs archive
CREATE TABLE IF NOT EXISTS gps_attendance_logs_archive (
    LIKE gps_attendance_logs INCLUDING ALL
);

-- Salary slips archive (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'salary_slips') THEN
        CREATE TABLE IF NOT EXISTS salary_slips_archive (
            LIKE salary_slips INCLUDING ALL
        );
    END IF;
END $$;

-- =============================================================================
-- STEP 2: CREATE ARCHIVAL FUNCTION
-- =============================================================================

CREATE OR REPLACE FUNCTION archive_old_data()
RETURNS TABLE(
    archived_attendance bigint,
    archived_gps_logs bigint,
    archived_salary_slips bigint
) AS $$
DECLARE
    attendance_count bigint := 0;
    gps_logs_count bigint := 0;
    salary_slips_count bigint := 0;
BEGIN
    -- Archive attendance older than 2 years
    INSERT INTO attendance_archive
    SELECT * FROM attendance
    WHERE date < CURRENT_DATE - INTERVAL '2 years'
      AND deleted = false
      AND id NOT IN (SELECT id FROM attendance_archive);
    
    GET DIAGNOSTICS attendance_count = ROW_COUNT;
    
    -- Delete archived attendance records
    DELETE FROM attendance
    WHERE date < CURRENT_DATE - INTERVAL '2 years'
      AND deleted = false
      AND id IN (SELECT id FROM attendance_archive);
    
    -- Archive GPS logs older than 1 year
    INSERT INTO gps_attendance_logs_archive
    SELECT * FROM gps_attendance_logs
    WHERE punch_time < CURRENT_DATE - INTERVAL '1 year'
      AND deleted = false
      AND id NOT IN (SELECT id FROM gps_attendance_logs_archive);
    
    GET DIAGNOSTICS gps_logs_count = ROW_COUNT;
    
    -- Delete archived GPS logs
    DELETE FROM gps_attendance_logs
    WHERE punch_time < CURRENT_DATE - INTERVAL '1 year'
      AND deleted = false
      AND id IN (SELECT id FROM gps_attendance_logs_archive);
    
    -- Archive salary slips older than 5 years (if table exists)
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'salary_slips') THEN
        INSERT INTO salary_slips_archive
        SELECT * FROM salary_slips
        WHERE year < EXTRACT(YEAR FROM CURRENT_DATE) - 5
          AND deleted = false
          AND id NOT IN (SELECT id FROM salary_slips_archive);
        
        GET DIAGNOSTICS salary_slips_count = ROW_COUNT;
        
        -- Delete archived salary slips
        DELETE FROM salary_slips
        WHERE year < EXTRACT(YEAR FROM CURRENT_DATE) - 5
          AND deleted = false
          AND id IN (SELECT id FROM salary_slips_archive);
    END IF;
    
    -- Return counts
    RETURN QUERY SELECT attendance_count, gps_logs_count, salary_slips_count;
    
    RAISE NOTICE 'Archival completed: % attendance, % GPS logs, % salary slips archived',
        attendance_count, gps_logs_count, salary_slips_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- STEP 3: CREATE RESTORE FUNCTION (for data recovery)
-- =============================================================================

CREATE OR REPLACE FUNCTION restore_archived_data(
    table_name text,
    start_date date,
    end_date date
) RETURNS bigint AS $$
DECLARE
    restored_count bigint := 0;
BEGIN
    IF table_name = 'attendance' THEN
        INSERT INTO attendance
        SELECT * FROM attendance_archive
        WHERE date >= start_date AND date <= end_date
          AND id NOT IN (SELECT id FROM attendance WHERE deleted = false);
        
        GET DIAGNOSTICS restored_count = ROW_COUNT;
        
    ELSIF table_name = 'gps_attendance_logs' THEN
        INSERT INTO gps_attendance_logs
        SELECT * FROM gps_attendance_logs_archive
        WHERE punch_time >= start_date AND punch_time <= end_date
          AND id NOT IN (SELECT id FROM gps_attendance_logs WHERE deleted = false);
        
        GET DIAGNOSTICS restored_count = ROW_COUNT;
        
    ELSIF table_name = 'salary_slips' THEN
        IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'salary_slips') THEN
            INSERT INTO salary_slips
            SELECT * FROM salary_slips_archive
            WHERE year >= EXTRACT(YEAR FROM start_date)
              AND year <= EXTRACT(YEAR FROM end_date)
              AND id NOT IN (SELECT id FROM salary_slips WHERE deleted = false);
            
            GET DIAGNOSTICS restored_count = ROW_COUNT;
        END IF;
    END IF;
    
    RETURN restored_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- STEP 4: SCHEDULE AUTOMATED ARCHIVAL
-- =============================================================================

-- Schedule monthly archival (first day of month at 4 AM)
-- Requires pg_cron extension - will skip if not available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Check if job already exists
        IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'monthly-archive') THEN
            PERFORM cron.schedule(
                'monthly-archive',
                '0 4 1 * *',  -- First day of month at 4 AM
                'SELECT archive_old_data()'
            );
            RAISE NOTICE 'Scheduled monthly archival job';
        ELSE
            RAISE NOTICE 'Monthly archival job already exists, skipping';
        END IF;
    ELSE
        RAISE NOTICE 'pg_cron extension not available. Use system cron instead (see comments below)';
    END IF;
END $$;

-- =============================================================================
-- STEP 5: CREATE ARCHIVAL STATISTICS VIEW
-- =============================================================================

CREATE OR REPLACE VIEW archival_statistics AS
SELECT 
    'attendance' AS table_name,
    COUNT(*) AS active_records,
    (SELECT COUNT(*) FROM attendance_archive) AS archived_records,
    MIN(date) AS oldest_active_date,
    MAX(date) AS newest_active_date
FROM attendance
WHERE deleted = false

UNION ALL

SELECT 
    'gps_attendance_logs' AS table_name,
    COUNT(*) AS active_records,
    (SELECT COUNT(*) FROM gps_attendance_logs_archive) AS archived_records,
    MIN(punch_time::date) AS oldest_active_date,
    MAX(punch_time::date) AS newest_active_date
FROM gps_attendance_logs
WHERE deleted = false

UNION ALL

SELECT 
    'salary_slips' AS table_name,
    COUNT(*) AS active_records,
    (SELECT COUNT(*) FROM salary_slips_archive) AS archived_records,
    make_date(MIN(year), 1, 1) AS oldest_active_date,
    make_date(MAX(year), 12, 31) AS newest_active_date
FROM salary_slips
WHERE deleted = false;

-- =============================================================================
-- STEP 6: CREATE ARCHIVAL MAINTENANCE FUNCTION
-- =============================================================================

-- Function to compress archived data (optional - for very large archives)
CREATE OR REPLACE FUNCTION compress_archived_data()
RETURNS void AS $$
BEGIN
    -- VACUUM FULL on archive tables to reclaim space
    -- This locks tables, so run during maintenance window
    VACUUM FULL VERBOSE attendance_archive;
    VACUUM FULL VERBOSE gps_attendance_logs_archive;
    
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'salary_slips_archive') THEN
        VACUUM FULL VERBOSE salary_slips_archive;
    END IF;
    
    RAISE NOTICE 'Archive compression completed';
END;
$$ LANGUAGE plpgsql;

-- Schedule archive compression (quarterly)
-- Requires pg_cron extension - will skip if not available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Check if job already exists
        IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'compress-archives') THEN
            PERFORM cron.schedule(
                'compress-archives',
                '0 5 1 1,4,7,10 *',  -- First day of quarter (Jan, Apr, Jul, Oct) at 5 AM
                'SELECT compress_archived_data()'
            );
            RAISE NOTICE 'Scheduled archive compression job';
        ELSE
            RAISE NOTICE 'Archive compression job already exists, skipping';
        END IF;
    ELSE
        RAISE NOTICE 'pg_cron extension not available. Use system cron instead (see comments below)';
    END IF;
END $$;

-- =============================================================================
-- STEP 7: CREATE EXPORT FUNCTION (for backup before archival)
-- =============================================================================

CREATE OR REPLACE FUNCTION export_data_before_archival(
    table_name text,
    start_date date,
    end_date date,
    export_path text
) RETURNS text AS $$
DECLARE
    filename text;
BEGIN
    filename := export_path || '/' || table_name || '_' || 
                to_char(start_date, 'YYYY_MM_DD') || '_to_' || 
                to_char(end_date, 'YYYY_MM_DD') || '.csv';
    
    -- Export to CSV (requires COPY command with file path)
    -- Note: This requires superuser privileges or use COPY TO with file path
    -- For production, consider using pg_dump or application-level export
    
    IF table_name = 'attendance' THEN
        EXECUTE format(
            'COPY (SELECT * FROM attendance WHERE date >= %L AND date <= %L) TO %L CSV HEADER',
            start_date, end_date, filename
        );
    ELSIF table_name = 'gps_attendance_logs' THEN
        EXECUTE format(
            'COPY (SELECT * FROM gps_attendance_logs WHERE punch_time >= %L AND punch_time <= %L) TO %L CSV HEADER',
            start_date, end_date, filename
        );
    END IF;
    
    RETURN filename;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- View archival statistics
SELECT * FROM archival_statistics;

-- Check archive table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE '%_archive'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Count records to be archived (dry run)
SELECT 
    'attendance' AS table_name,
    COUNT(*) AS records_to_archive
FROM attendance
WHERE date < CURRENT_DATE - INTERVAL '2 years' AND deleted = false

UNION ALL

SELECT 
    'gps_attendance_logs' AS table_name,
    COUNT(*) AS records_to_archive
FROM gps_attendance_logs
WHERE punch_time < CURRENT_DATE - INTERVAL '1 year' AND deleted = false;

-- =============================================================================
-- MANUAL ARCHIVAL COMMANDS
-- =============================================================================

-- Run archival manually
-- SELECT * FROM archive_old_data();

-- Restore specific date range
-- SELECT restore_archived_data('attendance', '2023-01-01', '2023-12-31');

-- =============================================================================
-- ALTERNATIVE: SYSTEM CRON (if pg_cron not available)
-- =============================================================================
--
-- Add to crontab (crontab -e):
--
-- Monthly archival - 1st of month at 4 AM:
-- 0 4 1 * * psql -U postgres -d civildesk -c "SELECT archive_old_data();"
--
-- Quarterly archive compression - First day of quarter at 5 AM:
-- 0 5 1 1,4,7,10 * psql -U postgres -d civildesk -c "SELECT compress_archived_data();"
-- (Note: Using 1,4,7,10 instead of */3 to avoid comment delimiter conflict)

-- =============================================================================
-- CLEANUP: DROP OLD ARCHIVES (optional - after backup)
-- =============================================================================

-- Function to drop archives older than retention period
CREATE OR REPLACE FUNCTION drop_old_archives(
    retention_years integer DEFAULT 7
) RETURNS void AS $$
DECLARE
    cutoff_date date;
BEGIN
    cutoff_date := CURRENT_DATE - (retention_years || ' years')::interval;
    
    -- Drop old attendance archives
    DELETE FROM attendance_archive
    WHERE date < cutoff_date;
    
    -- Drop old GPS log archives
    DELETE FROM gps_attendance_logs_archive
    WHERE punch_time < cutoff_date;
    
    -- Drop old salary slip archives
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'salary_slips_archive') THEN
        DELETE FROM salary_slips_archive
        WHERE year < EXTRACT(YEAR FROM cutoff_date);
    END IF;
    
    RAISE NOTICE 'Dropped archives older than %', cutoff_date;
END;
$$ LANGUAGE plpgsql;

