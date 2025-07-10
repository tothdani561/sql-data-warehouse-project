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

SELECT * FROM silver.crm_cust_info;


/*
Check unmatching data
*/
SELECT
REPLACE(cid, '-', '') AS cid,
cntry
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info);

SELECT DISTINCT cntry FROM silver.erp_loc_a101;

SELECT DISTINCT CASE
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry FROM bronze.erp_loc_a101;