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
-- ============================================================================

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
    END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN attendance.working_hours IS 'Calculated office working hours (always <= 8 hours)';
COMMENT ON COLUMN attendance.overtime_hours IS 'Calculated overtime hours';

