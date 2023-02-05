CREATE PROCEDURE [dbo].[sp_GenerateRandomUniqueUrlKey] @UrlKey char(32) output
AS   
BEGIN
	DECLARE @key char(32)
	Set @key = NULL
	EXEC dbo.sp_GenerateRandomKey @key output

	While exists (select 1 from RequestWorkflows where UrlKey=@key)
	Begin
		EXEC dbo.sp_GenerateRandomKey @key output
	End

	Set @UrlKey = @key;
END;