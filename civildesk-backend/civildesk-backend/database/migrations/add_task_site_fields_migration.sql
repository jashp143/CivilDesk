-- =============================================================================
-- ADD SITE FIELDS TO TASKS TABLE
-- Migration: Add optional site information fields to tasks table
-- =============================================================================
-- This migration adds three optional fields to the tasks table:
--   - site_name: Name of the site
--   - site_contact_person_name: Name of the site contact person
--   - site_contact_phone: Phone number of the site contact person
-- =============================================================================

BEGIN;

-- Add site_name column
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS site_name VARCHAR(255);

-- Add site_contact_person_name column
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS site_contact_person_name VARCHAR(255);

-- Add site_contact_phone column
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS site_contact_phone VARCHAR(50);

-- Add comment to document the columns
COMMENT ON COLUMN tasks.site_name IS 'Optional: Name of the site where the task is to be performed';
COMMENT ON COLUMN tasks.site_contact_person_name IS 'Optional: Name of the contact person at the site';
COMMENT ON COLUMN tasks.site_contact_phone IS 'Optional: Phone number of the site contact person';

COMMIT;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================
-- The tasks table now includes three optional fields for site information.
-- These fields are nullable and can be left empty if not applicable.
-- =============================================================================

