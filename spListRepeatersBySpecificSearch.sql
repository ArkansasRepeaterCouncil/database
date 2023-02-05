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