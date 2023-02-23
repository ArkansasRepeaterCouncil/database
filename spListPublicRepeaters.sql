CREATE PROCEDURE [dbo].[spListPublicRepeaters] 
	@state varchar(10),
	@search varchar(8000) = '',
	@latitude varchar(20) = '39.83',
	@longitude varchar(20) = '-98.583',
	@miles int = 99999,--2680,
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