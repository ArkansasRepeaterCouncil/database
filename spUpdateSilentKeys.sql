CREATE PROCEDURE spUpdateSilentKeys @calls NVARCHAR(1000)
AS
BEGIN
	IF @calls <> ''
	Begin
		--Declare @calls nvarchar(1000); Set @calls = 'aa5jc,n5gc,n5xfw';
		DROP TABLE IF EXISTS tempSilentKeys
		SELECT value INTO tempSilentKeys FROM string_split(@calls,',');
		Alter table tempSilentKeys add UserId int;
		Update tempSilentKeys set UserId = (Select ID from Users where Users.callsign = tempSilentKeys.value)
		
		Declare @skCallsign nvarchar(10), @skUserId int;
		While exists (select 1 from tempSilentKeys)
		Begin
			Select top 1 @skCallsign = value, @skUserId = UserId from tempSilentKeys;
			
			-- REMOVE PERMISSIONS
			Declare @repeatersSilentKeyHadPermissionsOn table (RepeaterId int)
			Insert into @repeatersSilentKeyHadPermissionsOn Select RepeaterId from Permissions where UserId = @skUserId
			Declare @repeaterIdForPermissions int
			While exists (Select 1 from @repeatersSilentKeyHadPermissionsOn)
			Begin
				Select top 1 @repeaterIdForPermissions = RepeaterId from @repeatersSilentKeyHadPermissionsOn
				Delete from Permissions where UserId = @skUserId and RepeaterID = @repeaterIdForPermissions;
				Declare @emailContents varchar(8000); Set @emailContents = concat('We regret that, according to QRZ, ', @skCallsign, ' has become a silent key. Their account has been removed as a user from this repeater.');
				exec sp_AddAutomatedRepeaterNote @repeaterIdForPermissions, @emailContents
				Delete from @repeatersSilentKeyHadPermissionsOn where @repeaterIdForPermissions = RepeaterId
			End
	
			-- FLAG ANY REPEATERS ON WHICH THEY ARE THE TRUSTEE
			Declare @repeatersOnWhichSilentKeyWasTrustee table (RepeaterId int)
			Insert into @repeatersOnWhichSilentKeyWasTrustee Select ID from Repeaters where TrusteeID = @skUserId
			Declare @repeaterIdForTrustee int
			While exists (Select 1 from @repeatersOnWhichSilentKeyWasTrustee)
			Begin
				Select top 1 @repeaterIdForTrustee = RepeaterId from @repeatersOnWhichSilentKeyWasTrustee
				
				-- Let's randomly select one of the users of this repeater and set them as the trustee
				Declare @repeaterUsers table (UserID int, Callsign varchar(8000))
				Insert into @repeaterUsers Select permissions.UserID, Users.Callsign from permissions join users on permissions.userid = users.id where RepeaterId = @repeaterIdForTrustee and UserId <> @skUserId
				If exists (Select 1 from @repeaterUsers)
				Begin
					Declare @newTrusteeId int, @newTrusteeCallsign varchar(8000)
					Select top 1 @newTrusteeId = UserId, @newTrusteeCallsign = callsign from @repeaterUsers
					Update Repeaters set TrusteeID = @newTrusteeId Where ID = @repeaterIdForTrustee
					Declare @emailContents2 varchar(8000); Set @emailContents2 = 'We regret that, according to QRZ, ' + @skCallsign + ' has become a silent key. We have automatically changed the primary trustee to ' + @newTrusteeCallsign + '.  You can login to change that at any time.';
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents2;
				End
				Else
				Begin
					Update repeaters Set LicenseeSK = 1 WHERE id = @repeaterIdForTrustee;
					Declare @emailContents3 varchar(8000); Set @emailContents3 = concat('We regret that, according to QRZ, ', @skCallsign, ' has become a silent key. Their account has been removed as a user from this repeater.');
					exec sp_AddAutomatedRepeaterNote @repeaterIdForTrustee, @emailContents3
				End
				
				Delete from @repeatersOnWhichSilentKeyWasTrustee where @repeaterIdForTrustee = RepeaterId
			End
	
			-- FLAG ANY REPEATERS THAT USE THEIR CALLSIGN
			Declare @repeatersUsingSilentKeysCallsign table (RepeaterId int);
			Insert into @repeatersUsingSilentKeysCallsign Select ID from Repeaters where callsign = @skCallsign
			While exists (Select 1 from @repeatersUsingSilentKeysCallsign)
			Begin
				Declare @repeaterIdForCallsign int;
				Select top 1 @repeaterIdForCallsign = RepeaterId from @repeatersUsingSilentKeysCallsign;
				Update repeaters Set LicenseeSK = 1 WHERE id = @repeaterIdForCallsign;
				Declare @emailContents4 varchar(8000); Set @emailContents4 = 'We regret that, according to QRZ, ' + @skCallsign + ' has become a silent key. This repeater will need to be assigned a new callsign, and should be taken off the air until such time.  If this repeater has not been updated with a new callsign within 30 days it will be decoordinated.';
				exec sp_AddAutomatedRepeaterNote @repeaterIdForCallsign, @emailContents4
				Delete from @repeatersUsingSilentKeysCallsign where repeaterId = @repeaterIdForCallsign;
			End

			-- Finally, flag the accounts as SK
			Update users Set SK = 1 WHERE callsign = @skCallsign;

			Delete from tempSilentKeys where @skUserId = UserId;
		End
		
		DROP TABLE IF EXISTS tempSilentKeys
	End
END