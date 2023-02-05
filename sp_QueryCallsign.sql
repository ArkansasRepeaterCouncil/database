CREATE PROCEDURE [dbo].[sp_QueryCallsign] @callsign varchar(10)    
AS   
BEGIN

	Declare @userid int;
	Select @userid=Users.ID from Users Where Users.Callsign = @callsign

	Select Users.Callsign 'User.Callsign', Users.Fullname 'User.Name', Users.Email 'User.Email', Users.PhoneHome 'User.Phone.Home', Users.PhoneWork 'User.Phone.Work', Users.PhoneCell 'User.Phone.Cell', Users.LastLogin 'User.LastLogin'
, (
	SELECT Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.OutputFrequency', Repeaters.City 'Repeater.City', RepeaterStatuses.Status 'Repeater.Status', Repeaters.DateUpdated 'Repeater.DateUpdated'
	FROM Repeaters
	JOIN RepeaterStatuses on RepeaterStatuses.ID = Repeaters.status
	WHERE Repeaters.ID in (Select Permissions.RepeaterId from Permissions where Permissions.UserId = @userid)
	OR Repeaters.TrusteeID = @userId
	for JSON path) 'User.Repeaters'
From Users where ID = @userid
FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER

END;