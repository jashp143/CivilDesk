-- Migration: Create salary_slips table
-- Date: 2024
-- Description: Creates the salary_slips table for storing calculated salary slips

CREATE TABLE IF NOT EXISTS salary_slips (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    
    -- Calendar & Working Days
    total_days_in_month INTEGER,
    working_days INTEGER,
    weekly_offs INTEGER,
    
    -- Attendance Data
    total_effective_working_hours DOUBLE PRECISION,
    total_overtime_hours DOUBLE PRECISION,
    raw_present_days DOUBLE PRECISION,
    present_days INTEGER,
    absent_days INTEGER,
    proration_factor DOUBLE PRECISION,
    
    -- Earnings (Prorated)
    basic_pay DOUBLE PRECISION,
    hra_amount DOUBLE PRECISION,
    medical_allowance DOUBLE PRECISION,
    conveyance_allowance DOUBLE PRECISION,
    uniform_and_safety_allowance DOUBLE PRECISION,
    bonus DOUBLE PRECISION,
    food_allowance DOUBLE PRECISION,
    special_allowance DOUBLE PRECISION,
    overtime_pay DOUBLE PRECISION,
    total_special_allowance DOUBLE PRECISION,
    other_incentive DOUBLE PRECISION,
    epf_employer_earnings DOUBLE PRECISION,
    total_earnings DOUBLE PRECISION,
    
    -- Deductions
    epf_employee_deduction DOUBLE PRECISION,
    epf_employer_deduction DOUBLE PRECISION,
    esic_deduction DOUBLE PRECISION,
    professional_tax DOUBLE PRECISION,
    tds DOUBLE PRECISION,
    advance_salary_recovery DOUBLE PRECISION,
    loan_recovery DOUBLE PRECISION,
    fuel_advance_recovery DOUBLE PRECISION,
    other_deductions DOUBLE PRECISION,
    total_statutory_deductions DOUBLE PRECISION,
    total_other_deductions DOUBLE PRECISION,
    total_deductions DOUBLE PRECISION,
    
    -- Net Salary
    net_salary DOUBLE PRECISION,
    
    -- Rates
    daily_rate DOUBLE PRECISION,
    hourly_rate DOUBLE PRECISION,
    overtime_rate DOUBLE PRECISION,
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    generated_by BIGINT,
    generated_at TIMESTAMP,
    notes TEXT,
    
    -- Base Entity fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Foreign key
    CONSTRAINT fk_salary_slip_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    
    -- Unique constraint: one salary slip per employee per month
    CONSTRAINT uk_employee_year_month UNIQUE (employee_id, year, month)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_salary_slips_employee_id ON salary_slips(employee_id);
CREATE INDEX IF NOT EXISTS idx_salary_slips_year_month ON salary_slips(year, month);
CREATE INDEX IF NOT EXISTS idx_salary_slips_status ON salary_slips(status);
CREATE INDEX IF NOT EXISTS idx_salary_slips_deleted ON salary_slips(deleted);

-- Add comments for documentation
COMMENT ON TABLE salary_slips IS 'Stores calculated salary slips for employees';
COMMENT ON COLUMN salary_slips.year IS 'Year of the salary period (e.g., 2024)';
COMMENT ON COLUMN salary_slips.month IS 'Month of the salary period (1-12)';
COMMENT ON COLUMN salary_slips.working_days IS 'Number of working days (Monday to Saturday)';
COMMENT ON COLUMN salary_slips.weekly_offs IS 'Number of Sundays in the month';
COMMENT ON COLUMN salary_slips.present_days IS 'Number of days employee was present (rounded)';
COMMENT ON COLUMN salary_slips.proration_factor IS 'Proration factor = present_days / working_days';
COMMENT ON COLUMN salary_slips.status IS 'Status: DRAFT, FINALIZED, PAID, CANCELLED';

