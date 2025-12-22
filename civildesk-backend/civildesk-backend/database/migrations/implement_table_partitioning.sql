-- =============================================================================
-- TABLE PARTITIONING IMPLEMENTATION
-- Civildesk Employee Management System
-- Phase 4 Optimization - Long-term Scalability
-- Generated: December 2025 / January 2026
-- =============================================================================
--
-- PURPOSE:
-- Partition large tables by date to improve query performance and maintenance.
-- Tables to partition:
-- - attendance (by month)
-- - gps_attendance_logs (by month)
-- - salary_slips (by year)
--
-- WARNING: This migration requires downtime and should be run during
--          maintenance window. Test thoroughly on staging first!
--
-- Expected improvement: 70% faster queries on historical data
-- =============================================================================

-- =============================================================================
-- STEP 1: BACKUP EXISTING TABLES
-- =============================================================================
-- IMPORTANT: Create backups before proceeding!
-- pg_dump -U postgres -d civildesk -t attendance > attendance_backup.sql
-- pg_dump -U postgres -d civildesk -t gps_attendance_logs > gps_attendance_backup.sql

-- =============================================================================
-- STEP 2: ATTENDANCE TABLE PARTITIONING
-- =============================================================================

-- Create new partitioned table structure
CREATE TABLE attendance_new (
    LIKE attendance INCLUDING ALL
) PARTITION BY RANGE (date);

-- Create partitions for current and future months
-- December 2025 and all months for 2026

-- December 2025 partition
CREATE TABLE attendance_2025_12 PARTITION OF attendance_new
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- 2026 monthly partitions
CREATE TABLE attendance_2026_01 PARTITION OF attendance_new
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE attendance_2026_02 PARTITION OF attendance_new
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE attendance_2026_03 PARTITION OF attendance_new
FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE attendance_2026_04 PARTITION OF attendance_new
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE attendance_2026_05 PARTITION OF attendance_new
FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE attendance_2026_06 PARTITION OF attendance_new
FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE attendance_2026_07 PARTITION OF attendance_new
FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE attendance_2026_08 PARTITION OF attendance_new
FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE attendance_2026_09 PARTITION OF attendance_new
FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE attendance_2026_10 PARTITION OF attendance_new
FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE attendance_2026_11 PARTITION OF attendance_new
FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE attendance_2026_12 PARTITION OF attendance_new
FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- Create default partition for future dates
CREATE TABLE attendance_default PARTITION OF attendance_new
DEFAULT;

-- Migrate data from old table to new partitioned table
-- This may take time depending on data volume
INSERT INTO attendance_new SELECT * FROM attendance;

-- Verify data migration
-- SELECT COUNT(*) FROM attendance;
-- SELECT COUNT(*) FROM attendance_new;
-- Should match!

-- Rename tables (swap)
ALTER TABLE attendance RENAME TO attendance_old;
ALTER TABLE attendance_new RENAME TO attendance;

-- Recreate indexes on partitioned table
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date_status 
ON attendance(employee_id, date, status) 
WHERE deleted = false;

CREATE INDEX IF NOT EXISTS idx_attendance_date_status 
ON attendance(date, status) 
WHERE deleted = false;

-- =============================================================================
-- STEP 3: GPS ATTENDANCE LOGS PARTITIONING
-- =============================================================================

-- Create new partitioned table
CREATE TABLE gps_attendance_logs_new (
    LIKE gps_attendance_logs INCLUDING ALL
) PARTITION BY RANGE (punch_time);

-- Create monthly partitions for December 2025 and all months for 2026
-- December 2025 partition
CREATE TABLE gps_attendance_logs_2025_12 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- 2026 monthly partitions
CREATE TABLE gps_attendance_logs_2026_01 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE gps_attendance_logs_2026_02 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE gps_attendance_logs_2026_03 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE gps_attendance_logs_2026_04 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE gps_attendance_logs_2026_05 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE gps_attendance_logs_2026_06 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE gps_attendance_logs_2026_07 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE gps_attendance_logs_2026_08 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE gps_attendance_logs_2026_09 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE gps_attendance_logs_2026_10 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE gps_attendance_logs_2026_11 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE gps_attendance_logs_2026_12 PARTITION OF gps_attendance_logs_new
FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- Default partition
CREATE TABLE gps_attendance_logs_default PARTITION OF gps_attendance_logs_new
DEFAULT;

-- Migrate data
INSERT INTO gps_attendance_logs_new SELECT * FROM gps_attendance_logs;

-- Verify
-- SELECT COUNT(*) FROM gps_attendance_logs;
-- SELECT COUNT(*) FROM gps_attendance_logs_new;

-- Swap tables
ALTER TABLE gps_attendance_logs RENAME TO gps_attendance_logs_old;
ALTER TABLE gps_attendance_logs_new RENAME TO gps_attendance_logs;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_gps_attendance_employee_site_time
ON gps_attendance_logs(employee_id, site_id, punch_time)
WHERE deleted = false;

-- =============================================================================
-- STEP 4: SALARY SLIPS PARTITIONING (BY YEAR)
-- =============================================================================

