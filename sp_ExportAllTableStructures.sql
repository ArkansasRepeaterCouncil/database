CREATE PROCEDURE sp_ExportAllTableStructures
AS
BEGIN	
	Declare @Enumerator table (name varchar(max), definition varchar(max));
	
	Insert into @Enumerator (name) select name from sys.objects where type = 'U' and name not like 'zz_%';
	
	While exists (select 1 from @Enumerator where definition is null)
	Begin
		Declare @currentTableName varchar(max);
		Select top 1 @currentTableName = name from @Enumerator where definition is null;
		
		Declare @currentTableDefinition varchar(max);
		exec sp_ExportTableStructure @currentTableName, @currentTableDefinition output
		Update @Enumerator set definition = @currentTableDefinition where name = @currentTableName;
	End
	
	Select * from @Enumerator; 
END