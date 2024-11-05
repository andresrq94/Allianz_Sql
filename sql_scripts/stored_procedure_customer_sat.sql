USE [Allianz_SQL];
GO

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
