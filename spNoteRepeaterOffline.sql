CREATE PROCEDURE [dbo].[spNoteRepeaterOffline] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20)
AS   
BEGIN

	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @userID int, @trusteeID int, @RepeaterCallsign varchar(255), @outputFreq varchar(255), 
	@stateName varchar(50), @website varchar(255);

	EXEC dbo.sp_GetUserID @callsign, @password, @userID output
	Insert into RepeaterChangeLogs (UserId, RepeaterId, ChangeDescription, ChangeDateTime) values (@userID, @repeaterID, '*Repeater reported to be off-the-air*', GETDATE());
	Update Repeaters set Status = 5 where ID = @repeaterID;
	
	

	-- If this user isn't the primary trustee, then email the trustee about the update.
	Select @trusteeID = Repeaters.trusteeID, @RepeaterCallsign = Repeaters.Callsign, @outputFreq = Repeaters.OutputFrequency, @stateName = States.State, @website = States.website 
	from Repeaters inner join States on States.StateAbbreviation = Repeaters.State
	where Repeaters.ID = @repeaterID
	
	DECLARE @emailToName varchar(255), @emailToAddress varchar(255);
	Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;
	
	If @userid <> @trusteeID and @emailToAddress is not null and @emailToAddress <> ''
	Begin
		Declare @templateData nvarchar(max) = (Select @stateName as state, @RepeaterCallsign as RepeaterCallsign, @outputFreq as outputFreq, @callsign as callsign, @website as website, @repeaterID as repeaterID for json path);
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@emailToName, @emailToAddress, 'Repeater reported off-the-air', @templateData, 'd-fc04bd48965d41b0b3020baaee2f6bc9');
	End

END;