USE [Allianz_SQL];
GO

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