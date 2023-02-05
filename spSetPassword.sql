CREATE PROCEDURE [dbo].[spSetPassword] @callsign varchar(10), @password varchar(255)     
AS   
BEGIN

	DECLARE @salt varchar(255) = ( Select TOP(1) [Key] from Keys );
	DECLARE @userID varchar(10) = ( SELECT CONVERT(varchar(10), ID) FROM Users WHERE Callsign = @callsign );
	DECLARE @hashedPassword varbinary(8000) = HASHBYTES('SHA2_256', @password + @userID + @salt);

	Update Users set password = @hashedPassword where callsign = @callsign;

END;