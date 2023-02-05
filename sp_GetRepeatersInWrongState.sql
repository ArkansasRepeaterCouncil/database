CREATE PROCEDURE sp_GetRepeatersInWrongState
AS
BEGIN

  Select ID, Status, Location.Lat, Location.Long, _Latitude, _Longitude from Repeaters where Status <> 6 and Location.STIntersects((Select Borders from States where State = '')) = 0

END