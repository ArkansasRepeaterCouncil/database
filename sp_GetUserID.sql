CREATE PROCEDURE sp_GetUserID @callsign varchar(10), @password varchar(255), @result int output
AS
BEGIN

	Declare @passwordHash varbinary(8000);
	EXEC dbo.sp_CreatePasswordHash @callsign, @password, @passwordHash output;

	UPDATE Users SET LastLogin = GETDATE() WHERE Callsign = @callsign and Password = @passwordHash;
	Select @result = Users.ID from Users Where Users.Callsign = @callsign and Users.Password = @passwordHash
END