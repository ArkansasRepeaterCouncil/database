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

CREATE PROCEDURE [dbo].[spSetPassword] @callsign varchar(10), @password varchar(255)     
AS   
BEGIN

	DECLARE @salt varchar(255) = ( Select TOP(1) [Key] from Keys );
	DECLARE @userID varchar(10) = ( SELECT CONVERT(varchar(10), ID) FROM Users WHERE Callsign = @callsign );
	DECLARE @hashedPassword varbinary(8000) = HASHBYTES('SHA2_256', @password + @userID + @salt);

	Update Users set password = @hashedPassword where callsign = @callsign;

END;

CREATE PROCEDURE [dbo].[spListUsedFrequenciesNearPoint] @lat decimal(10, 7), @lon decimal (10, 7), @miles integer
AS   
BEGIN
	Declare @meters int;
	Set @meters = @miles * 1609.34;

	DECLARE @point geography;
	SET @point = geography::Point(@lat, @lon, 4326);

	Select OutputFrequency
	from Repeaters 
	where 
		DateDecoordinated is null and 
		@point.STBuffer(@meters).STIntersects(Location) = 1
END
CREATE PROCEDURE sp_MilesToMeters @miles decimal(18,2), @meters decimal(18,2) output
AS
BEGIN
	SET @meters = @miles * 1609.34;
END
CREATE PROCEDURE [dbo].[spListUnusedFrequenciesNearPoint] @lat decimal(10, 7), @lon decimal (10, 7), @miles integer, @band varchar(10)
AS   
BEGIN
	Declare @meters int;
	Set @meters = @miles * 1609.34;

	DECLARE @point geography;
	SET @point = geography::Point(@lat, @lon, 4326);

	Declare @AllFrequencies table (outputFreq decimal(9,4), inputFreq decimal(9,4), NearbyRepeaters int, Reviewed int);
	Insert into @AllFrequencies (outputFreq, inputFreq) Select output as outputFreq, input as inputFreq from Frequencies 
		where Frequencies.band = @band;
	
	While exists (select 1 from @AllFrequencies where Reviewed is null)
	Begin
		Declare @count int = 0, @outputFreq decimal(9,4), @inputFreq decimal(9,4);
		Select top 1 @outputFreq = outputFreq, @inputFreq = inputFreq from @AllFrequencies where Reviewed is null;
		exec spProposedCoordinationCount @lat, @lon, @outputFreq, @count output;
		--Select @count;
		Update @AllFrequencies set NearbyRepeaters = @count, Reviewed = '1' where outputFreq = @outputFreq;
	End

	Select outputFreq, inputFreq from @AllFrequencies Where NearbyRepeaters = 0 Order by outputFreq;
END
CREATE PROCEDURE sp_MetersToMiles @meters decimal(18,2), @miles decimal(18,2) output
AS
BEGIN
	SET @miles = @meters / 1609.34;
END
CREATE PROCEDURE spProposedCoordinationCount @latitude decimal (15, 12), @longitude decimal (15, 12), @freq decimal(18,6), @count int output 
AS
BEGIN
	DECLARE @point geography = geography::Point(@latitude, @longitude, 4326);
	Set @count = 0;

	IF @freq between 144.0 and 148.0
	BEGIN
		SELECT @count=Count(ID) FROM Repeaters
		WHERE Status <> 6 AND (
		 (OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
		 OR (ABS(OutputFrequency - @freq) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles
		)

		SELECT @count=@count+Count(ID) FROM Requests
		WHERE StatusID = 1 AND (
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		OR (ABS(OutputFrequency - @freq) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		OR (ABS(OutputFrequency - @freq) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
		OR (ABS(OutputFrequency - @freq) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles
		)
	END;
	
	
	IF @freq between 222.0 and 225.0
	BEGIN
		SELECT @count=Count(ID) FROM Repeaters
		WHERE Status <> 6 AND (
		 (OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)

		SELECT @count=@count+Count(ID) FROM Requests
		WHERE StatusID = 1 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
	END;
	
	
	IF @freq between 420.0 and 450.0
	BEGIN
		SELECT @count=Count(ID) FROM Repeaters
		WHERE Status <> 6 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)

		SELECT @count=@count+Count(ID) FROM Requests
		WHERE StatusID = 1 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
	END;

END
CREATE PROCEDURE spListRepeatersBySpecificSearch
	@username varchar(255), 
	@password varchar(255), 
	@latitude decimal (15, 12), 
	@longitude decimal (15, 12), 
	@outputFreq decimal(18,6),
	@inputFreq decimal(18,6),
	@freqMargin decimal(18,6),
	@milesMargin decimal(18,6)
AS
BEGIN
	DECLARE @point geography = geography::Point(@latitude, @longitude, 4326);
	DECLARE @metersMargin int = @milesMargin * 1609.34;

	Select Repeaters.ID, Repeaters.Callsign, Location.STDistance(@point) / 1609.34 as MilesAway, RepeaterStatuses.Status, OutputFrequency, InputFrequency, Repeaters.City
	
	from Repeaters 
		join Users on TrusteeID = Users.ID
		join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
		join RepeaterTypes on RepeaterTypes.ID = Repeaters.Type
	
	where 
		Repeaters.Type NOT IN (2,3) and 
		DateDecoordinated is null and 
		(
			(ABS(OutputFrequency - @outputFreq) <= @freqMargin AND @point.STBuffer(@metersMargin).STIntersects(Location) = 1)
			OR 
			(ABS(InputFrequency - @inputFreq) <= @freqMargin AND @point.STBuffer(@metersMargin).STIntersects(Location) = 1)
		)
	
	ORDER BY MilesAway

END
CREATE PROCEDURE [dbo].[sp_GenerateRandomUniqueUrlKey] @UrlKey char(32) output
AS   
BEGIN
	DECLARE @key char(32)
	Set @key = NULL
	EXEC dbo.sp_GenerateRandomKey @key output

	While exists (select 1 from RequestWorkflows where UrlKey=@key)
	Begin
		EXEC dbo.sp_GenerateRandomKey @key output
	End

	Set @UrlKey = @key;
END;
CREATE PROCEDURE [dbo].[spGetUsersRepeaters] @callsign varchar(10), @password varchar(255)     
AS   
BEGIN

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	SELECT Repeaters.ID, Repeaters.Callsign, Repeaters.OutputFrequency, Repeaters.City, RepeaterStatuses.Status, Repeaters.DateUpdated
	FROM Repeaters
	JOIN RepeaterStatuses on RepeaterStatuses.ID = Repeaters.status
	WHERE Repeaters.ID in (Select Permissions.RepeaterId from Permissions where Permissions.UserId = @userid)
	OR Repeaters.TrusteeID = @userId
	ORDER BY CASE WHEN Repeaters.status = '3' THEN '5'
				WHEN Repeaters.status = '4' THEN '3'
				WHEN Repeaters.status = '5' THEN '4'
				WHEN Repeaters.status = '6' THEN '100'
				ELSE Repeaters.status END ASC

END;
CREATE PROCEDURE [dbo].[spReportOpenCoordinationRequests] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions where (Permissions.UserId = @userid and Permissions.RepeaterId = -1));

	If @allowed = 1 
	BEGIN
		Select 
		
		(Select 'Open coordination requests' 'Report.Title', (
			-- List open coordinations 
			Select Requests.ID 'Request.ID', Requests.requestedOn 'Request.RequestedDate', Users.FullName + ' (' + Users.Callsign + ')' 'Request.RequestedBy', 
			Requests.Location.Lat 'Request.Latitude', Requests.Location.Long 'Request.Longitude', Requests.OutputFrequency 'Request.OutputFrequency',
			(
				SELECT RequestWorkflows.State 'Workflow.State', RequestStatuses.Description 'Workflow.Status', 
				RequestWorkflows.Note 'Workflow.Note', RequestWorkflows.TimeStamp 'Workflow.TimeStamp', 
				RequestWorkflows.LastReminderSent 'Workflow.LastReminderSent' 
				FROM RequestWorkflows 
				INNER JOIN RequestStatuses on RequestWorkflows.StatusID = RequestStatuses.ID
				where RequestWorkflows.RequestID = Requests.ID 
				For JSON path, INCLUDE_NULL_VALUES
			) 'Request.Workflows'
			FROM Requests 
			Inner join Users on Requests.UserID = Users.ID
			where statusID = 1
			ORDER BY Requests.ID ASC
			For JSON path, INCLUDE_NULL_VALUES) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
	END
	ELSE
		Select '{}'
END;
CREATE PROCEDURE [dbo].[spReportExpiredRepeaters] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions 
	where (
		(Permissions.UserId = @userid and Permissions.RepeaterId = -1) OR 
		(Permissions.UserId = @userid and Permissions.RepeaterId = -2)
		)
	);

	If @allowed = 1 
	BEGIN
		Select 
		
			(Select 'Expired repeaters' 'Report.Title',
				(Select 
					Round(DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate()))/12.00, 2) 'Repeater.YearsExpired', 
					Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
					Repeaters.City 'Repeater.City', Repeaters.Location.Lat 'Repeater.Latitude', Repeaters.Location.Long 'Repeater.Longitude', 
					Repeaters.Sponsor 'Repeater.Sponsor', CONCAT(Users.Fullname, ', ', Users.Callsign, 
					' (', Users.ID, ')') 'Repeater.Trustee.Name', Users.Callsign 'Repeater.Trustee.Callsign', COALESCE(Users.Email, '') 'Repeater.Trustee.Email', 
					COALESCE(Users.phoneCell, '') 'Repeater.Trustee.CellPhone', COALESCE(Users.phoneHome, '') 'Repeater.Trustee.HomePhone', COALESCE(Users.PhoneWork, '') 'Repeater.Trustee.WorkPhone', 
					(
						Select 
							Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', 
							RepeaterChangeLogs.ChangeDateTime 'Note.Timestamp', RepeaterChangeLogs.ChangeDescription 'Note.Text'
						From RepeaterChangeLogs
						Inner Join Users on Users.ID = RepeaterChangeLogs.UserID
						Where RepeaterChangeLogs.RepeaterID = Repeaters.ID
						Order by RepeaterChangeLogs.ChangeDateTime
						For JSON path
					) 'Repeater.Notes'
				From Repeaters 
				Join Users on Users.ID = Repeaters.TrusteeID
				Where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 
				Order by DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate())) Desc
				FOR JSON PATH) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
	END
	ELSE
		exec spReportExpiredRepeaters_Public
END;
CREATE PROCEDURE [dbo].[spCreateRequest] @callsign varchar(10), @password varchar(max), @Latitude varchar(15), @Longitude varchar(15), @OutputPower int, @Altitude int, @AntennaHeight decimal(10,2), @OutputFrequency varchar(12)
AS   
BEGIN
	-- Validate the username and password
	DECLARE @userid int;
	EXEC dbo.sp_GetUserID @callsign, @password, @userid output;

	If @userid is null
	Begin
		Select 0 as AffectedRows;
	End
	Else 
	Begin
		Declare @inputFrequency varchar(12);
		Select @inputFrequency=input from frequencies where output = @OutputFrequency;
		Declare @decLatitude Decimal(9,6) = CAST(@latitude AS Decimal(9,6));
		Declare @decLongitude Decimal(9,6) = CAST(@longitude AS Decimal(9,6));
		Declare @decFrequency Decimal(9,6) = CAST(@OutputFrequency AS Decimal(9,6));

		DECLARE @location geography = geography::Point(@latitude,@longitude, 4326);
		DECLARE @state varchar(2) ;
		Select @state=StateAbbreviation from States where Borders.STContains(@location) = 1

		-- Make sure we can offer this frequency in the state
		Declare @numberOfInterferingRepeaters int = 0;
		exec spProposedCoordinationCount @Latitude, @Longitude, @decFrequency, @numberOfInterferingRepeaters output

		Insert into Requests (UserId, Location, OutputPower, Altitude, AntennaHeight, OutputFrequency, State, StatusID) 
		values (@userid, @location, @OutputPower, @Altitude, @AntennaHeight, @decFrequency, @state, 1);
		
		Declare @RequestID int
		Select @RequestID=SCOPE_IDENTITY();
		
		If @numberOfInterferingRepeaters > 0
		Begin
			Declare @note varchar(255) = 'According to our records this request would interfer with ' + Convert(varchar(10),  @numberOfInterferingRepeaters) + ' repeater(s). Keep in mind that some repeaters are coordinated privately and, as such, would not be publicly listed.'
			Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), @note);

			Declare @toName varchar(255), @toEmail varchar(255);
			Select @toName = FullName, @toEmail = email from Users where ID = @userid;

			Insert into EmailQueue (ToName, ToEmail, Subject, Body) 
			values (@toName, @toEmail, 'Coordination request #' + @state + Convert(varchar(10), @RequestID), @note);
			Update Requests set StatusID='3' where ID=@RequestID;
		End
		Else
		Begin
			-- Create a table in memory with the states that will need to be included
			Declare @Enumerator table (state varchar(max), email varchar(max), miles int)
			Insert into @Enumerator exec spGetStatesWithinRange @latitude, @longitude
			
			-- Loop through the enumerator table to build the workflow for this request
			Declare @coordinationState varchar(max), @coordinationEmail varchar(max), @urlKey char(128) = NULL
			While exists (select 1 from @Enumerator)
			Begin
				Select top 1 @coordinationState = state, @coordinationEmail = email from @Enumerator;

				-- Generate unique URL key for this workflow step
				Set @urlKey = NULL;
				EXEC dbo.sp_GenerateRandomUniqueUrlKey @urlKey output;

				-- Create this workflow step
				Insert into RequestWorkflows (RequestID, State, UrlKey, StatusID, RequestedTimeStamp) values (@RequestID, @coordinationState, @urlKey, 1, GetDate());
				
				-- Enumerator table only contains states within 90 miles of this repeater. If any of those states
				-- are in the database, then we can approve, because the numberOfInterferingRepeaters already
				-- checked for interference between all repeaters in the database.
				If exists (Select 1 from States where State = @coordinationState and PopulatedInDatabase = 1)
				begin
					-- Record an automatic approval for this state
					Update RequestWorkflows set StatusID = 2, Note = 'Approved by Hiram', TimeStamp = GetDate() where urlkey = @urlKey;
				end
				else -- We'll need to email them
				begin
					-- Create table in memory for request info
					Declare @templateDataTable table (latitude varchar(20), longitude varchar(20), outputPower int, amsl int, 
					antennaHeight int, outputFrequency varchar(12), inputFrequency varchar(12), urlKey char(128), requestId int);
	
					Delete from @templateDataTable;
	
					Insert into @templateDataTable values (@Latitude, @Longitude, @OutputPower, @Altitude, @AntennaHeight, 
					@OutputFrequency, @inputFrequency, @urlKey, @RequestID);
	
					Declare @templateData varchar(max) = (Select * from @templateDataTable for json auto, WITHOUT_ARRAY_WRAPPER);
	
					-- Email the coordinator for this step
					Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
					values (@coordinationState + ' Coordinator', @coordinationEmail, 'NOPC #AR' + Convert(varchar(10), @RequestID), 
					@templateData, 'd-a39c8542aa9946119b067788c80d12cd');
	
					-- Add a note that we emailed them.
					Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), 
					'Notice of proposed coordination sent to ' + @coordinationState + '.');
				End
				
				Delete from @Enumerator where @coordinationState = state;
			End

			-- Check and see if there are any states that are left to reply.
			exec spCheckIfAllWorkflowsCompleted @RequestID

		End
		Select 1 as AffectedRows; 
	End
