-- Migration 001: Enable UUID Extension
-- Description: Enable UUID generation for primary keys
-- Date: Phase 1 Setup
-- Run this FIRST before any other migrations

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Verify installation
SELECT * FROM pg_extension WHERE extname = 'uuid-ossp';
