-- Rollback Migration: Remove new employee registration fields
-- Date: 2024
-- Description: Removes UAN, ESIC, new salary structure fields, and deduction fields from employees table

-- Remove Deduction fields
ALTER TABLE employees
DROP COLUMN IF EXISTS esic,
DROP COLUMN IF EXISTS professional_tax;

-- Remove new Salary Structure fields
ALTER TABLE employees
DROP COLUMN IF EXISTS conveyance,
DROP COLUMN IF EXISTS uniform_and_safety,
DROP COLUMN IF EXISTS bonus,
DROP COLUMN IF EXISTS food_allowance,
DROP COLUMN IF EXISTS other_allowance,
DROP COLUMN IF EXISTS overtime_rate,
DROP COLUMN IF EXISTS epf_employee,
DROP COLUMN IF EXISTS epf_employer;

-- Remove Identification fields
ALTER TABLE employees
DROP COLUMN IF EXISTS uan_number,
DROP COLUMN IF EXISTS esic_number;

