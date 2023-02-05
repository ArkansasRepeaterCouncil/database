CREATE PROCEDURE [dbo].[spListOpenRequests]
AS   
BEGIN
	-- List open coordinations 
	Select Requests.ID, Requests.requestedOn, Users.FullName + ' (' + Users.Callsign + ')' as Requestor, 
	Requests.Location.Lat as Latitude, Requests.Location.Long as Longitude, Requests.OutputFrequency FROM dbo.Requests 
	Inner join Users on Requests.UserID = Users.ID
	where statusID = 1;
END;