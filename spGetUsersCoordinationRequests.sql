CREATE PROCEDURE [dbo].[spGetUsersCoordinationRequests] @callsign varchar(10), @password varchar(255)     
AS   
BEGIN

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Select Requests.ID, Requests.OutputFrequency
	, RequestStatuses.Description
	, (Select top 1 RequestNotes.Timestamp from RequestNotes where RequestNotes.RequestID = Requests.ID Order by TimeStamp Desc)  as LastUpdated 
	from Requests
	join RequestStatuses on RequestStatuses.ID = Requests.statusID
	where Requests.UserID = @userid;

END;