-- Only if salary_slips table exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'salary_slips') THEN
        -- Create partitioned table
        CREATE TABLE salary_slips_new (
            LIKE salary_slips INCLUDING ALL
        ) PARTITION BY RANGE (year, month);
        
        -- Create yearly partitions
        CREATE TABLE salary_slips_2024 PARTITION OF salary_slips_new
        FOR VALUES FROM (2024, 1) TO (2025, 1);
        
        CREATE TABLE salary_slips_2025 PARTITION OF salary_slips_new
        FOR VALUES FROM (2025, 1) TO (2026, 1);
        
        CREATE TABLE salary_slips_2026 PARTITION OF salary_slips_new
        FOR VALUES FROM (2026, 1) TO (2027, 1);
        
        CREATE TABLE salary_slips_2027 PARTITION OF salary_slips_new
        FOR VALUES FROM (2027, 1) TO (2028, 1);
        
        -- Default partition
        CREATE TABLE salary_slips_default PARTITION OF salary_slips_new
        DEFAULT;
        
        -- Migrate data
        INSERT INTO salary_slips_new SELECT * FROM salary_slips;
        
        -- Swap
        ALTER TABLE salary_slips RENAME TO salary_slips_old;
        ALTER TABLE salary_slips_new RENAME TO salary_slips;
        
        -- Recreate indexes
        CREATE INDEX IF NOT EXISTS idx_salary_slips_employee_period
        ON salary_slips(employee_id, year, month)
        WHERE deleted = false;
    END IF;
END $$;

-- =============================================================================
-- STEP 5: AUTO-CREATE PARTITION FUNCTION
-- =============================================================================

-- Function to automatically create monthly partitions
CREATE OR REPLACE FUNCTION create_monthly_partition(
    table_name text,
    start_date date
) RETURNS void AS $$
DECLARE
    partition_name text;
    end_date date;
BEGIN
    partition_name := table_name || '_' || to_char(start_date, 'YYYY_MM');
    end_date := start_date + interval '1 month';
    
    -- Check if partition already exists
    IF EXISTS (
        SELECT 1 FROM pg_class 
        WHERE relname = partition_name
    ) THEN
        RAISE NOTICE 'Partition % already exists', partition_name;
        RETURN;
    END IF;
    
    -- Create partition
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
        partition_name,
        table_name,
        start_date,
        end_date
    );
    
    RAISE NOTICE 'Created partition % for %', partition_name, table_name;
END;
$$ LANGUAGE plpgsql;

-- Function to create next month's partition (run monthly via cron)
CREATE OR REPLACE FUNCTION create_next_month_partitions()
RETURNS void AS $$
DECLARE
    next_month date;
BEGIN
    next_month := date_trunc('month', CURRENT_DATE + interval '1 month');
    
    -- Create partition for attendance
    PERFORM create_monthly_partition('attendance', next_month);
    
    -- Create partition for GPS logs
    PERFORM create_monthly_partition('gps_attendance_logs', next_month);
    
    RAISE NOTICE 'Created partitions for %', next_month;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- STEP 6: SCHEDULE AUTO-PARTITION CREATION
-- =============================================================================

-- Schedule monthly partition creation (requires pg_cron)
-- Runs on the 25th of each month to create next month's partition
SELECT cron.schedule(
    'create-monthly-partitions',
    '0 2 25 * *',  -- 25th of month at 2 AM
    $$SELECT create_next_month_partitions()$$
);

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- List all partitions
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'attendance_%' 
   OR tablename LIKE 'gps_attendance_logs_%'
   OR tablename LIKE 'salary_slips_%'
ORDER BY tablename;

-- Check partition constraints
SELECT 
    schemaname,
    tablename,
    pg_get_expr(relpartbound, oid) AS partition_constraint
FROM pg_class
WHERE relkind = 'r' 
  AND relname LIKE 'attendance_%'
ORDER BY tablename;

-- =============================================================================
-- ROLLBACK SCRIPT (if needed)
-- =============================================================================

/*
-- WARNING: This will drop partitioned tables and restore old tables
-- Only use if migration fails and you need to rollback

-- Drop partitioned tables
DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS gps_attendance_logs CASCADE;
DROP TABLE IF EXISTS salary_slips CASCADE;

-- Restore old tables
ALTER TABLE attendance_old RENAME TO attendance;
ALTER TABLE gps_attendance_logs_old RENAME TO gps_attendance_logs;
ALTER TABLE salary_slips_old RENAME TO salary_slips;

-- Drop functions
DROP FUNCTION IF EXISTS create_monthly_partition(text, date);
DROP FUNCTION IF EXISTS create_next_month_partitions();
*/

-- =============================================================================
-- MAINTENANCE: DROP OLD PARTITIONS
-- =============================================================================

-- Function to drop old partitions (older than retention period)
CREATE OR REPLACE FUNCTION drop_old_partitions(
    table_name text,
    retention_months integer DEFAULT 12
) RETURNS void AS $$
DECLARE
    partition_record record;
    cutoff_date date;
BEGIN
    cutoff_date := CURRENT_DATE - (retention_months || ' months')::interval;
    
    FOR partition_record IN
        SELECT tablename
        FROM pg_tables
        WHERE tablename LIKE table_name || '_%'
          AND tablename != table_name || '_default'
          AND tablename != table_name || '_old'
    LOOP
        -- Extract date from partition name (format: table_YYYY_MM)
        DECLARE
            date_str text;
            partition_date date;
        BEGIN
            date_str := substring(partition_record.tablename from '(\d{4}_\d{2})$');
            IF date_str IS NOT NULL THEN
                partition_date := to_date(date_str, 'YYYY_MM');
                
                IF partition_date < cutoff_date THEN
                    EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', partition_record.tablename);
                    RAISE NOTICE 'Dropped old partition: %', partition_record.tablename;
                END IF;
            END IF;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule old partition cleanup (runs quarterly)
SELECT cron.schedule(
    'drop-old-partitions',
    '0 3 1 */3 *',  -- First day of quarter at 3 AM
    $$SELECT drop_old_partitions('attendance', 12);
      SELECT drop_old_partitions('gps_attendance_logs', 6);$$
);

