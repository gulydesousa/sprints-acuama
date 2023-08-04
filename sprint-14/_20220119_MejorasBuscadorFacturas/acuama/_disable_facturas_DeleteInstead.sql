ALTER TRIGGER [dbo].[facturas_DeleteInstead]
ON [dbo].[facturas]
INSTEAD OF DELETE
AS
SET NOCOUNT ON;

/****************************************
IMPIDE BORRAR LINEAS DE FACTURA CUANDO:
* Hay cobros asociados a esta linea de factura: Registra fallo en ErrorLog
* No hay cobros asociados a la linea. Se ejecuta el DELETE   
*****************************************/

--[01]Explotación
DECLARE @expl VARCHAR(20) = '';
SELECT @expl = P.pgsvalor 
FROM dbo.parametros AS P
WHERE P.pgsclave = 'EXPLOTACION_CODIGO';

--[02]Numero de cobros asociados a la linea de la factura
DECLARE @COBS AS TABLE(
  facCod INT
, facPerCod VARCHAR(6)
, facCtrCod INT
, facVersion INT
, numCobros INT);


INSERT INTO @COBS
SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, COUNT(C.cobNum) AS numCobros 
FROM dbo.cobros AS C
INNER JOIN dbo.cobLin AS CL
ON  CL.cblPpag = C.cobPpag 
AND CL.cblNum = C.cobNum 
AND CL.cblScd = C.cobScd
INNER JOIN DELETED AS F
ON  F.facCod= CL.cblFacCod
AND F.facPerCod = CL.cblPer
AND F.facCtrCod = C.cobCtr
AND F.facVersion = CL.cblFacVersion
GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion;

--[11]Escribimos en el log los que no se pueden borrar
DECLARE @LOGINSERT VARCHAR(500);
DECLARE @QUERY VARCHAR(500) = 'EXEC dbo.ErrorLog_Insert 
  @erlProcedimiento=''dbo.facturas_DeleteInstead''
, @erlProcedure=''dbo.facturas_DeleteInstead''
, @erlMessage=''Ha intentado borrar una factura con cobros''
, @erlExplotacion=''%s''
, @erlParams = ''facCod=%i, facPerCod=%s, facCtrCod=%i, facVersion=%i, numCobros=%i''';

DECLARE _CURSOR CURSOR FOR

SELECT LOGINSERT = FORMATMESSAGE(@QUERY, @expl, facCod, facPerCod, facCtrCod, facVersion, numCobros)
FROM @COBS
WHERE numCobros IS NOT NULL AND numCobros>0;

OPEN _CURSOR;
FETCH NEXT FROM _CURSOR INTO @LOGINSERT;

WHILE @@FETCH_STATUS = 0
BEGIN 
	EXEC(@LOGINSERT);
	FETCH NEXT FROM _CURSOR INTO @LOGINSERT;
END
CLOSE _CURSOR;
DEALLOCATE _CURSOR;

--*********************************
--*********************************
--Borramos las que se pueden borrar

--[21]Borramos los registros del total
DELETE F
FROM dbo.facTotales AS F
INNER JOIN DELETED AS D
ON  F.fctCod= D.facCod
AND F.fctPerCod = D.facPerCod
AND F.fctCtrCod = D.facCtrCod
AND F.fctVersion = D.facVersion
LEFT JOIN @COBS AS C 
ON  F.fctCod= C.facCod
AND F.fctPerCod = C.facPerCod
AND F.fctCtrCod = C.facCtrCod
AND F.fctVersion = C.facVersion
WHERE C.numCobros IS NULL OR C.numCobros=0;

--[22]Borramos los registros del total
DELETE F
FROM dbo.facturas AS F
INNER JOIN DELETED AS D
ON  F.facCod= D.facCod
AND F.facPerCod = D.facPerCod
AND F.facCtrCod = D.facCtrCod
AND F.facVersion = D.facVersion
LEFT JOIN @COBS AS C 
ON  F.facCod= C.facCod
AND F.facPerCod = C.facPerCod
AND F.facCtrCod = C.facCtrCod
AND F.facVersion = C.facVersion
WHERE C.numCobros IS NULL OR C.numCobros=0;
--*********************************
--*********************************


GO


