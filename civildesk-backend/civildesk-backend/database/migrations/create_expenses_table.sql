-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    expense_date DATE NOT NULL,
    category VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT NOT NULL,
    receipt_urls TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP,
    review_note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviewed_by FOREIGN KEY (reviewed_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_category CHECK (category IN (
        'TRAVEL', 'MEALS', 'ACCOMMODATION', 'SUPPLIES', 
        'EQUIPMENT', 'COMMUNICATION', 'TRANSPORTATION', 
        'ENTERTAINMENT', 'TRAINING', 'OTHER'
    )),
    CONSTRAINT chk_status CHECK (status IN (
        'PENDING', 'APPROVED', 'REJECTED'
    )),
    CONSTRAINT chk_amount CHECK (amount > 0)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_expenses_employee_id ON expenses(employee_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_reviewed_by ON expenses(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_expenses_deleted ON expenses(deleted);

-- Create a composite index for common queries
CREATE INDEX IF NOT EXISTS idx_expenses_employee_status ON expenses(employee_id, status) WHERE deleted = false;

-- Add comments to the table and columns
COMMENT ON TABLE expenses IS 'Stores employee expense applications and their approval status';
COMMENT ON COLUMN expenses.employee_id IS 'Foreign key to employees table';
COMMENT ON COLUMN expenses.expense_date IS 'Date when the expense was incurred';
COMMENT ON COLUMN expenses.category IS 'Category of the expense';
COMMENT ON COLUMN expenses.amount IS 'Amount of the expense';
COMMENT ON COLUMN expenses.description IS 'Description of the expense';
COMMENT ON COLUMN expenses.receipt_urls IS 'Comma-separated URLs of receipt files';
COMMENT ON COLUMN expenses.status IS 'Current status of the expense application';
COMMENT ON COLUMN expenses.reviewed_by IS 'User ID of admin/HR who reviewed the expense';
COMMENT ON COLUMN expenses.reviewed_at IS 'Timestamp when the expense was reviewed';
COMMENT ON COLUMN expenses.review_note IS 'Optional note from reviewer for the employee';
COMMENT ON COLUMN expenses.deleted IS 'Soft delete flag';

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_expenses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_expenses_updated_at
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_expenses_updated_at();

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON expenses TO your_app_user;
-- GRANT USAGE, SELECT ON SEQUENCE expenses_id_seq TO your_app_user;
