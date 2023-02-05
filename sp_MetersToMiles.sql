CREATE PROCEDURE sp_MetersToMiles @meters decimal(18,2), @miles decimal(18,2) output
AS
BEGIN
	SET @miles = @meters / 1609.34;
END