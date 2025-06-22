-- Ensure the script runs in the master database initially
USE master;
GO

-- Drop the procedure if it exists to avoid conflicts
IF OBJECT_ID('DeployTimesheetDatabase', 'P') IS NOT NULL
    DROP PROCEDURE DeployTimesheetDatabase;
GO

-- Create the DeployTimesheetDatabase stored procedure
CREATE PROCEDURE DeployTimesheetDatabase
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Create Timesheet database if it doesn't exist
        IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Timesheet')
        BEGIN
            CREATE DATABASE Timesheet;
        END

        -- Use dynamic SQL to create tables in Timesheet database
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            USE Timesheet;

            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Consultant'')
            CREATE TABLE Consultant (ConsultantId INT PRIMARY KEY, Name NVARCHAR(100), Email NVARCHAR(100));

            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Client'')
            CREATE TABLE Client (ClientId INT PRIMARY KEY, Name NVARCHAR(100), Contact NVARCHAR(100));

            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Timesheet'')
            CREATE TABLE Timesheet (TimesheetId INT PRIMARY KEY, ConsultantId INT, ClientId INT, DateWorked DATE, HoursWorked DECIMAL(5,2),
                                    FOREIGN KEY (ConsultantId) REFERENCES Consultant(ConsultantId),
                                    FOREIGN KEY (ClientId) REFERENCES Client(ClientId));

            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Leave'')
            CREATE TABLE Leave (LeaveId INT PRIMARY KEY, ConsultantId INT, StartDate DATE, EndDate DATE, Reason NVARCHAR(200),
                                FOREIGN KEY (ConsultantId) REFERENCES Consultant(ConsultantId));

            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''AuditLog'')
            CREATE TABLE AuditLog (AuditLogId INT PRIMARY KEY IDENTITY, EventType NVARCHAR(100), EventDateTime DATETIME, Details NVARCHAR(500));

            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ErrorLog'')
            CREATE TABLE ErrorLog (ErrorLogId INT PRIMARY KEY IDENTITY, ErrorMessage NVARCHAR(500), ErrorDateTime DATETIME, StackTrace NVARCHAR(MAX));
        ';
        EXEC sp_executesql @SQL;

        -- Log successful deployment in Timesheet.dbo.AuditLog
        SET @SQL = N'
            INSERT INTO Timesheet.dbo.AuditLog (EventType, EventDateTime, Details)
            VALUES (''Database Deployment'', GETDATE(), ''Timesheet database deployed successfully.'');
        ';
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        -- Log error in Timesheet.dbo.ErrorLog using dynamic SQL
        DECLARE @ErrorSQL NVARCHAR(MAX);
        DECLARE @ErrorMsg NVARCHAR(500) = ERROR_MESSAGE();
        DECLARE @StackTrace NVARCHAR(MAX) = 'Procedure: DeployTimesheetDatabase, Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        SET @ErrorSQL = N'
            INSERT INTO Timesheet.dbo.ErrorLog (ErrorMessage, ErrorDateTime, StackTrace)
            VALUES (@ErrorMsg, GETDATE(), @StackTrace);
        ';
        BEGIN TRY
            EXEC sp_executesql @ErrorSQL,
                N'@ErrorMsg NVARCHAR(500), @StackTrace NVARCHAR(MAX)',
                @ErrorMsg, @StackTrace;
        END TRY
        BEGIN CATCH
            -- If error logging fails, print the error for debugging
            PRINT 'Failed to log error to Timesheet.dbo.ErrorLog: ' + ERROR_MESSAGE();
        END CATCH

        -- Throw the original error
        THROW 50001, 'Failed to deploy Timesheet database. Check Timesheet.dbo.ErrorLog for details.', 1;
    END CATCH
END;
GO

-- Execute the procedure
EXEC DeployTimesheetDatabase;
GO
