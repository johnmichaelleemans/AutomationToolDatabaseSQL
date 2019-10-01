-- automation database create tables
CREATE DATABASE TestAutomationData 
GO

USE TestAutomationData
GO

CREATE TABLE [Std_LookUpValues] (
    [LookUpName]        NVARCHAR (145) NOT NULL,
    [LookUpValue]       NVARCHAR (145) COLLATE Latin1_General_CS_AS NOT NULL,
    [LookUpDescription] NVARCHAR (145) NULL,
    CONSTRAINT [Std_LookUpValues_PK] PRIMARY KEY CLUSTERED ([LookUpName] ASC, [LookUpValue] ASC)
);
GO

CREATE FUNCTION lookupChecker(@LookUpName NVARCHAR (145) , @LookUpValueCheck NVARCHAR (145)  ) RETURNS BIT
AS
BEGIN
    IF EXISTS 
    (
    SELECT [LookUpValue]
    FROM [Std_LookUpValues]
    WHERE [LookUpName] = @LookUpName  AND [LookUpValue] = @LookUpValueCheck
    ) 
        RETURN 1
    IF @LookUpValueCheck IS NULL
        RETURN 1
    RETURN 0
END

GO

CREATE FUNCTION lookupCheckerPageClass(@LookUpName NVARCHAR (145) ) RETURNS BIT
AS
BEGIN
    IF EXISTS 
    (
    SELECT [PageClassName]
    FROM [PageClass]
    WHERE [PageClassName] = @LookUpName
    ) 
        RETURN 1
    IF @LookUpName IS NULL
        RETURN 1
    RETURN 0
END

GO



CREATE TABLE [TestCase] (
    [TestID]          INT  NOT NULL,
    [JiraTestKey]     NVARCHAR (145) NULL,
    [TestName]        NVARCHAR (145) NOT NULL,
    [TestDescription] NVARCHAR (145) NOT NULL,
    [Application]     NVARCHAR (145) COLLATE Latin1_General_CS_AS NOT NULL,
    [SmokeTest]       BIT            DEFAULT ((0)) NOT NULL,
    [ProdTest]        BIT            DEFAULT ((0)) NOT NULL,
    [RegressionTest]  BIT            DEFAULT ((0)) NOT NULL,
    [FunctionalTest]  BIT            DEFAULT ((0)) NOT NULL,
    [Locale_MT]       NVARCHAR (145) COLLATE Latin1_General_CS_AS NOT NULL,
    CONSTRAINT [TestCase_PK] PRIMARY KEY CLUSTERED ([TestID] ASC),
    CONSTRAINT [ApplicationLookUp_Test_Case] CHECK ([dbo].[lookupChecker]('Application',[Application])=(1)),
    CONSTRAINT [Locale_MTLookUp_Test_Case] CHECK ([dbo].[lookupChecker]('Locale_MT',[Locale_MT])=(1))
);
GO

CREATE TRIGGER  testIDtrigger ON TestCase INSTEAD OF INSERT
AS
BEGIN

DECLARE @gapInSequence INT 
SET @gapInSequence = (
SELECT  TOP 1 *
FROM
( SELECT t1.TestID +1 
AS ID FROM TestCase t1 WHERE NOT EXISTS
(SELECT NULL FROM TestCase t2 WHERE t2.TestID = t1.TestID + 1 )
 UNION 
 SELECT 1 AS ID WHERE NOT EXISTS 
 (SELECT null FROM TestCase t3 WHERE t3.TestID = 1)
 ) AS GapSelect ORDER BY ID ASC
)


--DECLARE @sql nvarchar(max);
--SET @sql = N'ALTER SEQUENCE [TestCaseIDSequence] RESTART WITH ' + cast(@gapInSequence as nvarchar(20)) + ';';
--EXEC SP_EXECUTESQL @sql;

INSERT INTO TestCase
SELECT
	[TestID]  = @gapInSequence,
    [JiraTestKey]        ,
    [TestName]       ,
    [TestDescription],
    [Application]     ,
    [SmokeTest]      ,
    [ProdTest]       ,
    [RegressionTest] ,
    [FunctionalTest]  ,
    [Locale_MT] 
