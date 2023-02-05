CREATE PROCEDURE [dbo].[spListPossibleTrustees] @callsign varchar(max), @password varchar(max), @repeaterID varchar(max)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

If @hasPermission = 1
	Begin
		Select ID, Callsign from Users where SK=0 and LicenseExpired=0 order by Callsign;
	End

END;