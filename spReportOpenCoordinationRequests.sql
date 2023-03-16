CREATE PROCEDURE [dbo].[spReportOpenCoordinationRequests] @callsign varchar(10), @password varchar(255), @state varchar(2)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions where (Permissions.UserId = @userid and Permissions.RepeaterId = -1));

	If @allowed = 1 
	BEGIN
		Select 
		
		(Select 'Open coordination requests' 'Report.Title', (
			-- List open coordinations 
			Select Requests.ID 'Request.ID', Requests.requestedOn 'Request.RequestedDate', Users.FullName + ' (' + Users.Callsign + ')' 'Request.RequestedBy', 
			Requests.Location.Lat 'Request.Latitude', Requests.Location.Long 'Request.Longitude', Requests.OutputFrequency 'Request.OutputFrequency',
			(
				SELECT RequestWorkflows.State 'Workflow.State', RequestStatuses.Description 'Workflow.Status', 
				RequestWorkflows.Note 'Workflow.Note', RequestWorkflows.TimeStamp 'Workflow.TimeStamp', 
				RequestWorkflows.LastReminderSent 'Workflow.LastReminderSent' 
				FROM RequestWorkflows 
				INNER JOIN RequestStatuses on RequestWorkflows.StatusID = RequestStatuses.ID
				where RequestWorkflows.RequestID = Requests.ID 
				For JSON path, INCLUDE_NULL_VALUES
			) 'Request.Workflows'
			FROM Requests 
			Inner join Users on Requests.UserID = Users.ID
			where statusID = 1 and Requests.State = @state
			ORDER BY Requests.ID ASC
			For JSON path, INCLUDE_NULL_VALUES) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
	END
	ELSE
		Select '{}'
END;