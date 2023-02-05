CREATE PROCEDURE [dbo].[spGetStatusReports] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions where (Permissions.UserId = @userid and Permissions.RepeaterId = -1));

	If @allowed = 1 
	BEGIN
		Select '['+ CONCAT_WS(',',
		
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
				where statusID = 1
				ORDER BY Requests.ID ASC
				For JSON path, INCLUDE_NULL_VALUES) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
		
			(Select 'Expired repeaters' 'Report.Title',
				(Select 
					Round(DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate()))/12.00, 2) 'Repeater.YearsExpired', 
					Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
					Repeaters.City 'Repeater.City', Repeaters.Sponsor 'Repeater.Sponsor', CONCAT(Users.Fullname, ', ', Users.Callsign, 
					' (', Users.ID, ')') 'Repeater.Trustee.Name', COALESCE(Users.Email, '') 'Repeater.Trustee.Email', 
					COALESCE(Users.phoneCell, '') 'Repeater.Trustee.CellPhone', COALESCE(Users.phoneHome, '') 'Repeater.Trustee.HomePhone', COALESCE(Users.PhoneWork, '') 'Repeater.Trustee.WorkPhone', 
					(
						Select 
							Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', 
							RepeaterChangeLogs.ChangeDateTime 'Note.Timestamp', RepeaterChangeLogs.ChangeDescription 'Note.Text'
						From RepeaterChangeLogs
						Inner Join Users on Users.ID = RepeaterChangeLogs.UserID
						Where RepeaterChangeLogs.RepeaterID = Repeaters.ID
						For JSON path
					) 'Repeater.Notes'
				From Repeaters 
				Join Users on Users.ID = Repeaters.TrusteeID
				Where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 
				Order by DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate())) Desc
				FOR JSON PATH) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
		)
		
		+ ']' 
	END
	ELSE
		Select '[]'
END;