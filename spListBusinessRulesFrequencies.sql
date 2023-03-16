CREATE PROCEDURE spListBusinessRulesFrequencies @stateAbbreviation nvarchar(2)
AS
BEGIN

	Select FrequencyStart, FrequencyEnd, SpacingMhz, SeparationMiles from BusinessRulesFrequencies 
	where StateAbbreviation = @stateAbbreviation 
	order by FrequencyStart Asc, SpacingMhz Asc

END