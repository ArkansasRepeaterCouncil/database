CREATE PROCEDURE [dbo].[spRemoveRepeaterLink] @callsign varchar(max), @password varchar(max), @repeaterid varchar(20), @linkrepeaterid varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int;

	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterid, @hasPermission output

	If @hasPermission > 0
	Begin
		Delete from Links where (LinkFromRepeaterID = @repeaterid and LinkToRepeaterID = @linkrepeaterid)
			OR (LinkToRepeaterID = @repeaterid and LinkFromRepeaterID = @linkrepeaterid);

		Declare @note varchar(max), @repeaterCallsign varchar(255), @repeaterFreq varchar(255), @linkCallsign varchar(255), @linkFreq varchar(255);
		Select @repeaterCallsign = Callsign, @repeaterFreq = OutputFrequency from Repeaters where ID = @repeaterid;
		Select @linkCallsign = Callsign, @linkFreq = OutputFrequency from Repeaters where ID = @linkrepeaterid;
		Set @note = CONCAT('No longer listed as being linked to the ', UPPER(@linkCallsign), ' (', @linkFreq, ') repeater.');
		exec spAddRepeaterNote @callsign, @password, @repeaterID, @note;
		exec sp_AddAutomatedRepeaterNote @linkrepeaterid, @note;
	End

END;