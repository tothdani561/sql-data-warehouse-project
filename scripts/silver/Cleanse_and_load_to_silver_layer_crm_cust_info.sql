/*
========================================
Script: Cleanse and Load to Silver Layer
Author: [Tóth Dániel]
Description:
  This script performs cleansing and standardization of CRM customer data
  from the Bronze layer and loads the results into the Silver layer.

  Key operations include:
    - Removal of duplicate customer records (based on cst_id)
    - Trimming of whitespace in name fields
    - Standardization of coded values (e.g., 'M' → 'Male')
    - Retention of only the latest record per customer
    - Post-load data validation for consistency and quality

  Assumptions:
    - The target table silver.crm_cust_info expects unique cst_id values
    - Cleaned and standardized fields are required for downstream processing
========================================

==============================
: CRM Customer Cleansing & Load
Source: bronze.crm_cust_info
Target: silver.crm_cust_info
==============================
*/


/*
Check for nulls or duplicates in Primary Key
Expectation: No Result
*/
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL


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



SELECT * FROM bronze.crm_cust_info;


/*
--------------------------------
Check for unwanted spaces
--------------------------------
*/
SELECT *
FROM bronze.crm_cust_info;

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

/*
No result -> GOOD
*/
SELECT cst_marital_status
FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

/*
Data Standardization & Consistency
*/
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info



/*
--------------------------------
Check the result
--------------------------------
*/
SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

SELECT * FROM silver.crm_cust_info