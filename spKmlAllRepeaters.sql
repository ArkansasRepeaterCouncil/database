CREATE PROCEDURE spKmlAllRepeaters @callsign varchar(10), @password varchar(255)
AS
BEGIN
	DECLARE @userID int;
	exec sp_GetUserID @callsign, @password, @userID output;
	
	Declare @allowed int = (Select Count(UserID) from Permissions where UserId = @userID and RepeaterId < 0)

	If @allowed >= 1
	Begin
		with xmlnamespaces(default 'http://www.opengis.net/kml/2.2')
		Select (
			Select 
				Concat(Callsign,'<br/>Output: ', OutputFrequency, '<br/>Input: ', InputFrequency, '<br/><br/>',States.website,'/repeaters/details/?id=', ID) 'description', 
				Concat(Location.Long, ',', Location.Lat, ',', 0) 'Point/coordinates', 
				CAST(CASE 
					WHEN OutputFrequency between 902 and 928 THEN '#33cm'
					WHEN OutputFrequency between 420 and 450 THEN '#70cm'
					WHEN OutputFrequency between 222 and 225 THEN '#1.25m'
					WHEN OutputFrequency between 144 and 148 THEN '#2m'
					WHEN OutputFrequency between 50 and 54 THEN '#6m'
					WHEN OutputFrequency between 28 and 29.7 THEN '#10m' END AS varchar(60)
				) 'styleUrl'
			from Repeaters 
			inner join States on States.StateAbbreviation = Repeaters.State
			Where ID > 0 And Status <> 6 AND location is not null
			FOR XML PATH('Placemark'), type
		 ) for xml path('Document'), root('kml')
	End

END