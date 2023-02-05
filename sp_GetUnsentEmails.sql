CREATE PROCEDURE [dbo].[sp_GetUnsentEmails]
AS   
BEGIN
	exec spGenerateReminderEmails

	Select ID, ToEmail as ToUserEmail, ToName as ToUserName, FromEmail as FromUserEmail, FromName as FromUserName, Subject, Body, TemplateID 
	from EmailQueue 
	where Sent is null and ToEmail is not null
END