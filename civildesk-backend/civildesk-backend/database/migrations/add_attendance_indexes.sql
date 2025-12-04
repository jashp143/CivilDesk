-- Add indexes for optimized attendance queries
-- This will improve performance for attendance analytics queries

-- Index for employee_id and date range queries (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date 
ON attendance(employee_id, date);

-- Index for date queries (for daily attendance queries)
CREATE INDEX IF NOT EXISTS idx_attendance_date 
ON attendance(date);

-- Index for employee_id queries
CREATE INDEX IF NOT EXISTS idx_attendance_employee_id 
ON attendance(employee_id);

-- Index for status queries (for filtering by attendance status)
CREATE INDEX IF NOT EXISTS idx_attendance_status 
ON attendance(status);

-- Composite index for employee and status (useful for analytics)
CREATE INDEX IF NOT EXISTS idx_attendance_employee_status 
ON attendance(employee_id, status);

-- Verify indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'attendance'
ORDER BY indexname;

