
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