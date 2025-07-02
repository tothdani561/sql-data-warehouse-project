/*
========================================
Script: Create Data Warehouse Database with Schemas
Author: [Tóth Dániel]
Description: This script creates a new data warehouse database 
             named 'DataWarehouse' and defines a multi-layered 
             schema structure: bronze, silver, and gold.

WARNING:
Running this script will drop the entire 'DataWarehouse' database if it exists.
All data in the database will be permanently deleted. Proceed with caution
and ensure you have proper backups before running this script.
========================================
*/

-- Switch to the 'master' database to ensure we are in a valid context
USE master;
GO

-- Create the main Data Warehouse database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
	PRINT 'DataWarehouse database dropped.';
	PRINT '';
END;
GO

CREATE DATABASE DataWarehouse;
GO

-- Confirmation message (Note: PRINT uses single quotes in T-SQL)
PRINT 'DataWarehouse database has been created.';
PRINT '';
GO

-- Switch to the newly created DataWarehouse database to begin schema creation
USE DataWarehouse;
GO

-- ========================================
-- Create Schemas to represent layered architecture
-- Bronze: Raw data ingestion layer (no transformation)
-- Silver: Cleaned and lightly transformed data
-- Gold: Final, business-ready data models
-- ========================================

-- Create Bronze layer schema
CREATE SCHEMA bronze;
GO

-- Create Silver layer schema
CREATE SCHEMA silver;
GO

-- Create Gold layer schema
CREATE SCHEMA gold;
GO
PRINT 'DataWarehouse schemas has created.';
