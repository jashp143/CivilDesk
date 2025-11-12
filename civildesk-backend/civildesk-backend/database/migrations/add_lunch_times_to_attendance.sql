-- ============================================================================
-- Migration Script: Add Lunch Times to Attendance Table
-- ============================================================================
-- Description: Adds lunch_out_time and lunch_in_time columns to the attendance table
--              to support lunch break tracking in attendance marking.
-- 
-- Database: PostgreSQL
-- Table: attendance
-- Version: 1.0
-- Date: 2025-11-08
-- 
-- Run this script using one of the following methods:
--   1. pgAdmin Query Tool: Connect to civildesk database and execute
--   2. psql command line: psql -U postgres -d civildesk -f add_lunch_times_to_attendance.sql
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

-- Add lunch_out_time column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_out_time'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN lunch_out_time TIMESTAMP NULL;
        
        RAISE NOTICE 'Column lunch_out_time added successfully';
    ELSE
        RAISE NOTICE 'Column lunch_out_time already exists, skipping...';
    END IF;
END $$;

-- Add lunch_in_time column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_in_time'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN lunch_in_time TIMESTAMP NULL;
        
        RAISE NOTICE 'Column lunch_in_time added successfully';
    ELSE
        RAISE NOTICE 'Column lunch_in_time already exists, skipping...';
    END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN attendance.lunch_out_time IS 'Time when employee went for lunch break';
COMMENT ON COLUMN attendance.lunch_in_time IS 'Time when employee returned from lunch break';

-- Verify the changes
DO $$
DECLARE
    lunch_out_exists BOOLEAN;
    lunch_in_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_out_time'
    ) INTO lunch_out_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_in_time'
    ) INTO lunch_in_exists;
    
    IF lunch_out_exists AND lunch_in_exists THEN
        RAISE NOTICE 'Migration completed successfully!';
        RAISE NOTICE 'Both lunch_out_time and lunch_in_time columns are now available.';
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
-- ALTER TABLE attendance DROP COLUMN IF EXISTS lunch_out_time;
-- ALTER TABLE attendance DROP COLUMN IF EXISTS lunch_in_time;
-- COMMIT;
-- ============================================================================

