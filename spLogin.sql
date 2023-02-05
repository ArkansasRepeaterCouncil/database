CREATE PROCEDURE [dbo].[spLogin] @callsign varchar(10), @password varchar(255)     
AS   
BEGIN
	DECLARE @salt varchar(255) = ( Select TOP(1) [Key] from Keys );
	DECLARE @userID varchar(10) = ( SELECT CONVERT(varchar(10), ID) FROM Users WHERE Callsign = @callsign );
	DECLARE @hashedPassword varbinary(8000) = HASHBYTES('SHA2_256', @password + @userID + @salt);
	Set @callsign = Upper(@callsign)

	DECLARE @loggedIn int = ( Select COUNT(Callsign) from Users where Callsign = @callsign and Password = @hashedPassword );
	
	IF @loggedIn = 1
		BEGIN
			UPDATE Users SET LastLogin = GETDATE() WHERE Callsign = @callsign;
			Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"login", "message":"' + @callsign + ' has logged in." }', 'login');
		END

	Declare @isReportViewer int = (Select Count(UserID) from Permissions where UserId = @userID and RepeaterId = -2)

	Declare @isAdmin int = (Select Count(UserID) from Permissions where UserId = @userID and RepeaterId = -1)

	Declare @isCoordinator int = (Select Count(UserID) from Permissions where UserId = @userID and RepeaterId = -3)

	Declare @profileIncomplete int = (Select Count(ID) from Users where ID = @userID and (FullName = '' OR Address = '' OR
	City = '' OR State = '' OR Zip = '' OR Email = '' OR FullName is null OR Address is null OR City is null OR 
	State is null OR Zip is null OR Email is null OR 
	((PhoneHome = '' OR PhoneHome is null) AND (PhoneWork = '' OR PhoneWork is null) AND 
	(PhoneCell = '' OR PhoneCell is null))))

	Select @loggedIn as 'Return', @isReportViewer as 'isReportViewer', @isAdmin as 'isAdmin', @isCoordinator as 'isCoordinator',
	@profileIncomplete as 'profileIncomplete';
END;