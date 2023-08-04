CREATE TRIGGER tgrFacturas_facLecLectorFec_AfterUpdate
ON [dbo].[facturas]
AFTER UPDATE
AS
SET NOCOUNT ON;
--SET ANSI_WARNINGS OFF;


--************************************************
--Se ejecuta solo si actualizamos la fecha de lectura del lector
IF UPDATE(facLecLectorFec) OR UPDATE(facLecActFec)
BEGIN	

	--************************************************
	--[00]Tabla donde guardamos la información del update
	DECLARE @inserted AS TABLE(
	  facCod INT
	, facPerCod VARCHAR(6)
	, facCtrCod INT
	, facVersion INT
	, facZonCod VARCHAR(4)
	, facLecLectorFec DATETIME
	, facLecActFec DATETIME);


	DECLARE @nuevos AS TABLE(
	  facCod INT
	, facPerCod VARCHAR(6)
	, facCtrCod INT
	, facVersion INT
	, facLecLectorFec DATETIME
	, diasLec INT
	, facLecActFec DATETIME
	, diasAct INT);
	
	--************************************************
	--[01]Ponemos la fecha de lectura a NULL para sacar la media sin tener en cuenta estas facturas porque alteraría la media
	--Lo guadamos en @inserted para volver a ponerlo
	UPDATE F SET facLecLectorFec= NULL
	OUTPUT DELETED.facCod, DELETED.facPerCod, DELETED.facCtrCod,  DELETED.facVersion, DELETED.facZonCod
	, DELETED.facLecLectorFec
	, DELETED.facLecActFec
	INTO @inserted 
	FROM dbo.facturas AS F
	INNER JOIN INSERTED AS I
	ON F.facCod = I.facCod
	AND F.facPerCod = I.facPerCod
	AND F.facCtrCod = I.facCtrCod
	AND F.facVersion = I.facVersion;
	
	--************************************************
	--[02]Sacamos la fecha de lectura media y lo comparamos con el valor actualizado
	--Insertamos solo las lineas que requieren cambiar el valor por el medio de la zona
	INSERT INTO @nuevos
	SELECT I.facCod, I.facPerCod, I.facCtrCod, I.facVersion
	, facLecLectorFec	= IIF(DATEDIFF(DAY, V.fecLector_zona, I.facLecLectorFec) > P.pgsvalor, V.fecLector_zona, I.facLecLectorFec)
	, diasLec			= DATEDIFF(DAY, V.fecLector_zona, I.facLecLectorFec)
	
	, facLecActFec	= IIF(DATEDIFF(DAY, V.fecLector_zona, I.facLecActFec) > P.pgsvalor, V.fecLector_zona, I.facLecActFec)
	, diasAct		= DATEDIFF(DAY, V.fecLector_zona, I.facLecActFec)	
	FROM dbo.facturas AS F
	INNER JOIN @inserted AS I
	ON F.facCod = I.facCod
	AND F.facPerCod = I.facPerCod
	AND F.facCtrCod = I.facCtrCod
	AND F.facVersion = I.facVersion
	INNER JOIN vPerZona_FechaLecturaMedia AS V
	ON F.facCod = V.facCod
	AND F.facCtrCod = V.facCtrCod
	AND F.facPerCod = V.facPerCod
	AND F.facVersion = V.facVersion
	LEFT JOIN dbo.parametros AS P
	ON P.pgsclave = 'MAXDIASENTRELECTURAS'

	WHERE V.[numFacturas] = 0 --No tiene facturas de consumo anteriores
	AND ISNUMERIC(P.pgsvalor)=1
	AND P.pgsvalor>0 
	AND I.facLecLectorFec IS NOT NULL 
	--La zona ha sido leida en al menos un 80%
	AND V.[zona%AvanceLectura] > 80
	--La fecha que quiero poner supera los 120 días respecto a la media de lectura de toda la zona
	AND (DATEDIFF(DAY, V.fecLector_zona, I.facLecLectorFec) > P.pgsvalor OR
		 DATEDIFF(DAY, V.fecLector_zona, I.facLecActFec) > P.pgsvalor);

	--[99] Hacemos el Update definitivo.
	UPDATE F SET 
	F.facLecLectorFec = ISNULL(N.facLecLectorFec, I.facLecLectorFec),
	F.facLecActFec = ISNULL(N.facLecActFec, I.facLecActFec)
	FROM @inserted AS I
	INNER JOIN dbo.facturas AS F
	ON  I.facCod = F.facCod
	AND I.facPerCod = F.facPerCod
	AND I.facCtrCod = F.facCtrCod
	AND I.facVersion = F.facVersion
	LEFT JOIN @nuevos AS N
	ON  N.facCod = F.facCod
	AND N.facPerCod = F.facPerCod
	AND N.facCtrCod = F.facCtrCod
	AND N.facVersion = F.facVersion;

	
	--********************************************
	--Dejamos en el log las fechas que han sido modificadas por el trigger
	DECLARE @quiero AS VARCHAR(500);
	DECLARE @puedo AS VARCHAR(4000);

	DECLARE CUR  CURSOR
	FOR
	SELECT quiero = FORMATMESSAGE('::Quiero:: MAXDIASENTRELECTURAS:%s faccod:%i facpercod:%s facCtrCod:%i facVersion:%i facLecLectorFec: %s facLecActFec: %s'
						, P.pgsvalor
						, I.facCod
						, I.facPerCod
						, I.facCtrCod
						, I.facVersion
						, CONVERT(VARCHAR, I.facLecLectorFec, 120)
						, CONVERT(VARCHAR, I.facLecActFec, 120))
		, puedo= FORMATMESSAGE ('::Puedo:: %sfacLecLectorFec[%s, dias:%i], %sfacLecActFec:[%s, dias:%i]'
						, IIF(N.diasLec>P.pgsvalor, 'FecMediaZona-', '') 
						, CONVERT(VARCHAR, N.facLecLectorFec, 120)
						, N.diasLec

						, IIF(N.diasAct>P.pgsvalor, 'FecMediaZona-', '') 
						, CONVERT(VARCHAR, N.facLecActFec, 120)
						, N.diasAct)
	FROM @nuevos AS N
	INNER JOIN @inserted AS I
	ON  I.facCod = N.facCod
	AND I.facPerCod = N.facPerCod
	AND I.facCtrCod = N.facCtrCod
	AND I.facVersion = N.facVersion
	LEFT JOIN dbo.parametros AS P
	ON P.pgsclave = 'MAXDIASENTRELECTURAS';

	OPEN CUR;
	FETCH NEXT FROM CUR INTO @quiero, @puedo;
	WHILE @@FETCH_STATUS = 0  
    BEGIN
		EXEC Trabajo.errorLog_Insert 'tgrFacturas_facLecLectorFec_AfterUpdate', @quiero, @puedo;
        FETCH NEXT FROM CUR INTO @quiero, @puedo;
    END;

	CLOSE CUR;
	DEALLOCATE CUR;
END


GO