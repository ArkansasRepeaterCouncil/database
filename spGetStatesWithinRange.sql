CREATE PROCEDURE [dbo].[spGetStatesWithinRange] @latitude decimal, @longitude decimal
AS   
BEGIN
	declare @miles int = 90;
	declare @meters int = @miles / 0.0006213712
	declare @point geography = geography::Point(@latitude, @longitude, 4326);
	
	Select State, CoordinatorEmail, (@point.STDistance(Borders) * 0.0006213712) as Miles from States where 
		@point.STBuffer(@meters).STIntersects(Borders) = 1
END;