-- Migration: Modify salary_slips unique constraint
-- Date: 2025
-- Description: Removes the unique constraint on (employee_id, year, month) and replaces it
--              with a partial unique index that only applies to FINALIZED status records.
--              This allows multiple DRAFT salary slips per employee per month, but only
--              one FINALIZED salary slip per employee per month.

-- Drop the existing unique constraint by finding it dynamically
-- This handles cases where the constraint name might be auto-generated
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find the unique constraint on (employee_id, year, month)
    SELECT conname INTO constraint_name
    FROM pg_constraint
    WHERE conrelid = 'salary_slips'::regclass
      AND contype = 'u'
      AND array_length(conkey, 1) = 3
      AND EXISTS (
          SELECT 1
          FROM pg_attribute a1, pg_attribute a2, pg_attribute a3
          WHERE a1.attrelid = conrelid
            AND a1.attnum = conkey[1]
            AND a1.attname = 'employee_id'
            AND a2.attrelid = conrelid
            AND a2.attnum = conkey[2]
            AND a2.attname = 'year'
            AND a3.attrelid = conrelid
            AND a3.attnum = conkey[3]
            AND a3.attname = 'month'
      )
    LIMIT 1;
    
    -- Drop the constraint if found
    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE salary_slips DROP CONSTRAINT IF EXISTS %I', constraint_name);
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No unique constraint found on (employee_id, year, month)';
    END IF;
END $$;

-- Drop the constraint by known names as well (in case the above doesn't find it)
ALTER TABLE salary_slips DROP CONSTRAINT IF EXISTS uk_employee_year_month;
ALTER TABLE salary_slips DROP CONSTRAINT IF EXISTS uk82y57uowsigmccyl3fvchf5u6;

-- Drop the index if it already exists (in case migration was partially run)
DROP INDEX IF EXISTS uk_salary_slips_finalized_unique;

-- Create a partial unique index that only applies to FINALIZED status
-- This ensures only one FINALIZED salary slip per employee per month
CREATE UNIQUE INDEX uk_salary_slips_finalized_unique 
ON salary_slips(employee_id, year, month) 
WHERE status = 'FINALIZED' AND deleted = false;

-- Add comment for documentation
COMMENT ON INDEX uk_salary_slips_finalized_unique IS 
'Ensures only one FINALIZED salary slip per employee per month. Multiple DRAFT slips are allowed.';

