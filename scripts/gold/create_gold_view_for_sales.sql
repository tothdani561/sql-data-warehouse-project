CREATE VIEW gold.fact_sales AS
SELECT
sd.sls_ord_num AS order_number,
pr.product_key,
cu.customer_id,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr ON sd.sls_prd_key = pr.product_number
lEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id

/*
Data lookup

Building Fact
Use the dimension's surrogate keys instead of IDs to easily connect facts with dimensions
*/

/*
Check the data and foreign key integrity (Dimensions)
*/
SELECT product_key FROM gold.dim_products;

SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c 
ON c.customer_key = f.product_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE f.product_key IS NULL