CREATE PROCEDURE spProposedCoordination @callsign varchar(7), @password varchar(255), @latitude decimal (15, 12), @longitude decimal (15, 12), @TransmitFrequency decimal(18,6), @receiveFreq decimal(18,6)
AS
BEGIN
	Declare @userId int;
	exec sp_GetUserID @callsign, @password, @userId output;

	If @userId is not null
	BEGIN

		-- Create a table in memory with the states that will need to be included
		Declare @tblInterferingRepeaters table (Miles int, OutputFrequency decimal(12,6), City varchar(24), Callsign varchar(6));
		Declare @countInterferingRepeaters int, @answer int = 2, @comment varchar(255);
		Declare @point geography = geography::Point(@latitude, @longitude, 4326);
	
		IF @TransmitFrequency between 144.0 and 148.0
		BEGIN
			Insert into @tblInterferingRepeaters SELECT Round(Location.STDistance(@point) / 1609.34,1) as Miles, OutputFrequency, City, Callsign FROM Repeaters
			WHERE (OutputFrequency = @TransmitFrequency AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .015 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .020 AND Location.STDistance(@point) < 40234) --  meters ~= 25 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .030 AND Location.STDistance(@point) < 32187) --  meters ~= 20 miles
			ORDER BY Location.STDistance(@point);
		END;
		
		IF @TransmitFrequency between 222.0 and 225.0
		BEGIN
			Insert into @tblInterferingRepeaters SELECT Round(Location.STDistance(@point) / 1609.34,1) as Miles, OutputFrequency, City, Callsign FROM Repeaters
			WHERE (OutputFrequency = @TransmitFrequency AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .025 AND Location.STDistance(@point) < 64374) --  meters ~= 40 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .040 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
			ORDER BY Location.STDistance(@point);
		END;
		
		IF @TransmitFrequency between 420.0 and 450.0
		BEGIN
			Insert into @tblInterferingRepeaters SELECT Round(Location.STDistance(@point) / 1609.34,1) as Miles, OutputFrequency, City, Callsign FROM Repeaters
			WHERE (OutputFrequency = @TransmitFrequency AND Location.STDistance(@point) < 144841) -- 144841 meters ~= 90 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .025 AND Location.STDistance(@point) < 8047) --  meters ~= 5 miles
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .040 AND Location.STDistance(@point) < 1610) --  meters ~= 1 mile
			 OR (ABS(OutputFrequency - @TransmitFrequency) <= .050 AND Location.STDistance(@point) < 1) --  meters ~= 1 meter (no minimum)
			ORDER BY Location.STDistance(@point);
		END;
	
		select @countInterferingRepeaters=count(Miles) from @tblInterferingRepeaters;
		IF @countInterferingRepeaters = 0 
		BEGIN
			Set @answer = 1;
			Set @comment = 'According to our records, a repeater at this location on this frequency will not interfer with any coordinated repeater.';
		END;
	
		IF @countInterferingRepeaters > 0
		BEGIN
			Declare @closestMiles int;
			Select top 1 @closestMiles=Miles from @tblInterferingRepeaters order by Miles asc;
			Set @comment=concat('This would potentially interfer with ', @countInterferingRepeaters, ' repeater(s), the closest of which is ', @closestMiles, ' miles away.');
		END;
	
		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"NOPC", "message":"Proposed coordination filed by ' + @callsign + '" }', 'NOPC');
		Insert into ProposedCoordinationsLog Select @userId, @point, @TransmitFrequency, @receiveFreq, @answer, @comment, GetDate();
	
		Declare @RequestID int;
		Select @RequestID=SCOPE_IDENTITY();
	
		Select TransmitFrequency, ReceiveFrequency, ProposedCoordinationAnswers.Description as Answer, Comment from ProposedCoordinationsLog 
		Inner join ProposedCoordinationAnswers on ProposedCoordinationsLog.Answer = ProposedCoordinationAnswers.ID
		where ProposedCoordinationsLog.ID = @RequestID;
	END
	ELSE
	BEGIN
		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Security", "message":"Invalid login attempt against ' + @callsign + '" }', 'Security');
	END
END