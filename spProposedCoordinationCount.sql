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