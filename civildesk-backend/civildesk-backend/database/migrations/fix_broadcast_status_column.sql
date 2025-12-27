-- =============================================================================
-- FIX BROADCAST MESSAGES TABLE COLUMNS
-- Remove columns that shouldn't exist in broadcast_messages table
-- =============================================================================
-- This migration fixes the issue where the table has columns (status, sent_at, sent_by)
-- that shouldn't exist. Broadcast messages use is_active instead of status,
-- and sent_at/sent_by are not needed since notifications are sent immediately
-- and we already track created_by/updated_by.
-- =============================================================================

BEGIN;

-- Drop the status column if it exists (not needed - we use is_active)
ALTER TABLE broadcast_messages 
DROP COLUMN IF EXISTS status;

-- Drop the sent_at column if it exists (not needed - notifications sent immediately)
ALTER TABLE broadcast_messages 
DROP COLUMN IF EXISTS sent_at;

-- Drop the sent_by column if it exists (not needed - we use created_by instead)
ALTER TABLE broadcast_messages 
DROP COLUMN IF EXISTS sent_by;

-- Fix the priority check constraint to match our enum values
-- Drop existing constraint if it exists (might have different name)
ALTER TABLE broadcast_messages 
DROP CONSTRAINT IF EXISTS broadcast_messages_priority_check;

ALTER TABLE broadcast_messages 
DROP CONSTRAINT IF EXISTS chk_priority;

-- Recreate the constraint with correct values
ALTER TABLE broadcast_messages 
ADD CONSTRAINT chk_priority CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT'));

COMMIT;

