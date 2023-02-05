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