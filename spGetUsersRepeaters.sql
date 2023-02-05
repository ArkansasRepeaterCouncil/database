CREATE PROCEDURE [dbo].[spGetUsersRepeaters] @callsign varchar(10), @password varchar(255)     
AS   
BEGIN

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	SELECT Repeaters.ID, Repeaters.Callsign, Repeaters.OutputFrequency, Repeaters.City, RepeaterStatuses.Status, Repeaters.DateUpdated
	FROM Repeaters
	JOIN RepeaterStatuses on RepeaterStatuses.ID = Repeaters.status
	WHERE Repeaters.ID in (Select Permissions.RepeaterId from Permissions where Permissions.UserId = @userid)
	OR Repeaters.TrusteeID = @userId
	ORDER BY CASE WHEN Repeaters.status = '3' THEN '5'
				WHEN Repeaters.status = '4' THEN '3'
				WHEN Repeaters.status = '5' THEN '4'
				WHEN Repeaters.status = '6' THEN '100'
				ELSE Repeaters.status END ASC

END;