CREATE PROCEDURE [dbo].[spListRepeaterLinks] @repeaterID varchar(max)
AS   
BEGIN
	
	DECLARE @LinkedRepeaters TABLE (RepeaterID INT, DirectlyLinked bit)
	
	SET NOCOUNT ON;
	
	--Get top level repeater links and add them to a table variable
	INSERT INTO @LinkedRepeaters
	SELECT DISTINCT ID, 1 FROM
	(
	SELECT LinkToRepeaterID [ID] FROM Links WHERE (LinkFromRepeaterID = @RepeaterID OR LinkToRepeaterID = @RepeaterID)
	AND LinkToRepeaterID NOT IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	UNION ALL 
	SELECT LinkFromRepeaterID [ID] FROM Links WHERE (LinkFromRepeaterID = @RepeaterID OR LinkToRepeaterID = @RepeaterID)
	AND LinkFromRepeaterID NOT IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	) AS res
	
	DECLARE @RowPos INT = 0;
	DECLARE @RowCnt INT = 0;
	
	SELECT @RowCnt = COUNT(0) FROM @LinkedRepeaters;
	
	WHILE @RowPos <= @RowCnt
	BEGIN
	
	DECLARE @LinkToRepeaterID INT
	
	--Get row of @RowPos
	SELECT @LinkToRepeaterID = RepeaterID
	FROM 
	(
	SELECT ROW_NUMBER() OVER
	(
	ORDER BY (SELECT NULL)
	) As RowNum, RepeaterID
	FROM @LinkedRepeaters
	) t2
	WHERE RowNum = @RowPos
	
	--CURSOR to get linked repeaters
	DECLARE @ID INT
	DECLARE db_cursor CURSOR FOR 
	SELECT LinkFromRepeaterID FROM Links 
	WHERE LinkToRepeaterID IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	UNION ALL
	SELECT LinkToRepeaterID FROM Links 
	WHERE LinkFromRepeaterID IN
	(
	SELECT RepeaterID FROM @LinkedRepeaters
	)
	
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @ID
	
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
	
	IF NOT EXISTS (SELECT RepeaterID FROM @LinkedRepeaters WHERE RepeaterID = @ID)
	BEGIN
	INSERT INTO @LinkedRepeaters
	VALUES (@ID,0)
	END
	
	FETCH NEXT FROM db_cursor INTO @ID 
	END
	CLOSE db_cursor  
	DEALLOCATE db_cursor 
	--CURSOR
	
	--Update @RowCnt for loop
	SELECT @RowCnt = COUNT(0) FROM @LinkedRepeaters;
	
	-- Update next @RowPos 
	SET @RowPos = @RowPos + 1
	
	END 
	
	--Ouputs table variable values
	SELECT DISTINCT RepeaterID, DirectlyLinked, Repeaters.ID, Repeaters.Callsign, Repeaters.OutputFrequency, Repeaters.City
		FROM @LinkedRepeaters 
		INNER JOIN Repeaters on RepeaterID = Repeaters.ID 
		WHERE RepeaterID <> @RepeaterID
		Order by OutputFrequency;



END;