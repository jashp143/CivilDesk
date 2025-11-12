-- ============================================================================
-- Rollback Script: Remove Lunch Times from Attendance Table
-- ============================================================================
-- Description: Removes lunch_out_time and lunch_in_time columns from attendance table
-- 
-- WARNING: This will permanently delete all lunch time data!
-- Only run this if you need to rollback the migration.
-- ============================================================================

BEGIN;

-- Remove lunch_out_time column
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_out_time'
    ) THEN
        ALTER TABLE attendance DROP COLUMN lunch_out_time;
        RAISE NOTICE 'Column lunch_out_time removed successfully';
    ELSE
        RAISE NOTICE 'Column lunch_out_time does not exist, skipping...';
    END IF;
END $$;

-- Remove lunch_in_time column
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_in_time'
    ) THEN
        ALTER TABLE attendance DROP COLUMN lunch_in_time;
        RAISE NOTICE 'Column lunch_in_time removed successfully';
    ELSE
        RAISE NOTICE 'Column lunch_in_time does not exist, skipping...';
    END IF;
END $$;

COMMIT;

