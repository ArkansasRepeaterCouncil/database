CREATE PROCEDURE [dbo].[spCreateRepeaterFromRequest] @requestId int
AS   
BEGIN
	Declare @callsign varchar(6), @userid int, @location geography, @outputpower int, @altitude int, @antennaHeight int, @outputFreq decimal(12,6), @inputFreq decimal(12,6), @requestedDate datetime, @newRepeaterId int, @state varchar(10);

	Select @userid=UserID, @location=Location, @outputpower=OutputPower, @altitude=Altitude, @antennaHeight=AntennaHeight, @outputFreq=OutputFrequency, @requestedDate=RequestedOn, @state=State from Requests where ID = @requestId;
	
	Select @callsign=Callsign from Users where ID = @userid;

	Select @inputFreq=Input from Frequencies where output = @outputFreq;

	Insert into Repeaters ([Type], [Callsign], TrusteeID, Status, OutputFrequency, InputFrequency, Location, DateCoordinated, DateUpdated, State, CoordinatedLocation, CoordinatedAntennaHeight, CoordinatedOutputPower, AntennaHeight, OutputPower) values 
							(1, @callsign, @userid, 2, @outputfreq, @inputFreq, @location, GETDATE(), GETDATE(), @state, @location, @antennaHeight, @outputpower, @antennaHeight, @outputpower);

	Select @newRepeaterId = @@IDENTITY;

	Update Requests set RepeaterId = @newRepeaterId where ID = @requestId

	Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) 
	values (@newRepeaterId, 264, @requestedDate, concat('Coordination requested on ', @requestedDate, '.'));
	Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) 
	values (@newRepeaterId, 264, GetDate(), concat('Coordination approved on ', GetDate(), '.'))

	Declare @WorkflowNotes table (id int, state varchar(max), note varchar(max), timestamp datetime)
	Insert into @WorkflowNotes Select ID, State, Note, TimeStamp from RequestWorkflows where RequestID = @requestId
	
	Declare @_id int, @_state varchar(max), @_note varchar(max), @_timestamp datetime
	While exists (select 1 from @WorkflowNotes)
	Begin
		Select top 1 @_id = id, @_state = state, @_note = note, @_timestamp = timestamp from @WorkflowNotes
	
		Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) 
		values (@newRepeaterId, 264, @_timestamp, concat(@_state, ' coordinator approved on ', @requestedDate, '. Note: ', @_note))
	
		Delete from @WorkflowNotes where id = @_id
	End
	
END;