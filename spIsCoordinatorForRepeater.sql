CREATE PROCEDURE spIsCoordinatorForRepeater @callsign varchar(10), @password varchar(255), @repeaterID int
AS
BEGIN
	Declare @result int = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @result = 
	(
		SELECT Top 1 1 FROM Permissions 
			where (Permissions.UserId = @userid and Permissions.RepeaterId = -1)
	)

	If @result = 1 
		Select 'true' [IsCoordinatorForRepeater];
	Else
		Select 'false' [IsCoordinatorForRepeater];
END