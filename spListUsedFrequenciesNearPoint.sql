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