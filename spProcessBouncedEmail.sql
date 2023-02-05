CREATE PROCEDURE [dbo].[spProcessBouncedEmail] @email varchar(max)
AS   
BEGIN

	Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) 
	SELECT Repeaters.ID, 264, GetDate(), 'Trustee''s email address was invalid. Need new email address.' FROM Users
	INNER JOIN Repeaters ON Users.ID = Repeaters.TrusteeID
	Where Users.email = @email;

	Select * from Users where email = @email;

	Update Users set email = '' where email = @email;

END;