CREATE PROCEDURE [dbo].[spAddRepeaterNote] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20), @note varchar(max)
AS   
BEGIN

	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int, @userID int, @trusteeID int, @RepeaterCallsign varchar(255), @outputFreq varchar(255), 
	@stateName varchar(50), @website varchar(255);

	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1 OR @note = '*Repeater reported to be off-the-air*'
	Begin
		EXEC dbo.sp_GetUserID @callsign, @password, @userID output
		Insert into RepeaterChangeLogs (UserId, RepeaterId, ChangeDescription, ChangeDateTime) values (@userID, @repeaterID, @note, GETDATE());
		
		-- If this user isn't the primary trustee, then email the trustee about the update.
		Select @trusteeID = Repeaters.trusteeID, @RepeaterCallsign = Repeaters.Callsign, @outputFreq = Repeaters.OutputFrequency, @stateName = States.State, @website = States.website
		from Repeaters 
		inner join states on Repeaters.State = States.StateAbbreviation
		where Repeaters.ID = @repeaterID;
		
		DECLARE @emailToName varchar(255), @emailToAddress varchar(255);
		Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;
		
		If @userid <> @trusteeID and @emailToAddress is not null and @emailToAddress <> ''
		Begin
			Declare @templateData varchar(max) = (Select @callsign as callsign, @RepeaterCallsign as RepeaterCallsign, @stateName as state, @note as note, @outputFreq as outputFreq, @website as website, @repeaterID as repeaterID for json path, WITHOUT_ARRAY_WRAPPER);
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@emailToName, @emailToAddress, 'Repeater update', @templateData, 'd-7e33cdad63e8449bad5e97daccb3adb7');
		End
	End

END;