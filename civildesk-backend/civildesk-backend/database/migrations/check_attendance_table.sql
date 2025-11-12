-- Diagnostic script to check attendance table structure
-- Run this in pgAdmin Query Tool to verify table structure

-- Check if table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'attendance'
) AS table_exists;

-- Check all columns in attendance table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'attendance'
ORDER BY ordinal_position;

-- Check if lunch columns exist
SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_out_time'
    ) THEN 'EXISTS' ELSE 'MISSING' END AS lunch_out_time_status,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_in_time'
    ) THEN 'EXISTS' ELSE 'MISSING' END AS lunch_in_time_status;

-- Check recent attendance records
SELECT 
    id,
    employee_id,
    date,
    check_in_time,
    lunch_out_time,
    lunch_in_time,
    check_out_time,
    status,
    recognition_method,
    created_at
FROM attendance
ORDER BY created_at DESC
LIMIT 10;

