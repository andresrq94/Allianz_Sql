
USE [Allianz_SQL];
GO

-- Procedure for incremental loading in customer hub
CREATE OR ALTER PROCEDURE [dbo].[IncrementalLoad_Hub_Customer] AS
BEGIN TRY
    -- Insert new records from the staging table into the hub
    INSERT INTO hub_customer (customer_id, record_source)
    SELECT DISTINCT s.customer_id, 'Staging'
    FROM staging_customer AS s
    LEFT JOIN hub_customer AS h ON h.customer_id = s.customer_id
    WHERE h.customer_id IS NULL;  -- Only insert customer IDs that do not already exist in the hub

    -- Update staging table to reflect the hub_customer_id for matching records
    UPDATE staging_customer
    SET hub_customer_id = h.hub_customer_id
    FROM staging_customer AS sp
    INNER JOIN hub_customer AS h ON sp.customer_id = h.customer_id;

    -- Log a success message for this load operation
    INSERT INTO load_log (process_name, log_message) 
    VALUES ('IncrementalLoad_Hub_Customer', 'Load successful.');
END TRY
BEGIN CATCH
    -- Log an error message if an error occurs during execution
    INSERT INTO load_log (process_name, log_message, error_code) 
    VALUES ('IncrementalLoad_Hub_Customer', ERROR_MESSAGE(), ERROR_NUMBER());
END CATCH;



-- Procedure for incremental loading in product hub
CREATE OR ALTER PROCEDURE [dbo].[IncrementalLoad_Hub_Product] AS
BEGIN TRY
    -- Insert new records from the staging table into the hub
    INSERT INTO hub_product (product_id, record_source)
    SELECT DISTINCT s.product_id, 'Staging'
    FROM staging_product AS s
    LEFT JOIN hub_product AS h ON h.product_id = s.product_id
    WHERE h.product_id IS NULL;  -- Only insert product IDs that do not already exist in the hub

    -- Update staging table to reflect the hub_product_id for matching records
    UPDATE staging_product
    SET hub_product_id = h.hub_product_id
    FROM staging_product AS sp
    INNER JOIN hub_product AS h ON sp.product_id = h.product_id;

    -- Log a success message for this load operation
    INSERT INTO load_log (process_name, log_message) 
    VALUES ('IncrementalLoad_Hub_Product', 'Load successful.');
END TRY
BEGIN CATCH
    -- Log an error message if an error occurs during execution
    INSERT INTO load_log (process_name, log_message, error_code) 
    VALUES ('IncrementalLoad_Hub_Product', ERROR_MESSAGE(), ERROR_NUMBER());
END CATCH;



-- Procedure for incremental loading in product satellite
CREATE OR ALTER PROCEDURE [dbo].[IncrementalLoad_Sat_Product] AS
BEGIN TRY
    -- Declare a variable to hold the current date and time
    DECLARE @current_time DATETIME = GETDATE();

    -- Deactivate outdated records in the satellite table
    UPDATE sat_product
    SET effective_to = @current_time, is_current = 0
    FROM sat_product AS sp
    INNER JOIN staging_product AS s ON sp.hub_product_id = s.product_id
    WHERE sp.is_current = 1
      AND (sp.hub_company != s.company
           OR sp.hub_product_category != s.product_category);

    -- Insert new records into the satellite table with current effective dates
    INSERT INTO sat_product (hub_product_id, hub_company, hub_premium, 
                              hub_product_category, hub_product_detail, effective_from)
    SELECT h.hub_product_id, s.company, s.premium, s.product_category, s.product_detail, @current_time
    FROM staging_product AS s
    INNER JOIN hub_product AS h ON h.product_id = s.product_id
    LEFT JOIN sat_product AS sp ON sp.hub_product_id = h.hub_product_id AND sp.is_current = 1
    WHERE sp.sat_product_id IS NULL  -- Check for new entries
       OR (sp.hub_company != s.company 
           OR sp.hub_product_category != s.product_category);  -- Update existing records if changes are detected

    -- Log a success message for this load operation
    INSERT INTO load_log (process_name, log_message) 
    VALUES ('IncrementalLoad_Sat_Product', 'Load successful.');
END TRY
BEGIN CATCH
    -- Log an error message if an error occurs during execution
    INSERT INTO load_log (process_name, log_message, error_code) 
    VALUES ('IncrementalLoad_Sat_Product', ERROR_MESSAGE(), ERROR_NUMBER());
END CATCH;