END;
CREATE PROCEDURE [dbo].[sp_GetUnsentEmails]
AS   
BEGIN
	exec spGenerateReminderEmails

	Select ID, ToEmail as ToUserEmail, ToName as ToUserName, FromEmail as FromUserEmail, FromName as FromUserName, Subject, Body, TemplateID 
	from EmailQueue 
	where Sent is null and ToEmail is not null
END
CREATE PROCEDURE [dbo].[spGetCoordinationRequestWorkflowStep] @urlKey char(128)
AS   
BEGIN

Select Requests.ID 'Request.ID', Users.FullName 'Request.Requestor.Name', Users.Callsign 'Request.Requestor.Callsign', CONVERT(VARCHAR(15), Requests.Location.Lat) 'Request.Latitude', CONVERT(VARCHAR(15), Requests.Location.Long) 'Request.Longitude', CONVERT(VARCHAR(15), Requests.OutputFrequency) 'Request.OutputFrequency', Requests.OutputPower 'Request.OutputPower', Requests.Altitude 'Request.Altitude', Requests.AntennaHeight 'Request.AntennaHeight', Requests.State 'Request.State', RequestStatuses.ID 'Request.Status.ID', RequestStatuses.Description 'Request.Status.Description'
, (
	Select Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', Timestamp 'Note.Timestamp', Note 'Note.Text'
	from RequestNotes 
	INNER Join Users on Users.ID = RequestNotes.UserID
	where RequestNotes.RequestID = Requests.ID
	for JSON path) 'Request.Notes'
, (
	Select State 'Step.State', Note 'Step.Note', TimeStamp 'Step.TimeStamp',
	RequestStatuses.ID 'Step.Status.ID', RequestStatuses.Description 'Step.Status.Description'
	from RequestWorkflows 
	INNER Join RequestStatuses on RequestStatuses.ID = RequestWorkflows.StatusID
	where RequestWorkflows.RequestID = Requests.ID
	for JSON path) 'Request.Workflow'
, (
	Select State 'State' from RequestWorkflows 
	where RequestWorkflows.UrlKey = @urlKey
	for JSON path) 'Request.Authorized'
From Requests
INNER Join Users on Users.ID = Requests.UserID
INNER Join RequestStatuses on RequestStatuses.ID = Requests.StatusID
INNER Join RequestWorkflows on RequestWorkflows.RequestID = Requests.ID
WHERE RequestWorkflows.UrlKey = @urlKey
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER

END;
CREATE PROCEDURE [dbo].[spUpdateCoordinationRequestWorkflowStep] @UrlKey char(128), @statusId varchar(1), @note varchar(max)
AS   
BEGIN
	Update RequestWorkflows set StatusID=@statusId, Note=@note, TimeStamp=GETDATE()
	where UrlKey=@UrlKey;

	Declare @userid int, @username varchar(100), @useremail varchar(255), @coordinatorstate varchar(40), @status varchar(10), 
		@statusdt datetime, @requestid int, @requeststate varchar(40), @requestFreq varchar(20), @workflowNote varchar(max)

	SELECT @userid = Users.ID, @username = Users.FullName, @useremail = Users.Email, @coordinatorstate = RequestWorkflows.State, 
		@status = RequestStatuses.Description, @statusdt = RequestWorkflows.TimeStamp, @requestid = RequestWorkflows.RequestID, 
		@requeststate = Requests.State, @requestFreq = Requests.OutputFrequency, @workflowNote = RequestWorkflows.Note
	FROM dbo.RequestWorkflows
	INNER JOIN Requests on RequestWorkflows.RequestID = Requests.ID
	INNER JOIN Users on Requests.UserID = Users.ID
	INNER JOIN RequestStatuses on RequestWorkflows.StatusID = RequestStatuses.ID
	WHERE UrlKey=@UrlKey

	If @statusId = '3' -- Declined
	Begin
		Update Requests set StatusID = 3, ClosedOn = GetDate() Where ID = @requestid;
		
		-- create email, add to queue
		Declare @emailBody varchar(max) = 'The ' + @coordinatorstate + ' repeater coordinator has declined coordination request #' + UPPER(SUBSTRING(@requeststate, 1, 2)) + CONVERT(varchar, @requestid) + ' for the frequency ' + @requestFreq + '.'
  		+ '<blockquote>&quot;' + @workflowNote + '&quot;<br>&nbsp; &nbsp; - ' + @coordinatorstate + ' coordinator</blockquote>'
		+ 'Please visit <a href="https://www.arkansasrepeatercouncil.org/request/details/?id=' + CONVERT(varchar, @requestid) + '">https://www.arkansasrepeatercouncil.org/request/details/?id=' + CONVERT(varchar, @requestid) + '</a> for the complete details.<br><br>'
		+ '<a href="https://www.arkansasrepeatercouncil.org">Arkansas Repeater Council</a>'

		Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@username, @useremail, 'Repeater coordination update', @emailBody);
	End
	Else
	Begin
		exec spCheckIfAllWorkflowsCompleted @requestid
	End
END;
CREATE PROCEDURE [dbo].[spUpdateRepeater] @callsign varchar(max), @password varchar(max), @repeaterID varchar(max), @type varchar(max), @RepeaterCallsign varchar(max), 
	@trusteeID varchar(max), @status varchar(max), @city varchar(max), @siteName varchar(max), @outputFreq varchar(max), @inputFreq varchar(max), 
	@latitude varchar(max), @longitude varchar(max), @sponsor varchar(max), @amsl varchar(max), @erp varchar(max), @outputPower varchar(max), 
	@antennaGain varchar(max), @antennaHeight varchar(max), @analogInputAccess varchar(max), @analogOutputAccess varchar(max), @analogWidth varchar(max), 
	@dstarModule varchar(max), @dmrColorCode varchar(max), @dmrId varchar(max), @dmrNetwork varchar(max), @p25nac varchar(max), @nxdnRan varchar(max), 
	@ysfDsq varchar(max), @autopatch varchar(max), @emergencyPower varchar(max), @linked varchar(max), @races varchar(max), @ares varchar(max), 
	@wideArea varchar(max), @weather varchar(max), @experimental varchar(max), @changenote varchar(max), @dateupated datetime, @additionalInformation varchar(max)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int = 0
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

DECLARE @Updated int;
Set @Updated = 0;

If @amsl = '' Set @amsl = 0.0
If @erp = '' Set @erp = 0.0
If @outputPower = '' Set @outputPower = 0
If @antennaGain = '' Set @antennaGain = 0.0
If @antennaHeight = '' Set @antennaHeight = 0.0
If @analogWidth = '' Set @analogWidth = 0.0
If @autopatch = '' Set @autopatch = 0;

If @hasPermission = 1
	Begin

		Update Repeaters Set Repeaters.Type=@type, Repeaters.Callsign=UPPER(@RepeaterCallsign), TrusteeID=@trusteeID, Status=@status, 
			City=@city, SiteName=@siteName, OutputFrequency=@outputFreq, InputFrequency=@inputFreq,
			Location=geography::Point(@latitude,@longitude, 4326), Sponsor=@sponsor, AMSL=@amsl, ERP=@erp, OutputPower=@outputPower, 
			AntennaGain=@antennaGain, AntennaHeight=@antennaHeight, Analog_InputAccess=@analogInputAccess,
			Analog_OutputAccess=@analogOutputAccess, Analog_Width=@analogWidth, DSTAR_Module=@dstarModule, DMR_ColorCode=@dmrColorCode, 
			DMR_ID=@dmrId, DMR_Network=@dmrNetwork, P25_NAC=@p25nac, NXDN_RAN=@nxdnRan, YSF_DSQ=@ysfDsq, Autopatch=@autopatch,
			EmergencyPower=@emergencyPower, Linked=@linked, RACES=@races, ARES=@ares, WideArea=@wideArea, Weather=@weather, 
			Experimental=@experimental, DateUpdated=@dateupated, AdditionalInformation=@additionalInformation WHERE Id = @repeaterID;

		SET @Updated = @@ROWCOUNT;

		If @changenote like '** Coordinator override **%'
		Begin
			Update Repeaters Set CoordinatedLocation = Location, CoordinatedAntennaHeight = AntennaHeight, CoordinatedOutputPower = OutputPower where Id = @repeaterID;
		End

		DECLARE @userid int
		Select @userid = Users.ID from Users where Users.callsign = @callsign; 

		If @changenote <> ''
		Begin
			Insert into RepeaterChangeLogs (RepeaterId, UserId, ChangeDateTime, ChangeDescription) values (@repeaterID, @userid, GETDATE(), @changenote);
		End

		If @userid <> @trusteeID
		Begin
			DECLARE @emailToName varchar(255)
			DECLARE @emailToAddress varchar(255)
			Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;
			Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@emailToName, @emailToAddress, 'Repeater update', 'The ' + UPPER(@RepeaterCallsign) + ' (' + @outputFreq + ') repeater was updated on <a href="http://ArkansasRepeaterCouncil.com">ArkansasRepeaterCouncil.com</a> by ' + @callsign + '.<br><br>' + @changenote);
		End
	End

Select @hasPermission as LoggedIn, @Updated as RowsUpdated;

END;
CREATE PROCEDURE [dbo].[spGetUsersCoordinationRequests] @callsign varchar(10), @password varchar(255)     
AS   
BEGIN

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Select Requests.ID, Requests.OutputFrequency
	, RequestStatuses.Description
	, (Select top 1 RequestNotes.Timestamp from RequestNotes where RequestNotes.RequestID = Requests.ID Order by TimeStamp Desc)  as LastUpdated 
	from Requests
	join RequestStatuses on RequestStatuses.ID = Requests.statusID
	where Requests.UserID = @userid;

END;
CREATE PROCEDURE spUpdateExpiredLicenses @calls NVARCHAR(1000)
AS
BEGIN
	IF @calls <> ''
	Begin
		--Declare @calls nvarchar(1000); Set @calls = 'aa5jc,n5gc,n5xfw';
		DROP TABLE IF EXISTS tempExpiredLicenses
		SELECT value INTO tempExpiredLicenses FROM string_split(@calls,',');
		Alter table tempExpiredLicenses add UserId int;
		Update tempExpiredLicenses set UserId = (Select ID from Users where Users.callsign = tempExpiredLicenses.value)
		
		Declare @skCallsign nvarchar(10), @skUserId int;
		While exists (select 1 from tempExpiredLicenses)
		Begin
			Select top 1 @skCallsign = value, @skUserId = UserId from tempExpiredLicenses;
			
			-- REMOVE PERMISSIONS
			Declare @repeatersExpiredLicenseeHadPermissionsOn table (RepeaterId int)
			Insert into @repeatersExpiredLicenseeHadPermissionsOn Select RepeaterId from Permissions where UserId = @skUserId
			Declare @repeaterIdForPermissions int
			While exists (Select 1 from @repeatersExpiredLicenseeHadPermissionsOn)
			Begin
				Select top 1 @repeaterIdForPermissions = RepeaterId from @repeatersExpiredLicenseeHadPermissionsOn
				Delete from Permissions where UserId = @skUserId and RepeaterID = @repeaterIdForPermissions;
				Declare @emailContents varchar(8000); Set @emailContents = concat('According to QRZ, the license ', @skCallsign, ' has expired. Their account has been removed as a user from this repeater.');
				exec sp_AddAutomatedRepeaterNote @repeaterIdForPermissions, @emailContents
				Delete from @repeatersExpiredLicenseeHadPermissionsOn where @repeaterIdForPermissions = RepeaterId
			End
	
			-- FLAG ANY REPEATERS ON WHICH THEY ARE THE TRUSTEE
			Declare @repeatersOnWhichExpiredLicenseeWasTrustee table (RepeaterId int)
			Insert into @repeatersOnWhichExpiredLicenseeWasTrustee Select ID from Repeaters where TrusteeID = @skUserId
			Declare @repeaterIdForTrustee int
			While exists (Select 1 from @repeatersOnWhichExpiredLicenseeWasTrustee)
			Begin
				Select top 1 @repeaterIdForTrustee = RepeaterId from @repeatersOnWhichExpiredLicenseeWasTrustee
				
				-- Let's randomly select one of the users of this repeater and set them as the trustee
				Declare @repeaterUsers table (UserID int, Callsign varchar(8000))
				Insert into @repeaterUsers Select permissions.UserID, Users.Callsign from permissions join users on permissions.userid = users.id where RepeaterId = @repeaterIdForTrustee and UserId <> @skUserId
				If exists (Select 1 from @repeaterUsers)
				Begin
					Declare @newTrusteeId int, @newTrusteeCallsign varchar(8000)
					Select top 1 @newTrusteeId = UserId, @newTrusteeCallsign = callsign from @repeaterUsers
					Update Repeaters set TrusteeID = @newTrusteeId Where ID = @repeaterIdForTrustee
					Declare @emailContents2 varchar(8000); Set @emailContents2 = 'According to QRZ, the license ' + @skCallsign + ' has expired. We have automatically changed the primary trustee to ' + @newTrusteeCallsign + '.  You can login to change that at any time.';
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents2;
				End
				Else
				Begin
					Update repeaters Set LicenseeSK = 1 WHERE id = @repeaterIdForTrustee;
					Declare @emailContents3 varchar(8000); Set @emailContents3 = concat('According to QRZ, the license ', @skCallsign, ' has expired. Their account has been removed as a user from this repeater.');
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents3
				End
				
				Delete from @repeatersOnWhichExpiredLicenseeWasTrustee where @repeaterIdForTrustee = RepeaterId
			End
	
			-- FLAG ANY REPEATERS THAT USE THEIR CALLSIGN
			Declare @repeatersUsingExpiredLicensesCallsign table (RepeaterId int);
			Insert into @repeatersUsingExpiredLicensesCallsign Select ID from Repeaters where callsign = @skCallsign
			While exists (Select 1 from @repeatersUsingExpiredLicensesCallsign)
			Begin
				Declare @repeaterIdForCallsign int;
				Select top 1 @repeaterIdForCallsign = RepeaterId from @repeatersUsingExpiredLicensesCallsign;
				Update repeaters Set LicenseExpired = 1 WHERE id = @repeaterIdForCallsign;
				Declare @emailContents4 varchar(8000); Set @emailContents4 = 'According to QRZ, the license ' + @skCallsign + ' has expired. This repeater will need to be assigned a new callsign, and should be taken off the air until such time.  If this repeater has not been updated with a new callsign within 30 days it will be decoordinated.';
				exec sp_AddAutomatedRepeaterNote @repeaterIdForCallsign, @emailContents4
				Delete from @repeatersUsingExpiredLicensesCallsign where repeaterId = @repeaterIdForCallsign;
			End

		-- Finally, flag the accounts as expired
			Update users Set LicenseExpired = 1 WHERE callsign = @skCallsign;
	
			Delete from tempExpiredLicenses where @skUserId = UserId;
		End
		
		DROP TABLE IF EXISTS tempExpiredLicenses
	End
