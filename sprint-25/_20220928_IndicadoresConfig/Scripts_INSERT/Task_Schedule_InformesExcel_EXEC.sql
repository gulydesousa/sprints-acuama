/*
--***************************
--UNA TAREA
--***************************
DECLARE @tskScheduledDate DATETIME = GETDATE();
EXEC [dbo].[Task_Schedule_InformesExcel] 'gmdesousa', '000/901', @tskScheduledDate, NULL, 3;
*/


--***************************
--LOOP PARA INSERTAR VARIAS TAREAS: UNA POR MES A FUTURO
--***************************
DECLARE @user AS VARCHAR(10) = 'gmdesousa';
DECLARE @ExcCod VARCHAR(10) =  '000/901';
DECLARE @tipoEnvio INT = 3; --3: FTP+Email


DECLARE @fecha DATE = '20220801'; 
DECLARE @fHasta DATE = '20230801'; 
DECLARE @ahora DATE =  GETDATE();
DECLARE @tskScheduledDate DATETIME = GETDATE();


WHILE @fecha <= @fHasta
BEGIN
	SELECT [@fecha]=@fecha, [@tskScheduledDate]=@tskScheduledDate;
	--EXEC [dbo].[Task_Schedule_InformesExcel] @user, @ExcCod, @tskScheduledDate, @fecha, @tipoEnvio;
	

	SELECT @fecha = DATEADD(WEEK, 1, @fecha), @tskScheduledDate= DATEADD(SECOND, 30, @tskScheduledDate);
	SELECT @tskScheduledDate = CASE WHEN @fecha <@ahora THEN  @tskScheduledDate ELSE @fecha END;

END
