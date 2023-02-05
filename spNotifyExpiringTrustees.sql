CREATE PROCEDURE [dbo].[spNotifyExpiringTrustees]
AS   
BEGIN

	Declare @lateUsers table (UserID int, Fullname varchar(max), Callsign varchar(max), Email varchar(max), State varchar(50), Website varchar(255), RepeaterList varchar(max))
	
	Insert into @lateUsers (UserID, Fullname, Callsign, Email, State, Website)
	Select Users.ID, Users.FullName, Users.Callsign, Users.Email, States.State, States.website From Repeaters
	join Users on Repeaters.TrusteeID = Users.ID
	join States on Repeaters.State = States.StateAbbreviation 
	where Repeaters.DateUpdated < DateAdd(month, -33, GetDate()) and Repeaters.DateUpdated > DateAdd(month, -36, GetDate()) 
	and Repeaters.status <> 6 and Users.Email is not null
	group by Users.ID, Users.FullName, Users.Callsign, Users.Email, States.State, States.Website;
	
	Declare @userid int, @fullname varchar(max), @callsign varchar(10), @email varchar(max);
	While exists (select 1 from @lateUsers where RepeaterList is null)
	Begin
		Select top 1 @userid = userid, @fullname = Fullname, @callsign = Callsign, @email = Email from @lateUsers where RepeaterList is null;
	
		Declare @Enumerator table (ID int, Callsign varchar(max), OutputFrequency varchar(max), MonthsLeft int)
		
		Insert into @Enumerator 
		Select Repeaters.ID, Repeaters.Callsign 'Callsign', Repeaters.OutputFrequency 'OutputFrequency',
		DateDiff(month, DateUpdated, DateAdd(month, -33, GetDate())) 'MonthsLeft'
		from Repeaters 
		join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
		where Repeaters.DateUpdated < DateAdd(month, -33, GetDate()) and Repeaters.DateUpdated > DateAdd(month, -36, GetDate())
		and Repeaters.status <> 6 and Repeaters.TrusteeID = @userid
		
		Declare @repeaters varchar(max), @repeatercallsign varchar(10), @output varchar(max), @months int, @repeaterID int
		Set @repeaters = '';
		While exists (select 1 from @Enumerator)
		Begin
			Select top 1 @repeatercallsign = Callsign, @output = OutputFrequency, @months = MonthsLeft, @repeaterID = ID from @Enumerator
				Order by MonthsLeft Desc;
		
			Select @repeaters = CONCAT(@repeaters, '<br>', CHAR(13), CHAR(10), @repeatercallsign, ' ', @output, ' has ', @months, ' month(s) left before its coordination expires.');
		
			Delete from @Enumerator where Callsign = @repeatercallsign and OutputFrequency = @output;

			-- Add a note that we emailed them.
			Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) values (@repeaterID, 264, GetDate(), 'Notice of upcoming coordination expiration sent to trustee.');
		End
		
		Update @lateUsers set RepeaterList = @repeaters where userid = @userid;

		Declare @templateData varchar(max) = (Select FullName as 'name', Callsign as 'callsign', RepeaterList as 'repeaters', State as 'state', Website as 'website' from @lateUsers where userid = @userid for json auto, WITHOUT_ARRAY_WRAPPER);

		-- Create the email record
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
		values (@fullname, @email, 'ACTION REQUIRED: Repeater coordination expiring', @templateData, 'd-c68aa4d9e64045a980020d7cf858c2e0');
	End

	Select * from @lateUsers
END;