FROM INSERTED;


END
GO


CREATE TRIGGER tescaseIDupdateTrigger ON TestCase 
FOR UPDATE 
AS 
BEGIN  
	IF UPDATE(TestID) 
		BEGIN 
		ROLLBACK 
		RAISERROR('Changes to TestID Locked', 16, 1); END
	ELSE 
		BEGIN 
		UPDATE TestCase
		SET
		[JiraTestKey]   = INSERTED.[JiraTestKey]     ,
		[TestName]    = INSERTED.[TestName]   ,
		[TestDescription] = INSERTED.[TestDescription],
		[Application]   = INSERTED.[Application]  ,
		[SmokeTest]    = INSERTED.[SmokeTest]  ,
		[ProdTest]    = INSERTED.[ProdTest]   ,
		[RegressionTest] = INSERTED.[RegressionTest] ,
		[FunctionalTest] = INSERTED.[FunctionalTest] ,
		[Locale_MT] = INSERTED.[Locale_MT]
		FROM INSERTED
		WHERE [TestCase].[TestID] = INSERTED.[TestID];
		END 

END
GO
-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Application''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TestCase', @level2type = N'COLUMN', @level2name = N'Application';
-- GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Locale_MT''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TestCase', @level2type = N'COLUMN', @level2name = N'Locale_MT';
-- GO


CREATE TABLE [RunManager] (
    [RM_ID]            INT            IDENTITY (1, 1) NOT NULL,
    [TestID]           INT            NOT NULL,
    [TestEnv]          NVARCHAR (145) COLLATE Latin1_General_CS_AS NOT NULL,
    [Execute]          BIT            DEFAULT ((0)) NOT NULL,
    [Iteration_Mode]   NVARCHAR (145) DEFAULT (('RunOneIterationOnly')) COLLATE Latin1_General_CS_AS NOT NULL,
    [Start_Iteration]  INT            DEFAULT ((1)) NOT NULL,
    [End_Iteration]    INT            DEFAULT ((1)) NOT NULL,
    [Single_Browser]   NVARCHAR (145) COLLATE Latin1_General_CS_AS NULL,
    [Driver]           NVARCHAR (145) COLLATE Latin1_General_CS_AS NULL,
    [DriverCreated]    NVARCHAR (145) NULL,
    [Dependency_RM_ID] INT            NULL,
    CONSTRAINT [RunManager_PK] PRIMARY KEY CLUSTERED ([TestID] ASC, [TestEnv] ASC),
    CONSTRAINT [RunManager_FK] FOREIGN KEY ([TestID]) REFERENCES [TestCase] ([TestID]),
    CONSTRAINT [chk_Iteration_Mode_RunMan] CHECK ([dbo].[lookupChecker]('Iteration_Mode',[Iteration_Mode])=(1)),
    CONSTRAINT [chk_Single_Browser_RunMan] CHECK ([dbo].[lookupChecker]('Single_Browser',[Single_Browser])=(1)),
    CONSTRAINT [chk_Driver_RunMan] CHECK ([dbo].[lookupChecker]('Driver',[Driver])=(1)),
    CONSTRAINT [chk_Env_RunMan] CHECK ([dbo].[lookupChecker]('TestEnv',[TestEnv])=(1))
);
GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''TestEnv''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'RunManager', @level2type = N'COLUMN', @level2name = N'TestEnv';
-- GO

CREATE TABLE [FunctionList] (
    [Application]     NVARCHAR (145) collate Latin1_General_CS_AS NULL,
    [Test_Function] NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [Test_Function_Desc] NVARCHAR (145) NULL,
    [Modified_Date] smalldatetime NULL,
    CONSTRAINT [FunctionList_PK] PRIMARY KEY CLUSTERED ([Test_Function] ASC),
    CONSTRAINT [ApplicationLookUp_Func_List] CHECK ([dbo].[lookupChecker]('Application',[Application])=(1))
);
GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Application''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'FunctionList', @level2type = N'COLUMN', @level2name = N'Application';
-- GO


