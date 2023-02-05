CREATE PROCEDURE [dbo].[spAddRepeaterLink] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20), @linkrepeaterid varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Insert into Links (LinkFromRepeaterID, LinkToRepeaterID) values (@repeaterID, @linkrepeaterid);
		
		Declare @note varchar(max), @repeaterCallsign varchar(255), @repeaterFreq varchar(255), @linkCallsign varchar(255), @linkFreq varchar(255);
		Select @repeaterCallsign = Callsign, @repeaterFreq = OutputFrequency from Repeaters where ID = @repeaterID;
		Select @linkCallsign = Callsign, @linkFreq = OutputFrequency from Repeaters where ID = @linkrepeaterid;

		Set @note = CONCAT('Linked to the ', UPPER(@linkCallsign), ' (', @linkFreq, ') repeater.');
		exec spAddRepeaterNote @callsign, @password, @repeaterID, @note;
		exec sp_AddAutomatedRepeaterNote @linkrepeaterid, @note;
	End

	-- Return new list
	exec spListRepeaterLinks @repeaterID 
	
END;