CREATE PROCEDURE sp_ImportOtherStatesRecords
AS
BEGIN

-- Add binary field to track which records have been imported
--ALTER TABLE dbo.Combined ADD imported bit DEFAULT('0');

While exists (select 1 from Combined where imported is null or imported = 0)
Begin
	DECLARE @metadata NVARCHAR(MAX) = (Select top 1 * from Combined Where (imported is null OR imported = 0) and State='AL' AND [Decoordination Date] Is Null for json auto);
	Declare @oldID int = (Select JSON_VALUE(@metadata, '$[0]."Record Number"') AS RecordNumber);
	Print Concat('**** Importing #', @oldID);

	-- Person records to create	
	Declare @trusteeOldId int = (Select [Trustee Record Number] from Combined where [Record Number] = @oldID);
	Declare @trusteeCallsign varchar(10) = ( Select top 1 callsign from ActiveContacts where [Record Number] = @trusteeOldId )
	Declare @TrusteeID int = ( Select top 1 ID from Users where Callsign = @trusteeCallsign );
	Print Concat('****   Creating user for ', @trusteeCallsign);

	IF @TrusteeID is null
	BEGIN
		Print '****   TrusteeId is null'
		Insert into Users (OldID, Callsign, FullName, Address, City, State, ZIP, Email, PhoneHome, PhoneWork, PhoneCell) 
		SELECT Top 1 [Record Number] as OldID, Callsign, name as FullName, Address, City, State, ZipCode as ZIP, Email, Phone as PhoneHome, [Phone Day] as PhoneWork, [Phone Cell] as PhoneCell 
		FROM ActiveContacts WHERE [Record Number] = @trusteeOldId order by [Record Number] desc;
	
		Set @TrusteeID = (SELECT SCOPE_IDENTITY());
	END;
	Print Concat('****   ', @TrusteeID, ' created');

	Insert into Repeaters (_OldID, InputFrequency, OutputFrequency, Callsign, _Latitude, _Longitude, Autopatch, EmergencyPower,
	RACES, ARES, WideArea, Weather, Analog_InputAccess, Analog_OutputAccess, Notes, Sponsor, DateCoordinated,
	DateConstruction, DateDecoordinated, CoordinatorComments, AMSL, ERP, SiteName, AntennaGain, OutputPower, AntennaHeight, TrusteeID, State, LegacyMetadata, [Type], Status)
		SELECT [Record Number], Input, Output, Call, [TX Latitude], [TX Longitude], 
		Autopatch, [Emergency Power], RACES, ARES, 
		[Wide Area], Weather, [Receive PL], [Transmit PL], 
		[Published Notes], Sponsor, [Coordination Date], 
		[Construction Date], [Decoordination Date], Comments, AMSL, 
		ERP, [Repeater Site Name], [TX Antenna Gain], [TX Power], 
		[TX Antenna Height], @TrusteeID, 'AL', @metadata, '1', '3' 
		FROM Combined WHERE [Record Number] = @oldID;

	Print Concat('****   Repeater ', SCOPE_IDENTITY(), ' created');
	
	Update Combined set imported = 1 where [Record Number] = @oldID;

END

END