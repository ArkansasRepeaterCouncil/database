CREATE PROCEDURE sp_CreatePasswordHash @callsign varchar(10), @password varchar(255), @hash varbinary(8000) output
AS
BEGIN
	DECLARE @salt varchar(255) = ( Select TOP(1) [Key] from Keys );
	DECLARE @userID varchar(10) = ( SELECT CONVERT(varchar(10), ID) FROM Users WHERE Callsign = @callsign );
	Set @hash = HASHBYTES('SHA2_256', @password + @userID + @salt);
END