END
CREATE PROCEDURE [dbo].[spGetCoordinationRequestDetails] @callsign varchar(10), @password varchar(max), @requestid varchar(100)
AS   
BEGIN

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	If @userid <> 0
	Begin
		Select Requests.ID 'Request.ID', Users.FullName 'Request.Requestor.Name', Users.Callsign 'Request.Requestor.Callsign', CONVERT(VARCHAR(15), Requests.Location.Lat) 'Request.Latitude', CONVERT(VARCHAR(15), Requests.Location.Long) 'Request.Longitude', CONVERT(VARCHAR(15), Requests.OutputFrequency) 'Request.OutputFrequency', Requests.OutputPower 'Request.OutputPower', Requests.Altitude 'Request.Altitude', Requests.AntennaHeight 'Request.AntennaHeight', Requests.State 'Request.State', RequestStatuses.ID 'Request.Status.ID', RequestStatuses.Description 'Request.Status.Description'

		, (
			Select Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', Timestamp 'Note.Timestamp', Note 'Note.Text'
			from RequestNotes 
			INNER Join Users on Users.ID = RequestNotes.UserID
			where RequestNotes.RequestID = Requests.ID
			for JSON path) 'Request.Notes'
		, (
			Select State 'Step.State', Note 'Step.Note', TimeStamp 'Step.TimeStamp',
			RequestStatuses.ID 'Step.Status.ID', RequestStatuses.Description 'Step.Status.Description'
			from RequestWorkflows 
			INNER Join RequestStatuses on RequestStatuses.ID = RequestWorkflows.StatusID
			where RequestWorkflows.RequestID = Requests.ID
			for JSON path) 'Request.Workflow'
		, (
			Select State 'State' from RequestWorkflows 
			where RequestWorkflows.RequestID = @requestid
			for JSON path) 'Request.Authorized'

		From Requests
		INNER Join Users on Users.ID = Requests.UserID
		INNER Join RequestStatuses on RequestStatuses.ID = Requests.StatusID
		WHERE Requests.ID = @requestid
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	End
END;
CREATE PROCEDURE [dbo].[spAddRepeaterNote] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20), @note varchar(max)
AS   
BEGIN

	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int, @userID int, @trusteeID int, @RepeaterCallsign varchar(255), @outputFreq varchar(255)

	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1 OR @note = '*Repeater reported to be off-the-air*'
	Begin
		EXEC dbo.sp_GetUserID @callsign, @password, @userID output
		Insert into RepeaterChangeLogs (UserId, RepeaterId, ChangeDescription, ChangeDateTime) values (@userID, @repeaterID, @note, GETDATE());
		
		-- If this user isn't the primary trustee, then email the trustee about the update.
		Select @trusteeID = Repeaters.trusteeID, @RepeaterCallsign = Repeaters.Callsign, @outputFreq = Repeaters.OutputFrequency from Repeaters where Repeaters.ID = @repeaterID
		If @userid <> @trusteeID
		Begin
			DECLARE @emailToName varchar(255), @emailToAddress varchar(255);
			Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;
			Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@emailToName, @emailToAddress, 'Repeater update', '<span></span>The ' + UPPER(@RepeaterCallsign) + ' (' + @outputFreq + ') repeater has a new note from ' + UPPER(@callsign) + ':  <br><br>' + @note + '<br><hr>Open this repeater''s record at: https://arkansasrepeatercouncil.org/update/?id=' + @repeaterID);
		End
	End

END;
CREATE PROCEDURE [dbo].[spRemoveRepeaterUser] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20), @userID varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Delete from Permissions where UserId = @userID and RepeaterId = @repeaterID;
	End

END;
CREATE PROCEDURE [dbo].[spAddRepeaterUser] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20), @userID varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Insert into Permissions (UserId, RepeaterId) values (@userID, @repeaterID);
	End

END;
CREATE PROCEDURE [dbo].[spListPossibleRepeaterUsers] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Select ID, Callsign, FullName from Users 
		where ID not in (Select UserId from Permissions where RepeaterId = @repeaterID) 
			and SK = 0 and LicenseExpired = 0
		order by Callsign
		FOR JSON AUTO
	End

END;
CREATE PROCEDURE sp_ReportMonthlyActivity
AS
BEGIN

Declare @Enumerator table (City varchar(max), Callsign varchar(max), OutputFrequency varchar(max), ChangeDescription varchar(max));

Insert into @Enumerator 
SELECT DISTINCT Repeaters.City, Repeaters.Callsign, Repeaters.outputFrequency, ChangeDescription
FROM dbo.RepeaterChangeLogs Join Repeaters on RepeaterID = Repeaters.ID 
where ChangeDateTime > dateadd(day, -30, getdate())
order by city, outputFrequency;

Select CONCAT(City, ' - ', Callsign, ' (', outputFrequency,'): ', ChangeDescription) 
from @Enumerator;

END
CREATE PROCEDURE sp_CreatePasswordHash @callsign varchar(10), @password varchar(255), @hash varbinary(8000) output
AS
BEGIN
	DECLARE @salt varchar(255) = ( Select TOP(1) [Key] from Keys );
	DECLARE @userID varchar(10) = ( SELECT CONVERT(varchar(10), ID) FROM Users WHERE Callsign = @callsign );
	Set @hash = HASHBYTES('SHA2_256', @password + @userID + @salt);
END
CREATE PROCEDURE [dbo].[spListRecentActivity]      
AS   
BEGIN
	Select top 20
		ID,
		TimeStamp,
		JSON_VALUE(jsonData,'$.callsign') callsign, 
		JSON_VALUE(jsonData,'$.event') event, 
		JSON_VALUE(jsonData,'$.message') message
	from EventLog
	Where Type <> 'error' 
	order by ID Desc

END
CREATE PROCEDURE [dbo].[spLogError] @exceptionReport nvarchar(max)
AS   
BEGIN
	Insert into EventLog (jsonData, Type) values (@exceptionReport, 'error');
END;
CREATE PROCEDURE [dbo].[spNotifyExpiringTrustees]
AS   
BEGIN

	Declare @lateUsers table (UserID int, Fullname varchar(max), Callsign varchar(max), Email varchar(max), RepeaterList varchar(max))
	
	Insert into @lateUsers (UserID, Fullname, Callsign, Email)
	Select Users.ID, Users.FullName, Users.Callsign, Users.Email From Repeaters
	join Users on Repeaters.TrusteeID = Users.ID
	where Repeaters.DateUpdated < DateAdd(month, -33, GetDate()) and Repeaters.DateUpdated > DateAdd(month, -36, GetDate()) 
	and Repeaters.status <> 6 and Users.Email is not null
	group by Users.ID, Users.FullName, Users.Callsign, Users.Email;
	
	Declare @userid int, @fullname varchar(max), @callsign varchar(10), @email varchar(max);
	While exists (select 1 from @lateUsers where RepeaterList is null)
	Begin
		Select top 1 @userid = userid, @fullname = Fullname, @callsign = Callsign, @email = Email from @lateUsers where RepeaterList is null;
	
		Declare @Enumerator table (ID int, Callsign varchar(max), OutputFrequency varchar(max), MonthsLeft int)
		Insert into @Enumerator 
		Select Repeaters.ID, Repeaters.Callsign 'Callsign', Repeaters.OutputFrequency 'OutputFrequency', 
		DateDiff(month, DateUpdated, DateAdd(month, -33, GetDate())) 'MonthsLeft'
		from Repeaters 
		join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
		where Repeaters.DateUpdated < DateAdd(month, -33, GetDate()) and Repeaters.DateUpdated > DateAdd(month, -36, GetDate())
		and Repeaters.status <> 6 and Repeaters.TrusteeID = @userid
		
		Declare @repeaters varchar(max), @repeatercallsign varchar(10), @output varchar(max), @months int, @repeaterID int
		Set @repeaters = '';
		While exists (select 1 from @Enumerator)
		Begin
			Select top 1 @repeatercallsign = Callsign, @output = OutputFrequency, @months = MonthsLeft, @repeaterID = ID from @Enumerator
				Order by MonthsLeft Desc;
		
			Select @repeaters = CONCAT(@repeaters, '<br>', CHAR(13), CHAR(10), @repeatercallsign, ' ', @output, ' has ', @months, ' month(s) left before its coordination expires.');
		
			Delete from @Enumerator where Callsign = @repeatercallsign and OutputFrequency = @output;

			-- Add a note that we emailed them.
			Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) values (@repeaterID, 264, GetDate(), 'Notice of upcoming coordination expiration sent to trustee.');
		End
		
		Update @lateUsers set RepeaterList = @repeaters where userid = @userid;

		Declare @templateData varchar(max) = (Select FullName as 'name', Callsign as 'callsign', RepeaterList as 'repeaters' from @lateUsers where userid = @userid for json auto, WITHOUT_ARRAY_WRAPPER);

		-- Create the email record
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
		values (@fullname, @email, 'ACTION REQUIRED: Repeater coordination expiring', @templateData, 'd-27d382ac0e724e268b80441e8be2dfbf');
	End

	Select * from @lateUsers
END;
CREATE PROCEDURE [dbo].[spListRecentErrors]      
AS   
BEGIN
	Select top 20
		ID,
		TimeStamp,
		JSON_VALUE(jsonData,'$.url') url, 
		JSON_VALUE(jsonData,'$.querystring') querystring, 
		JSON_VALUE(jsonData,'$.message') message, 
		JSON_VALUE(jsonData,'$.source') source, 
		JSON_VALUE(jsonData,'$.stacktrace') stacktrace
	from EventLog
	Where Type = 'error' 
	order by ID Desc
END
CREATE PROCEDURE [dbo].[spMonthlyTasks]
AS   
BEGIN
	exec spNotifyExpiringTrustees;
	exec spNotifyLateTrustees;
END;
CREATE PROCEDURE spIsCoordinatorForRepeater @callsign varchar(10), @password varchar(255), @repeaterID int
AS
BEGIN
	Declare @result int = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @result = 
	(
		SELECT Top 1 1 FROM Permissions 
			where (Permissions.UserId = @userid and Permissions.RepeaterId = -1)
	)

	If @result = 1 
		Select 'true' [IsCoordinatorForRepeater];
	Else
		Select 'false' [IsCoordinatorForRepeater];
END
CREATE PROCEDURE [dbo].[spDailyTasks]
AS   
BEGIN
	exec spGenerateReminderEmails;
END;
CREATE PROCEDURE [dbo].[spGetOverdueWorkflows] @daysago int
AS   
BEGIN
	Select RequestWorkflows.ID, RequestWorkflows.RequestID, RequestWorkflows.State, RequestWorkflows.StatusID, URLKey, RequestedTimeStamp, LastReminderSent, States.CoordinatorEmail
	From RequestWorkflows 
	INNER JOIN States on RequestWorkflows.State = States.State
	INNER JOIN Requests on RequestWorkflows.RequestID = Requests.ID
	Where 
	Requests.StatusID = 1 AND
	RequestWorkflows.StatusID = 1 AND 
	DATEDIFF(day, RequestedTimeStamp, GETDATE()) >= @daysago AND
	(LastReminderSent is null OR DATEDIFF(day, LastReminderSent, GETDATE()) >= @daysago)

