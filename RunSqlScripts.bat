@echo off
SETLOCAL

REM Set SQL Server details
SET SERVER_NAME=localhost\SQLEXPRESS
SET DATABASE_NAME=Allianz_SQL

REM Prompt user for SQL Server username and password
SET /P USERNAME=Enter SQL Server username: 
SET /P PASSWORD=Enter SQL Server password: 

REM Path to your SQL scripts (no trailing backslash)
SET SQL_PATH="C:\Users\AndresRoldan\Desktop\Andres\Allianz\sql_assignment\sql_scripts"

REM Full path to sqlcmd executable (if not in PATH)
SET SQLCMD_PATH="C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"

REM Execute each SQL script in the specified order
echo Executing data_vault_tables_creation.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\data_vault_tables_creation.sql
IF ERRORLEVEL 1 (
    echo Failed to execute data_vault_tables_creation.sql
    pause
    exit /b %ERRORLEVEL%
)

echo Executing bulk_insert_data.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\bulk_insert_data.sql
IF ERRORLEVEL 1 (
    echo Failed to execute bulk_insert_data.sql
    pause
    exit /b %ERRORLEVEL%
)

echo Executing stored_procedure_customer_hub.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\stored_procedure_customer_hub.sql
IF ERRORLEVEL 1 (
    echo Failed to execute stored_procedure_customer_hub.sql
    pause
    exit /b %ERRORLEVEL%
)

echo Executing stored_procedure_customer_sat.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\stored_procedure_customer_sat.sql
IF ERRORLEVEL 1 (
    echo Failed to execute stored_procedure_customer_sat.sql
    pause
    exit /b %ERRORLEVEL%
)

echo Executing stored_procedure_link_sales.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\stored_procedure_link_sales.sql
IF ERRORLEVEL 1 (
    echo Failed to execute stored_procedure_link_sales.sql
    pause
    exit /b %ERRORLEVEL%
)

echo Executing stored_procedure_product_hub.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\stored_procedure_product_hub.sql
IF ERRORLEVEL 1 (
    echo Failed to execute stored_procedure_product_hub.sql
    pause
    exit /b %ERRORLEVEL%
)

echo Executing stored_procedure_product_sat.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\stored_procedure_product_sat.sql
IF ERRORLEVEL 1 (
    echo Failed to execute stored_procedure_product_sat.sql
    pause
    exit /b %ERRORLEVEL%
)

echo Executing stored_procedure_product_sat.sql
%SQLCMD_PATH% -S %SERVER_NAME% -d %DATABASE_NAME% -U %USERNAME% -P %PASSWORD% -i %SQL_PATH%\stored_procedure_all_tables.sql
IF ERRORLEVEL 1 (
    echo Failed to execute stored_procedure_all_tables.sql
    pause
    exit /b %ERRORLEVEL%
)

echo All scripts executed successfully.
pause
ENDLOCAL
