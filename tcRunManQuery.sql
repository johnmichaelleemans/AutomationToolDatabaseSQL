--create local runManager from a query
--save file as tcRunManDB.xls
--have single sheet  named as Query(default from MSQL server management studio)

SELECT [TestName] , [Iteration_Mode], [Start_Iteration], [End_Iteration] , [RunManager].[TestID] ,[Execute], [Application],[TestDescription],[Locale_MT],[TestEnv],[Single_Browser],[Driver],[DriverCreated], [QCTestID],[ProdTest],[RegressionTest],[SmokeTest],[FunctionalTest] 
FROM [TestCase], [RunManager] 
WHERE  [TestCase].[TestID] = [RunManager].[TestID]  