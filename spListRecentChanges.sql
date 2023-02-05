CREATE PROCEDURE [dbo].[spListRecentChanges]      
AS   
BEGIN
	select top 20 RepeaterChangeLogs.ID as ChangeID, CONCAT('https://arkansasrepeatercouncil.org/repeaters/details/?id=', Repeaters.ID) as RepeaterURL, Repeaters.Callsign as RepeaterCallsign, Repeaters.OutputFrequency as Frequency,  
	Repeaters.City, Repeaters.State,  Users.callsign, Users.FullName, Users.Email, 
	CONVERT(DATETIME, RepeaterChangeLogs.ChangeDateTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time') as ChangeDateTime, 
	RepeaterChangeLogs.ChangeDescription
	from RepeaterChangeLogs 
	join Users on UserId = Users.ID
	join Repeaters on RepeaterId = Repeaters.ID
	Where 
		ChangeDescription not like '%• Latitude %'
		AND ChangeDescription not like '%• Longitude %'
	Order by RepeaterChangeLogs.ID Desc


END