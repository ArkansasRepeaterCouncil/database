CREATE PROCEDURE spProposedCoordination @callsign varchar(7), @password varchar(255), @latitude decimal (15, 12), @longitude decimal (15, 12), @TransmitFrequency decimal(18,6), @receiveFreq decimal(18,6)
AS
BEGIN
	Declare @userId int;
	exec sp_GetUserID @callsign, @password, @userId output;

	If @userId is not null
	BEGIN
	
		Declare @point geography = geography::Point(@latitude, @longitude, 4326);
		
		-- Get the list of states affected
		Declare @conflicts table (RepeaterID int, Miles decimal(20,2), OutputFrequency decimal(12,6), City nvarchar(24), Callsign varchar(6));
		Declare @statesToCheck table(stateabbr varchar(2)); Declare @miles decimal(20,2);
		Select @miles = Max(SeparationMiles) from BusinessRulesFrequencies;
		Insert into @statesToCheck Select StateAbbreviation from States where @point.STBuffer(dbo.MilesToMeters(@miles)).STIntersects(Borders) = 1;
		
		-- Loop through each affected state to apply their rules
		While exists (Select 1 from @statesToCheck)
		Begin
			Declare @currentState varchar(2);
			Select top 1 @currentState = stateabbr from @statesToCheck;
			
			Declare @rules table(id int, spacing decimal(5,3), separation int);
			Insert into @rules Select ID, SpacingMhz, SeparationMiles from BusinessRulesFrequencies where StateAbbreviation = @currentState and FrequencyStart <= @TransmitFrequency and @TransmitFrequency <= FrequencyEnd;
			
			-- Loop through each of this state's rules and apply them.
			While exists (Select 1 from @rules)
			Begin
				Declare @currentRuleID int, @currentSpacing decimal(5,3), @currentSeparation int;
				Select top 1 @currentRuleID = ID, @currentSpacing = spacing, @currentSeparation = separation from @rules;
				
				Insert into @conflicts SELECT ID, Round(dbo.MetersToMiles(Location.STDistance(@point)),0) as Miles, OutputFrequency, City, Callsign FROM Repeaters
		WHERE ABS(OutputFrequency - @TransmitFrequency) <= @currentSpacing AND Location.STDistance(@point) < dbo.MilesToMeters(@currentSeparation);
				
				Delete from @rules where ID = @currentRuleID;
			End
			
			Delete from @statesToCheck where stateabbr = @currentState;
		End
		
--Select Distinct RepeaterID, Miles, OutputFrequency, City, Callsign from @conflicts;
		Declare @countInterferingRepeaters int, @answer int = 2, @comment varchar(255);
		
		Select @countInterferingRepeaters=count(RepeaterID) from @conflicts;
	
		IF @countInterferingRepeaters > 0
		BEGIN
			Declare @closestMiles int;
			Select top 1 @closestMiles=Miles from @conflicts order by Miles asc;
			Set @comment=concat('This would potentially interfer with ', @countInterferingRepeaters, ' repeater(s), the closest of which is ', @closestMiles, ' miles away.');
		END;
		ELSE
		BEGIN
			Set @answer = 1;
			Set @comment = 'According to our records, a repeater at this location on this frequency will not interfer with any coordinated repeater.';
		END;

		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"NOPC", "message":"Proposed coordination filed by ' + @callsign + '" }', 'NOPC');
		Insert into ProposedCoordinationsLog Select @userId, @point, @TransmitFrequency, @receiveFreq, @answer, @comment, GetDate();
	
		Declare @RequestID int;
		Select @RequestID=SCOPE_IDENTITY();
	
		-- Send the response to the client
		Select TransmitFrequency, ReceiveFrequency, ProposedCoordinationAnswers.Description as Answer, Comment from ProposedCoordinationsLog
		Inner join ProposedCoordinationAnswers on ProposedCoordinationsLog.Answer = ProposedCoordinationAnswers.ID
		where ProposedCoordinationsLog.ID = @RequestID;
		
	END
	ELSE
	BEGIN
		Insert into EventLog (jsonData, Type) values ('{ "callsign":"' + @callsign + '", "event":"Security", "message":"Invalid login attempt against ' + @callsign + '" }', 'Security');
	END
END