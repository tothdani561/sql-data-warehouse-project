/*
========================================
Script: Create Silver Layer Tables
Author: [Tóth Dániel]
Description:
  This script initializes the silver layer of the data warehouse.
  It includes customer, product, sales, and external ERP source tables.
  Each table is dropped if it already exists to allow fresh creation.
========================================

==============================
: Customer Information Table
Contains core CRM customer details
==============================
*/
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id INT,                        -- Customer ID (internal key)
    cst_key NVARCHAR(50),              -- Customer business key (external reference)
    cst_firstname NVARCHAR(50),        -- First name
    cst_lastname NVARCHAR(50),         -- Last name
    cst_marital_status NVARCHAR(50),   -- Marital status (e.g. Single, Married)
    cst_gndr NVARCHAR(50),             -- Gender (Male/Female/Other)
    cst_create_date DATE,              -- Date the customer was created in CRM
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ==============================
-- CRM: Product Master Table
-- Holds product metadata and lifecycle dates
-- ==============================
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id INT,                       -- Product ID
    cat_id NVARCHAR(50),
    prd_key NVARCHAR(50),             -- Business key (SKU or catalog ID)
    prd_nm NVARCHAR(100),             -- Product name
    prd_cost INT NULL,                -- Product cost (nullable)
    prd_line NVARCHAR(20),            -- Product line/category
    prd_start_dt DATETIME NULL,       -- Product introduction date
    prd_end_dt DATETIME NULL,         -- Product discontinuation date (nullable)
    wh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ==============================
-- CRM: Sales Order Detail Table
-- Contains transactional sales data
-- ==============================
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num NVARCHAR(20),         -- Sales order number
    sls_prd_key NVARCHAR(50),         -- Product key (foreign key to product table)
    sls_cust_id INT,                  -- Customer ID (foreign key to customer)
    sls_order_dt NVARCHAR(20),                 -- Order date (YYYYMMDD format)
    sls_ship_dt NVARCHAR(20),                  -- Shipping date
    sls_due_dt NVARCHAR(20),                   -- Due date
    sls_sales INT,                    -- Total sales amount
    sls_quantity INT,                 -- Quantity ordered
    sls_price INT,                    -- Price per unit
    wh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ==============================
-- ERP: Customer Demographics Table (az12)
-- Contains external system customer demographic data
-- ==============================
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid NVARCHAR(50),                 -- Customer ID from external ERP system
    bdate DATE,                       -- Birthdate
    gen NVARCHAR(50),                 -- Gender (nullable, sometimes M/F or blank)
    wh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ==============================
-- ERP: Customer Location Table (a101)
-- Stores customer-country mappings
-- ==============================
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid NVARCHAR(50),                 -- Customer ID
    cntry NVARCHAR(50),               -- Country
    wh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- ==============================
-- ERP: Product Category Mapping Table (g1v2)
-- Links products to categories and maintenance info
-- ==============================
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id NVARCHAR(50),                  -- Product ID or reference
    cat NVARCHAR(50),                 -- Product category
    subcat NVARCHAR(50),              -- Product subcategory
    maintenance NVARCHAR(50),         -- Maintenance flag/info
    wh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
