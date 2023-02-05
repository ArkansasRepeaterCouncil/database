CREATE PROCEDURE [dbo].[spCreateNewUser] @callsign varchar(10), @fullname varchar(100), @address varchar(100), @city varchar(24), @state varchar(2), @zip varchar(10), @email varchar(255), @webSiteState varchar(2)     
AS   
BEGIN

	-- Check to see if a user with that callsign exists
	DECLARE @existingCallsign varchar(10) = ( Select callsign from Users where callsign = @callsign );
	IF @existingCallsign is not null
	BEGIN
		DECLARE @existingEmail varchar(255) = ( Select email from Users where callsign = @callsign );
		IF @existingEmail is not null
			Select 1 as ReturnCode, 'An account with that callsign already exists. Please use the password recovery option to reset your password. If you no longer have access to that email address, contact a member of the coordination team.' as ReturnDescription,  LEFT(email, 3) + '____@' + RIGHT(email, LEN(email) - CHARINDEX('@', email)) as maskedEmail from Users where callsign = @callsign;
		ELSE
			Select 2 as ReturnCode, 'An account with that callsign already exists but does not have an email address on file. Contact a member of the coordination team to claim your account.';
	END;
	ELSE
	BEGIN
		INSERT into Users (Callsign, Fullname, Address, City, State, Zip, Email) values (Upper(@callsign), @fullname, @address, @city, @state, @zip, @email);

		DECLARE @password VARCHAR(8) = (select cast((Abs(Checksum(NewId()))%10) as varchar(1)) + char(ascii('a')+(Abs(Checksum(NewId()))%25)) + char(ascii('A')+(Abs(Checksum(NewId()))%25)) + left(newid(),5))
		DECLARE @hashedPassword varbinary(8000);
		DECLARE @salt varchar(255) = ( Select TOP(1) [Key] from Keys );
		DECLARE @userID varchar(10) = ( SELECT CONVERT(varchar(10), ID) FROM Users WHERE Callsign = @callsign );
		Set @hashedPassword = HASHBYTES('SHA2_256', @password + @userID + @salt);
		Update Users set password = @hashedPassword where callsign = @callsign;

		-- Check to see if this person is known to be another state's coordinator
		IF (Select 1 from States where CoordinatorEmail like concat('%', @email,'%')) is not null
		BEGIN
			Insert into permissions (UserID, RepeaterID) values (@userID, -3);
			Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Account created", "message":"   *********  Account created for ' + @callsign + ' (state coordinator)" }', 'security');
		END
		
		Declare @website varchar(255) = (Select website from States where state = @webSiteState);
		
		Declare @templateData varchar(max) = (Select @callsign as callsign, @password as password, @state as state, @website as website for json path, WITHOUT_ARRAY_WRAPPER);
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@callsign, @email, 'Repeater Council account', @templateData, 'd-7329081b03ff423a9a46b1c6767ed751');
			
		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Account created", "message":"Account created for ' + @callsign + '" }', 'security');

		Select 0 as ReturnCode;
	END;
END;