SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.trg_AfterCloudAdoption', N'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_AfterCloudAdoption;
GO

IF OBJECT_ID(N'dbo.DeviceLog', N'U') IS NOT NULL
    DROP TABLE dbo.DeviceLog;
GO
IF OBJECT_ID(N'dbo.CloudAdoption', N'U') IS NOT NULL
    DROP TABLE dbo.CloudAdoption;
GO
IF OBJECT_ID(N'dbo.TransactionSummary', N'U') IS NOT NULL
    DROP TABLE dbo.TransactionSummary;
GO
IF OBJECT_ID(N'dbo.SmartDevice', N'U') IS NOT NULL
    DROP TABLE dbo.SmartDevice;
GO
IF OBJECT_ID(N'dbo.PlatformUser', N'U') IS NOT NULL
    DROP TABLE dbo.PlatformUser;
GO
IF OBJECT_ID(N'dbo.Animal', N'U') IS NOT NULL
    DROP TABLE dbo.Animal;
GO

CREATE TABLE dbo.Animal
(
    AnimalID        INT IDENTITY(1,1) NOT NULL,
    Nickname        NVARCHAR(50) NOT NULL,
    Species         NVARCHAR(20) NOT NULL,
    SpayedStatus    NVARCHAR(20) NOT NULL,
    AdoptionStatus  NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_Animal PRIMARY KEY CLUSTERED (AnimalID),
    CONSTRAINT CK_Animal_Species CHECK (Species IN (N'Dog', N'Cat', N'Other')),
    CONSTRAINT CK_Animal_SpayedStatus CHECK (SpayedStatus IN (N'Unknown', N'NotSpayed', N'Spayed')),
    CONSTRAINT CK_Animal_AdoptionStatus CHECK (AdoptionStatus IN (N'Waiting', N'Adopted', N'MedicalCare'))
);
GO

CREATE TABLE dbo.PlatformUser
(
    UserID      INT IDENTITY(1,1) NOT NULL,
    UserName    NVARCHAR(50) NOT NULL,
    [Role]      NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_PlatformUser PRIMARY KEY CLUSTERED (UserID),
    CONSTRAINT UQ_PlatformUser_UserName UNIQUE (UserName),
    CONSTRAINT CK_PlatformUser_Role CHECK ([Role] IN (N'Visitor', N'Volunteer', N'Staff', N'Admin'))
);
GO

CREATE TABLE dbo.SmartDevice
(
    DeviceID     INT IDENTITY(1,1) NOT NULL,
    DeviceType   NVARCHAR(30) NOT NULL,
    [Location]   NVARCHAR(100) NOT NULL,
    [Status]     NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_SmartDevice PRIMARY KEY CLUSTERED (DeviceID),
    CONSTRAINT CK_SmartDevice_DeviceType CHECK (DeviceType IN (N'Feeder', N'Camera', N'WaterDispenser', N'EnvironmentSensor', N'DoorLock')),
    CONSTRAINT CK_SmartDevice_Status CHECK ([Status] IN (N'Online', N'Offline', N'Maintenance'))
);
GO

CREATE TABLE dbo.CloudAdoption
(
    RecordID       INT IDENTITY(1,1) NOT NULL,
    UserID         INT NOT NULL,
    AnimalID       INT NOT NULL,
    MonthlyAmount  DECIMAL(10,2) NOT NULL,
    StartDate      DATE NOT NULL CONSTRAINT DF_CloudAdoption_StartDate DEFAULT (CONVERT(DATE, GETDATE())),
    EndDate        DATE NULL,

    CONSTRAINT PK_CloudAdoption PRIMARY KEY CLUSTERED (RecordID),
    CONSTRAINT FK_CloudAdoption_User FOREIGN KEY (UserID) REFERENCES dbo.PlatformUser(UserID),
    CONSTRAINT FK_CloudAdoption_Animal FOREIGN KEY (AnimalID) REFERENCES dbo.Animal(AnimalID),
    CONSTRAINT CK_CloudAdoption_MonthlyAmount CHECK (MonthlyAmount > 0),
    CONSTRAINT CK_CloudAdoption_DateRange CHECK (EndDate IS NULL OR EndDate >= StartDate),
    CONSTRAINT UQ_CloudAdoption_UserAnimalStart UNIQUE (UserID, AnimalID, StartDate)
);
GO

CREATE TABLE dbo.TransactionSummary
(
    TransactionID  BIGINT IDENTITY(1,1) NOT NULL,
    TransType      NVARCHAR(30) NOT NULL,
    Amount         DECIMAL(12,2) NOT NULL,
    TransDate      DATETIME2(0) NOT NULL CONSTRAINT DF_TransactionSummary_TransDate DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_TransactionSummary PRIMARY KEY CLUSTERED (TransactionID),
    CONSTRAINT CK_TransactionSummary_TransType CHECK (TransType IN (N'ADOPTION_DEBIT', N'DONATION_INCOME', N'MEDICAL_EXPENSE', N'SUPPLY_EXPENSE', N'OTHER')),
    CONSTRAINT CK_TransactionSummary_Amount CHECK (Amount > 0)
);
GO

CREATE TABLE dbo.DeviceLog
(
    LogID       BIGINT IDENTITY(1,1) NOT NULL,
    DeviceID    INT NOT NULL,
    AnimalID    INT NULL,
    LogType     NVARCHAR(30) NOT NULL,
    EventTime   DATETIME2(0) NOT NULL CONSTRAINT DF_DeviceLog_EventTime DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_DeviceLog PRIMARY KEY CLUSTERED (LogID),
    CONSTRAINT FK_DeviceLog_Device FOREIGN KEY (DeviceID) REFERENCES dbo.SmartDevice(DeviceID),
    CONSTRAINT FK_DeviceLog_Animal FOREIGN KEY (AnimalID) REFERENCES dbo.Animal(AnimalID),
    CONSTRAINT CK_DeviceLog_LogType CHECK (LogType IN (N'Visit', N'Feeding', N'Drinking', N'Motion', N'AbnormalAlert'))
);
GO

-- 复合索引：加速按设备+时间窗口的时序查询
CREATE NONCLUSTERED INDEX IX_DeviceLog_DeviceID_EventTime
ON dbo.DeviceLog (DeviceID ASC, EventTime DESC);
GO

CREATE TRIGGER dbo.trg_AfterCloudAdoption
ON dbo.CloudAdoption
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.TransactionSummary (TransType, Amount, TransDate)
    SELECT
        N'ADOPTION_DEBIT',
        i.MonthlyAmount,
        CAST(i.StartDate AS DATETIME2(0))
    FROM inserted AS i;
END;
GO
