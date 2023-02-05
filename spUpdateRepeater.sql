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
		
		DECLARE @repeaterState nvarchar(2), @stateName nvarchar(50), @website nvarchar(255);
		
		Select @repeaterState = Repeaters.State, @stateName = States.State, @website = States.website
		from Repeaters
		inner join States on States.StateAbbreviation = Repeaters.State
		where Id = @repeaterID;

		DECLARE @emailToName varchar(255)
		DECLARE @emailToAddress varchar(255)
		Select @emailToName = Users.FullName, @emailToAddress = Users.Email from Users where Users.ID = @trusteeID;

		If @userid <> @trusteeID and @emailToAddress is not null and @emailToAddress <> ''
		Begin
			Declare @templateData varchar(max) = (Select @callsign as callsign, @stateName as state, UPPER(@RepeaterCallsign) as RepeaterCallsign, @outputFreq as outputFreq, @website as website, @changenote as changenote for json path, WITHOUT_ARRAY_WRAPPER);
			Insert into EmailQueue (ToName, ToEmail, Subject, Body, TemplateID) values (@emailToName, @emailToAddress, 'Repeater update', @templateData, 'd-fc5063a8aece455d930fc03b50040ff1');
		End
	End

Select @hasPermission as LoggedIn, @Updated as RowsUpdated;

END;