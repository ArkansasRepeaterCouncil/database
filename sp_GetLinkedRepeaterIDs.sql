CREATE PROCEDURE [sp_GetLinkedRepeaterIDs] @repeaterId int
AS
BEGIN
	
	Declare @Enumerator table (RepeaterID int, checked bit);
	Insert into @Enumerator Select LinkToRepeaterID,0 from Links where LinkFromRepeaterID = @repeaterid and @repeaterid not in (Select RepeaterID from @Enumerator);
	Insert into @Enumerator Select LinkFromRepeaterID,0 from Links where LinkToRepeaterID = @repeaterid and @repeaterid not in (Select RepeaterID from @Enumerator);
	
	Declare @rID int;
	While exists (select 1 from @Enumerator where checked = 0)
	Begin
		Select top 1 @rID = RepeaterID from @Enumerator where checked = 0;
		Update @Enumerator set checked = 1 where RepeaterID = @rId;

		Declare @Enumerator2 table (RepeaterID int);
		Insert into @Enumerator2 Exec sp_GetLinkedRepeaterIDs @rId;

		While exists (Select 1 from @Enumerator2)
		Begin
			Declare @repeaterIdToCheck int;
			Select Top 1 @repeaterIdToCheck = RepeaterID from @Enumerator2;
			If @repeaterIdToCheck not in (Select RepeaterID from @Enumerator)
				Begin
					Insert into @Enumerator values (@repeaterIdToCheck,0);
				End
			Delete from @Enumerator2 where RepeaterID = @repeaterIdToCheck;
		End
	End

	Select DISTINCT RepeaterID from @Enumerator

END