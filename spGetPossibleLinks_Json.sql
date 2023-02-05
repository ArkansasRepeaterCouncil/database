CREATE PROCEDURE spGetPossibleLinks_Json
AS
BEGIN

	Select CAST((Select ID 'Link.Value', Concat(OutputFrequency, ' - ', Callsign, ' in ', City) 'Link.Description'
	from Repeaters where Status between 2 and 5 and ID > 0 
	Order By OutputFrequency, Callsign
	FOR JSON PATH, INCLUDE_NULL_VALUES) as text) as JSON

END