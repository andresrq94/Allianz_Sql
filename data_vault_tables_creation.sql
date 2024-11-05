BEGIN TRY
    -- Drop tables if they exist
    IF OBJECT_ID('dbo.sat_customer', 'U') IS NOT NULL DROP TABLE dbo.sat_customer;
    IF OBJECT_ID('dbo.sat_product', 'U') IS NOT NULL DROP TABLE dbo.sat_product;
    IF OBJECT_ID('dbo.link_sales', 'U') IS NOT NULL DROP TABLE dbo.link_sales;
    IF OBJECT_ID('dbo.hub_customer', 'U') IS NOT NULL DROP TABLE dbo.hub_customer;
    IF OBJECT_ID('dbo.hub_product', 'U') IS NOT NULL DROP TABLE dbo.hub_product;
    IF OBJECT_ID('dbo.staging_product', 'U') IS NOT NULL DROP TABLE dbo.staging_product;
    IF OBJECT_ID('dbo.staging_customer', 'U') IS NOT NULL DROP TABLE dbo.staging_customer;
    IF OBJECT_ID('dbo.staging_sales', 'U') IS NOT NULL DROP TABLE dbo.staging_sales;
    IF OBJECT_ID('dbo.unmatched_sales_log', 'U') IS NOT NULL DROP TABLE dbo.unmatched_sales_log;
    IF OBJECT_ID('dbo.load_log', 'U') IS NOT NULL DROP TABLE dbo.load_log;

    -- Drop partition scheme if it exists
    IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'SaleDateRangePS')
        DROP PARTITION SCHEME SaleDateRangePS;

    -- Drop partition function if it exists
    IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'SaleDateRangePF')
        DROP PARTITION FUNCTION SaleDateRangePF;

END TRY
BEGIN CATCH
    -- Capture error information
    DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
    SET @ErrorMessage = ERROR_MESSAGE();
    SET @ErrorSeverity = ERROR_SEVERITY();
    SET @ErrorState = ERROR_STATE();

    -- Print the error message for debugging purposes
    PRINT 'Error occurred: ' + @ErrorMessage;

    -- Optionally, rethrow the error if you want the transaction to fail
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;



-- Partition Function for sales date, partitioning by year
CREATE PARTITION FUNCTION SaleDateRangePF (DATETIME)
AS RANGE RIGHT FOR VALUES ('2022-01-01', '2023-01-01', '2024-01-01');

CREATE PARTITION SCHEME SaleDateRangePS
AS PARTITION SaleDateRangePF TO ([PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY]);

-- Create Hub for Customers
CREATE TABLE hub_customer (
    hub_customer_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    load_date DATETIME DEFAULT GETDATE(),
    record_source VARCHAR(50) NOT NULL,
    CONSTRAINT unique_customer_id UNIQUE (customer_id)
	) WITH (DATA_COMPRESSION = ROW
);

CREATE UNIQUE INDEX IX_hub_customer_id ON hub_customer(customer_id);


-- Create Hub for Products
CREATE TABLE hub_product (
    hub_product_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT,
    load_date DATETIME DEFAULT GETDATE(),
    record_source VARCHAR(50) NOT NULL,
    CONSTRAINT unique_product_id UNIQUE (product_id)
	) WITH (DATA_COMPRESSION = ROW
);

CREATE UNIQUE INDEX IX_hub_product_id ON hub_product(product_id);

-- Satellite for Customers (Type 2)
CREATE TABLE sat_customer (
    sat_customer_id INT IDENTITY(1,1) PRIMARY KEY,
    hub_customer_id INT,
	hub_personal_id VARCHAR(50) NOT NULL,
	hub_country VARCHAR(50),
	hub_year_of_birth INT,
	hub_income_range VARCHAR(50),
    hub_first_name VARCHAR(100),
    hub_last_name VARCHAR(100),
    effective_from DATETIME DEFAULT GETDATE(),
    effective_to DATETIME DEFAULT '9999-12-31',
    is_current BIT DEFAULT 1,
    CONSTRAINT fk_customer_hub FOREIGN KEY (hub_customer_id) REFERENCES hub_customer(hub_customer_id)
);

-- Satellite for Products (Type 2)
CREATE TABLE sat_product (
    sat_product_id INT IDENTITY(1,1) PRIMARY KEY,
    hub_product_id INT,
    hub_company VARCHAR(100),
	hub_premium INT,
    hub_product_category VARCHAR(100),
	hub_product_detail VARCHAR(100),
    effective_from DATETIME DEFAULT GETDATE(),
    effective_to DATETIME DEFAULT '9999-12-31',
    is_current BIT DEFAULT 1,
    CONSTRAINT fk_productr_hub FOREIGN KEY (hub_product_id) REFERENCES hub_product(hub_product_id)
);

-- Create Link Table for Sales Transactions
CREATE TABLE link_sales (
    sales_link_id INT IDENTITY(1,1),
    hub_customer_id INT,
    hub_product_id INT,
    quantity DECIMAL(10, 2) NOT NULL,
    sale_date DATETIME NOT NULL,
    CONSTRAINT pk_link_sales PRIMARY KEY (sales_link_id, sale_date),  -- Include sale_date in the primary key
    CONSTRAINT fk_customer_link FOREIGN KEY (hub_customer_id) REFERENCES hub_customer(hub_customer_id),
    CONSTRAINT fk_product_link FOREIGN KEY (hub_product_id) REFERENCES hub_product(hub_product_id)
) ON SaleDateRangePS(sale_date)  -- Partitioning on sale_date
WITH (DATA_COMPRESSION = PAGE); 


-- Create staging_customer Table for stored procedure
CREATE TABLE staging_customer (
	customer_id INT,
    hub_customer_id INT,
	personal_id VARCHAR(50) NOT NULL,
	country VARCHAR(50),
	year_of_birth INT,
	income_range VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100)
);


-- Create a staging table for products
CREATE TABLE staging_product (
    product_id INT,       -- Product ID, typically matches the source system�s product ID
	hub_product_id INT,
    company VARCHAR (100),
	premium INT,
	product_category VARCHAR(100), 
    product_detail VARCHAR(100),
);

-- Create a staging table for products
CREATE TABLE staging_sales (
    customer_id INT,
    product_id INT,
    quantity DECIMAL(10, 2) NOT NULL,
	sale_date DATETIME NOT NULL,
);

--Create a table for values that are not product & customer
CREATE TABLE unmatched_sales_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    product_id INT,
    quantity DECIMAL(10, 2),
    sale_date DATETIME,
    reason VARCHAR(50),
    log_date DATETIME DEFAULT GETDATE()
);

-- Table for tracking loading errors and process details
CREATE TABLE load_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    process_name VARCHAR(100),
    log_date DATETIME DEFAULT GETDATE(),
    log_message VARCHAR(500),
    error_code INT
);


