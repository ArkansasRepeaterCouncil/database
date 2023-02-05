CREATE PROCEDURE sp_UserHasPermissionForRepeater @callsign varchar(10), @password varchar(255), @repeaterID int, @result int output
AS
BEGIN
	Set @result = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @result = 
	(
		SELECT Top 1 1 FROM Repeaters WHERE 
		( 
			Repeaters.ID in 
			( 
				Select @repeaterID from Permissions 
				where 
				(
					(Permissions.UserId = @userid and Permissions.RepeaterId = @repeaterID) OR
					(Permissions.UserId = @userid and Permissions.RepeaterId = -1) OR
					(Permissions.UserId = @userid and Permissions.RepeaterId = -2)
				)
			)
		)
		OR (Repeaters.TrusteeID = @userId AND Repeaters.ID = @repeaterID)
	)
END