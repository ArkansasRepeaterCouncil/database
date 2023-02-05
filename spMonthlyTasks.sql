CREATE PROCEDURE [dbo].[spMonthlyTasks]
AS   
BEGIN
	exec spNotifyExpiringTrustees;
	exec spNotifyLateTrustees;
END;