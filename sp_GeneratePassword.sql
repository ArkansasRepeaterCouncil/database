CREATE PROCEDURE [dbo].[sp_GeneratePassword] @callsign varchar(10), @state varchar(50), @website varchar(255)
AS   
BEGIN
	DECLARE @password VARCHAR(8) = (select cast((Abs(Checksum(NewId()))%10) as varchar(1)) + char(ascii('a')+(Abs(Checksum(NewId()))%25)) + char(ascii('A')+(Abs(Checksum(NewId()))%25)) + left(newid(),5))

	DECLARE @hashedPassword varbinary(8000);

	exec sp_CreatePasswordHash @callsign, @password, @hashedPassword output

	Update Users set password = @hashedPassword where callsign = @callsign;

	DECLARE @userName varchar(100), @userEmail varchar(255), @userID int;
	Select @userID=ID, @userName=FullName, @userEmail=Email from Users where callsign=@callsign;

	If @userID is not null
	BEGIN
		If (@userEmail is not null) AND (@userEmail <> '')
		BEGIN
			Declare @templateData varchar(max) = (Select @callsign as callsign, @password as password, @state as state, @website as website for json path, WITHOUT_ARRAY_WRAPPER);
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@userName, @userEmail, 'Repeater Council account', @templateData, 'd-96e274591e0049e9844918010c887c2b');
			
			Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Password reset", "message":"Password reset for account ' + @callsign + '" }', 'security');
			Select @callsign as callsign, @userEmail as email;
		END;
		Else
		BEGIN
			Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Password reset request for account without email address.", "message":"Password reset for account ' + @callsign + '" }', 'security');
			Select @callsign as callsign, '' as email, 'There is an account with this callsign, but we do not have an email address. Please contact a member of the coordination team for assistance.' as message;
		END;
	END;
	Else
	Begin
		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Password reset request for non-existant account.", "message":"Password reset for account ' + @callsign + '" }', 'security');
		Select @callsign as callsign, '' as email, 'There is no account with that callsign.' as message;
	End;
END;