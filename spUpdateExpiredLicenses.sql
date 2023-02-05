CREATE PROCEDURE spUpdateExpiredLicenses @calls NVARCHAR(1000)
AS
BEGIN
	IF @calls <> ''
	Begin
		--Declare @calls nvarchar(1000); Set @calls = 'aa5jc,n5gc,n5xfw';
		DROP TABLE IF EXISTS tempExpiredLicenses
		SELECT value INTO tempExpiredLicenses FROM string_split(@calls,',');
		Alter table tempExpiredLicenses add UserId int;
		Update tempExpiredLicenses set UserId = (Select ID from Users where Users.callsign = tempExpiredLicenses.value)
		
		Declare @skCallsign nvarchar(10), @skUserId int;
		While exists (select 1 from tempExpiredLicenses)
		Begin
			Select top 1 @skCallsign = value, @skUserId = UserId from tempExpiredLicenses;
			
			-- REMOVE PERMISSIONS
			Declare @repeatersExpiredLicenseeHadPermissionsOn table (RepeaterId int)
			Insert into @repeatersExpiredLicenseeHadPermissionsOn Select RepeaterId from Permissions where UserId = @skUserId
			Declare @repeaterIdForPermissions int
			While exists (Select 1 from @repeatersExpiredLicenseeHadPermissionsOn)
			Begin
				Select top 1 @repeaterIdForPermissions = RepeaterId from @repeatersExpiredLicenseeHadPermissionsOn
				Delete from Permissions where UserId = @skUserId and RepeaterID = @repeaterIdForPermissions;
				Declare @emailContents varchar(8000); Set @emailContents = concat('According to QRZ, the license ', @skCallsign, ' has expired. Their account has been removed as a user from this repeater.');
				exec sp_AddAutomatedRepeaterNote @repeaterIdForPermissions, @emailContents
				Delete from @repeatersExpiredLicenseeHadPermissionsOn where @repeaterIdForPermissions = RepeaterId
			End
	
			-- FLAG ANY REPEATERS ON WHICH THEY ARE THE TRUSTEE
			Declare @repeatersOnWhichExpiredLicenseeWasTrustee table (RepeaterId int)
			Insert into @repeatersOnWhichExpiredLicenseeWasTrustee Select ID from Repeaters where TrusteeID = @skUserId
			Declare @repeaterIdForTrustee int
			While exists (Select 1 from @repeatersOnWhichExpiredLicenseeWasTrustee)
			Begin
				Select top 1 @repeaterIdForTrustee = RepeaterId from @repeatersOnWhichExpiredLicenseeWasTrustee
				
				-- Let's randomly select one of the users of this repeater and set them as the trustee
				Declare @repeaterUsers table (UserID int, Callsign varchar(8000))
				Insert into @repeaterUsers Select permissions.UserID, Users.Callsign from permissions join users on permissions.userid = users.id where RepeaterId = @repeaterIdForTrustee and UserId <> @skUserId
				If exists (Select 1 from @repeaterUsers)
				Begin
					Declare @newTrusteeId int, @newTrusteeCallsign varchar(8000)
					Select top 1 @newTrusteeId = UserId, @newTrusteeCallsign = callsign from @repeaterUsers
					Update Repeaters set TrusteeID = @newTrusteeId Where ID = @repeaterIdForTrustee
					Declare @emailContents2 varchar(8000); Set @emailContents2 = 'According to QRZ, the license ' + @skCallsign + ' has expired. We have automatically changed the primary trustee to ' + @newTrusteeCallsign + '.  You can login to change that at any time.';
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents2;
				End
				Else
				Begin
					Update repeaters Set LicenseeSK = 1 WHERE id = @repeaterIdForTrustee;
					Declare @emailContents3 varchar(8000); Set @emailContents3 = concat('According to QRZ, the license ', @skCallsign, ' has expired. Their account has been removed as a user from this repeater.');
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents3
				End
				
				Delete from @repeatersOnWhichExpiredLicenseeWasTrustee where @repeaterIdForTrustee = RepeaterId
			End
	
			-- FLAG ANY REPEATERS THAT USE THEIR CALLSIGN
			Declare @repeatersUsingExpiredLicensesCallsign table (RepeaterId int);
			Insert into @repeatersUsingExpiredLicensesCallsign Select ID from Repeaters where callsign = @skCallsign
			While exists (Select 1 from @repeatersUsingExpiredLicensesCallsign)
			Begin
				Declare @repeaterIdForCallsign int;
				Select top 1 @repeaterIdForCallsign = RepeaterId from @repeatersUsingExpiredLicensesCallsign;
				Update repeaters Set LicenseExpired = 1 WHERE id = @repeaterIdForCallsign;
				Declare @emailContents4 varchar(8000); Set @emailContents4 = 'According to QRZ, the license ' + @skCallsign + ' has expired. This repeater will need to be assigned a new callsign, and should be taken off the air until such time.  If this repeater has not been updated with a new callsign within 30 days it will be decoordinated.';
				exec sp_AddAutomatedRepeaterNote @repeaterIdForCallsign, @emailContents4
				Delete from @repeatersUsingExpiredLicensesCallsign where repeaterId = @repeaterIdForCallsign;
			End

		-- Finally, flag the accounts as expired
			Update users Set LicenseExpired = 1 WHERE callsign = @skCallsign;
	
			Delete from tempExpiredLicenses where @skUserId = UserId;
		End
		
		DROP TABLE IF EXISTS tempExpiredLicenses
	End
END