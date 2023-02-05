CREATE PROCEDURE [dbo].[spGetRepeaterNotes] @callsign varchar(10), @password varchar(255), @repeaterID int
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	DECLARE @Updated int;
	Set @Updated = 0;
	
	If @hasPermission = 1
	Begin

		select RepeaterChangeLogs.ID as ChangeID, Users.callsign, Users.FullName, 
			CONVERT(DATETIME, RepeaterChangeLogs.ChangeDateTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time')  as ChangeDateTime, RepeaterChangeLogs.ChangeDescription
		from RepeaterChangeLogs 
			join Users on UserId = Users.ID
			join Repeaters on RepeaterId = Repeaters.ID
		where RepeaterChangeLogs.RepeaterId = @repeaterID 
		Order by RepeaterChangeLogs.ChangeDateTime Desc
	End
END