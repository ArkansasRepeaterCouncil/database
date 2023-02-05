CREATE PROCEDURE [dbo].[spNotifyLateTrustees]
AS   
BEGIN

	Declare @lateUsers table (UserID int, Fullname varchar(max), Callsign varchar(max), Email varchar(max), State varchar(50), StateName varchar(50), Website varchar(255), RepeaterList varchar(max))
	
	Insert into @lateUsers (UserID, Fullname, Callsign, Email, State, StateName, Website)
	Select Users.ID, Users.FullName, Users.Callsign, Users.Email, Repeaters.State, States.State as StateName, States.Website From Repeaters
	join Users on Repeaters.TrusteeID = Users.ID
	join States on Repeaters.State = States.StateAbbreviation
	where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 and Users.Email is not null
	
	and Repeaters.State = 'AR' 
	
	group by Users.ID, Users.FullName, Users.Callsign, Users.Email, Repeaters.State, States.State, States.Website;
	
	Declare @userid int, @fullname varchar(max), @callsign varchar(10), @email varchar(max);
	While exists (select 1 from @lateUsers where RepeaterList is null)
	Begin
		Select top 1 @userid = userid, @fullname = Fullname, @callsign = Callsign, @email = Email from @lateUsers where RepeaterList is null;
	
		Declare @Enumerator table (ID int, Callsign varchar(max), OutputFrequency varchar(max), MonthsExpired int)
		Insert into @Enumerator 
		Select Repeaters.ID, Repeaters.Callsign 'Callsign', Repeaters.OutputFrequency 'OutputFrequency', 
		DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate())) 'MonthsExpired'
		from Repeaters 
		join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
		where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 and Repeaters.TrusteeID = @userid
		
		Declare @repeaters varchar(max), @repeatercallsign varchar(10), @output varchar(max), @months int, @repeaterID int
		Set @repeaters = '';
		While exists (select 1 from @Enumerator)
		Begin
			Select top 1 @repeatercallsign = Callsign, @output = OutputFrequency, @months = MonthsExpired, @repeaterID = ID from @Enumerator
				Order by MonthsExpired Desc;
		
			Select @repeaters = CONCAT(@repeaters, '<br>', CHAR(13), CHAR(10), @repeatercallsign, ' ', @output, ' is ', @months, ' month(s) overdue.');
		
			Delete from @Enumerator where Callsign = @repeatercallsign and OutputFrequency = @output;

			-- Add a note that we emailed them.
			If @email is not null
			Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) values (@repeaterID, 264, GetDate(), 'Notice of coordination expiration sent to trustee.');
			else
			Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) values (@repeaterID, 264, GetDate(), 'Unable to email coordination expiration notice to trustee.');
		End
		
		Update @lateUsers set RepeaterList = @repeaters where userid = @userid;

		Declare @templateData varchar(max) = (Select FullName as 'name', Callsign as 'callsign', RepeaterList as 'repeaters', StateName as 'state', Website as 'website' from @lateUsers where userid = @userid for json auto, WITHOUT_ARRAY_WRAPPER);

		If @email is not null
		Begin
			-- Create the email record
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
			values (@fullname, @email, 'ACTION REQUIRED: Repeater coordination expired', @templateData, 'd-c68aa4d9e64045a980020d7cf858c2e0');
		End
	End

	Select * from @lateUsers
END;