END;
CREATE PROCEDURE [dbo].[spReportInoperationalRepeaters] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions 
	where (
		(Permissions.UserId = @userid and Permissions.RepeaterId = -1) OR 
		(Permissions.UserId = @userid and Permissions.RepeaterId = -2)
		)
	);

	If @allowed = 1 
	BEGIN
		Select 
			(Select 'Inoperational repeaters' 'Report.Title',
				(
					Select 
					RepeaterStatuses.Status 'Repeater.Status', Repeaters.DateUpdated 'Repeater.DateUpdated',
					Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
					Repeaters.City 'Repeater.City', Repeaters.Location.Lat 'Repeater.Latitude', Repeaters.Location.Long 'Repeater.Longitude', 
					Repeaters.Sponsor 'Repeater.Sponsor', CONCAT(Users.Fullname, ', ', Users.Callsign, 
					' (', Users.ID, ')') 'Repeater.Trustee.Name', Users.Callsign 'Repeater.Trustee.Callsign', COALESCE(Users.Email, '') 'Repeater.Trustee.Email', 
					COALESCE(Users.phoneCell, '') 'Repeater.Trustee.CellPhone', COALESCE(Users.phoneHome, '') 'Repeater.Trustee.HomePhone', COALESCE(Users.PhoneWork, '') 'Repeater.Trustee.WorkPhone', 
					(
						Select 
							Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', 
							RepeaterChangeLogs.ChangeDateTime 'Note.Timestamp', RepeaterChangeLogs.ChangeDescription 'Note.Text'
						From RepeaterChangeLogs
						Inner Join Users on Users.ID = RepeaterChangeLogs.UserID
						Where RepeaterChangeLogs.RepeaterID = Repeaters.ID
						Order by RepeaterChangeLogs.ChangeDateTime
						For JSON path
					) 'Repeater.Notes'
				From Repeaters 
				Join Users on Users.ID = Repeaters.TrusteeID
				Join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
				Where repeaters.status not in (3,6) 
				Order by DateUpdated Asc
				FOR JSON PATH
				) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
)
	END
	ELSE
		Select '{}'
END;
CREATE PROCEDURE [dbo].[spGenerateReminderEmails]
AS   
BEGIN
	DECLARE @RemindOtherStatesOfWorkflowEveryThisManyDays int = 2;


	-- Create a table in memory with the states that will need to be included
	Declare @Enumerator table (ID int, RequestID int, State varchar(30), StatusID int, URLKey char(128), 
	RequestedTimeStamp datetime, LastReminderSent datetime, CoordinatorEmail varchar(255));

	Insert into @Enumerator exec spGetOverdueWorkflows @RemindOtherStatesOfWorkflowEveryThisManyDays;

	-- Loop through the enumerator table to build the workflow for this request
	While exists (select 1 from @Enumerator)
	Begin
		-- Declare variables
		Declare @ID int, @RequestID int, @State varchar(30), @StatusID int, @URLKey char(128), @RequestedTimeStamp datetime, 
		@LastReminderSent datetime, @CoordinatorEmail varchar(255);

		-- Assign variables
		Select top 1 @ID =ID, @RequestID =RequestID, @State =State, @StatusID =StatusID, @URLKey =URLKey, 
		@RequestedTimeStamp =RequestedTimeStamp, @LastReminderSent =LastReminderSent, @CoordinatorEmail =CoordinatorEmail 
		from @Enumerator;

		-- Check to see if this is more than 30 days old, if so automatically approve
		If DATEDIFF(day, @RequestedTimeStamp, GETDATE()) >= 30
			BEGIN
			exec spUpdateCoordinationRequestWorkflowStep @UrlKey, 2, 'Automatically approved because the request waited 30 days without a response.';
			-- Remove record from enumerator
			Delete from @Enumerator where ID = @ID;
		END
		Else
		BEGIN
			-- Create table in memory for request info
			Declare @templateDataTable table (requestedtimestamp datetime, urlKey char(128), requestId int);
			Delete from @templateDataTable; -- Apparently SQL server doesn't delete outside scope, so this.
			Insert into @templateDataTable values (@RequestedTimeStamp, @URLKey, @RequestID);
			Declare @templateData varchar(max) = (Select * from @templateDataTable for json auto, WITHOUT_ARRAY_WRAPPER);
	
			-- Add this to the email queue
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
			values (@State + ' Coordinator', @CoordinatorEmail, 'NOPC #AR' + Convert(varchar(10), @RequestID), 
			@templateData, 'd-b0bace804b204ca4a4c69f46351fe56f');
	
			-- Add a note that we emailed them.
			Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), 
			'Reminder sent to ' + @State + '.');
			
			-- Update the workflow with this reminder date
			Update RequestWorkflows set LastReminderSent = GETDATE() WHERE ID = @ID;
	
			-- Remove record from enumerator
			Delete from @Enumerator where ID = @ID;
		END
	End
END;
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
CREATE PROCEDURE [dbo].[spCheckIfAllWorkflowsCompleted] @requestid int
AS   
BEGIN
	Declare @requeststate varchar(10), @username varchar(100), @useremail varchar(255)
	
	Select @requeststate = Requests.State, @username = FullName, @useremail = Email 
	from Requests
	join Users on Users.ID = Requests.UserID
	where requests.ID = @requestid;

	-- Check to see if there are other states still needing to reply.
	Declare @countReplied int, @countTotal int, @countApproved int;
	Select @countReplied=(Select Count(ID) FROM dbo.RequestWorkflows Where RequestID = @requestid and StatusID != 1), @countTotal=(Select Count(ID) FROM dbo.RequestWorkflows Where RequestID = @requestid), @countApproved=(Select Count(ID) FROM dbo.RequestWorkflows Where RequestID = @requestid and StatusID = 2);
	If @countReplied = @countTotal
	Begin
		

		If @countApproved = @countTotal
		Begin
			Update Requests set StatusID = 2, ClosedOn = GetDate() Where ID = @requestid;
			exec spCreateRepeaterFromRequest @requestid;
		End
	
		-- All have replied create email, add to queue
		Declare @coordinationNumber varchar(200) = '#' + UPPER(@requeststate) + CONVERT(varchar, @requestid)
		Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@username, @useremail, 'Coordination ' + @coordinationNumber, 'All repeater coordinators have replied to coordination request ' + @coordinationNumber + '.<br><br>Please visit <a href="https://www.arkansasrepeatercouncil.org/request/details/?id=' + CONVERT(varchar, @requestid) + '">https://www.arkansasrepeatercouncil.org/request/details/?id=' + CONVERT(varchar, @requestid) + '</a> for the complete details.<br><br><a href="https://www.arkansasrepeatercouncil.org">Arkansas Repeater Council</a>');
	End
END;
CREATE PROCEDURE [dbo].[spListOpenRequests]
AS   
BEGIN
	-- List open coordinations 
	Select Requests.ID, Requests.requestedOn, Users.FullName + ' (' + Users.Callsign + ')' as Requestor, 
	Requests.Location.Lat as Latitude, Requests.Location.Long as Longitude, Requests.OutputFrequency FROM dbo.Requests 
	Inner join Users on Requests.UserID = Users.ID
	where statusID = 1;
END;
CREATE PROCEDURE spKmlAllRepeaters @callsign varchar(10), @password varchar(255)
AS
BEGIN
	DECLARE @userID int;
	exec sp_GetUserID @callsign, @password, @userID output;
	
	Declare @allowed int = (Select Count(UserID) from Permissions where UserId = @userID and RepeaterId < 0)

	If @allowed >= 1
	Begin
		with xmlnamespaces(default 'http://www.opengis.net/kml/2.2')
		Select (
			Select 
				Concat(Callsign,'<br/>Output: ', OutputFrequency, '<br/>Input: ', InputFrequency, '<br/><br/>','https://www.arkansasrepeatercouncil.org/repeaters/details/?id=', ID) 'description', 
				Concat(Location.Long, ',', Location.Lat, ',', 0) 'Point/coordinates', 
				CAST(CASE 
					WHEN OutputFrequency between 902 and 928 THEN '#33cm'
					WHEN OutputFrequency between 420 and 450 THEN '#70cm'
					WHEN OutputFrequency between 222 and 225 THEN '#1.25m'
					WHEN OutputFrequency between 144 and 148 THEN '#2m'
					WHEN OutputFrequency between 50 and 54 THEN '#6m'
					WHEN OutputFrequency between 28 and 29.7 THEN '#10m' END AS varchar(60)
				) 'styleUrl'
			from Repeaters 
			Where ID > 0 And Status <> 6 AND location is not null
			FOR XML PATH('Placemark'), type
		 ) for xml path('Document'), root('kml')
	End

END
CREATE PROCEDURE [dbo].[spCreateRepeaterFromRequest] @requestId int
AS   
BEGIN
	Declare @callsign varchar(6), @userid int, @location geography, @outputpower int, @altitude int, @antennaHeight int, @outputFreq decimal(12,6), @inputFreq decimal(12,6), @requestedDate datetime, @newRepeaterId int;

	Select @userid=UserID, @location=Location, @outputpower=OutputPower, @altitude=Altitude, @antennaHeight=AntennaHeight, @outputFreq=OutputFrequency, @requestedDate=RequestedOn from Requests where ID = @requestId;
	
	Select @callsign=Callsign from Users where ID = @userid;

	Select @inputFreq=Input from Frequencies where output = @outputFreq;

	Insert into Repeaters ([Type], [Callsign], TrusteeID, Status, OutputFrequency, InputFrequency, Location, DateCoordinated, DateUpdated, State, CoordinatedLocation, CoordinatedAntennaHeight, CoordinatedOutputPower, AntennaHeight, OutputPower) values 
							(1, @callsign, @userid, 2, @outputfreq, @inputFreq, @location, GETDATE(), GETDATE(), 'AR', @location, @antennaHeight, @outputpower, @antennaHeight, @outputpower);

	Select @newRepeaterId = @@IDENTITY;

	Update Requests set RepeaterId = @newRepeaterId where ID = @requestId

	Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) 
	values (@newRepeaterId, 264, @requestedDate, concat('Coordination requested on ', @requestedDate, '.'));
	Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) 
	values (@newRepeaterId, 264, GetDate(), concat('Coordination approved on ', GetDate(), '.'))

	Declare @WorkflowNotes table (id int, state varchar(max), note varchar(max), timestamp datetime)
	Insert into @WorkflowNotes Select ID, State, Note, TimeStamp from RequestWorkflows where RequestID = @requestId
	
	Declare @_id int, @_state varchar(max), @_note varchar(max), @_timestamp datetime
	While exists (select 1 from @WorkflowNotes)
	Begin
		Select top 1 @_id = id, @_state = state, @_note = note, @_timestamp = timestamp from @WorkflowNotes
	
		Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) 
		values (@newRepeaterId, 264, @_timestamp, concat(@_state, ' coordinator approved on ', @requestedDate, '. Note: ', @_note))
	
		Delete from @WorkflowNotes where id = @_id
	End
	
END;
CREATE PROCEDURE [dbo].[spReportNonstandardRepeaters] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions 
	where (
		(Permissions.UserId = @userid and Permissions.RepeaterId = -1) OR 
		(Permissions.UserId = @userid and Permissions.RepeaterId = -2)
		)
	);

	If @allowed = 1 
	BEGIN
		Select 
			(Select 'Nonstandard repeaters' 'Report.Title',
				(
					Select 
					Repeaters.DateUpdated 'Repeater.DateUpdated',
					Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
					Repeaters.InputFrequency 'Repeater.Input',
					Repeaters.City 'Repeater.City', Repeaters.Location.Lat 'Repeater.Latitude', Repeaters.Location.Long 'Repeater.Longitude', Repeaters.Sponsor 'Repeater.Sponsor', 
					CONCAT(Users.Fullname, ', ', Users.Callsign, ' (', Users.ID, ')') 'Repeater.Trustee.Name', 
					Users.Callsign 'Repeater.Trustee.Callsign', COALESCE(Users.Email, '') 'Repeater.Trustee.Email', 
					COALESCE(Users.phoneCell, '') 'Repeater.Trustee.CellPhone', COALESCE(Users.phoneHome, '') 'Repeater.Trustee.HomePhone', 
					COALESCE(Users.PhoneWork, '') 'Repeater.Trustee.WorkPhone', 
					(
						Select 
							Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', 
							RepeaterChangeLogs.ChangeDateTime 'Note.Timestamp', RepeaterChangeLogs.ChangeDescription 'Note.Text'
						From RepeaterChangeLogs
						Inner Join Users on Users.ID = RepeaterChangeLogs.UserID
						Where RepeaterChangeLogs.RepeaterID = Repeaters.ID
						Order by RepeaterChangeLogs.ChangeDateTime
						For JSON path
					) 'Repeater.Notes'
				From Repeaters 
				Join Users on Users.ID = Repeaters.TrusteeID
				Join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
				Where Repeaters.status <> 6 AND Repeaters.ID > 0 AND (Repeaters.outputfrequency not in (select output from frequencies) OR Repeaters.inputfrequency not in (select input from frequencies)) 
				Order by DateUpdated Asc
				FOR JSON PATH
				) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
)
	END
	ELSE
		Select '{}'
END;
CREATE PROCEDURE [dbo].[spGetRepeaterDetails] @callsign varchar(10), @password varchar(255), @repeaterID int
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

DECLARE @Updated int;
Set @Updated = 0;

If @hasPermission = 1
	Begin

		SELECT Repeaters.ID, Repeaters.Type, Repeaters.Callsign as RepeaterCallsign, Repeaters.TrusteeID, Users.Callsign as TrusteeCallsign, Repeaters.Status, Repeaters.City, Repeaters.SiteName, Repeaters.OutputFrequency, Repeaters.InputFrequency, Repeaters.Sponsor, Repeaters.Location.Lat as Latitude, Repeaters.Location.Long as Longitude, Repeaters.AMSL, Repeaters.ERP, Repeaters.OutputPower, Repeaters.AntennaGain, Repeaters.AntennaHeight, Repeaters.Analog_InputAccess, Repeaters.Analog_OutputAccess, Repeaters.Analog_Width, Repeaters.DSTAR_Module, Repeaters.DMR_ColorCode, Repeaters.DMR_ID, Repeaters.DMR_Network, Repeaters.P25_NAC, Repeaters.NXDN_RAN, Repeaters.YSF_DSQ, Repeaters.Autopatch, Repeaters.EmergencyPower, Repeaters.Linked, Repeaters.RACES, Repeaters.ARES, Repeaters.WideArea, Repeaters.Weather, Repeaters.Experimental, Repeaters.DateCoordinated, Repeaters.DateUpdated, Repeaters.DateDecoordinated, Repeaters.DateCoordinationSource, Repeaters.DateConstruction, Repeaters.CoordinatorComments, Repeaters.Notes, Repeaters.State, Repeaters.CoordinatedLocation.Lat as CoordinatedLatitude, Repeaters.CoordinatedLocation.Long as CoordinatedLongitude, Repeaters.CoordinatedAntennaHeight, Repeaters.CoordinatedOutputPower, Repeaters.AdditionalInformation

		FROM Repeaters
		JOIN Users on Repeaters.TrusteeID = Users.ID
		WHERE Repeaters.ID = @repeaterID
	End
