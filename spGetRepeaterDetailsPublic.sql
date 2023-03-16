CREATE PROCEDURE [dbo].[spGetRepeaterDetailsPublic] @repeaterID int
AS   
BEGIN
	SELECT Repeaters.ID, Repeaters.Type, Repeaters.Callsign as RepeaterCallsign, Users.Callsign as TrusteeCallsign, Repeaters.Status, Repeaters.City, Repeaters.SiteName, Repeaters.OutputFrequency, Repeaters.InputFrequency, Repeaters.Sponsor, 
	ROUND(Repeaters.Location.Lat,1) as Latitude, ROUND(Repeaters.Location.Long,1) as Longitude, 
	Repeaters.AMSL, Repeaters.ERP, Repeaters.OutputPower, Repeaters.AntennaGain, Repeaters.AntennaHeight, Repeaters.Analog_InputAccess, Repeaters.Analog_OutputAccess, Repeaters.Analog_Width, Repeaters.DSTAR_Module, Repeaters.DMR_ColorCode, Repeaters.DMR_ID, Repeaters.DMR_Network, Repeaters.P25_NAC, Repeaters.NXDN_RAN, Repeaters.YSF_DSQ, Repeaters.Autopatch, Repeaters.EmergencyPower, Repeaters.Linked, Repeaters.RACES, Repeaters.ARES, Repeaters.WideArea, Repeaters.Weather, Repeaters.Experimental, Repeaters.DateCoordinated, Repeaters.DateUpdated, Repeaters.DateDecoordinated, Repeaters.DateConstruction, Repeaters.Notes, Repeaters.State, Repeaters.AdditionalInformation,
	CONCAT('https://www.google.com/maps/dir/',ROUND(Repeaters.Location.Lat,1),',',ROUND(Repeaters.Location.Long,1)) as MapUrl

	FROM Repeaters
	left JOIN Users on Repeaters.TrusteeID = Users.ID
	WHERE Repeaters.ID = @repeaterID
END;