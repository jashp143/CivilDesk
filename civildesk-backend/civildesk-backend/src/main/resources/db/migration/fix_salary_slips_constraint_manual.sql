-- Manual fix script for salary_slips unique constraint
-- Run this if the migration doesn't work properly
-- This script will find and drop the existing constraint and create the new partial index

-- Step 1: Drop the constraint by finding it dynamically
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

-- Step 2: Also try to drop by known constraint names
ALTER TABLE salary_slips DROP CONSTRAINT IF EXISTS uk_employee_year_month;
ALTER TABLE salary_slips DROP CONSTRAINT IF EXISTS uk82y57uowsigmccyl3fvchf5u6;

-- Step 3: Drop the index if it exists
DROP INDEX IF EXISTS uk_salary_slips_finalized_unique;

-- Step 4: Create the partial unique index for FINALIZED status only
CREATE UNIQUE INDEX uk_salary_slips_finalized_unique 
ON salary_slips(employee_id, year, month) 
WHERE status = 'FINALIZED' AND deleted = false;

-- Step 5: Add comment
COMMENT ON INDEX uk_salary_slips_finalized_unique IS 
'Ensures only one FINALIZED salary slip per employee per month. Multiple DRAFT slips are allowed.';

-- Verify the constraint is dropped and index is created
SELECT 
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint
WHERE conrelid = 'salary_slips'::regclass
  AND contype = 'u'
ORDER BY conname;

SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'salary_slips'
  AND indexname = 'uk_salary_slips_finalized_unique';

