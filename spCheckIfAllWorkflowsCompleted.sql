CREATE PROCEDURE [dbo].[spCheckIfAllWorkflowsCompleted] @requestid int
AS   
BEGIN
	Declare @requeststate varchar(10), @username varchar(100), @useremail varchar(255), @stateName varchar(50), @website varchar(255)
	
	Select @requeststate = Requests.State, @username = FullName, @useremail = Email, @stateName = States.State, @website = States.website
	from Requests 
	inner join States on Requests.State = States.StateAbbreviation
	join Users on Users.ID = Requests.UserID
	where requests.ID = @requestid;

	-- Check to see if there are other states still needing to reply.
	Declare @countReplied int, @countTotal int, @countApproved int;
	Select @countReplied=(Select Count(ID) FROM dbo.RequestWorkflows Where RequestID = @requestid and StatusID != 1), @countTotal=(Select Count(ID) FROM dbo.RequestWorkflows Where RequestID = @requestid), @countApproved=(Select Count(ID) FROM dbo.RequestWorkflows Where RequestID = @requestid and StatusID = 2);
	If @countReplied = @countTotal
	Begin
		Declare @instructions nvarchar(max) = concat('Please visit <a href="', @website, '/request/details/?id=', @requestid, '">', @website, '/request/details/?id=', @requestid, ' for the complete details.');
		Declare @repeaterid int;
		
		If @countApproved = @countTotal
		Begin
			Update Requests set StatusID = 2, ClosedOn = GetDate() Where ID = @requestid;
			exec spCreateRepeaterFromRequest @requestid;
			Select @repeaterid = RepeaterID from Requests where ID = @requestid;
			Select @instructions = concat('Please visit <a href="', @website, '/update/?id=', @repeaterid, '">', @website, '/update/?id=', @repeaterid, '</a> to provide additional details about your newly coordinated repeater.');
		End
		
		Declare @templateData nvarchar(max) = (Select @stateName as state, @requestid as requestid, @instructions as note for json path);
		-- All have replied create email, add to queue
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@username, @useremail, 'Coordination request #' + @requestid, @templateData, 'd-1842265a811b497fbdad8b68d927b834');
	End
END;