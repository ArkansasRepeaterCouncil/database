CREATE PROCEDURE sp_ReportMonthlyActivity
AS
BEGIN

Declare @Enumerator table (City varchar(max), Callsign varchar(max), OutputFrequency varchar(max), ChangeDescription varchar(max));

Insert into @Enumerator 
SELECT DISTINCT Repeaters.City, Repeaters.Callsign, Repeaters.outputFrequency, ChangeDescription
FROM dbo.RepeaterChangeLogs Join Repeaters on RepeaterID = Repeaters.ID 
where ChangeDateTime > dateadd(day, -30, getdate())
order by city, outputFrequency;

Select CONCAT(City, ' - ', Callsign, ' (', outputFrequency,'): ', ChangeDescription) 
from @Enumerator;

END