Create database TimesheetDB
GO

USE TimesheetDB
GO
    
CREATE TABLE Consultant (
    ConsultantID INT PRIMARY KEY IDENTITY(1,1),
    ConsultantName NVARCHAR(100) NOT NULL
);

-- Create Clients table
CREATE TABLE Client (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    ClientName NVARCHAR(100) NOT NULL
);

-- Create Timesheets table
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
    FOREIGN KEY (ClientID) REFERENCES Client(ClientID),
);


-- Create Leaves table
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
CREATE TABLE AuditLog (
    AuditLogID INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100) NOT NULL,
    Action NVARCHAR(10) NOT NULL,           -- e.g., INSERT, UPDATE, DELETE
    RecordID INT NOT NULL,                  -- ID of the affected row
    ChangedBy NVARCHAR(100) NOT NULL      -- Username or consultant name
      
);
CREATE TABLE ErrorLog (
    ErrorLogID INT PRIMARY KEY IDENTITY(1,1),
    ErrorDate DATETIME DEFAULT GETDATE(),   -- When the error occurred
    ErrorMessage NVARCHAR(MAX) NOT NULL,
    TableName nvarchar(100) NOT NULL,
    FOREIGN KEY (ConsultantID) REFERENCES Consultant(ConsultantID)
);
