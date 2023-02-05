CREATE PROCEDURE [dbo].[spListRecentChangesPublic] @state nvarchar(2)     
AS   
BEGIN
	;WITH logs AS
	(
	   SELECT *,
	         ROW_NUMBER() OVER (PARTITION BY RepeaterID ORDER BY ID DESC) AS rn
	   FROM RepeaterChangeLogs
	)
	SELECT TOP 5 Repeaters.ID as RepeatersID, Repeaters.Callsign as RepeaterCallsign, Repeaters.OutputFrequency as Frequency, logs.ChangeDateTime, logs.ChangeDescription
	FROM logs
	JOIN Repeaters on RepeaterId = Repeaters.ID
	WHERE rn = 1 
	AND logs.ChangeDescription not like '%• Latitude %'
	AND logs.ChangeDescription not like '%• Longitude %'
	AND state = @state
	Order by logs.ID Desc
END