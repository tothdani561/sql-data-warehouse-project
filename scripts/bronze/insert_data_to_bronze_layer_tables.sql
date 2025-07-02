-- ========================================
-- Procedure: bronze.load_bronze
-- Author: [Tóth Dániel]
-- Description:
--   Loads raw data from .csv files into Bronze Layer staging tables.
--   The procedure truncates each target table and loads fresh data using BULK INSERT.
--   Duration metrics and basic logging are included for each step.
--   Includes error handling with PRINT-based diagnostics.
-- ========================================

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
    -- Declare variables for timing each step
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        -- Start full batch timing
        SET @batch_start_time = GETDATE();

        -- Logging: Start of Bronze layer load
        PRINT('=================================================');
        PRINT('Loading Bronze Layer');
        PRINT('=================================================');
        PRINT('');

        -- =============================
        -- Load CRM Tables
        -- =============================
        PRINT('-------------------------------------------------');
        PRINT('Loading CRM Tables');
        PRINT('-------------------------------------------------');
        PRINT('');

        -- === Load CRM Customer Info ===
        SET @start_time = GETDATE();
        PRINT('>> Truncating Table: bronze.crm_cust_info');
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT('>> Inserting Data Into: bronze.crm_cust_info');
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\sarka\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,               -- Skip header row
            FIELDTERMINATOR = ',',      -- CSV delimiter
            TABLOCK                     -- Improves performance by locking the table during load
        );
        SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');

        -- === Load CRM Product Info ===
        SET @start_time = GETDATE();
        PRINT('>> Truncating Table: bronze.crm_prd_info');
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT('>> Inserting Data Into: bronze.crm_prd_info');
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\sarka\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');

        -- === Load CRM Sales Details ===
        SET @start_time = GETDATE();
        PRINT('>> Truncating Table: bronze.crm_sales_details');
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT('>> Inserting Data Into: bronze.crm_sales_details');
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\sarka\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');

        -- =============================
        -- Load ERP Tables
        -- =============================
        PRINT('-------------------------------------------------');
        PRINT('Loading ERP Tables');
        PRINT('-------------------------------------------------');

        -- === Load ERP Customer Demographics (az12) ===
        SET @start_time = GETDATE();
        PRINT('>> Truncating Table: bronze.erp_cust_az12');
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT('>> Inserting Data Into: bronze.erp_cust_az12');
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\sarka\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');

        -- === Load ERP Customer Location (a101) ===
        SET @start_time = GETDATE();
        PRINT('>> Truncating Table: bronze.erp_loc_a101');
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT('>> Inserting Data Into: bronze.erp_loc_a101');
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\sarka\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');

        -- === Load ERP Product Category Mapping (g1v2) ===
        SET @start_time = GETDATE();
        PRINT('>> Truncating Table: bronze.erp_px_cat_g1v2');
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT('>> Inserting Data Into: bronze.erp_px_cat_g1v2');
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\sarka\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');

        -- Final total duration log
        SET @batch_end_time = GETDATE();
        PRINT('=====================================');
        PRINT('Loading bronze Layer is Completed');
        PRINT('>> Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds');
        PRINT('=====================================');

    END TRY
    BEGIN CATCH
        -- Error handling section
        PRINT('=====================================');
        PRINT('ERROR ACCURED DURING LOADING BRONZE LAYER.');

        -- Output error details for debugging
        PRINT('Error message' + ERROR_MESSAGE());
        PRINT('Error message' + CAST(ERROR_MESSAGE() AS NVARCHAR(50)));
        PRINT('Error message' + CAST(ERROR_STATE() AS NVARCHAR(50)));
        PRINT('=====================================');
    END CATCH
END
GO

-- Execute the procedure to load all bronze layer tables
EXEC bronze.load_bronze;
