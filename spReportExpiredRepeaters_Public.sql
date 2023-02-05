CREATE PROCEDURE [dbo].[spReportExpiredRepeaters_Public] @state nvarchar(2)
AS   
BEGIN
	Select 
		(Select 'Expired Most Wanted' 'Report.Title',(
			Select Top 10
			Round(DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate()))/12.00, 2) 'Repeater.YearsExpired', 
			Repeaters.ID 'Repeater.ID', Repeaters.Callsign 'Repeater.Callsign', Repeaters.OutputFrequency 'Repeater.Output', 
			Repeaters.City 'Repeater.City', Repeaters.Sponsor 'Repeater.Sponsor', CONCAT(Users.Fullname, ', ', Users.Callsign) 'Repeater.Trustee.Name', Users.Callsign 'Repeater.Trustee.Callsign'
			From Repeaters 
			Join Users on Users.ID = Repeaters.TrusteeID
			Where Repeaters.DateUpdated < DateAdd(year, -3, GetDate()) and Repeaters.status <> 6 and Repeaters.State = @state
			Order by DateDiff(month, DateUpdated, DateAdd(month, -36, GetDate())) Desc
			FOR JSON PATH) 'Report.Data' FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
END;