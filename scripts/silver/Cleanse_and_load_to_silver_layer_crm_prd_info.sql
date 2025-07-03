/*
========================================
Script: Cleanse and Load Product Data to Silver Layer
Author: [Tóth Dániel]
Description:
  This script performs cleansing, enrichment and standardisation of CRM product
  data residing in the Bronze layer and loads the curated result into the Silver
  layer.

  Key operations include:
    - (Re)create target table `silver.crm_prd_info` with harmonised datatypes
      and new technical columns (`cat_id`, `dwh_create_date`).
    - Derive a business category identifier (`cat_id`) from the product key.
    - Decode abbreviated product line flags to descriptive values
      (e.g. 'M' → 'Mountain').
    - Impute missing product cost with 0 (business rule: unknown cost = free).
    - Compute a surrogate product end‑date (`prd_end_dt`) using the LEAD window
      function so that each record’s validity ends the day before the next
      record starts.
    - Execute a suite of post‑load data‑quality checks to validate duplicates,
      trimming, negative costs, date consistency and domain values.

  Assumptions:
    - `prd_id` is the business primary key and must be unique in the Silver
      layer.
    - `prd_start_dt` is populated for every record in Bronze. If `prd_end_dt` is
      NULL, the product is considered currently active.
    - Bronze data may contain duplicates and inconsistent coding which will be
      resolved here.
========================================

==============================
: CRM Product Cleansing & Load
Source: bronze.crm_prd_info
Target: silver.crm_prd_info
==============================
*/

/*--------------------------------------------------------------------------
: 1) (Re)Create target table in Silver layer
   – Ensures we start from a clean slate and that column definitions match the
     agreed Silver contract. If the table already exists it will be dropped.
--------------------------------------------------------------------------*/
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id         INT NOT NULL,                      -- Business PK
    cat_id         NVARCHAR(50),                      -- Derived category key
    prd_key        NVARCHAR(50),                      -- Natural product key (without cat‑part)
    prd_nm         NVARCHAR(100),                     -- Product name
    prd_cost       INT NULL,                          -- Cost in smallest currency unit (0 ⇒ unknown)
    prd_line       NVARCHAR(50),                      -- Decoded product line description
    prd_start_dt   DATE NULL,                         -- Valid‑from date
    prd_end_dt     DATE NULL,                         -- Valid‑to date (derived)
    dwh_create_date DATETIME2 DEFAULT GETDATE()       -- ETL load timestamp
);
GO

/*--------------------------------------------------------------------------
: 2) Load cleansed & enriched data from Bronze
--------------------------------------------------------------------------*/
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
GO

/*--------------------------------------------------------------------------
: 3) Post‑load Data Quality Checks
   – These checks must all return zero rows. Any result indicates a breach of
     data‑quality rules that should be investigated before progressing to Gold.
--------------------------------------------------------------------------*/

/* 3.1 Duplicates / NULLs in primary key */
SELECT prd_id, COUNT(*) AS rows_per_prd_id
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

/* 3.2 Leading / trailing spaces in product name */
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

/* 3.3 NULL or negative product cost */
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;

/* 3.4 End date earlier than start date */
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

/* 3.5 Value‑domain check for product line */
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

/*--------------------------------------------------------------------------
: 4) Spot‑check result set (optional, for debugging / audit)
--------------------------------------------------------------------------*/
SELECT *
FROM silver.crm_prd_info;

/*--------------------------------------------------------------------------
: 5) Regression test – verify LEAD logic on a sample of product keys
   – Compare stored prd_end_dt with a freshly computed value (prd_end_dt_test)
--------------------------------------------------------------------------*/
SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    LEAD(prd_start_dt) OVER (
        PARTITION BY prd_key
        ORDER BY prd_start_dt
    ) - 1 AS prd_end_dt_test
FROM silver.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');

/* End of script */