CREATE TABLE [BusinessFlow] (
    [TestID]              INT            NOT NULL,
    [TestEnv]             NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [Test_Function]       NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [Test_Function_Order] INT            NOT NULL,
    CONSTRAINT [BusinessFlow_PK] PRIMARY KEY NONCLUSTERED ([TestID] ASC, [TestEnv] ASC, [Test_Function_Order] ASC),
    CONSTRAINT [BusinessFlow_FK] FOREIGN KEY ([Test_Function]) REFERENCES [FunctionList] ([Test_Function]),
    CONSTRAINT [BusinessFlow_FK01] FOREIGN KEY ([TestID]) REFERENCES [TestCase] ([TestID]),
    CONSTRAINT [chk_Env_BF] CHECK ([dbo].[lookupChecker]('TestEnv',[TestEnv])=(1))
);

GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''TestEnv''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'BusinessFlow', @level2type = N'COLUMN', @level2name = N'TestEnv';

-- GO


-- CREATE TABLE [BrowserDeviceConfig] (
--     [BD_ID]    INT            IDENTITY (1, 1) NOT NULL,
--     [Browser]  NVARCHAR (145) collate Latin1_General_CS_AS NULL,
--     [Device]   NVARCHAR (145) collate Latin1_General_CS_AS NULL,
--     [Rotation] NVARCHAR (145) collate Latin1_General_CS_AS NULL,
--     CONSTRAINT [BrowserDeviceConfig_PK] PRIMARY KEY NONCLUSTERED ([BD_ID] ASC),
--     CONSTRAINT [chk_Browser_BDC] CHECK ([dbo].[lookupChecker]('Browser',[Browser])=(1)),
--     CONSTRAINT [chk_Device_BDC] CHECK ([dbo].[lookupChecker]('Device',[Device])=(1)),
--     CONSTRAINT [chk_Rotation_BDC] CHECK ([dbo].[lookupChecker]('Rotation',[Rotation])=(1))
-- );
-- GO

CREATE TABLE [dbo].[BrowserDeviceConfig] (
    [BD_ID]    INT            IDENTITY (1, 1) NOT NULL,
    [Browser]  NVARCHAR (145) COLLATE Latin1_General_CS_AS NULL,
    [Device]   NVARCHAR (145) COLLATE Latin1_General_CS_AS NULL,
    [Rotation] NVARCHAR (145) COLLATE Latin1_General_CS_AS NULL,
    [headless] NVARCHAR (145) COLLATE Latin1_General_CS_AS NULL,
    [res]      NVARCHAR (145) COLLATE Latin1_General_CS_AS NULL,
    CONSTRAINT [BrowserDeviceConfig_PK] PRIMARY KEY NONCLUSTERED ([BD_ID] ASC),
    CONSTRAINT [chk_Browser_BDC] CHECK ([dbo].[lookupChecker]('Browser',[Browser])=(1)),
    CONSTRAINT [chk_Device_BDC] CHECK ([dbo].[lookupChecker]('Device',[Device])=(1)),
    CONSTRAINT [chk_Rotation_BDC] CHECK ([dbo].[lookupChecker]('Rotation',[Rotation])=(1)),
    CONSTRAINT [chk_headless_BDC] CHECK ([dbo].[lookupChecker]('headless',[headless])=(1)),
    CONSTRAINT [chk_res_BDC] CHECK ([dbo].[lookupChecker]('res',[res])=(1))
);
GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Browser''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'BrowserDeviceConfig', @level2type = N'COLUMN', @level2name = N'Browser';

-- GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Device''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'BrowserDeviceConfig', @level2type = N'COLUMN', @level2name = N'Device';

-- GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Rotation''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'BrowserDeviceConfig', @level2type = N'COLUMN', @level2name = N'Rotation';

-- GO



