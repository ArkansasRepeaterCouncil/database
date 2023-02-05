CREATE PROCEDURE [dbo].[spDailyTasks]
AS   
BEGIN
	exec spGenerateReminderEmails;
END;