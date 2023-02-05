CREATE PROCEDURE [dbo].[spReportMostActiveUsers] 
AS   
BEGIN
	SELECT Top 10 Count(JSON_VALUE(jsonData, '$.callsign')) AS Logins, JSON_VALUE(jsonData, '$.callsign') as Callsign FROM dbo.EventLog 
	where type = 'login'
		and TimeStamp > DATEADD(day, -30, GetDate()) 
		and JSON_VALUE(jsonData, '$.callsign') <> 'n5kwl'
		and JSON_VALUE(jsonData, '$.callsign') <> 'n5jlc'
	group by JSON_VALUE(jsonData, '$.callsign')
	order by Logins desc;
END;