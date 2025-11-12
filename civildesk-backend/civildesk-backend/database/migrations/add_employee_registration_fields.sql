-- Migration: Add new employee registration fields
-- Date: 2024
-- Description: Adds UAN, ESIC, new salary structure fields, and deduction fields to employees table

-- Add Identification fields
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS uan_number VARCHAR(12),
ADD COLUMN IF NOT EXISTS esic_number VARCHAR(17);

-- Add new Salary Structure fields (replacing old ones)
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS conveyance DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS uniform_and_safety DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS bonus DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS food_allowance DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS other_allowance DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS overtime_rate DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS epf_employee DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS epf_employer DOUBLE PRECISION;

-- Add Deduction fields
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS esic DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS professional_tax DOUBLE PRECISION;

-- Note: The following columns may need to be dropped if they exist and are being replaced:
-- transport_allowance, medical_allowance, other_allowances (plural)
-- These are being replaced by: conveyance, uniform_and_safety, bonus, food_allowance, other_allowance (singular)

-- Optional: Migrate data from old columns to new columns if needed
-- UPDATE employees SET conveyance = transport_allowance WHERE conveyance IS NULL AND transport_allowance IS NOT NULL;
-- UPDATE employees SET other_allowance = other_allowances WHERE other_allowance IS NULL AND other_allowances IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN employees.uan_number IS 'Universal Account Number for EPF';
COMMENT ON COLUMN employees.esic_number IS 'Employee State Insurance Corporation number';
COMMENT ON COLUMN employees.conveyance IS 'Conveyance allowance in rupees';
COMMENT ON COLUMN employees.uniform_and_safety IS 'Uniform and safety allowance in rupees';
COMMENT ON COLUMN employees.bonus IS 'Bonus amount in rupees';
COMMENT ON COLUMN employees.food_allowance IS 'Food allowance in rupees';
COMMENT ON COLUMN employees.other_allowance IS 'Other allowance in rupees';
COMMENT ON COLUMN employees.overtime_rate IS 'Overtime rate per hour in rupees';
COMMENT ON COLUMN employees.epf_employee IS 'EPF contribution percentage for employee';
COMMENT ON COLUMN employees.epf_employer IS 'EPF contribution percentage for employer';
COMMENT ON COLUMN employees.esic IS 'ESIC contribution percentage';
COMMENT ON COLUMN employees.professional_tax IS 'Professional tax amount in rupees';

