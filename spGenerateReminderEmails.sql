CREATE PROCEDURE [dbo].[spGenerateReminderEmails]
AS   
BEGIN
	DECLARE @RemindOtherStatesOfWorkflowEveryThisManyDays int = 2;


	-- Create a table in memory with the states that will need to be included
	Declare @Enumerator table (ID int, RequestID int, State varchar(30), StatusID int, URLKey char(128), 
	RequestedTimeStamp datetime, LastReminderSent datetime, CoordinatorEmail varchar(255), Website varchar(255), OriginatingState varchar(50));

	Insert into @Enumerator exec spGetOverdueWorkflows @RemindOtherStatesOfWorkflowEveryThisManyDays;

	-- Loop through the enumerator table to build the workflow for this request
	While exists (select 1 from @Enumerator)
	Begin
		-- Declare variables
		Declare @ID int, @RequestID int, @State varchar(30), @StatusID int, @URLKey char(128), @RequestedTimeStamp datetime, 
		@LastReminderSent datetime, @CoordinatorEmail varchar(255), @Website varchar(255), @OriginatingState varchar(50);

		-- Assign variables
		Select top 1 @ID =ID, @RequestID =RequestID, @State =State, @StatusID =StatusID, @URLKey =URLKey, 
		@RequestedTimeStamp =RequestedTimeStamp, @LastReminderSent =LastReminderSent, @CoordinatorEmail =CoordinatorEmail 
		from @Enumerator;
		
		Select @Website = States.website, @OriginatingState = States.State from Requests
		join states on Requests.State = States.StateAbbreviation
		where Requests.ID = @RequestID; 

		-- Check to see if this is more than 30 days old, if so automatically approve
		If DATEDIFF(day, @RequestedTimeStamp, GETDATE()) >= 30
			BEGIN
			exec spUpdateCoordinationRequestWorkflowStep @UrlKey, 2, 'Automatically approved because the request waited 30 days without a response.';
			-- Remove record from enumerator
			Delete from @Enumerator where ID = @ID;
		END
		Else
		BEGIN
			-- Create table in memory for request info
			Declare @templateDataTable table (requestedtimestamp datetime, urlKey char(128), requestId int, state varchar(50), website varchar(255));
			Delete from @templateDataTable; -- Apparently SQL server doesn't delete outside scope, so this.
			Insert into @templateDataTable values (@RequestedTimeStamp, @URLKey, @RequestID, @OriginatingState, @Website);
			Declare @templateData varchar(max) = (Select * from @templateDataTable for json auto, WITHOUT_ARRAY_WRAPPER);
	
			-- Add this to the email queue
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
			values (@State + ' Coordinator', @CoordinatorEmail, 'NOPC #' + Convert(varchar(10), @RequestID), 
			@templateData, 'd-b5060c7289a6484c8d8ecf1a8520b431');
	
			-- Add a note that we emailed them.
			Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), 
			'Reminder sent to ' + @State + '.');
			
			-- Update the workflow with this reminder date
			Update RequestWorkflows set LastReminderSent = GETDATE() WHERE ID = @ID;
	
			-- Remove record from enumerator
			Delete from @Enumerator where ID = @ID;
		END
	End
END;