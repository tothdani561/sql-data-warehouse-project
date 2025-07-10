-- ========================================
-- Procedure: silver.load_silver
-- Author: [Tóth Dániel]
-- ========================================

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	BEGIN TRY
		-- Start full batch timing
		SET @batch_start_time = GETDATE();

		SET @start_time = GETDATE();
		PRINT('>> Truncating Table: silver.crm_cust_info');
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT('>> Inserting Data Into: silver.crm_cust_info');
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT 
		cst_id, cst_key,
		-- Data Cleansing
		TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) AS cst_lastname,
		-- Data Normalization / Standardization & Handling Missing Data
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' 
			 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			 ELSE 'n/a' 
		END cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
			 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			 ELSE 'n/a' 
		END cst_gndr,
		cst_create_date
		FROM (
			/*
			Remove Duplicates

			ROW_NUMBER() -> Window function
			PARTITION BY -> Külön csoportra bontja a {cst_id} alapján és arra alkalmazza az Order By-t
			Cél: Legutolsó rendelés kiszűrése
			*/
			SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)t
		-- Data Filtering
		WHERE flag_last = 1;

		SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');





		SET @start_time = GETDATE();
		PRINT('>> Truncating Table: silver.crm_prd_info');
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT('>> Inserting Data Into: silver.crm_prd_info');
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			/*---------------------------------------------------------------
			  Derive category identifier: first 5 chars of prd_key, replacing
			  hyphens with underscores (e.g. AC-HE → AC_HE)
			---------------------------------------------------------------*/
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

			/* Remove the cat‑part from product key so downstream keys remain
			   stable even if the category logic changes */
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

			prd_nm,

			/* Replace NULL cost with 0 to avoid NULL handling downstream */
			ISNULL(prd_cost, 0) AS prd_cost,

			/* Decode single‑letter product line to meaningful description */
			CASE UPPER(TRIM(prd_line))
				 WHEN 'M' THEN 'Mountain'
				 WHEN 'R' THEN 'Road'
				 WHEN 'S' THEN 'Other Sales'
				 WHEN 'T' THEN 'Touring'
				 ELSE 'n/a'
			END AS prd_line,

			/* Cast to DATE for storage economy and consistency */
			CAST(prd_start_dt AS DATE) AS prd_start_dt,

			/*
			  Use LEAD to get the next product start date (per prd_key) and
			  subtract 1 day so current record’s validity ends the day before
			  the next begins. The final record per key will return NULL.
			*/
			CAST(
				LEAD(prd_start_dt) OVER (
					PARTITION BY prd_key
					ORDER BY prd_start_dt
				) - 1 AS DATE
			) AS prd_end_dt
		FROM bronze.crm_prd_info;

		SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');





		SET @start_time = GETDATE();
		PRINT('>> Truncating Table: silver.crm_sales_details');
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT('>> Inserting Data Into: silver.crm_sales_details');
		INSERT INTO silver.crm_sales_details (
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
		SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE 
			WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,
		CASE
			WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,
		CASE
			WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,
		CASE
			WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
				THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE
			WHEN sls_price IS NULL OR sls_price <= 0
				THEN sls_sales / NULLIF(sls_quantity, 0)
			ELSE sls_price
		END AS sls_price
		FROM bronze.crm_sales_details;

		SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');





		SET @start_time = GETDATE();
		PRINT('>> Truncating Table: silver.erp_cust_az12');
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT('>> Inserting Data Into: silver.erp_cust_az12');
		INSERT INTO silver.erp_cust_az12 (
		cid, bdate, gen
		)
		SELECT
		CASE
			WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
			ELSE cid
		END cid,
		CASE
			WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END AS bdate,
		CASE
			WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			ELSE 'n/a'
		END as gen
		FROM bronze.erp_cust_az12;

		SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');





		SET @start_time = GETDATE();
		PRINT('>> Truncating Table: silver.erp_loc_a101');
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT('>> Inserting Data Into: silver.erp_loc_a101');
		INSERT INTO silver.erp_loc_a101 (
		cid, cntry
		)
		SELECT
		REPLACE(cid, '-', '') AS cid,
		CASE
			WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
			WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
		END AS cntry
		FROM bronze.erp_loc_a101;

		SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');





		SET @start_time = GETDATE();
		PRINT('>> Truncating Table: silver.erp_px_cat_g1v2');
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT('>> Inserting Data Into: silver.erp_px_cat_g1v2');
		INSERT INTO silver.erp_px_cat_g1v2 (
		id, cat, subcat, maintenance
		)
		SELECT
		id, 
		cat,
		subcat, 
		maintenance 
		FROM bronze.erp_px_cat_g1v2;

		SET @end_time = GETDATE();
        PRINT('>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds');
        PRINT('');
        PRINT('');

		-- Final total duration log
        SET @batch_end_time = GETDATE();
        PRINT('=====================================');
        PRINT('Loading silver Layer is Completed');
        PRINT('>> Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds');
        PRINT('=====================================');

	END TRY
	BEGIN CATCH
	-- Error handling section
        PRINT('=====================================');
        PRINT('ERROR ACCURED DURING LOADING SILVER LAYER.');

        -- Output error details for debugging
        PRINT('Error message' + ERROR_MESSAGE());
        PRINT('Error message' + CAST(ERROR_MESSAGE() AS NVARCHAR(50)));
        PRINT('Error message' + CAST(ERROR_STATE() AS NVARCHAR(50)));
        PRINT('=====================================');
	END CATCH
END

EXEC silver.load_silver;