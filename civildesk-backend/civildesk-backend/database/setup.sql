-- Create Civildesk Database
-- Run this script in PostgreSQL to set up the database

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE civildesk'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'civildesk')\gexec

-- Connect to the database
\c civildesk

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Note: Tables will be created automatically by Hibernate/JPA
-- when you run the Spring Boot application with 
-- spring.jpa.hibernate.ddl-auto=update

-- Verify database creation
SELECT current_database();