-- Procedure for incremental loading in customer satellite
CREATE OR ALTER PROCEDURE [dbo].[IncrementalLoad_Sat_Customer] AS
BEGIN TRY
    -- Declare a variable to hold the current date and time
    DECLARE @current_time DATETIME = GETDATE();

    -- Deactivate outdated records in the satellite table
    UPDATE sat_customer
    SET effective_to = @current_time, is_current = 0
    FROM sat_customer AS sc
    INNER JOIN staging_customer AS s ON sc.hub_customer_id = s.hub_customer_id
    WHERE sc.is_current = 1  -- Only update current records
      AND (sc.hub_first_name != s.first_name 
           OR sc.hub_last_name != s.last_name
           OR sc.hub_income_range != s.income_range);  -- Check for changes in key fields

    -- Insert new records with the latest values into the satellite table
    INSERT INTO sat_customer (hub_customer_id, hub_personal_id, hub_country, hub_year_of_birth, 
                              hub_income_range, hub_first_name, hub_last_name, effective_from)
    SELECT s.hub_customer_id, s.personal_id, s.country, s.year_of_birth, 
           s.income_range, s.first_name, s.last_name, @current_time
    FROM staging_customer AS s
    INNER JOIN hub_customer AS h ON h.hub_customer_id = s.hub_customer_id
    LEFT JOIN sat_customer AS sc ON sc.hub_customer_id = h.hub_customer_id AND sc.is_current = 1
    WHERE sc.sat_customer_id IS NULL  -- Check for new entries
       OR (sc.hub_first_name != s.first_name 
           OR sc.hub_last_name != s.last_name
           OR sc.hub_income_range != s.income_range);  -- Update existing records if changes are detected

    -- Log a success message for this load operation
    INSERT INTO load_log (process_name, log_message) 
    VALUES ('IncrementalLoad_Sat_Customer', 'Load successful.');
END TRY
BEGIN CATCH
    -- Log an error message if an error occurs during execution
    INSERT INTO load_log (process_name, log_message, error_code) 
    VALUES ('IncrementalLoad_Sat_Customer', ERROR_MESSAGE(), ERROR_NUMBER());
END CATCH;



-- Procedure for incremental loading in link sales
CREATE OR ALTER PROCEDURE [dbo].[IncrementalLoad_Link_Sales] AS
BEGIN TRY   
    -- Log records with missing `customer_id`
    INSERT INTO unmatched_sales_log (customer_id, product_id, quantity, sale_date, reason)
    SELECT s.customer_id, s.product_id, s.quantity, s.sale_date, 'Missing customer_id'
    FROM staging_sales AS s
    LEFT JOIN hub_customer AS c ON c.customer_id = s.customer_id
    WHERE c.hub_customer_id IS NULL;  -- Log where customer IDs are not found

    -- Log records with missing `product_id`
    INSERT INTO unmatched_sales_log (customer_id, product_id, quantity, sale_date, reason)
    SELECT s.customer_id, s.product_id, s.quantity, s.sale_date, 'Missing product_id'
    FROM staging_sales AS s
    LEFT JOIN hub_product AS p ON p.product_id = s.product_id
    WHERE p.hub_product_id IS NULL;  -- Log where product IDs are not found

    -- Insert matching records into `link_sales` from staging
    INSERT INTO link_sales (hub_customer_id, hub_product_id, quantity, sale_date)
    SELECT c.hub_customer_id, p.hub_product_id, s.quantity, s.sale_date
    FROM staging_sales AS s
    INNER JOIN hub_customer AS c ON c.customer_id = s.customer_id
    INNER JOIN hub_product AS p ON p.product_id = s.product_id;

    -- Log a success message for this load operation
    INSERT INTO load_log (process_name, log_message) 
    VALUES ('IncrementalLoad_Link_Sales', 'Load successful.');
END TRY
BEGIN CATCH
    -- Log an error message if an error occurs during execution
    INSERT INTO load_log (process_name, log_message, error_code) 
    VALUES ('IncrementalLoad_Link_Sales', ERROR_MESSAGE(), ERROR_NUMBER());
END CATCH;



-- Procedure for all incremental loading together
CREATE OR ALTER PROCEDURE [dbo].[IncrementalLoad_All_Tables]
AS
BEGIN
    -- Begin transaction to ensure all or nothing execution
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Call the procedure to load customers into the hub
        EXEC IncrementalLoad_Hub_Customer;

        -- Call the procedure to load products into the hub
        EXEC IncrementalLoad_Hub_Product;

        -- Call the procedure to load customers into the satellite
        EXEC IncrementalLoad_Sat_Customer;

        -- Call the procedure to load products into the satellite
        EXEC IncrementalLoad_Sat_Product;

        -- Call the procedure to link sales
        EXEC IncrementalLoad_Link_Sales;

        -- Clean up staging tables after processing
        DELETE FROM staging_product;
        DELETE FROM staging_customer;
        DELETE FROM staging_sales;

        -- Log a success message for this complete load operation
        INSERT INTO load_log (process_name, log_message) 
        VALUES ('IncrementalLoad_All_Tables', 'Load successful.');

        -- Commit the transaction if all procedures succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if any error occurs
        ROLLBACK TRANSACTION;

        -- Handle the error by logging it
        DECLARE @ErrorMessage NVARCHAR(4000);
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Log the error for this complete load operation
        INSERT INTO load_log (process_name, log_message, error_code) 
        VALUES ('IncrementalLoad_All_Tables', ERROR_MESSAGE(), ERROR_NUMBER());
    END CATCH
END;
