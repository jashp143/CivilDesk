-- ============================================================================
-- Migration Script: Add Working Hours and Overtime Hours to Attendance Table
-- ============================================================================
-- Description: Adds working_hours and overtime_hours columns to the attendance table
--              to store calculated office working hours and overtime hours.
-- 
-- Database: PostgreSQL
-- Table: attendance
-- Version: 1.0
-- Date: 2025-01-XX
-- 
-- Run this script using one of the following methods:
--   1. pgAdmin Query Tool: Connect to civildesk database and execute
--   2. psql command line: psql -U postgres -d civildesk -f add_working_hours_to_attendance.sql
--   3. Spring Boot: Place in db/migration folder if using Flyway
-- ============================================================================

-- Start transaction for safe execution
BEGIN;

-- Check if table exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance'
    ) THEN
        RAISE EXCEPTION 'Table attendance does not exist. Please create it first.';
    END IF;
END $$;

-- Add working_hours column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'working_hours'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN working_hours DOUBLE PRECISION NULL;
        
        RAISE NOTICE 'Column working_hours added successfully';
    ELSE
        RAISE NOTICE 'Column working_hours already exists, skipping...';
    END IF;
END $$;

-- Add overtime_hours column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'overtime_hours'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN overtime_hours DOUBLE PRECISION NULL;
        
        RAISE NOTICE 'Column overtime_hours added successfully';
    ELSE
        RAISE NOTICE 'Column overtime_hours already exists, skipping...';
    END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN attendance.working_hours IS 'Calculated office working hours (always <= 8 hours)';
COMMENT ON COLUMN attendance.overtime_hours IS 'Calculated overtime hours';

-- Verify the changes
DO $$
DECLARE
    working_hours_exists BOOLEAN;
    overtime_hours_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'working_hours'
    ) INTO working_hours_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'overtime_hours'
    ) INTO overtime_hours_exists;
    
    IF working_hours_exists AND overtime_hours_exists THEN
        RAISE NOTICE 'Migration completed successfully!';
        RAISE NOTICE 'Both working_hours and overtime_hours columns are now available.';
    ELSE
        RAISE WARNING 'Migration may have failed. Please check the columns manually.';
    END IF;
END $$;

-- Commit the transaction
COMMIT;

-- ============================================================================
-- Rollback Script (if needed)
-- ============================================================================
-- To rollback this migration, run:
-- 
-- BEGIN;
-- ALTER TABLE attendance DROP COLUMN IF EXISTS working_hours;
-- ALTER TABLE attendance DROP COLUMN IF EXISTS overtime_hours;
-- COMMIT;
-- ============================================================================

