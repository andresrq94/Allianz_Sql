-- Create a temporary staging table
CREATE TABLE #Staging_Customers (
	customer_id INT IDENTITY(1,1) PRIMARY KEY,
    personal_id VARCHAR(50),
	country VARCHAR(50),
	year_of_birth INT,
	income_range VARCHAR(50),
	merge_key VARCHAR(150),
    first_name VARCHAR(100),
    last_name VARCHAR(100)
);

-- Bulk insert from CSV file
BULK INSERT #Staging_Customers
FROM 'C:\Users\AndresRoldan\Desktop\Andres\Allianz\python_assignment\build\dim_customer.csv'
WITH (
    FIELDTERMINATOR = ',',  -- Specify the column delimiter
    ROWTERMINATOR = '\n',   -- Specify the row delimiter
    FIRSTROW = 2            -- Skip the header row
);

-- Create a temporary table to hold the new customer IDs
CREATE TABLE #NewCustomerIDs (
    hub_customer_id INT,
    customer_id VARCHAR(50)
);

-- Insert data into the hub table and get the new IDs
INSERT INTO dbo.hub_customer (customer_id, record_source)
OUTPUT INSERTED.hub_customer_id, INSERTED.customer_id INTO #NewCustomerIDs (hub_customer_id, customer_id)  -- Capture the new IDs
SELECT customer_id, 'allianz_project'
FROM #Staging_Customers
WHERE customer_id IS NOT NULL;

-- Insert data into the satellite table using the new IDs
INSERT INTO dbo.sat_customer (hub_customer_id, hub_personal_id, hub_country, hub_year_of_birth, hub_income_range, hub_first_name, hub_last_name)
SELECT n.hub_customer_id, sc.personal_id, sc.country, sc.year_of_birth, sc.income_range, sc.first_name, sc.last_name
FROM #Staging_Customers sc
JOIN #NewCustomerIDs n ON sc.customer_id = n.customer_id;  -- Join to get the correct hub_customer_id

-- Clean up temporary tables
DROP TABLE #Staging_Customers;
DROP TABLE #NewCustomerIDs;



-- Create a temporary staging table
CREATE TABLE #Staging_Products (
	product_id INT IDENTITY(1,1) PRIMARY KEY,
    company VARCHAR(50),
	premium INT,
	merge_key VARCHAR(150),
    product_category VARCHAR(100),
	product_detail VARCHAR(100),
);

-- Bulk insert from CSV file
BULK INSERT #Staging_Products
FROM 'C:\Users\AndresRoldan\Desktop\Andres\Allianz\python_assignment\build\dim_product.csv'
WITH (
    FIELDTERMINATOR = ',',  -- Specify the column delimiter
    ROWTERMINATOR = '\n',   -- Specify the row delimiter
    FIRSTROW = 2            -- Skip the header row
);

-- Create a temporary table to hold the new customer IDs
CREATE TABLE #NewProductsIDs (
    hub_product_id INT,
    product_id INT
);

-- Insert data into the hub table and get the new IDs
INSERT INTO dbo.hub_product (product_id, record_source)
OUTPUT INSERTED.hub_product_id, INSERTED.product_id INTO #NewProductsIDs (hub_product_id, product_id)  -- Capture the new IDs
SELECT product_id, 'allianz_project'
FROM #Staging_Products
WHERE product_id IS NOT NULL;

-- Insert data into the satellite table using the new IDs
INSERT INTO dbo.sat_product (hub_product_id, hub_company, hub_premium, hub_product_category, hub_product_detail)
SELECT n.hub_product_id, sc.company, sc.premium, sc.product_category, sc.product_detail
FROM #Staging_Products sc
JOIN #NewProductsIDs n ON sc.product_id = n.product_id;  -- Join to get the correct hub_customer_id

-- Clean up temporary tables
DROP TABLE #Staging_Products;
DROP TABLE #NewProductsIDs;


-- Create a temporary staging table
CREATE TABLE #Staging_Sales (
	transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
	product_id INT,
    quantity DECIMAL(10, 2),
	sale_date DATETIME,
);

-- Bulk insert from CSV file
BULK INSERT #Staging_Sales
FROM 'C:\Users\AndresRoldan\Desktop\Andres\Allianz\python_assignment\build\sales.csv'
WITH (
    FIELDTERMINATOR = ',',  -- Specify the column delimiter
    ROWTERMINATOR = '\n',   -- Specify the row delimiter
    FIRSTROW = 2            -- Skip the header row
);


-- Insert data into the sales table using
INSERT INTO dbo.link_sales (hub_customer_id, hub_product_id, quantity, sale_date)
SELECT customer_id, product_id, quantity, sale_date
FROM #Staging_Sales

-- Clean up temporary tables
DROP TABLE #Staging_Sales;