END;
CREATE PROCEDURE spGetPossibleLinks_Json
AS
BEGIN

	Select CAST((Select ID 'Link.Value', Concat(OutputFrequency, ' - ', Callsign, ' in ', City) 'Link.Description'
	from Repeaters where Status between 2 and 5 and ID > 0 
	Order By OutputFrequency, Callsign
	FOR JSON PATH, INCLUDE_NULL_VALUES) as text) as JSON

END
CREATE PROCEDURE [dbo].[spGetRepeaterTypes]       
AS   
BEGIN
	select * from RepeaterTypes
END
CREATE PROCEDURE [dbo].[spGetRepeaterStatuses]       
AS   
BEGIN
	select * from RepeaterStatuses
END
CREATE PROCEDURE [dbo].[spReportExpiredRepeaters_Public] 
AS   
BEGIN
	Select 
		(Select 'Expired Most Wanted' 'Report.Title',(
			Select Top 10
			Round(DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate()))/12.00, 2) 'Repeater.YearsExpired', 
			Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
			Repeaters.City 'Repeater.City', Repeaters.Sponsor 'Repeater.Sponsor', CONCAT(Users.Fullname, ', ', Users.Callsign) 'Repeater.Trustee.Name', Users.Callsign 'Repeater.Trustee.Callsign'
			From Repeaters 
			Join Users on Users.ID = Repeaters.TrusteeID
			Where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 
			Order by DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate())) Desc
			FOR JSON PATH) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
END;
CREATE PROCEDURE [dbo].[sp_GeneratePasswordsForAllExistingAccounts]     
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
			Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@userName, @userEmail, 'Arkansas Repeater Council website', 'The Arkansas Repeater Council has a brand new website.  You can now login and maintain the records for your own repeaters.  Your username is ' + UPPER(@callsign) + ' and your password is ' + (@password) + ' (note that the password is case sensitive).  You may use these credentials to login at https://ArkansasRepeaterCouncil.org.');
		
			Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Password reset", "message":"Password reset for account ' + @callsign + '" }', 'security');
		END;
	
		Delete from @Trustees where trusteeCall = @callsign;
	End

END;
CREATE PROCEDURE sp_UserHasPermissionForRepeater @callsign varchar(10), @password varchar(255), @repeaterID int, @result int output
AS
BEGIN
	Set @result = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @result = 
	(
		SELECT Top 1 1 FROM Repeaters WHERE 
		( 
			Repeaters.ID in 
			( 
				Select @repeaterID from Permissions 
				where 
				(
					(Permissions.UserId = @userid and Permissions.RepeaterId = @repeaterID) OR
					(Permissions.UserId = @userid and Permissions.RepeaterId = -1) OR
					(Permissions.UserId = @userid and Permissions.RepeaterId = -2)
				)
			)
		)
		OR (Repeaters.TrusteeID = @userId AND Repeaters.ID = @repeaterID)
	)
END
CREATE PROCEDURE [dbo].[spListRecentChanges]      
AS   
BEGIN
	select top 20 RepeaterChangeLogs.ID as ChangeID, CONCAT('https://arkansasrepeatercouncil.org/repeaters/details/?id=', Repeaters.ID) as RepeaterURL, Repeaters.Callsign as RepeaterCallsign, Repeaters.OutputFrequency as Frequency,  
	Repeaters.City, Repeaters.State,  Users.callsign, Users.FullName, Users.Email, 
	CONVERT(DATETIME, RepeaterChangeLogs.ChangeDateTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time') as ChangeDateTime, 
	RepeaterChangeLogs.ChangeDescription
	from RepeaterChangeLogs 
	join Users on UserId = Users.ID
	join Repeaters on RepeaterId = Repeaters.ID
	Where 
		ChangeDescription not like '%• Latitude %'
		AND ChangeDescription not like '%• Longitude %'
	Order by RepeaterChangeLogs.ID Desc


END
CREATE PROCEDURE [dbo].[spGetRepeaterNotes] @callsign varchar(10), @password varchar(255), @repeaterID int
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	DECLARE @Updated int;
	Set @Updated = 0;
	
	If @hasPermission = 1
	Begin

		select RepeaterChangeLogs.ID as ChangeID, Users.callsign, Users.FullName, 
			CONVERT(DATETIME, RepeaterChangeLogs.ChangeDateTime AT TIME ZONE 'UTC' AT TIME ZONE 'Central Standard Time')  as ChangeDateTime, RepeaterChangeLogs.ChangeDescription
		from RepeaterChangeLogs 
			join Users on UserId = Users.ID
			join Repeaters on RepeaterId = Repeaters.ID
		where RepeaterChangeLogs.RepeaterId = @repeaterID 
		Order by RepeaterChangeLogs.ChangeDateTime Desc
	End
END
CREATE PROCEDURE [dbo].[spListPossibleTrustees] @callsign varchar(max), @password varchar(max), @repeaterID varchar(max)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

If @hasPermission = 1
	Begin
		Select ID, Callsign from Users where SK=0 and LicenseExpired=0 order by Callsign;
	End

END;
CREATE PROCEDURE [dbo].[spListRepeaterUsers] @callsign varchar(max), @password varchar(max), @repeaterID varchar(max)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Select Users.ID, Users.Callsign, Users.FullName, Users.Email from Users Where Users.ID in (Select Permissions.UserId from Permissions where Permissions.RepeaterId = @repeaterid) OR Users.ID in (Select Repeaters.TrusteeID from Repeaters where Repeaters.ID = @repeaterid) ;
	End

END;
CREATE PROCEDURE sp_GetUserID @callsign varchar(10), @password varchar(255), @result int output
AS
BEGIN

	Declare @passwordHash varbinary(8000);
	EXEC dbo.sp_CreatePasswordHash @callsign, @password, @passwordHash output;

	UPDATE Users SET LastLogin = GETDATE() WHERE Callsign = @callsign and Password = @passwordHash;
	Select @result = Users.ID from Users Where Users.Callsign = @callsign and Users.Password = @passwordHash
END
CREATE PROCEDURE [dbo].[spAddRepeaterLink] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20), @linkrepeaterid varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

	If @hasPermission = 1
	Begin
		Insert into Links (LinkFromRepeaterID, LinkToRepeaterID) values (@repeaterID, @linkrepeaterid);
		
		Declare @note varchar(max), @repeaterCallsign varchar(255), @repeaterFreq varchar(255), @linkCallsign varchar(255), @linkFreq varchar(255);
		Select @repeaterCallsign = Callsign, @repeaterFreq = OutputFrequency from Repeaters where ID = @repeaterID;
		Select @linkCallsign = Callsign, @linkFreq = OutputFrequency from Repeaters where ID = @linkrepeaterid;

		Set @note = CONCAT('The ', UPPER(@repeaterCallsign), ' (', @repeaterFreq, ') repeater was updated on <a href="http://ArkansasRepeaterCouncil.com">ArkansasRepeaterCouncil.com</a> by ', UPPER(@callsign), '.<br><br>It now is listed as being linked to the ', UPPER(@linkCallsign), ' (', @linkFreq, ') repeater.');
		exec spAddRepeaterNote @callsign, @password, @repeaterID, @note;
		exec sp_AddAutomatedRepeaterNote @linkrepeaterid, @note;
	End

	-- Return new list
	exec spListRepeaterLinks @repeaterID 
	
END;
CREATE PROCEDURE [dbo].[sp_GeneratePassword] @callsign varchar(10)     
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
			Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@userName, @userEmail, 'Arkansas Repeater Council account', 'Your password for the Arkansas Repeater Council website has been reset.  Your username is ' + UPPER(@callsign) + ' and your password is ' + (@password) + ' (note that the password is case sensitive).  You may use these credentials to login at https://ArkansasRepeaterCouncil.org');
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
CREATE PROCEDURE [dbo].[spListRepeaterLinks] @repeaterID varchar(max)
AS   
BEGIN
	
	DECLARE @LinkedRepeaters TABLE (RepeaterID INT, DirectlyLinked bit)
	
	SET NOCOUNT ON;
	
	--Get top level repeater links and add them to a table variable
	INSERT INTO @LinkedRepeaters
	SELECT DISTINCT ID, 1 FROM
	(
	SELECT LinkToRepeaterID [ID] FROM Links WHERE (LinkFromRepeaterID = @RepeaterID OR LinkToRepeaterID = @RepeaterID)
	AND LinkToRepeaterID NOT IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	UNION ALL 
	SELECT LinkFromRepeaterID [ID] FROM Links WHERE (LinkFromRepeaterID = @RepeaterID OR LinkToRepeaterID = @RepeaterID)
	AND LinkFromRepeaterID NOT IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	) AS res
	
	DECLARE @RowPos INT = 0;
	DECLARE @RowCnt INT = 0;
	
	SELECT @RowCnt = COUNT(0) FROM @LinkedRepeaters;
	
	WHILE @RowPos <= @RowCnt
	BEGIN
	
	DECLARE @LinkToRepeaterID INT
	
	--Get row of @RowPos
	SELECT @LinkToRepeaterID = RepeaterID
	FROM 
	(
	SELECT ROW_NUMBER() OVER
	(
	ORDER BY (SELECT NULL)
	) As RowNum, RepeaterID
	FROM @LinkedRepeaters
	) t2
	WHERE RowNum = @RowPos
	
	--CURSOR to get linked repeaters
	DECLARE @ID INT
	DECLARE db_cursor CURSOR FOR 
	SELECT LinkFromRepeaterID FROM Links 
	WHERE LinkToRepeaterID IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	UNION ALL
	SELECT LinkToRepeaterID FROM Links 
	WHERE LinkFromRepeaterID IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @ID
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
	
	IF NOT EXISTS (SELECT RepeaterID FROM @LinkedRepeaters WHERE RepeaterID = @ID)
	BEGIN
	INSERT INTO @LinkedRepeaters
	VALUES (@ID,0)
	END
	
	FETCH NEXT FROM db_cursor INTO @ID 
	END
	CLOSE db_cursor  
	DEALLOCATE db_cursor 
	--CURSOR
	
	--Update @RowCnt for loop
	SELECT @RowCnt = COUNT(0) FROM @LinkedRepeaters;
	
	-- Update next @RowPos 
	SET @RowPos = @RowPos + 1
	
	END 
	
	--Ouputs table variable values
	SELECT DISTINCT RepeaterID, DirectlyLinked, Repeaters.ID, Repeaters.Callsign, Repeaters.OutputFrequency, Repeaters.City
		FROM @LinkedRepeaters 
		INNER JOIN Repeaters on RepeaterID = Repeaters.ID 
		WHERE RepeaterID <> @RepeaterID
		Order by OutputFrequency;



END;
CREATE PROCEDURE [dbo].[spCreateRequestWorkflow] @RequestID int
AS   
BEGIN
	Declare @Latitude varchar(15), @Longitude varchar(15), @OutputPower int, @Altitude int, @AntennaHeight int, @OutputFrequency varchar(12)

	Select @Latitude=Location.Lat, @Longitude=Location.Long, @OutputPower=OutputPower, @Altitude=Altitude, @AntennaHeight=AntennaHeight, @OutputFrequency=OutputFrequency from Requests where ID = @RequestID;

	-- Create a table in memory with the states that will need to be included
	Declare @Enumerator table (state varchar(max), email varchar(max), miles int)
	Insert into @Enumerator exec spGetStatesWithinRange @latitude, @longitude
	
	-- Loop through the enumerator table to build the workflow for this request
	Declare @coordinationState varchar(max), @coordinationEmail varchar(max), @urlKey char(128) = NULL
	While exists (select 1 from @Enumerator)
	Begin
		Select top 1 @coordinationState = state, @coordinationEmail = email from @Enumerator;

		-- Generate unique URL key for this workflow step
		Set @urlKey = NULL;
		EXEC dbo.sp_GenerateRandomUniqueUrlKey @urlKey output;
		
		-- Create this workflow step
		Insert into RequestWorkflows (RequestID, State, UrlKey, StatusID) values (@RequestID, @coordinationState, @urlKey, 1);

		-- Create table in memory for request info
		Declare @templateDataTable table (latitude varchar(20), longitude varchar(20), outputPower int, amsl int, 
		antennaHeight int, outputFrequency varchar(12), urlKey char(128), requestId int);

		Delete from @templateDataTable;

		Insert into @templateDataTable values (@Latitude, @Longitude, @OutputPower, @Altitude, @AntennaHeight, 
		@OutputFrequency, @urlKey, @RequestID);

		Declare @templateData varchar(max) = (Select * from @templateDataTable for json auto, WITHOUT_ARRAY_WRAPPER);

		-- Email the coordinator for this step
		Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
		values (@coordinationState + ' Coordinator', @coordinationEmail, 'NOPC #AR' + Convert(varchar(10), @RequestID), 
		@templateData, 'd-a39c8542aa9946119b067788c80d12cd');

		-- Add a note that we emailed them.
		Insert into RequestNotes (RequestID, UserID, Timestamp, Note) values (@RequestID, 264, GetDate(), 
		'Notice of proposed coordination sent to ' + @coordinationState + '.');

		Delete from @Enumerator where @coordinationState = state;
	End
