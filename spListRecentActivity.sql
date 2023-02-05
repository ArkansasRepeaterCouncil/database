CREATE PROCEDURE [dbo].[spListRecentActivity]      
AS   
BEGIN
	Select top 20
		ID,
		TimeStamp,
		JSON_VALUE(jsonData,'$.callsign') callsign, 
		JSON_VALUE(jsonData,'$.event') event, 
		JSON_VALUE(jsonData,'$.message') message
	from EventLog
	Where Type <> 'error' 
	order by ID Desc

END