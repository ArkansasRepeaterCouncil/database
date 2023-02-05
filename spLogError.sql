CREATE PROCEDURE [dbo].[spLogError] @exceptionReport nvarchar(max)
AS   
BEGIN
	Insert into EventLog (jsonData, Type) values (@exceptionReport, 'error');
END;