END;
CREATE PROCEDURE [dbo].[spGetRepeaterDetailsPublic] @repeaterID int
AS   
BEGIN
	SELECT Repeaters.ID, Repeaters.Type, Repeaters.Callsign as RepeaterCallsign, Users.Callsign as TrusteeCallsign, Repeaters.Status, Repeaters.City, Repeaters.SiteName, Repeaters.OutputFrequency, Repeaters.InputFrequency, Repeaters.Sponsor, Repeaters.Location.Lat as Latitude, Repeaters.Location.Long as Longitude, Repeaters.AMSL, Repeaters.ERP, Repeaters.OutputPower, Repeaters.AntennaGain, Repeaters.AntennaHeight, Repeaters.Analog_InputAccess, Repeaters.Analog_OutputAccess, Repeaters.Analog_Width, Repeaters.DSTAR_Module, Repeaters.DMR_ColorCode, Repeaters.DMR_ID, Repeaters.DMR_Network, Repeaters.P25_NAC, Repeaters.NXDN_RAN, Repeaters.YSF_DSQ, Repeaters.Autopatch, Repeaters.EmergencyPower, Repeaters.Linked, Repeaters.RACES, Repeaters.ARES, Repeaters.WideArea, Repeaters.Weather, Repeaters.Experimental, Repeaters.DateCoordinated, Repeaters.DateUpdated, Repeaters.DateDecoordinated, Repeaters.DateConstruction, Repeaters.Notes, Repeaters.State, Repeaters.AdditionalInformation

	FROM Repeaters
	JOIN Users on Repeaters.TrusteeID = Users.ID
	WHERE Repeaters.ID = @repeaterID
END;
CREATE PROCEDURE [dbo].[spRemoveRepeaterLink] @callsign varchar(max), @password varchar(max), @repeaterid varchar(20), @linkrepeaterid varchar(20)
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int;

	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterid, @hasPermission output

	If @hasPermission > 0
	Begin
		Delete from Links where (LinkFromRepeaterID = @repeaterid and LinkToRepeaterID = @linkrepeaterid)
			OR (LinkToRepeaterID = @repeaterid and LinkFromRepeaterID = @linkrepeaterid);

		Declare @note varchar(max), @repeaterCallsign varchar(255), @repeaterFreq varchar(255), @linkCallsign varchar(255), @linkFreq varchar(255);
		Select @repeaterCallsign = Callsign, @repeaterFreq = OutputFrequency from Repeaters where ID = @repeaterid;
		Select @linkCallsign = Callsign, @linkFreq = OutputFrequency from Repeaters where ID = @linkrepeaterid;
		Set @note = CONCAT('The ', UPPER(@repeaterCallsign), ' (', @repeaterFreq, ') repeater was updated on <a href="http://ArkansasRepeaterCouncil.com">ArkansasRepeaterCouncil.com</a> by ', UPPER(@callsign), '.<br><br>It is no longer listed as being linked to the ', UPPER(@linkCallsign), ' (', @linkFreq, ') repeater.');
		exec spAddRepeaterNote @callsign, @password, @repeaterID, @note;
		exec sp_AddAutomatedRepeaterNote @linkrepeaterid, @note;
	End

END;
CREATE PROCEDURE [dbo].[spGetRepeaterUpdateNumbers] 
AS   
BEGIN
	Declare @pctUpdated int, @pctExpired int, @updatedCount int, @expiredCount int, @totalCount int, @notUpdatedInSeveralYears int, @TotalCoordinationRequests int, @AverageDays int;
	
	Select @updatedCount=Count(ID) from repeaters where Status <> 6 and DateUpdated >= DATEADD(year, -3, GETDATE())
	Select @expiredCount=Count(ID) from repeaters where Status <> 6 and DateUpdated < DATEADD(year, -3, GETDATE())
	Select @totalCount=Count(ID) from repeaters where Status <> 6
	Select @pctUpdated=CAST(@updatedCount * 100 / @totalCount AS int)
	Select @pctExpired=100-@pctUpdated
	
	Select @TotalCoordinationRequests=Count(ID) from Requests;
	Select @TotalCoordinationRequests=@TotalCoordinationRequests+Count(ID) from ProposedCoordinationsLog;
	
	SELECT @AverageDays=Avg(DATEDIFF(day, RequestedOn, ClosedOn)) from Requests where RequestedOn > DATEADD(day, -90, GetDate());
	
	Select @updatedCount as RepeatersCurrent, @expiredCount as RepeatersExpired, @totalCount as TotalRepeaters, @pctUpdated AS PercentageCurrent, 
	@pctExpired as PercentageExpired, @TotalCoordinationRequests as TotalCoordinationRequests, @AverageDays as AverageDays
END;
CREATE PROCEDURE [sp_GetLinkedRepeaterIDs] @repeaterId int
AS
BEGIN
	
	Declare @Enumerator table (RepeaterID int, checked bit);
	Insert into @Enumerator Select LinkToRepeaterID,0 from Links where LinkFromRepeaterID = @repeaterid and @repeaterid not in (Select RepeaterID from @Enumerator);
	Insert into @Enumerator Select LinkFromRepeaterID,0 from Links where LinkToRepeaterID = @repeaterid and @repeaterid not in (Select RepeaterID from @Enumerator);
	
	Declare @rID int;
	While exists (select 1 from @Enumerator where checked = 0)
	Begin
		Select top 1 @rID = RepeaterID from @Enumerator where checked = 0;
		Update @Enumerator set checked = 1 where RepeaterID = @rId;

		Declare @Enumerator2 table (RepeaterID int);
		Insert into @Enumerator2 Exec sp_GetLinkedRepeaterIDs @rId;

		While exists (Select 1 from @Enumerator2)
		Begin
			Declare @repeaterIdToCheck int;
			Select Top 1 @repeaterIdToCheck = RepeaterID from @Enumerator2;
			If @repeaterIdToCheck not in (Select RepeaterID from @Enumerator)
				Begin
					Insert into @Enumerator values (@repeaterIdToCheck,0);
				End
			Delete from @Enumerator2 where RepeaterID = @repeaterIdToCheck;
		End
	End

	Select DISTINCT RepeaterID from @Enumerator

END
CREATE PROCEDURE [dbo].[spListRecentChangesPublic]      
AS   
BEGIN
	;WITH logs AS
	(
	   SELECT *,
	         ROW_NUMBER() OVER (PARTITION BY RepeaterID ORDER BY ID DESC) AS rn
	   FROM RepeaterChangeLogs
	)
	SELECT TOP 5 Repeaters.ID as RepeatersID, Repeaters.Callsign as RepeaterCallsign, Repeaters.OutputFrequency as Frequency, logs.ChangeDateTime, logs.ChangeDescription
	FROM logs
	JOIN Repeaters on RepeaterId = Repeaters.ID
	WHERE rn = 1 
	AND logs.ChangeDescription not like '%• Latitude %'
	AND logs.ChangeDescription not like '%• Longitude %'
	Order by logs.ID Desc
END
CREATE PROCEDURE _GetRepeatersNotInArkansas
AS
BEGIN

  Select ID, Status, Location.Lat, Location.Long, _Latitude, _Longitude from Repeaters where Status <> 6 and Location.STIntersects((Select Borders from States where State = 'Arkansas')) = 0

END
CREATE PROCEDURE spGetAllCallsigns
AS
BEGIN
/*
	Select callsign from users where users.SK = 0
		and LicenseExpired = 0
		and callsign <> ' OM'
		and callsign <> 'FAKE'
		and callsign <> 'UNKNOWN'
	Union
	Select callsign from repeaters where status <> 6
		and LicenseeSK = 0
		and LicenseExpired = 0
*/

	Declare @callsignsToCheck table (Callsign varchar(10));
	
	Declare @currentRepeaters table (RepeaterId int, Callsign varchar(10), TrusteeID int)
	Insert into @currentRepeaters Select ID, Callsign, TrusteeID from Repeaters where Status <> 6 AND ID >= 1
	
	Declare @repeaterId int, @repeaterTrusteeId int, @repeaterCallsign varchar(10);
	While exists (Select 1 from @currentRepeaters)
	Begin
		Select top 1 @repeaterId = RepeaterId, @repeaterTrusteeId = TrusteeID, @repeaterCallsign = Callsign from @currentRepeaters
	
		Insert into @callsignsToCheck values (@repeaterCallsign);
		Insert into @callsignsToCheck Select callsign from Users where ID = @repeaterTrusteeId;
		Insert into @callsignsToCheck Select callsign from Users where ID in (Select UserID from Permissions where RepeaterID = @repeaterId)
		Delete from @currentRepeaters where RepeaterId = @repeaterId
	End
	
	Delete from @callsignsToCheck where callsign in (Select Callsign from Users where LicenseExpired = 1 OR SK = 1)
	
	Select DISTINCT callsign from @callsignsToCheck order by callsign

END
CREATE PROCEDURE [dbo].[spGetStatesWithinRange] @latitude decimal, @longitude decimal
AS   
BEGIN
	declare @miles int = 90;
	declare @meters int = @miles / 0.0006213712
	declare @point geography = geography::Point(@latitude, @longitude, 4326);
	
	Select State, CoordinatorEmail, (@point.STDistance(Borders) * 0.0006213712) as Miles from States where 
		@point.STBuffer(@meters).STIntersects(Borders) = 1
END;
CREATE PROCEDURE [dbo].[spGetUserDetails] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @passwordHash varbinary(8000);
	EXEC dbo.sp_CreatePasswordHash @callsign, @password, @passwordHash output;

	Select ID, Callsign, FullName, Address, City, State, ZIP, Email, PhoneHome, PhoneWork, PhoneCell from users
	WHERE Callsign = @callsign and Password = @passwordHash
END;
CREATE PROCEDURE [dbo].[spNotifyLateTrustees]
AS   
BEGIN

	Declare @lateUsers table (UserID int, Fullname varchar(max), Callsign varchar(max), Email varchar(max), RepeaterList varchar(max))
	
	Insert into @lateUsers (UserID, Fullname, Callsign, Email)
	Select Users.ID, Users.FullName, Users.Callsign, Users.Email From Repeaters
	join Users on Repeaters.TrusteeID = Users.ID
	where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 and Users.Email is not null
	group by Users.ID, Users.FullName, Users.Callsign, Users.Email;
	
	Declare @userid int, @fullname varchar(max), @callsign varchar(10), @email varchar(max);
	While exists (select 1 from @lateUsers where RepeaterList is null)
	Begin
		Select top 1 @userid = userid, @fullname = Fullname, @callsign = Callsign, @email = Email from @lateUsers where RepeaterList is null;
	
		Declare @Enumerator table (ID int, Callsign varchar(max), OutputFrequency varchar(max), MonthsExpired int)
		Insert into @Enumerator 
		Select Repeaters.ID, Repeaters.Callsign 'Callsign', Repeaters.OutputFrequency 'OutputFrequency', 
		DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate())) 'MonthsExpired'
		from Repeaters 
		join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
		where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 and Repeaters.TrusteeID = @userid
		
		Declare @repeaters varchar(max), @repeatercallsign varchar(10), @output varchar(max), @months int, @repeaterID int
		Set @repeaters = '';
		While exists (select 1 from @Enumerator)
		Begin
			Select top 1 @repeatercallsign = Callsign, @output = OutputFrequency, @months = MonthsExpired, @repeaterID = ID from @Enumerator
				Order by MonthsExpired Desc;
		
			Select @repeaters = CONCAT(@repeaters, '<br>', CHAR(13), CHAR(10), @repeatercallsign, ' ', @output, ' is ', @months, ' month(s) overdue.');
		
			Delete from @Enumerator where Callsign = @repeatercallsign and OutputFrequency = @output;

			-- Add a note that we emailed them.
			If @email is not null
			Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) values (@repeaterID, 264, GetDate(), 'Notice of coordination expiration sent to trustee.');
			else
			Insert into RepeaterChangeLogs (RepeaterID, UserID, ChangeDateTime, ChangeDescription) values (@repeaterID, 264, GetDate(), 'Unable to email coordination expiration notice to trustee.');
		End
		
		Update @lateUsers set RepeaterList = @repeaters where userid = @userid;

		Declare @templateData varchar(max) = (Select FullName as 'name', Callsign as 'callsign', RepeaterList as 'repeaters' from @lateUsers where userid = @userid for json auto, WITHOUT_ARRAY_WRAPPER);

		If @email is not null
		Begin
			-- Create the email record
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) 
			values (@fullname, @email, 'ACTION REQUIRED: Repeater coordination expired', @templateData, 'd-27d382ac0e724e268b80441e8be2dfbf');
		End
	End

	Select * from @lateUsers
END;
CREATE PROCEDURE [dbo].[sp_QueryCallsign] @callsign varchar(10)    
AS   
BEGIN

	Declare @userid int;
	Select @userid=Users.ID from Users Where Users.Callsign = @callsign

	Select Users.Callsign 'User.Callsign', Users.Fullname 'User.Name', Users.Email 'User.Email', Users.PhoneHome 'User.Phone.Home', Users.PhoneWork 'User.Phone.Work', Users.PhoneCell 'User.Phone.Cell', Users.LastLogin 'User.LastLogin'
, (
	SELECT Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.OutputFrequency', Repeaters.City 'Repeater.City', RepeaterStatuses.Status 'Repeater.Status', Repeaters.DateUpdated 'Repeater.DateUpdated'
	FROM Repeaters
	JOIN RepeaterStatuses on RepeaterStatuses.ID = Repeaters.status
	WHERE Repeaters.ID in (Select Permissions.RepeaterId from Permissions where Permissions.UserId = @userid)
	OR Repeaters.TrusteeID = @userId
	for JSON path) 'User.Repeaters'
From Users where ID = @userid
FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER

