CREATE PROCEDURE [dbo].[spGetUserDetails] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @passwordHash varbinary(8000);
	EXEC dbo.sp_CreatePasswordHash @callsign, @password, @passwordHash output;

	Select ID, Callsign, FullName, Address, City, State, ZIP, Email, PhoneHome, PhoneWork, PhoneCell from users
	WHERE Callsign = @callsign and Password = @passwordHash
END;