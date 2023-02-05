CREATE PROCEDURE [dbo].[spGetCoordinationRequestDetails] @callsign varchar(10), @password varchar(max), @requestid varchar(100)
AS   
BEGIN

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	If @userid <> 0
	Begin
		Select Requests.ID 'Request.ID', Users.FullName 'Request.Requestor.Name', Users.Callsign 'Request.Requestor.Callsign', CONVERT(VARCHAR(15), Requests.Location.Lat) 'Request.Latitude', CONVERT(VARCHAR(15), Requests.Location.Long) 'Request.Longitude', CONVERT(VARCHAR(15), Requests.OutputFrequency) 'Request.OutputFrequency', Requests.OutputPower 'Request.OutputPower', Requests.Altitude 'Request.Altitude', Requests.AntennaHeight 'Request.AntennaHeight', Requests.State 'Request.State', RequestStatuses.ID 'Request.Status.ID', RequestStatuses.Description 'Request.Status.Description'

		, (
			Select Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', Timestamp 'Note.Timestamp', Note 'Note.Text'
			from RequestNotes 
			INNER Join Users on Users.ID = RequestNotes.UserID
			where RequestNotes.RequestID = Requests.ID
			for JSON path) 'Request.Notes'
		, (
			Select State 'Step.State', Note 'Step.Note', TimeStamp 'Step.TimeStamp',
			RequestStatuses.ID 'Step.Status.ID', RequestStatuses.Description 'Step.Status.Description'
			from RequestWorkflows 
			INNER Join RequestStatuses on RequestStatuses.ID = RequestWorkflows.StatusID
			where RequestWorkflows.RequestID = Requests.ID
			for JSON path) 'Request.Workflow'
		, (
			Select State 'State' from RequestWorkflows 
			where RequestWorkflows.RequestID = @requestid
			for JSON path) 'Request.Authorized'

		From Requests
		INNER Join Users on Users.ID = Requests.UserID
		INNER Join RequestStatuses on RequestStatuses.ID = Requests.StatusID
		WHERE Requests.ID = @requestid
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	End
END;