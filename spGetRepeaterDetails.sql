CREATE PROCEDURE [dbo].[spGetRepeaterDetails] @callsign varchar(10), @password varchar(255), @repeaterID int
AS   
BEGIN
	-- Make sure this user/password is correct and this user has access to this repeater
	DECLARE @hasPermission int
	EXEC dbo.sp_UserHasPermissionForRepeater @callsign, @password, @repeaterID, @hasPermission output

DECLARE @Updated int;
Set @Updated = 0;

If @hasPermission = 1
	Begin

		SELECT Repeaters.ID, Repeaters.Type, Repeaters.Callsign as RepeaterCallsign, Repeaters.TrusteeID, Users.Callsign as TrusteeCallsign, Repeaters.Status, Repeaters.City, Repeaters.SiteName, Repeaters.OutputFrequency, Repeaters.InputFrequency, Repeaters.Sponsor, Repeaters.Location.Lat as Latitude, Repeaters.Location.Long as Longitude, Repeaters.AMSL, Repeaters.ERP, Repeaters.OutputPower, Repeaters.AntennaGain, Repeaters.AntennaHeight, Repeaters.Analog_InputAccess, Repeaters.Analog_OutputAccess, Repeaters.Analog_Width, Repeaters.DSTAR_Module, Repeaters.DMR_ColorCode, Repeaters.DMR_ID, Repeaters.DMR_Network, Repeaters.P25_NAC, Repeaters.NXDN_RAN, Repeaters.YSF_DSQ, Repeaters.Autopatch, Repeaters.EmergencyPower, Repeaters.Linked, Repeaters.RACES, Repeaters.ARES, Repeaters.WideArea, Repeaters.Weather, Repeaters.Experimental, Repeaters.DateCoordinated, Repeaters.DateUpdated, Repeaters.DateDecoordinated, Repeaters.DateCoordinationSource, Repeaters.DateConstruction, Repeaters.CoordinatorComments, Repeaters.Notes, Repeaters.State, Repeaters.CoordinatedLocation.Lat as CoordinatedLatitude, Repeaters.CoordinatedLocation.Long as CoordinatedLongitude, Repeaters.CoordinatedAntennaHeight, Repeaters.CoordinatedOutputPower, Repeaters.AdditionalInformation

		FROM Repeaters
		JOIN Users on Repeaters.TrusteeID = Users.ID
		WHERE Repeaters.ID = @repeaterID
	End
END;