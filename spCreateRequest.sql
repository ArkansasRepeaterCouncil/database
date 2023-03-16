CREATE PROCEDURE [dbo].[spCreateRequest] @callsign varchar(10), @password varchar(max), @Latitude varchar(15), @Longitude varchar(15), @OutputPower int, @Altitude int, @AntennaHeight decimal(10,2), @OutputFrequency varchar(12)
AS   
BEGIN
	-- Validate the username and password
	DECLARE @userid int;
	EXEC dbo.sp_GetUserID @callsign, @password, @userid output;

	If @userid is null
	Begin
		Select 0 as AffectedRows;
	End
	Else 
	Begin
		Declare @inputFrequency varchar(12);
		Select @inputFrequency=input from frequencies where output = @OutputFrequency;
		Declare @decLatitude Decimal(9,6) = CAST(@latitude AS Decimal(9,6));
		Declare @decLongitude Decimal(9,6) = CAST(@longitude AS Decimal(9,6));
		Declare @decFrequency Decimal(9,6) = CAST(@OutputFrequency AS Decimal(9,6));

		DECLARE @location geography = geography::Point(@latitude,@longitude, 4326);
		DECLARE @state varchar(2);
		Select @state=StateAbbreviation from States where Borders.STContains(@location) = 1

		-- Make sure we can offer this frequency in the state
		Declare @numberOfInterferingRepeaters int = 0;
		exec spProposedCoordinationCount @Latitude, @Longitude, @decFrequency, @numberOfInterferingRepeaters output

		Insert into Requests (UserId, Location, OutputPower, Altitude, AntennaHeight, OutputFrequency, State, StatusID) 
		values (@userid, @location, @OutputPower, @Altitude, @AntennaHeight, @decFrequency, @state, 1);
		
		Declare @RequestID int
		Select @RequestID=SCOPE_IDENTITY();
		
		If @numberOfInterferingRepeaters > 0
		Begin
			Declare @note varchar(255) = 'According to our records, this request would interfer with ' + Convert(varchar(10),  @numberOfInterferingRepeaters) + ' repeater(s). Keep in mind that some repeaters are coordinated privately and, as such, would not be publicly listed.'
			Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), @note);

			Declare @toName varchar(255), @toEmail varchar(255);
			Select @toName = FullName, @toEmail = email from Users where ID = @userid;

			Insert into EmailQueue (ToName, ToEmail, Subject, Body) 
			values (@toName, @toEmail, 'Coordination request #' + Convert(varchar(10), @RequestID), @note);
			Update Requests set StatusID='3' where ID=@RequestID;
		End
		Else
		Begin
			-- Create a table in memory with the states that will need to be included
			Declare @Enumerator table (state varchar(max), email varchar(max), miles int)
			Insert into @Enumerator exec spGetStatesWithinRange @latitude, @longitude
			
			-- Loop through the enumerator table to build the workflow for this request
			Declare @coordinationState varchar(max), @coordinationEmail varchar(max), @urlKey char(128) = NULL
			While exists (select 1 from @Enumerator)
			Begin
				Select top 1 @coordinationState = state, @coordinationEmail = email from @Enumerator;

				-- Generate unique URL key for this workflow step
				Set @urlKey = NULL;
				EXEC dbo.sp_GenerateRandomUniqueUrlKey @urlKey output;

				-- Create this workflow step
				Insert into RequestWorkflows (RequestID, State, UrlKey, StatusID, RequestedTimeStamp) values (@RequestID, @coordinationState, @urlKey, 1, GetDate());
				
				-- Enumerator table only contains states within 90 miles of this repeater. If any of those states
				-- are in the database, then we can approve, because the numberOfInterferingRepeaters already
				-- checked for interference between all repeaters in the database.
				If exists (Select 1 from States where State = @coordinationState and PopulatedInDatabase = 1)
				begin
					-- Record an automatic approval for this state
					Update RequestWorkflows set StatusID = 2, Note = 'Approved by Hiram', TimeStamp = GetDate() where urlkey = @urlKey;
				end
				else -- We'll need to email them
				begin
					-- Create table in memory for request info
					Declare @templateDataTable table (latitude varchar(20), longitude varchar(20), outputPower int, amsl int, 
					antennaHeight int, outputFrequency varchar(12), inputFrequency varchar(12), urlKey char(128), requestId int,
					state varchar(50), website nvarchar(255), stateAbbreviation nvarchar(255));
	
					Delete from @templateDataTable;
					
					Declare @website nvarchar(255), @stateName nvarchar(50);
					Select @website = website, @stateName = state from States where StateAbbreviation = @state;
	
					Insert into @templateDataTable values (@Latitude, @Longitude, @OutputPower, @Altitude, @AntennaHeight, 
					@OutputFrequency, @inputFrequency, @urlKey, @RequestID, @stateName, @website, @state);
	
					Declare @templateData varchar(max) = (Select * from @templateDataTable for json auto, WITHOUT_ARRAY_WRAPPER);
	
					-- Email the coordinator for this step
					Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
					values (@coordinationState + ' Coordinator', @coordinationEmail, 'NOPC #' + Convert(varchar(10), @RequestID), 
					@templateData, 'd-841dce6d75434442ab0328c9697c02fd');
	
					-- Add a note that we emailed them.
					Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), 
					'Notice of proposed coordination sent to ' + @coordinationState + '.');
				End
				
				Delete from @Enumerator where @coordinationState = state;
			End

			-- Check and see if there are any states that are left to reply.
			exec spCheckIfAllWorkflowsCompleted @RequestID

		End
		Select 1 as AffectedRows; 
	End
END;