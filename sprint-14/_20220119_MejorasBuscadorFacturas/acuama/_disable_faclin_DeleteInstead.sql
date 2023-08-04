
CREATE TRIGGER [dbo].[faclin_DeleteInstead]
ON [dbo].[faclin]
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
  fclFacCod INT
, fclFacPerCod VARCHAR(6)
, fclFacCtrCod INT
, fclFacVersion INT
, fclNumLinea INT
, numCobros INT);

INSERT INTO @COBS
SELECT FL.fclFacCod
, FL.fclFacPerCod
, FL.fclFacCtrCod
, FL.fclFacVersion
, FL.fclNumLinea
, COUNT(C.cobNum) AS numCobros 
FROM dbo.cobros AS C
INNER JOIN dbo.cobLin AS CL
ON  CL.cblPpag = C.cobPpag 
AND CL.cblNum = C.cobNum 
AND CL.cblScd = C.cobScd
INNER JOIN dbo.cobLinDes AS CLD 
ON  CLD.cldCblPpag = CL.cblPpag
AND CLD.cldCblNum = CL.cblNum 
AND CLD.cldCblScd = CL.cblScd 
AND CLD.cldCblLin = CL.cblLin
INNER JOIN DELETED AS FL
ON  FL.fclFacCod= CL.cblFacCod
AND FL.fclFacPerCod = CL.cblPer
AND FL.fclFacCtrCod = C.cobCtr
AND FL.fclFacVersion = CL.cblFacVersion
AND FL.fclNumLinea = CLD.cldFacLin
GROUP BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea;

--[11]Escribimos en el log los que no se pueden borrar
DECLARE @LOGINSERT VARCHAR(500);
DECLARE @QUERY VARCHAR(500) = 'EXEC dbo.ErrorLog_Insert 
  @erlProcedimiento=''dbo.faclin_DeleteInstead''
, @erlProcedure=''dbo.faclin_DeleteInstead''
, @erlMessage=''Ha intentado borrar una línea con cobros''
, @erlExplotacion=''%s''
, @erlParams = ''fclFacCod=%i, fclFacPerCod=%s, fclFacCtrCod=%i, fclFacVersion=%i, fclNumLinea=%i, numCobros=%i''';

DECLARE _CURSOR CURSOR FOR

SELECT LOGINSERT = FORMATMESSAGE(@QUERY, @expl, fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea, numCobros)
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


--[12]Borramos las que se pueden borrar
DELETE FL 
FROM dbo.faclin AS FL
INNER JOIN DELETED AS D
ON  FL.fclFacCod= D.fclFacCod
AND FL.fclFacPerCod = D.fclFacPerCod
AND FL.fclFacCtrCod = D.fclFacCtrCod
AND FL.fclFacVersion = D.fclFacVersion
AND FL.fclNumLinea = D.fclNumLinea
LEFT JOIN @COBS AS C 
ON  FL.fclFacCod= C.fclFacCod
AND FL.fclFacPerCod = C.fclFacPerCod
AND FL.fclFacCtrCod = C.fclFacCtrCod
AND FL.fclFacVersion = C.fclFacVersion
AND FL.fclNumLinea = C.fclNumLinea
WHERE C.numCobros IS NULL OR C.numCobros=0;



GO


