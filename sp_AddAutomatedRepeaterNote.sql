CREATE PROCEDURE [dbo].[sp_AddAutomatedRepeaterNote] @repeaterID int, @note varchar(max)
AS   
BEGIN

	DECLARE @userID int, @trusteeID int, @RepeaterCallsign varchar(255), @outputFreq varchar(255), @state varchar(50), @website varchar(255);
	Set @userID = 264; -- System account

	Insert into RepeaterChangeLogs (UserId, RepeaterId, ChangeDescription, ChangeDateTime) values (@userID, @repeaterID, @note, GETDATE());
	
	-- Email the trustee about the update.
	Select @trusteeID = Repeaters.trusteeID, @RepeaterCallsign = Repeaters.Callsign, @outputFreq = Repeaters.OutputFrequency, 
	 @state = States.State, @website = States.website
	from Repeaters join States on Repeaters.State = States.StateAbbreviation
	where Repeaters.ID = @repeaterID;
	
	DECLARE @emailToName varchar(255), @emailToAddress varchar(255), @emailContents varchar(max);
	Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;
	
	Declare @templateData varchar(max) = (Select @RepeaterCallsign as callsign, @outputFreq as frequency, @state as state, @website as website, @note as note, @repeaterID as repeaterid for json path, WITHOUT_ARRAY_WRAPPER);
	If @emailToAddress is not null
	Begin
		-- Create the email record
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
		values (@emailToName, @emailToAddress, 'Repeater update', @templateData, 'd-250dd9b19ed740faa7b5d669b67db412');
	End
	
	Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@emailToName, @emailToAddress, 'Repeater update', @emailContents);

	Declare @tblUsersWithPermission table (userID int);
	Insert into @tblUsersWithPermission Select UserID from Permissions where RepeaterId = @repeaterID;

	While exists (Select 1 from @tblUsersWithPermission)
	Begin
		Declare @repeaterUserId int;
		Select top 1 @repeaterUserId = UserID from @tblUsersWithPermission

		Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @repeaterUserId;
		Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@emailToName, @emailToAddress, 'Repeater update', @emailContents);

		Delete from @tblUsersWithPermission where @repeaterUserId = UserID
	End

END;