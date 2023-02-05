CREATE PROCEDURE [dbo].[sp_GeneratePasswordsForAllExistingAccounts] @stateName varchar(50), @website varchar(255) 
AS   
BEGIN
	Declare @Trustees table (trusteeCall varchar(10))
	Insert into @Trustees SELECT callsign FROM users where email is not null and password is null and id <> 40
	--Insert into @Trustees Select callsign from Users where Password is null and Email is not null and ID in (Select distinct TrusteeID from Repeaters);
	
	While exists (select 1 from @Trustees)
	Begin
		Declare @callsign varchar(10); 
		Select top 1 @callsign = trusteeCall from @Trustees;
	
		DECLARE @password VARCHAR(8) = (select cast((Abs(Checksum(NewId()))%10) as varchar(1)) + char(ascii('a')+(Abs(Checksum(NewId()))%25)) + char(ascii('A')+(Abs(Checksum(NewId()))%25)) + left(newid(),5))
	
		DECLARE @hashedPassword varbinary(8000);
	
		exec sp_CreatePasswordHash @callsign, @password, @hashedPassword output
	
		Update Users set password = @hashedPassword where callsign = @callsign;
	
		DECLARE @userName varchar(100), @userEmail varchar(255), @userID int;
		Select @userID=ID, @userName=FullName, @userEmail=Email from Users where callsign=@callsign;
	
		If (@userID is not null) AND (@userEmail is not null) AND (@userEmail <> '')
		BEGIN
			Declare @templateData varchar(max) = (Select @callsign as callsign, @password as password, @stateName as state, @website as website for json path, WITHOUT_ARRAY_WRAPPER);
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@userName, @userEmail, 'Repeater Council website', @templateData, 'd-d47e87e149524849ab2946ac29b56210');
			Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Password reset", "message":"Password reset for account ' + @callsign + '" }', 'security');
		END;
	
		Delete from @Trustees where trusteeCall = @callsign;
	End

END;