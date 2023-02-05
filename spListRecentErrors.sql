CREATE PROCEDURE [dbo].[spListRecentErrors]      
AS   
BEGIN
	Select top 20
		ID,
		TimeStamp,
		JSON_VALUE(jsonData,'$.url') url, 
		JSON_VALUE(jsonData,'$.querystring') querystring, 
		JSON_VALUE(jsonData,'$.message') message, 
		JSON_VALUE(jsonData,'$.source') source, 
		JSON_VALUE(jsonData,'$.stacktrace') stacktrace
	from EventLog
	Where Type = 'error' 
	order by ID Desc
END