END;
CREATE PROCEDURE spProposedCoordination @callsign varchar(7), @password varchar(255), @latitude decimal (15, 12), @longitude decimal (15, 12), @TransmitFrequency decimal(18,6), @receiveFreq decimal(18,6)
AS
BEGIN
	Declare @userId int;
	exec sp_GetUserID @callsign, @password, @userId output;

	If @userId is not null
	BEGIN

		-- Create a table in memory with the states that will need to be included
		Declare @tblInterferingRepeaters table (Miles int, OutputFrequency decimal(12,6), City varchar(24), Callsign varchar(6));
		Declare @countInterferingRepeaters int, @answer int = 2, @comment varchar(255);
		Declare @point geography = geography::Point(@latitude, @longitude, 4326);
	
		IF @TransmitFrequency between 144.0 and 148.0
		BEGIN
			Insert into @tblInterferingRepeaters SELECT Round(Location.STDistance(@point) / 1609.34,1) as Miles, OutputFrequency, City, Callsign FROM Repeaters
			WHERE (OutputFrequency = @TransmitFrequency AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles
			ORDER BY Location.STDistance(@point);
		END;
		
		IF @TransmitFrequency between 222.0 and 225.0
		BEGIN
			Insert into @tblInterferingRepeaters SELECT Round(Location.STDistance(@point) / 1609.34,1) as Miles, OutputFrequency, City, Callsign FROM Repeaters
			WHERE (OutputFrequency = @TransmitFrequency AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
			ORDER BY Location.STDistance(@point);
		END;
		
		IF @TransmitFrequency between 420.0 and 450.0
		BEGIN
			Insert into @tblInterferingRepeaters SELECT Round(Location.STDistance(@point) / 1609.34,1) as Miles, OutputFrequency, City, Callsign FROM Repeaters
			WHERE (OutputFrequency = @TransmitFrequency AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
			ORDER BY Location.STDistance(@point);
		END;
	
		select @countInterferingRepeaters=count(Miles) from @tblInterferingRepeaters;
		IF @countInterferingRepeaters = 0 
		BEGIN
			Set @answer = 1;
			Set @comment = 'According to our records, a repeater at this location on this frequency will not interfer with any coordinated repeater.';
		END;
	
		IF @countInterferingRepeaters > 0
		BEGIN
			Declare @closestMiles int;
			Select top 1 @closestMiles=Miles from @tblInterferingRepeaters order by Miles asc;
			Set @comment=concat('This would potentially interfer with ', @countInterferingRepeaters, ' repeater(s), the closest of which is ', @closestMiles, ' miles away.');
		END;
	
		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"NOPC", "message":"Proposed coordination filed by ' + @callsign + '" }', 'NOPC');
		Insert into ProposedCoordinationsLog Select @userId, @point, @TransmitFrequency, @receiveFreq, @answer, @comment, GetDate();
	
		Declare @RequestID int;
		Select @RequestID=SCOPE_IDENTITY();
	
		Select TransmitFrequency, ReceiveFrequency, ProposedCoordinationAnswers.Description as Answer, Comment from ProposedCoordinationsLog 
		Inner join ProposedCoordinationAnswers on ProposedCoordinationsLog.Answer = ProposedCoordinationAnswers.ID
		where ProposedCoordinationsLog.ID = @RequestID;
	END
	ELSE
	BEGIN
		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Security", "message":"Invalid login attempt against ' + @callsign + '" }', 'Security');
	END
END
CREATE PROCEDURE [dbo].[spReportMostActiveUsers] 
AS   
BEGIN
	SELECT Top 10 Count(JSON_VALUE(jsonData, '$.callsign')) AS Logins, JSON_VALUE(jsonData, '$.callsign') as Callsign FROM dbo.EventLog 
	where type = 'login'
		and TimeStamp > DATEADD(day, -30, GetDate()) 
		and JSON_VALUE(jsonData, '$.callsign') <> 'n5kwl'
		and JSON_VALUE(jsonData, '$.callsign') <> 'n5jlc'
	group by JSON_VALUE(jsonData, '$.callsign')
	order by Logins desc;
END;
CREATE PROCEDURE [dbo].[spListPublicRepeaters] 
	@state varchar(10),
	@search varchar(8000) = '',
	@latitude varchar(20) = '39.83',
	@longitude varchar(20) = '-98.583',
	@miles int = 2680,
	@pageSize int = 1000,
	@pageNumber int = 1,
	@orderBy varchar(20) = 'OutputFrequency',
	@includeDecoordinated int = 0
AS   
BEGIN
	DECLARE @point geography = geography::Point(@latitude, @longitude, 4326);
	Declare @meters int = @miles * 1609.34;

	select Repeaters.ID, Repeaters.Callsign, Users.Callsign as Trustee, RepeaterStatuses.Status, RepeaterTypes.Type, 
		Repeaters.City, OutputFrequency, InputFrequency-OutputFrequency as Offset, Analog_InputAccess, Analog_OutputAccess, 
		DSTAR_Module, DMR_ColorCode, DMR_ID, AutoPatch, EmergencyPower, Linked, RACES, ARES, Weather, DateUpdated,
		Repeaters.Location.STDistance(@point)/1609.34 as MilesAway
	
	from repeaters 
		join Users on TrusteeID = Users.ID
		join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
		join RepeaterTypes on RepeaterTypes.ID = Repeaters.Type
	
	where Repeaters.Type <> 8 
	and Repeaters.status not in (1,@includeDecoordinated)
	and Repeaters.DateDecoordinated is null 
	and Repeaters.State = @state
	and (Repeaters.OutputFrequency like @search + '%'
	or Repeaters.Callsign like '%' + @search + '%' 
	or Repeaters.City like '%' + @search + '%'
	or Users.Callsign like '%' + @search + '%' )
	and @point.STBuffer(@meters).STIntersects(Repeaters.Location) = 1

	Order by
		CASE WHEN @orderBy = 'MilesAway' THEN Repeaters.Location.STDistance(@point) END,
		CASE WHEN @orderBy = 'Distance' THEN Repeaters.Location.STDistance(@point) END,
		CASE WHEN @orderBy = 'OutputFrequency' THEN Repeaters.OutputFrequency END,
		CASE WHEN @orderBy = 'Callsign' THEN Repeaters.Callsign END,
		CASE WHEN @orderBy = 'Trustee' THEN Users.Callsign END,
		CASE WHEN @orderBy = 'Status' THEN RepeaterStatuses.Status END,
		CASE WHEN @orderBy = 'City' THEN Repeaters.City END

OFFSET @pageSize * (@pageNumber - 1) ROWS
	FETCH NEXT @pageSize ROWS ONLY
END
CREATE PROCEDURE [dbo].[sp_AddAutomatedRepeaterNote] @repeaterID int, @note varchar(max)
AS   
BEGIN

	DECLARE @userID int, @trusteeID int, @RepeaterCallsign varchar(255), @outputFreq varchar(255);
	Set @userID = 264; -- System account

	Insert into RepeaterChangeLogs (UserId, RepeaterId, ChangeDescription, ChangeDateTime) values (@userID, @repeaterID, @note, GETDATE());
	
	-- Email the trustee about the update.
	Select @trusteeID = Repeaters.trusteeID, @RepeaterCallsign = Repeaters.Callsign, @outputFreq = Repeaters.OutputFrequency from Repeaters where Repeaters.ID = @repeaterID;
	DECLARE @emailToName varchar(255), @emailToAddress varchar(255), @emailContents varchar(max);
	Set @emailContents = Concat('<span></span>The ', UPPER(@RepeaterCallsign), ' (', @outputFreq , ') repeater has a new system-generated note:  <br><br>' , @note , '<br><hr>Open this repeater''s record at: https://arkansasrepeatercouncil.org/update/?id=' , @repeaterID , ' ');

	Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;
	Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@emailToName, @emailToAddress, 'Repeater update', @emailContents);

	Declare @tblUsersWithPermission table (userID int);
	Insert into @tblUsersWithPermission Select UserID from Permissions where RepeaterId = @repeaterID;

	While exists (Select 1 from @tblUsersWithPermission)
	Begin
		Declare @repeaterUserId int;
		Select top 1 @repeaterUserId = UserID from @tblUsersWithPermission

		Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @repeaterUserId;
		Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@emailToName, @emailToAddress, 'Repeater update', @emailContents);

		Delete from @tblUsersWithPermission where @repeaterUserId = UserID
	End

END;
CREATE PROCEDURE spUpdateSilentKeys @calls NVARCHAR(1000)
AS
BEGIN
	IF @calls <> ''
	Begin
		--Declare @calls nvarchar(1000); Set @calls = 'aa5jc,n5gc,n5xfw';
		DROP TABLE IF EXISTS tempSilentKeys
		SELECT value INTO tempSilentKeys FROM string_split(@calls,',');
		Alter table tempSilentKeys add UserId int;
		Update tempSilentKeys set UserId = (Select ID from Users where Users.callsign = tempSilentKeys.value)
		
		Declare @skCallsign nvarchar(10), @skUserId int;
		While exists (select 1 from tempSilentKeys)
		Begin
			Select top 1 @skCallsign = value, @skUserId = UserId from tempSilentKeys;
			
			-- REMOVE PERMISSIONS
			Declare @repeatersSilentKeyHadPermissionsOn table (RepeaterId int)
			Insert into @repeatersSilentKeyHadPermissionsOn Select RepeaterId from Permissions where UserId = @skUserId
			Declare @repeaterIdForPermissions int
			While exists (Select 1 from @repeatersSilentKeyHadPermissionsOn)
			Begin
				Select top 1 @repeaterIdForPermissions = RepeaterId from @repeatersSilentKeyHadPermissionsOn
				Delete from Permissions where UserId = @skUserId and RepeaterID = @repeaterIdForPermissions;
				Declare @emailContents varchar(8000); Set @emailContents = concat('We regret that, according to QRZ, ', @skCallsign, ' has become a silent key. Their account has been removed as a user from this repeater.');
				exec sp_AddAutomatedRepeaterNote @repeaterIdForPermissions, @emailContents
				Delete from @repeatersSilentKeyHadPermissionsOn where @repeaterIdForPermissions = RepeaterId
			End
	
			-- FLAG ANY REPEATERS ON WHICH THEY ARE THE TRUSTEE
			Declare @repeatersOnWhichSilentKeyWasTrustee table (RepeaterId int)
			Insert into @repeatersOnWhichSilentKeyWasTrustee Select ID from Repeaters where TrusteeID = @skUserId
			Declare @repeaterIdForTrustee int
			While exists (Select 1 from @repeatersOnWhichSilentKeyWasTrustee)
			Begin
				Select top 1 @repeaterIdForTrustee = RepeaterId from @repeatersOnWhichSilentKeyWasTrustee
				
				-- Let's randomly select one of the users of this repeater and set them as the trustee
				Declare @repeaterUsers table (UserID int, Callsign varchar(8000))
				Insert into @repeaterUsers Select permissions.UserID, Users.Callsign from permissions join users on permissions.userid = users.id where RepeaterId = @repeaterIdForTrustee and UserId <> @skUserId
				If exists (Select 1 from @repeaterUsers)
				Begin
					Declare @newTrusteeId int, @newTrusteeCallsign varchar(8000)
					Select top 1 @newTrusteeId = UserId, @newTrusteeCallsign = callsign from @repeaterUsers
					Update Repeaters set TrusteeID = @newTrusteeId Where ID = @repeaterIdForTrustee
					Declare @emailContents2 varchar(8000); Set @emailContents2 = 'We regret that, according to QRZ, ' + @skCallsign + ' has become a silent key. We have automatically changed the primary trustee to ' + @newTrusteeCallsign + '.  You can login to change that at any time.';
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents2;
				End
				Else
				Begin
					Update repeaters Set LicenseeSK = 1 WHERE id = @repeaterIdForTrustee;
					Declare @emailContents3 varchar(8000); Set @emailContents3 = concat('We regret that, according to QRZ, ', @skCallsign, ' has become a silent key. Their account has been removed as a user from this repeater.');
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents3
				End
				
				Delete from @repeatersOnWhichSilentKeyWasTrustee where @repeaterIdForTrustee = RepeaterId
			End
	
			-- FLAG ANY REPEATERS THAT USE THEIR CALLSIGN
			Declare @repeatersUsingSilentKeysCallsign table (RepeaterId int);
			Insert into @repeatersUsingSilentKeysCallsign Select ID from Repeaters where callsign = @skCallsign
			While exists (Select 1 from @repeatersUsingSilentKeysCallsign)
			Begin
				Declare @repeaterIdForCallsign int;
				Select top 1 @repeaterIdForCallsign = RepeaterId from @repeatersUsingSilentKeysCallsign;
				Update repeaters Set LicenseeSK = 1 WHERE id = @repeaterIdForCallsign;
				Declare @emailContents4 varchar(8000); Set @emailContents4 = 'We regret that, according to QRZ, ' + @skCallsign + ' has become a silent key. This repeater will need to be assigned a new callsign, and should be taken off the air until such time.  If this repeater has not been updated with a new callsign within 30 days it will be decoordinated.';
				exec sp_AddAutomatedRepeaterNote @repeaterIdForCallsign, @emailContents4
				Delete from @repeatersUsingSilentKeysCallsign where repeaterId = @repeaterIdForCallsign;
			End

			-- Finally, flag the accounts as SK
			Update users Set SK = 1 WHERE callsign = @skCallsign;

			Delete from tempSilentKeys where @skUserId = UserId;
		End
		
		DROP TABLE IF EXISTS tempSilentKeys
	End
END
CREATE PROCEDURE [dbo].[spListRepeatersNearPoint] @lat decimal(10, 7), @lon decimal (10, 7), @miles integer
AS   
BEGIN
	Declare @meters int;
	Set @meters = @miles * 1609.34;

	DECLARE @point geography;
	SET @point = geography::Point(@lat, @lon, 4326);

	Select Repeaters.Callsign, Users.Callsign as Trustee, RepeaterStatuses.Status, RepeaterTypes.Type, Repeaters.City, OutputFrequency, InputFrequency-OutputFrequency as Offset, Analog_InputAccess, Analog_OutputAccess, DSTAR_Module, DMR_ColorCode, DMR_ID, AutoPatch, EmergencyPower, Linked, RACES, ARES, Weather, DateUpdated, Repeaters.Location.STDistance(@point)/1609.34 as Miles
	
	from Repeaters 
		join Users on TrusteeID = Users.ID
		join RepeaterStatuses on RepeaterStatuses.ID = Repeaters.Status
		join RepeaterTypes on RepeaterTypes.ID = Repeaters.Type
	
	where 
		Repeaters.Type NOT IN (2,3) and 
		DateDecoordinated is null and 
		@point.STBuffer(@meters).STIntersects(Location) = 1

	order by Repeaters.Location.STDistance(@point) asc
