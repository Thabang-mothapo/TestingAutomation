CREATE OR ALTER PROCEDURE DeployTimesheetDatabase
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Create Database if it doesn't exist
        IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Timesheet')
        BEGIN
            EXEC('CREATE DATABASE Timesheet');
        END

        -- Use the Timesheet database
        USE Timesheet;
        
        -- Create Consultant table
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Consultant]') AND type in (N'U'))
        BEGIN
            CREATE TABLE Consultant (
                ConsultantID INT PRIMARY KEY IDENTITY(1,1),
                ConsultantName NVARCHAR(100) NOT NULL
            );
        END

        -- Create Client table
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Client]') AND type in (N'U'))
        BEGIN
            CREATE TABLE Client (
                ClientID INT PRIMARY KEY IDENTITY(1,1),
                ClientName NVARCHAR(100) NOT NULL
            );
        END

        -- Create Timesheet table
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Timesheet]') AND type in (N'U'))
        BEGIN
            CREATE TABLE Timesheet (
                TimesheetID INT PRIMARY KEY IDENTITY(1,1),
                ConsultantID INT NOT NULL,
                EntryDate DATE NOT NULL,
                DayOfWeek NVARCHAR(20),
                ClientID INT,
                Description NVARCHAR(500),
                BillingStatus NVARCHAR(20),
                Comments NVARCHAR(1000),
                TotalHours DECIMAL(10,4),
                StartTime DECIMAL(10,4),
                EndTime DECIMAL(10,4),
                FOREIGN KEY (ConsultantID) REFERENCES Consultant(ConsultantID),
                FOREIGN KEY (ClientID) REFERENCES Client(ClientID)
            );
        END

        -- Create Leave table
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Leave]') AND type in (N'U'))
        BEGIN
            CREATE TABLE Leave (
                LeaveID INT PRIMARY KEY IDENTITY(1,1),
                ConsultantID INT NOT NULL,
                LeaveType NVARCHAR(50),
                StartDate DATE,
                EndDate DATE,
                NumberOfDays INT,
                ApprovalObtained NVARCHAR(10),
                SickNote NVARCHAR(10),
                FOREIGN KEY (ConsultantID) REFERENCES Consultant(ConsultantID)
            );
        END

        -- Create AuditLog table
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND type in (N'U'))
        BEGIN
            CREATE TABLE AuditLog (
                AuditLogID INT PRIMARY KEY IDENTITY(1,1),
                TableName NVARCHAR(100) NOT NULL,
                Action NVARCHAR(10) NOT NULL,
                RecordID INT NOT NULL,
                ChangedBy NVARCHAR(100) NOT NULL
            );
        END

        -- Create ErrorLog table
        -- Note: Your ErrorLog table references ConsultantID but it's missing in the schema. Assuming this is an error, I'll remove the FK constraint.
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ErrorLog]') AND type in (N'U'))
        BEGIN
            CREATE TABLE ErrorLog (
                ErrorLogID INT PRIMARY KEY IDENTITY(1,1),
                ErrorDate DATETIME DEFAULT GETDATE(),
                ErrorMessage NVARCHAR(MAX) NOT NULL,
                TableName NVARCHAR(100) NOT NULL
                -- Removed: FOREIGN KEY (ConsultantID) REFERENCES Consultant(ConsultantID)
            );
        END

        PRINT 'Timesheet database deployed successfully.';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        DECLARE @ErrorDate DATETIME = GETDATE();
        DECLARE @TableName NVARCHAR(100) = 'Unknown';

        -- Insert into ErrorLog if the table exists, otherwise print error
        IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ErrorLog]') AND type in (N'U'))
        BEGIN
            INSERT INTO ErrorLog (ErrorDate, ErrorMessage, TableName)
            VALUES (@ErrorDate, @ErrorMessage, @TableName);
        END
        ELSE
        BEGIN
            PRINT 'Error: ' + @ErrorMessage;
        END
        
        THROW;
    END CATCH
END;
GO

-- Execute the stored procedure to deploy the database
EXEC DeployTimesheetDatabase;
GO
