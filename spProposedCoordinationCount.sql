CREATE PROCEDURE spProposedCoordinationCount @latitude decimal (15, 12), @longitude decimal (15, 12), @freq decimal(18,6), @count int output 
AS
BEGIN
	DECLARE @point geography = geography::Point(@latitude, @longitude, 4326);
	Set @count = 0;
	
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
		Insert into @rules Select ID, SpacingMhz, SeparationMiles from BusinessRulesFrequencies where StateAbbreviation = @currentState and FrequencyStart <= @freq and @freq <= FrequencyEnd;
		
		-- Loop through each of this state's rules and apply them.
		While exists (Select 1 from @rules)
		Begin
			Declare @currentRuleID int, @currentSpacing decimal(5,3), @currentSeparation int;
			Select top 1 @currentRuleID = ID, @currentSpacing = spacing, @currentSeparation = separation from @rules;
			
			Insert into @conflicts SELECT ID, Round(dbo.MetersToMiles(Location.STDistance(@point)),0) as Miles, OutputFrequency, City, Callsign FROM Repeaters
				WHERE ABS(OutputFrequency - @freq) <= @currentSpacing AND Location.STDistance(@point) < dbo.MilesToMeters(@currentSeparation);
			
			Delete from @rules where ID = @currentRuleID;
		End
		
		Delete from @statesToCheck where stateabbr = @currentState;
	End
	
	Select count(Distinct RepeaterID) from @conflicts;

END