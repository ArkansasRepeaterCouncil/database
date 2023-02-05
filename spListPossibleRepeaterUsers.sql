CREATE PROCEDURE [dbo].[spListPossibleRepeaterUsers] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Select ID, Callsign, FullName from Users 
		where ID not in (Select UserId from Permissions where RepeaterId = @repeaterID) 
			and SK = 0 and LicenseExpired = 0
		order by Callsign
		FOR JSON AUTO
	End

END;