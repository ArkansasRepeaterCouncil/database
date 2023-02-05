CREATE PROCEDURE [dbo].[spUpdateUser] @id varchar(50), @callsign varchar(50), @password varchar(50), @fullname varchar(50), @address varchar(50), @city varchar(50), @state varchar(50), @zip varchar(50), @email varchar(50), @phonehome varchar(50), @phonework varchar(50), @phonecell varchar(50), @newpassword varchar(50)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this account
	DECLARE @userid int
	EXEC dbo.sp_GetUserID @callsign, @password, @userid output

If @userid = @id
	Begin
		Update Users set callsign=Upper(@callsign), fullname=@fullname, address=@address, city=@city, state=@state, zip=@zip, 
		email=@email, phonehome=@phonehome, phonecell=@phonecell, phonework=@phonework
		Where ID = @userid

		If @newpassword is not null and @newpassword != ''
		Begin
			Declare @hashedpassword varbinary(8000) 
			exec sp_CreatePasswordHash @callsign, @newpassword, @hashedpassword output
			Update Users set Password = @hashedpassword where ID=@userid
		End
	End

END;