END
CREATE PROCEDURE spProposedCoordinationMiles @latitude decimal (15, 12), @longitude decimal (15, 12), @freq decimal(18,6), @miles int 
AS
BEGIN
	DECLARE @point geography = geography::Point(@latitude, @longitude, 4326);
	DECLARE @meters int = Round(@miles * 1609.34, 0);

	IF @freq between 144.0 and 148.0
	BEGIN
		SELECT Round(Location.STDistance(@point) / 1609.34, 0) as Miles, OutputFrequency FROM Repeaters
		WHERE (OutputFrequency = @freq AND Location.STDistance(@point) < @meters) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
		 OR (ABS(OutputFrequency - @freq) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles

		SELECT Round(Location.STDistance(@point) / 1609.34, 0) as Miles, OutputFrequency FROM Requests
		WHERE StatusID = 1 AND (
		(OutputFrequency = @freq AND Location.STDistance(@point) < @meters) -- 144841 meters ~= 90 miles
		OR (ABS(OutputFrequency - @freq) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		OR (ABS(OutputFrequency - @freq) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
		OR (ABS(OutputFrequency - @freq) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles
		)
	END;
	
	
	IF @freq between 222.0 and 225.0
	BEGIN
		SELECT Round(Location.STDistance(@point) / 1609.34, 0) as Miles, OutputFrequency FROM Repeaters
		WHERE (OutputFrequency = @freq AND Location.STDistance(@point) < @meters) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)

		SELECT Round(Location.STDistance(@point) / 1609.34, 0) as Miles, OutputFrequency FROM Requests
		WHERE StatusID = 1 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < @meters) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
	END;
	
	
	IF @freq between 420.0 and 450.0
	BEGIN
		SELECT Round(Location.STDistance(@point) / 1609.34, 0) as Miles, OutputFrequency FROM Repeaters
		WHERE (OutputFrequency = @freq AND Location.STDistance(@point) < @meters) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)

		SELECT Round(Location.STDistance(@point) / 1609.34, 0) as Miles, OutputFrequency FROM Requests
		WHERE StatusID = 1 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < @meters) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
	END;

END
CREATE PROCEDURE [dbo].[sp_GenerateRandomKey] @randomKey char(128) output
AS   
BEGIN

	DECLARE @s char(128);

	SET @s = (
	SELECT
		c1 AS [text()]
	FROM
		(
		SELECT TOP (128) c1
		FROM
		  (
	    VALUES
('A'), ('B'), ('C'), ('D'), ('E'), ('F'), ('G'), ('H'), ('I'), ('J'),('K'), ('L'), ('M'), 
('N'), ('O'), ('P'), ('Q'), ('R'), ('S'), ('T'),('U'), ('V'), ('W'), ('X'), ('Y'), ('Z'), 
('A'), ('B'), ('C'), ('D'), ('E'), ('F'), ('G'), ('H'), ('I'), ('J'),('K'), ('L'), ('M'), 
('N'), ('O'), ('P'), ('Q'), ('R'), ('S'), ('T'),('U'), ('V'), ('W'), ('X'), ('Y'), ('Z'), 
('a'), ('b'), ('c'), ('d'), ('e'), ('f'), ('g'), ('h'), ('i'), ('j'), ('k'), ('l'), ('m'), 
('n'), ('o'), ('p'), ('q'), ('r'), ('s'), ('t'), ('u'), ('v'), ('w'), ('x'), ('y'), ('z'),
('a'), ('b'), ('c'), ('d'), ('e'), ('f'), ('g'), ('h'), ('i'), ('j'), ('k'), ('l'), ('m'), 
('n'), ('o'), ('p'), ('q'), ('r'), ('s'), ('t'), ('u'), ('v'), ('w'), ('x'), ('y'), ('z'),
('0'), ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'), 
('0'), ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'), 
('A'), ('B'), ('C'), ('D'), ('E'), ('F'), ('G'), ('H'), ('I'), ('J'),('K'), ('L'), ('M'), 
('N'), ('O'), ('P'), ('Q'), ('R'), ('S'), ('T'),('U'), ('V'), ('W'), ('X'), ('Y'), ('Z'), 
('A'), ('B'), ('C'), ('D'), ('E'), ('F'), ('G'), ('H'), ('I'), ('J'),('K'), ('L'), ('M'), 
('N'), ('O'), ('P'), ('Q'), ('R'), ('S'), ('T'),('U'), ('V'), ('W'), ('X'), ('Y'), ('Z'), 
('a'), ('b'), ('c'), ('d'), ('e'), ('f'), ('g'), ('h'), ('i'), ('j'), ('k'), ('l'), ('m'), 
('n'), ('o'), ('p'), ('q'), ('r'), ('s'), ('t'), ('u'), ('v'), ('w'), ('x'), ('y'), ('z'),
('a'), ('b'), ('c'), ('d'), ('e'), ('f'), ('g'), ('h'), ('i'), ('j'), ('k'), ('l'), ('m'), 
('n'), ('o'), ('p'), ('q'), ('r'), ('s'), ('t'), ('u'), ('v'), ('w'), ('x'), ('y'), ('z'),
('0'), ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'), 
('0'), ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9')
		  ) AS T1(c1)
		ORDER BY ABS(CHECKSUM(NEWID()))
		) AS T2
	FOR XML PATH('')
	);
	
	Set @randomKey = @s;

END;
CREATE PROCEDURE sp_WhyCantIHaveThisSpecificFrequency @latitude decimal (15, 12), @longitude decimal (15, 12), @freq decimal(18,6)
AS
BEGIN

	--Set @latitude = 35.829320;
	--Set @longitude = -91.421983;
	--Set @freq = 146.715;
	Declare @nearRepeaters table (TransmitFrequency decimal(12,6), FrequencyDifference decimal(6,3), MilesAway decimal(4,2));	
	DECLARE @point geography = geography::Point(@latitude, @longitude, 4326);
	
	IF @freq between 144.0 and 148.0
	BEGIN
	
		Insert into @nearRepeaters 
		SELECT OutputFrequency, abs(OutputFrequency-@freq) as FrequencyDifference, dbo.MetersToMiles(Location.STDistance(@point)) as MilesAway FROM Repeaters
		WHERE Status <> 6 AND (
		 (OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
		 OR (ABS(OutputFrequency - @freq) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles
		)
	
		Insert into @nearRepeaters 
		SELECT OutputFrequency, abs(OutputFrequency-@freq) as FrequencyDifference, dbo.MetersToMiles(Location.STDistance(@point)) as MilesAway FROM Requests
		WHERE StatusID = 1 AND (
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		OR (ABS(OutputFrequency - @freq) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		OR (ABS(OutputFrequency - @freq) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
		OR (ABS(OutputFrequency - @freq) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles
		)
	END;
	
	
	IF @freq between 222.0 and 225.0
	BEGIN
	
		Insert into @nearRepeaters 
		SELECT OutputFrequency, abs(OutputFrequency-@freq) as FrequencyDifference, dbo.MetersToMiles(Location.STDistance(@point)) as MilesAway FROM Repeaters
		WHERE Status <> 6 AND (
		 (OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
		
		Insert into @nearRepeaters 
		SELECT OutputFrequency, abs(OutputFrequency-@freq) as FrequencyDifference, dbo.MetersToMiles(Location.STDistance(@point)) as MilesAway FROM Requests
		WHERE StatusID = 1 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
	END;
	
	
	IF @freq between 420.0 and 450.0
	BEGIN
	
		Insert into @nearRepeaters 
		SELECT OutputFrequency, abs(OutputFrequency-@freq) as FrequencyDifference, dbo.MetersToMiles(Location.STDistance(@point)) as MilesAway FROM Repeaters
		WHERE Status <> 6 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
	
		Insert into @nearRepeaters 
		SELECT OutputFrequency, abs(OutputFrequency-@freq) as FrequencyDifference, dbo.MetersToMiles(Location.STDistance(@point)) as MilesAway FROM Requests
		WHERE StatusID = 1 AND ( 
		(OutputFrequency = @freq AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
		 OR (ABS(OutputFrequency - @freq) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
		 OR (ABS(OutputFrequency - @freq) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
		 OR (ABS(OutputFrequency - @freq) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
		)
	END;
	
	Select * from @nearRepeaters;


END
CREATE PROCEDURE [dbo].[spCreateNewUser] @callsign varchar(10), @fullname varchar(100), @address varchar(100), @city varchar(24), @state varchar(2), @zip varchar(10), @email varchar(255)     
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

		Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@callsign, @email, 'Arkansas Repeater Council account', 'Your account for the Arkansas Repeater Council website has been created.  Your username is ' + UPPER(@callsign) + ' and your password is ' + (@password) + ' (note that the password is case sensitive).  You may use these credentials to login at https://ArkansasRepeaterCouncil.org.');
			
				Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Account created", "message":"Account created for ' + @callsign + '" }', 'security');

		Select 0 as ReturnCode;
	END;
END;
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
CREATE PROCEDURE [dbo].[spNoteRepeaterOffline] @callsign varchar(max), @password varchar(max), @repeaterID varchar(20)
AS   
BEGIN

	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @userID int, @trusteeID int, @RepeaterCallsign varchar(255), @outputFreq varchar(255)

	EXEC dbo.sp_GetUserID @callsign, @password, @userID output
	Insert into RepeaterChangeLogs (UserId, RepeaterId, ChangeDescription, ChangeDateTime) values (@userID, @repeaterID, '*Repeater reported to be off-the-air*', GETDATE());
	Update Repeaters set Status = 5 where ID = @repeaterID;


	-- If this user isn't the primary trustee, then email the trustee about the update.
	Select @trusteeID = Repeaters.trusteeID, @RepeaterCallsign = Repeaters.Callsign, @outputFreq = Repeaters.OutputFrequency from Repeaters where Repeaters.ID = @repeaterID
	If @userid <> @trusteeID
	Begin
		DECLARE @emailToName varchar(255), @emailToAddress varchar(255);
		Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;
		Insert into EmailQueue (ToName, ToEmail, Subject, Body) values (@emailToName, @emailToAddress, 'Your repeater reported off-the-air', '<span></span>The ' + UPPER(@RepeaterCallsign) + ' (' + @outputFreq + ') repeater has been reported to be off-the-air by ' + UPPER(@callsign) + '.<br><br>The status of the repeater has been changed to <em>Suspected off the air</em>. According to our procedures you have 90 days to return this repeater to operation before its coordination is revoked.  If you don''t plan to return this repeater to operation, please update its status to <em>Decoordinated</em> as soon as possible.<br><hr>Update this repeater''s record at: https://arkansasrepeatercouncil.org/update/?id=' + @repeaterID);
	End

END;
CREATE PROCEDURE [dbo].[spGetStatusReports] @callsign varchar(10), @password varchar(255)
AS   
BEGIN
	Declare @allowed bit = 0;

	Declare @userid int;
	exec sp_GetUserID @callsign, @password, @userid output;

	Set @allowed = (Select 1 from Permissions where (Permissions.UserId = @userid and Permissions.RepeaterId = -1));

	If @allowed = 1 
	BEGIN
		Select '['+ CONCAT_WS(',',
		
			(Select 'Open coordination requests' 'Report.Title', (
				-- List open coordinations 
				Select Requests.ID 'Request.ID', Requests.requestedOn 'Request.RequestedDate', Users.FullName + ' (' + Users.Callsign + ')' 'Request.RequestedBy', 
				Requests.Location.Lat 'Request.Latitude', Requests.Location.Long 'Request.Longitude', Requests.OutputFrequency 'Request.OutputFrequency',
				(
					SELECT RequestWorkflows.State 'Workflow.State', RequestStatuses.Description 'Workflow.Status', 
					RequestWorkflows.Note 'Workflow.Note', RequestWorkflows.TimeStamp 'Workflow.TimeStamp', 
					RequestWorkflows.LastReminderSent 'Workflow.LastReminderSent' 
					FROM RequestWorkflows 
					INNER JOIN RequestStatuses on RequestWorkflows.StatusID = RequestStatuses.ID
					where RequestWorkflows.RequestID = Requests.ID 
					For JSON path, INCLUDE_NULL_VALUES
				) 'Request.Workflows'
				FROM Requests 
				Inner join Users on Requests.UserID = Users.ID
				where statusID = 1
				ORDER BY Requests.ID ASC
				For JSON path, INCLUDE_NULL_VALUES) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
		
			(Select 'Expired repeaters' 'Report.Title',
				(Select 
					Round(DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate()))/12.00, 2) 'Repeater.YearsExpired', 
					Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
					Repeaters.City 'Repeater.City', Repeaters.Sponsor 'Repeater.Sponsor', CONCAT(Users.Fullname, ', ', Users.Callsign, 
					' (', Users.ID, ')') 'Repeater.Trustee.Name', COALESCE(Users.Email, '') 'Repeater.Trustee.Email', 
					COALESCE(Users.phoneCell, '') 'Repeater.Trustee.CellPhone', COALESCE(Users.phoneHome, '') 'Repeater.Trustee.HomePhone', COALESCE(Users.PhoneWork, '') 'Repeater.Trustee.WorkPhone', 
					(
						Select 
							Users.FullName 'Note.User.Name', Users.Callsign 'Note.User.Callsign', 
							RepeaterChangeLogs.ChangeDateTime 'Note.Timestamp', RepeaterChangeLogs.ChangeDescription 'Note.Text'
						From RepeaterChangeLogs
						Inner Join Users on Users.ID = RepeaterChangeLogs.UserID
						Where RepeaterChangeLogs.RepeaterID = Repeaters.ID
						For JSON path
					) 'Repeater.Notes'
				From Repeaters 
				Join Users on Users.ID = Repeaters.TrusteeID
				Where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 
				Order by DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate())) Desc
				FOR JSON PATH) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
		)
		
		+ ']' 
	END
	ELSE
		Select '[]'
END;
