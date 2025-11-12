-- Verification Script: Check if new employee registration fields exist
-- Run this after the migration to verify all columns were added

SELECT 
    column_name, 
    data_type, 
    is_nullable,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'employees'
  AND column_name IN (
    'uan_number',
    'esic_number',
    'conveyance',
    'uniform_and_safety',
    'bonus',
    'food_allowance',
    'other_allowance',
    'overtime_rate',
    'epf_employee',
    'epf_employer',
    'esic',
    'professional_tax'
  )
ORDER BY column_name;

-- Expected output: 12 rows (one for each new column)
-- If you see all 12 columns, the migration was successful!