CREATE TABLE [TestData] (
    [TestID]          INT            NOT NULL,
    [Test_Attribute]  NVARCHAR (145) NOT NULL,
    [Test_Value]      NVARCHAR (145) NOT NULL,
    [TestEnv]         NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [DataSet]         NVARCHAR (145) NOT NULL,
    [Change_Priority] NVARCHAR (145) collate Latin1_General_CS_AS NULL,
    [Iteration]       INT            NOT NULL,
    [BD_ID]           INT    DEFAULT ((1)) NOT NULL,
    CONSTRAINT [TestData_PK] PRIMARY KEY CLUSTERED ([TestID] ASC, [TestEnv] ASC, [DataSet] ASC, [Iteration] ASC, [Test_Attribute] ASC),
    CONSTRAINT [TestData_FK00] FOREIGN KEY ([BD_ID]) REFERENCES [BrowserDeviceConfig] ([BD_ID]),
    CONSTRAINT [TestData_FK01] FOREIGN KEY ([TestID]) REFERENCES [TestCase] ([TestID]),
    CONSTRAINT [chk_DataSet_Test_Data] CHECK ([DataSet]  LIKE 'DataSet-%'),
    CONSTRAINT [chk_Change_Priority_Test_Data] CHECK ([dbo].[lookupChecker]('Change_Priority',[Change_Priority])=(1)),
    CONSTRAINT [chk_Env_Test_Data] CHECK ([dbo].[lookupChecker]('TestEnv',[TestEnv])=(1))
);

GO 

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''TestEnv''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TestData', @level2type = N'COLUMN', @level2name = N'TestEnv';

-- GO

CREATE TABLE [PageClass] (
    [PageClassName]     NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [Application]       NVARCHAR (145) collate Latin1_General_CS_AS NULL,
    [PageClassType]     NVARCHAR (145) collate Latin1_General_CS_AS NULL,
    [Resolution]        NVARCHAR (145) collate Latin1_General_CS_AS NULL,
    [ParentPageClassName] NVARCHAR (145) collate Latin1_General_CS_AS NULL,
    [PageDesign]        NVARCHAR (145) collate Latin1_General_CS_AS NULL,
    CONSTRAINT [PageClass_PK] PRIMARY KEY CLUSTERED ([PageClassName] ASC),
    CONSTRAINT [chk_ApplicationLookUp_PC] CHECK ([dbo].[lookupChecker]('Application',[Application])=(1)),
    CONSTRAINT [chk_PageClassTypeLookUp_PC] CHECK ([dbo].[lookupChecker]('PageClassType',[PageClassType])=(1)),
    CONSTRAINT [chk_ResolutionLookUp_PC] CHECK ([dbo].[lookupChecker]('Resolution',[Resolution])=(1)),
    CONSTRAINT [chk_PageDesignLookUp_PC] CHECK ([dbo].[lookupChecker]('PageDesign',[PageDesign])=(1)),
    CONSTRAINT [chk_ParentPageClassNameLookUp_PC] CHECK ([dbo].[lookupCheckerPageClass]([ParentPageClassName])=(1))
    
);
GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Application''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'PageClass', @level2type = N'COLUMN', @level2name = N'Application';
-- GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''Resolution''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'PageClass', @level2type = N'COLUMN', @level2name = N'Resolution';
-- GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''PageDesign''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'PageClass', @level2type = N'COLUMN', @level2name = N'PageDesign';
-- GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''PageClassType''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'PageClass', @level2type = N'COLUMN', @level2name = N'PageClassType';
-- GO


CREATE TABLE [Function_Page] (
    [Test_Function] NVARCHAR (145)  collate Latin1_General_CS_AS NOT NULL,
    [PageClassName]   NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    CONSTRAINT [Function_Page_PK] PRIMARY KEY CLUSTERED ([Test_Function] ASC, [PageClassName] ASC),
    CONSTRAINT [Function_Page_FK00] FOREIGN KEY ([Test_Function]) REFERENCES [dbo].[FunctionList] ([Test_Function]),
    CONSTRAINT [Function_Page_FK01] FOREIGN KEY ([PageClassName]) REFERENCES [dbo].[PageClass] ([PageClassName])
);
GO

CREATE TABLE [PageClassMethods] (
    [PageClassName]     NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [PageMethod] NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    CONSTRAINT [PageClassMethods_PK] PRIMARY KEY CLUSTERED ([PageClassName] ASC, [PageMethod] ASC),
    CONSTRAINT [PageClassMethods_FK00] FOREIGN KEY ([PageClassName]) REFERENCES [dbo].[PageClass] ([PageClassName])
);
GO

