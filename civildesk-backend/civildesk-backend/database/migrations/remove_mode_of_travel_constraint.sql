-- Migration: Remove mode_of_travel check constraint
-- Date: 2025-12-10
-- Description: Removes the check constraint on mode_of_travel to allow free-form text input

-- Drop the check constraint on mode_of_travel (trying both possible constraint names)
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS chk_mode_of_travel;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_mode_of_travel_check;

-- Increase the VARCHAR length to accommodate longer text entries
ALTER TABLE tasks ALTER COLUMN mode_of_travel TYPE VARCHAR(255);

