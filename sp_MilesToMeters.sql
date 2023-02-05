CREATE PROCEDURE sp_MilesToMeters @miles decimal(18,2), @meters decimal(18,2) output
AS
BEGIN
	SET @meters = @miles * 1609.34;
END