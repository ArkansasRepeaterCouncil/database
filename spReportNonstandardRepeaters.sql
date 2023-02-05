CREATE PROCEDURE [dbo].[spReportNonstandardRepeaters] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions 
	where (
		(Permissions.UserId = @userid and Permissions.RepeaterId = -1) OR 
		(Permissions.UserId = @userid and Permissions.RepeaterId = -2)
		)
	);

	If @allowed = 1 
	BEGIN
		Select 
			(Select 'Nonstandard repeaters' 'Report.Title',
				(
					Select 
					Repeaters.DateUpdated 'Repeater.DateUpdated',
					Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
					Repeaters.InputFrequency 'Repeater.Input',
					Repeaters.City 'Repeater.City', Repeaters.Location.Lat 'Repeater.Latitude', Repeaters.Location.Long 'Repeater.Longitude', Repeaters.Sponsor 'Repeater.Sponsor', 
					CONCAT(Users.Fullname, ', ', Users.Callsign, ' (', Users.ID, ')') 'Repeater.Trustee.Name', 
					Users.Callsign 'Repeater.Trustee.Callsign', COALESCE(Users.Email, '') 'Repeater.Trustee.Email', 
					COALESCE(Users.phoneCell, '') 'Repeater.Trustee.CellPhone', COALESCE(Users.phoneHome, '') 'Repeater.Trustee.HomePhone', 
					COALESCE(Users.PhoneWork, '') 'Repeater.Trustee.WorkPhone', 
					(
						Select 
							Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', 
							RepeaterChangeLogs.ChangeDateTime 'Note.Timestamp', RepeaterChangeLogs.ChangeDescription 'Note.Text'
						From RepeaterChangeLogs
						Inner Join Users on Users.ID = RepeaterChangeLogs.UserID
						Where RepeaterChangeLogs.RepeaterID = Repeaters.ID
						Order by RepeaterChangeLogs.ChangeDateTime
						For JSON path
					) 'Repeater.Notes'
				From Repeaters 
				Join Users on Users.ID = Repeaters.TrusteeID
				Join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
				Where Repeaters.status <> 6 AND Repeaters.ID > 0 AND (Repeaters.outputfrequency not in (select output from frequencies) OR Repeaters.inputfrequency not in (select input from frequencies)) 
				Order by DateUpdated Asc
				FOR JSON PATH
				) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
)
	END
	ELSE
		Select '{}'
END;