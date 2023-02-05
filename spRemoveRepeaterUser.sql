CREATE PROCEDURE [dbo].[spRemoveRepeaterUser] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20), @userID varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Delete from Permissions where UserId = @userID and RepeaterId = @repeaterID;
	End

END;