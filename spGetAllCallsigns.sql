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