-- Ensure the script runs in the master database initially
USE master;
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

        -- Switch to Timesheet database (handled dynamically here)
        -- Use dynamic SQL to avoid USE statement inside procedure
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'USE Timesheet; ' +
                  N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Consultant'') ' +
                  N'CREATE TABLE Consultant (ConsultantId INT PRIMARY KEY, Name NVARCHAR(100), Email NVARCHAR(100)); ' +
                  N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Client'') ' +
                  N'CREATE TABLE Client (ClientId INT PRIMARY KEY, Name NVARCHAR(100), Contact NVARCHAR(100)); ' +
                  N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Timesheet'') ' +
                  N'CREATE TABLE Timesheet (TimesheetId INT PRIMARY KEY, ConsultantId INT, ClientId INT, DateWorked DATE, HoursWorked DECIMAL(5,2), FOREIGN KEY (ConsultantId) REFERENCES Consultant(ConsultantId), FOREIGN KEY (ClientId) REFERENCES Client(ClientId)); ' +
                  N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''Leave'') ' +
                  N'CREATE TABLE Leave (LeaveId INT PRIMARY KEY, ConsultantId INT, StartDate DATE, EndDate DATE, Reason NVARCHAR(200), FOREIGN KEY (ConsultantId) REFERENCES Consultant(ConsultantId)); ' +
                  N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''AuditLog'') ' +
                  N'CREATE TABLE AuditLog (AuditLogId INT PRIMARY KEY IDENTITY, EventType NVARCHAR(100), EventDateTime DATETIME, Details NVARCHAR(500)); ' +
                  N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''ErrorLog'') ' +
                  N'CREATE TABLE ErrorLog (ErrorLogId INT PRIMARY KEY IDENTITY, ErrorMessage NVARCHAR(500), ErrorDateTime DATETIME, StackTrace NVARCHAR(MAX));';

        EXEC sp_executesql @SQL;

        -- Log successful deployment
        INSERT INTO Timesheet.AuditLog (EventType, EventDateTime, Details)
        VALUES ('Database Deployment', GETDATE(), 'Timesheet database deployed successfully.');
    END TRY
    BEGIN CATCH
        -- Log error
        INSERT INTO Timesheet.ErrorLog (ErrorMessage, ErrorDateTime, StackTrace)
        VALUES (
            ERROR_MESSAGE(),
            GETDATE(),
            'Procedure: DeployTimesheetDatabase, Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10))
        );

        -- Throw the error with proper syntax
        THROW 50001, 'Failed to deploy Timesheet database. Check ErrorLog for details.', 1;
    END CATCH
END;
GO

-- Execute the procedure
EXEC DeployTimesheetDatabase;
GO
