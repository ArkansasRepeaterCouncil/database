CREATE PROCEDURE [dbo].[spListRepeaterUsers] @callsign varchar(max), @password varchar(max), @repeaterID varchar(max)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Select Users.ID, Users.Callsign, Users.FullName, Users.Email from Users Where Users.ID in (Select Permissions.UserId from Permissions where Permissions.RepeaterId = @repeaterid) OR Users.ID in (Select Repeaters.TrusteeID from Repeaters where Repeaters.ID = @repeaterid) ;
	End

END;