CREATE TABLE [ObjectsTable] (
    [TestEnv]        NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [PageClassName]  NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [PageObjectName] NVARCHAR (145) NOT NULL,
    [MethodUsed]     NVARCHAR (145) collate Latin1_General_CS_AS NOT NULL,
    [PropertyValue]  NVARCHAR (255) NOT NULL,
    CONSTRAINT [ObjectsTable_PK] PRIMARY KEY CLUSTERED ([TestEnv] ASC, [PageClassName] ASC, [PageObjectName] ASC),
    CONSTRAINT [ObjectsTable_FK00] FOREIGN KEY ([PageClassName]) REFERENCES [dbo].[PageClass] ([PageClassName]),
    CONSTRAINT [chk_Env_Objects_Table] CHECK ([dbo].[lookupChecker]('TestEnv',[TestEnv])=(1)),
    CONSTRAINT [chk_MethodUsed_Objects_Table] CHECK ([dbo].[lookupChecker]('MethodUsed',[MethodUsed])=(1))
    
);
GO

CREATE TRIGGER  objectsInsertTrigger ON dbo.ObjectsTable INSTEAD OF INSERT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;
        
        UPDATE dbo.ObjectsTable SET PropertyValue =(Select PropertyValue FROM INSERTED) , MethodUsed =(Select MethodUsed FROM INSERTED)
                WHERE TestEnv = (Select TestEnv FROM INSERTED) 
                    AND PageClassName = (Select PageClassName FROM INSERTED) 
                    AND PageObjectName =(Select PageObjectName FROM INSERTED);
        IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO dbo.ObjectsTable SELECT [TestEnv]  ,[PageClassName]  , [PageObjectName], [MethodUsed], [PropertyValue] FROM INSERTED;
            END
    COMMIT TRANSACTION;
END
GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''TestEnv''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ObjectsTable', @level2type = N'COLUMN', @level2name = N'TestEnv';
-- GO

-- EXECUTE sp_addextendedproperty @name = N'MS_RowSource', @value = N'SELECT Std_LookUpValues.LookUpValue
-- FROM Std_LookUpValues
-- WHERE Std_LookUpValues.LookUpName = ''MethodUsed''
-- ORDER BY Std_LookUpValues.LookUpValue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ObjectsTable', @level2type = N'COLUMN', @level2name = N'MethodUsed';
-- GO


CREATE TABLE [StaticData] (
    [ST_ID]      INT            IDENTITY (1, 1) NOT NULL,
    [CC_Number]  NVARCHAR (145) NULL,
    [CardType]   NVARCHAR (145) NULL,
    [ExpDate]    NVARCHAR (145) NULL,
    [CVV]        INT            NULL,
    [First_Name] NVARCHAR (145) NULL,
    [Last_Name]  NVARCHAR (145) NULL,
    [Phone]      NVARCHAR (145) NULL,
    [Address1]   NVARCHAR (145) NULL,
    [Address2]   NVARCHAR (145) NULL,
    [ZipCode]    NVARCHAR (145) NULL,
    [City]       NVARCHAR (145) NULL,
    [State]      NVARCHAR (145) NULL,
    [emaiID]     NVARCHAR (145) NULL,
    CONSTRAINT [StaticData_PK] PRIMARY KEY CLUSTERED ([ST_ID] ASC)
);
GO

CREATE TABLE [ErrorTable] (
    [ID]        INT            IDENTITY (1, 1) NOT NULL,
    [ErrorID]   NVARCHAR (145) NULL,
    [ErrorDesc] NVARCHAR (145) NULL,
    CONSTRAINT [ErrorTable_PK] PRIMARY KEY CLUSTERED ([ID] ASC)
);
GO

CREATE TABLE [projectTable] (
    [TestID]    INT NOT NULL,
    [ProjectName]   NVARCHAR (145) COLLATE Latin1_General_CS_AS NOT NULL,
    CONSTRAINT [projectTable_PK] PRIMARY KEY CLUSTERED ([TestID] ASC,[ProjectName] ASC ),
    CONSTRAINT [projectTable_FK] FOREIGN KEY ([TestID]) REFERENCES [TestCase] ([TestID]),
    CONSTRAINT [chk_projectNameProjectTable] CHECK ([dbo].[lookupChecker]('ProjectName',[ProjectName])=(1))
);
GO


