USE [Allianz_SQL];
GO

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
