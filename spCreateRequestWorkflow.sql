CREATE PROCEDURE [dbo].[spCreateRequestWorkflow] @RequestID int
AS   
BEGIN
	Declare @Latitude varchar(15), @Longitude varchar(15), @OutputPower int, @Altitude int, @AntennaHeight int, 
	 @OutputFrequency varchar(12), @requestState varchar(50), @website varchar(255);

	Select @Latitude=Location.Lat, @Longitude=Location.Long, @OutputPower=OutputPower, @Altitude=Altitude, 
	 @AntennaHeight=AntennaHeight, @OutputFrequency=OutputFrequency, @requestState=States.State, @website=States.website 
	 from Requests 
	 join States on Requests.State = States.StateAbbreviation
	 where ID = @RequestID;

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
		Insert into RequestWorkflows (RequestID, State, UrlKey, StatusID) values (@RequestID, @coordinationState, @urlKey, 1);

		-- Create table in memory for request info
		Declare @templateDataTable table (latitude varchar(20), longitude varchar(20), outputPower int, amsl int, 
		antennaHeight int, outputFrequency varchar(12), urlKey char(128), requestId int, state varchar(50), website varchar(255));

		Delete from @templateDataTable;

		Insert into @templateDataTable values (@Latitude, @Longitude, @OutputPower, @Altitude, @AntennaHeight, 
		@OutputFrequency, @urlKey, @RequestID, @requestState, @website);

		Declare @templateData varchar(max) = (Select * from @templateDataTable for json auto, WITHOUT_ARRAY_WRAPPER);

		-- Email the coordinator for this step
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
		values (@coordinationState + ' Coordinator', @coordinationEmail, 'NOPC #' + Convert(varchar(10), @RequestID), 
		@templateData, 'd-841dce6d75434442ab0328c9697c02fd');

		-- Add a note that we emailed them.
		Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), 
		'Notice of proposed coordination sent to ' + @coordinationState + '.');

		Delete from @Enumerator where @coordinationState = state;
	End
END;