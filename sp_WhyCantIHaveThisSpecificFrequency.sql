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