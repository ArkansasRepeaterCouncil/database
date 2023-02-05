CREATE PROCEDURE [dbo].[spUpdateCoordinationRequestWorkflowStep] @UrlKey char(128), @statusId varchar(1), @note varchar(max)
AS   
BEGIN
	Update RequestWorkflows set StatusID=@statusId, Note=@note, TimeStamp=GETDATE()
	where UrlKey=@UrlKey;

	Declare @userid int, @username varchar(100), @useremail varchar(255), @coordinatorstate varchar(40), @status varchar(10), 
		@statusdt datetime, @requestid int, @requeststate varchar(40), @requestFreq varchar(20), @workflowNote varchar(max),
		@requestStateName varchar(50), @website varchar(255)

	SELECT @userid = Users.ID, @username = Users.FullName, @useremail = Users.Email, @coordinatorstate = RequestWorkflows.State, 
		@status = RequestStatuses.Description, @statusdt = RequestWorkflows.TimeStamp, @requestid = RequestWorkflows.RequestID, 
		@requeststate = Requests.State, @requestFreq = Requests.OutputFrequency, @workflowNote = RequestWorkflows.Note,
		@requestStateName = States.State, @website = States.website
	FROM dbo.RequestWorkflows
	INNER JOIN Requests on RequestWorkflows.RequestID = Requests.ID
	INNER JOIN Users on Requests.UserID = Users.ID
	INNER JOIN RequestStatuses on RequestWorkflows.StatusID = RequestStatuses.ID
	INNER JOIN States on States.StateAbbreviation = Requests.State
	WHERE UrlKey=@UrlKey

	If @statusId = '3' -- Declined
	Begin
		Update Requests set StatusID = 3, ClosedOn = GetDate() Where ID = @requestid;
		
		-- create email, add to queue
		Declare @templateData varchar(max) = (Select @coordinatorstate as coordinatorstate, @requestid as requestid, @requestFreq as requestFreq, @workflowNote as workflowNote, @requestStateName as state, @website as website for json path);

		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@username, @useremail, 'Repeater coordination update', @templateData, 'd-71916d4472614f73af3a21e49fd0ae47');
	End
	Else
	Begin
		Exec spCheckIfAllWorkflowsCompleted @requestid
	End
END;