USE [Allianz_SQL];
GO

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