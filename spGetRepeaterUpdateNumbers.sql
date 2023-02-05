CREATE PROCEDURE [dbo].[spGetRepeaterUpdateNumbers] @state nvarchar(2)
AS   
BEGIN
	Declare @pctUpdated int, @pctExpired int, @updatedCount int, @expiredCount int, @totalCount int, @notUpdatedInSeveralYears int, @TotalCoordinationRequests int, @AverageDays int;
	
	Select @updatedCount=Count(ID) from repeaters where Status <> 6 and DateUpdated >= DATEADD(year, -3, GETDATE()) and state = @state;
	Select @expiredCount=Count(ID) from repeaters where Status <> 6 and DateUpdated < DATEADD(year, -3, GETDATE()) and state = @state;
	Select @totalCount=Count(ID) from repeaters where Status <> 6 and state = @state;
	Select @pctUpdated=CAST(@updatedCount * 100 / @totalCount AS int);
	Select @pctExpired=100-@pctUpdated;
	
	Select @TotalCoordinationRequests=Count(ID) from Requests;
	Select @TotalCoordinationRequests=@TotalCoordinationRequests+Count(ID) from ProposedCoordinationsLog;
	
	SELECT @AverageDays=Avg(DATEDIFF(day, RequestedOn, ClosedOn)) from Requests where RequestedOn > DATEADD(day, -90, GetDate());
	
	Select @updatedCount as RepeatersCurrent, @expiredCount as RepeatersExpired, @totalCount as TotalRepeaters, @pctUpdated AS PercentageCurrent, 
	@pctExpired as PercentageExpired, @TotalCoordinationRequests as TotalCoordinationRequests, @AverageDays as AverageDays;
END;