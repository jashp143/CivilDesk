-- Rollback script for leaves table

-- Drop trigger
DROP TRIGGER IF EXISTS trigger_update_leaves_updated_at ON leaves;

-- Drop function
DROP FUNCTION IF EXISTS update_leaves_updated_at();

-- Drop indexes
DROP INDEX IF EXISTS idx_leaves_employee_status;
DROP INDEX IF EXISTS idx_leaves_deleted;
DROP INDEX IF EXISTS idx_leaves_reviewed_by;
DROP INDEX IF EXISTS idx_leaves_end_date;
DROP INDEX IF EXISTS idx_leaves_start_date;
DROP INDEX IF EXISTS idx_leaves_leave_type;
DROP INDEX IF EXISTS idx_leaves_status;
DROP INDEX IF EXISTS idx_leaves_employee_id;

-- Drop table
DROP TABLE IF EXISTS leaves;
