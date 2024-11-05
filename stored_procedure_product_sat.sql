USE [Allianz_SQL];
GO

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