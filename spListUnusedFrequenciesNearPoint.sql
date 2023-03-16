CREATE PROCEDURE [dbo].[spListUnusedFrequenciesNearPoint] @lat decimal(10, 7), @lon decimal (10, 7), @miles integer, @band varchar(10)
AS   
BEGIN
	Declare @meters int;
	Set @meters = @miles * 1609.34;

	DECLARE @point geography;
	SET @point = geography::Point(@lat, @lon, 4326);

	Declare @AllFrequencies table (outputFreq decimal(9,4), inputFreq decimal(9,4), NearbyRepeaters int, Reviewed int);
	Insert into @AllFrequencies (outputFreq, inputFreq) Select output as outputFreq, input as inputFreq from Frequencies 
		where Frequencies.band = @band;
	
	While exists (select 1 from @AllFrequencies where Reviewed is null)
	Begin
		Declare @count int = 0, @outputFreq decimal(9,4), @inputFreq decimal(9,4);
		Select top 1 @outputFreq = outputFreq, @inputFreq = inputFreq from @AllFrequencies where Reviewed is null;
		print(concat('spProposedCoordinationCount ', @lat, ', ', @lon,', ', @outputFreq));
		exec spProposedCoordinationCount @lat, @lon, @outputFreq, @count output;
		--Select @count;
		Update @AllFrequencies set NearbyRepeaters = @count, Reviewed = '1' where outputFreq = @outputFreq;
	End

	Select outputFreq, inputFreq from @AllFrequencies Where NearbyRepeaters = 0 Order by outputFreq;
END