CREATE TYPE functionListTableTypeCase AS TABLE 
( functionListNames VARCHAR(145) COLLATE Latin1_General_CS_AS
 );
GO

CREATE PROCEDURE sp_getPageClassNames
    @functionlist functionListTableTypeCase READONLY
    AS 
    SET NOCOUNT ON
    SELECT  DISTINCT [PageClassName] FROM  [PageClass] 
    WHERE 
        [ParentPageClassName]  IN  ( 
            (SELECT [PageClassName] FROM [Function_Page]
            WHERE [Test_Function] in (Select functionListNames FROM @functionlist)
            )
        )

    OR 
    
        [PageClassName] IN  ( 
            (SELECT [PageClassName] FROM [Function_Page]
            WHERE [Test_Function] in (Select functionListNames FROM @functionlist)
            )
        )
GO 

 CREATE PROCEDURE sp_getTestExecListSmoke @getReportEnv nvarchar(145)  AS
    SET NOCOUNT ON
    SELECT [TestName] , [Iteration_Mode], [Start_Iteration], [End_Iteration] , [RunManager].[TestID] , [Application],[TestDescription],[Locale_MT],[TestEnv],[Single_Browser],[Driver],[DriverCreated], [JiraTestKey] 
    FROM [TestCase], [RunManager] 
    WHERE  [TestCase].[TestID] = [RunManager].[TestID]  AND [TestEnv] = @getReportEnv AND [Execute] = 1 AND [TestCase].[SmokeTest] = 1
GO

 CREATE PROCEDURE sp_getTestExecListRegression @getReportEnv nvarchar(145) AS
    SET NOCOUNT ON
    SELECT [TestName] , [Iteration_Mode], [Start_Iteration], [End_Iteration] , [RunManager].[TestID] , [Application],[TestDescription],[Locale_MT],[TestEnv],[Single_Browser],[Driver],[DriverCreated], [JiraTestKey] 
    FROM [TestCase], [RunManager] 
    WHERE  [TestCase].[TestID] = [RunManager].[TestID]  AND [TestEnv] = @getReportEnv AND [Execute] = 1 AND [TestCase].[RegressionTest] = 1
GO 

 CREATE PROCEDURE sp_getTestExecListProd @getReportEnv nvarchar(145)  AS
    SET NOCOUNT ON
    SELECT [TestName] , [Iteration_Mode], [Start_Iteration], [End_Iteration] , [RunManager].[TestID] , [Application],[TestDescription],[Locale_MT],[TestEnv],[Single_Browser],[Driver],[DriverCreated], [JiraTestKey] 
    FROM [TestCase], [RunManager] 
    WHERE  [TestCase].[TestID] = [RunManager].[TestID]  AND [TestEnv] = @getReportEnv AND [Execute] = 1 AND [TestCase].[ProdTest] = 1
GO 

--  CREATE PROCEDURE sp_getTestExecListFunctional @getReportEnv nvarchar(145)  AS
--     SET NOCOUNT ON
--     SELECT [TestName] , [Iteration_Mode], [Start_Iteration], [End_Iteration] , [RunManager].[TestID] , [Application],[TestDescription],[Locale_MT],[TestEnv],[Single_Browser],[Driver],[DriverCreated], [JiraTestKey] 
--     FROM [TestCase], [RunManager] 
--     WHERE  [TestCase].[TestID] = [RunManager].[TestID]  AND [TestEnv] = @getReportEnv AND [Execute] = 1 AND [TestCase].[FunctionalTest] = 1
-- GO  
        
 CREATE PROCEDURE sp_getTestExecListFunctional @getReportEnv nvarchar(145),  @testSuiteType nvarchar(145)  AS
    SET NOCOUNT ON
    SELECT [TestName] , [Iteration_Mode], [Start_Iteration], [End_Iteration] , [RunManager].[TestID] , [Application],[TestDescription],[Locale_MT],[TestEnv],[Single_Browser],[Driver],[DriverCreated], [JiraTestKey] 
    FROM [TestCase], [RunManager] , [projectTable]
    WHERE  [TestCase].[TestID] = [RunManager].[TestID]  AND [TestEnv] = @getReportEnv AND [Execute] = 1 AND [TestCase].[FunctionalTest] = 1
    AND [TestCase].[TestID] = [ProjectTable].[TestID] AND [ProjectName] = @testSuiteType
    GO

