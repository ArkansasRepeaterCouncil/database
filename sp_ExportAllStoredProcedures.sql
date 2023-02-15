CREATE PROCEDURE sp_ExportAllStoredProcedures
AS
BEGIN
	select o.name, m.definition from sys.objects as o inner join sys.sql_modules as m on o.object_id = m.object_id where o.type = 'p' order by o.name
END