-- CREATE PROCEDURE sp_getTestExecList @getReportEnv nvarchar(145), @testSuiteType nvarchar(145) AS
--     SET NOCOUNT ON
--     IF @testSuiteType LIKE '%smoke%' 
--         EXEC sp_getTestExecListSmoke @getReportEnv
--     ELSE IF @testSuiteType LIKE '%regression%'
--         EXEC sp_getTestExecListRegression @getReportEnv
--     ELSE IF @testSuiteType LIKE '%functional%'
--         EXEC sp_getTestExecListFunctional @getReportEnv 
--     ELSE IF @testSuiteType LIKE '%prod%'
--         EXEC sp_getTestExecListProd @getReportEnv    
-- GO 

CREATE PROCEDURE sp_getTestExecList @getReportEnv nvarchar(145), @testSuiteType nvarchar(145) AS
    SET NOCOUNT ON
    IF @testSuiteType LIKE '%smoke%' 
        EXEC sp_getTestExecListSmoke @getReportEnv
    ELSE IF @testSuiteType LIKE '%regression%'
        EXEC sp_getTestExecListRegression @getReportEnv
    ELSE IF @testSuiteType LIKE '%prod%'
        EXEC sp_getTestExecListProd @getReportEnv
    ELSE 
        EXEC sp_getTestExecListFunctional @getReportEnv , @testSuiteType
GO

CREATE PROCEDURE sp_allIterationQuery @reportEnv nvarchar(145) , @dataSetNum nvarchar(145) , @testID int
    AS
    SET NOCOUNT ON
    SELECT  Distinct [Iteration] FROM [TestData]     
    Where [TestID] = @testID   
    AND [TestEnv] = @reportEnv   
    AND [DataSet] = 'DataSet-' + @dataSetNum   
    ORDER BY [Iteration] ASC; 
GO

CREATE PROCEDURE sp_getBusinessFlow @envParam nvarchar(145) , @paramID int
    AS
    SET NOCOUNT ON
    SELECT  [Test_Function], [Test_Function_Order]  
    FROM  [BusinessFlow] 
    WHERE  [TestID] = @paramID AND  [TestEnv] = @envParam  
    ORDER BY [Test_Function_Order] ASC;
GO 

CREATE PROCEDURE sp_QueryTestData @testIDParam int, @paramIter int, @paramEnv nvarchar(145), @dataSetNum nvarchar(145)
    AS
    SET NOCOUNT ON
    SELECT [Test_Attribute],[Test_Value]  
    FROM [TestData]  
    WHERE [TestID] = @testIDParam AND [Iteration] =  @paramIter  
         AND [TestEnv] = @paramEnv AND [DataSet] = 'DataSet-'+ @dataSetNum ;
GO

CREATE PROCEDURE sp_queryTestConfig  @testIDParam int, @paramIter int, @paramEnv nvarchar(145), @dataSetNum nvarchar(145)
    AS
    SET NOCOUNT ON
    SELECT Distinct [Browser],[Device],[Rotation],[headless],[res]
    FROM [BrowserDeviceConfig] , [TestData] 
    WHERE [TestID] = @testIDParam AND [Iteration] = @paramIter  
            AND [TestEnv] = @paramEnv AND [DataSet] = 'DataSet-'+ @dataSetNum 
            AND [TestData].[BD_ID] = [BrowserDeviceConfig].[BD_ID]; 
GO

CREATE PROCEDURE sp_objectsParamQuery @paramEnv nvarchar(145),@paramClass nvarchar(145)
    AS
    SET NOCOUNT ON
    SELECT [PageObjectName], [MethodUsed] , [PropertyValue]  
    FROM [ObjectsTable]  
    WHERE [TestEnv] = @paramEnv AND [PageClassName] = @paramClass ;
GO