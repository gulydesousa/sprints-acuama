CREATE TRIGGER [dbo].[faclin_UpdateInstead]
ON [dbo].[faclin]
INSTEAD OF UPDATE
AS
SET NOCOUNT ON;

/****************************************
IMPIDE ACTUALIZAR LINEAS DE FACTURA CUANDO:
* Hay cobros asociados a esta linea de factura: Registra fallo en ErrorLog
* No hay cobros asociados a la linea. Se ejecuta el UPDATE   
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
INNER JOIN INSERTED AS I
ON  FL.fclFacCod= I.fclFacCod
AND FL.fclFacPerCod = I.fclFacPerCod
AND FL.fclFacCtrCod = I.fclFacCtrCod
AND FL.fclFacVersion = I.fclFacVersion
AND FL.fclNumLinea = I.fclNumLinea
AND (I.fclTrfSvCod<>FL.fclTrfSvCod OR I.fclTrfCod<>FL.fclTrfCod OR I.fclNumLinea<>FL.fclNumLinea)
GROUP BY FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea;

--[11]Escribimos en el log los que no se pueden editar
DECLARE @LOGINSERT VARCHAR(500);
DECLARE @QUERY VARCHAR(500) = 'EXEC dbo.ErrorLog_Insert 
  @erlProcedimiento=''dbo.faclin_UpdateInstead''
, @erlProcedure=''dbo.faclin_UpdateInstead''
, @erlMessage=''Ha intentado editar una línea con cobros''
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


--[12]Actualizamos las que se pueden actualizar
UPDATE FL SET
  FL.fclFacCod = I.fclFacCod
, FL.fclFacPerCod = I.fclFacPerCod
, FL.fclFacCtrCod = I.fclFacCtrCod
, FL.fclFacVersion = I.fclFacVersion
, FL.fclNumLinea = I.fclNumLinea
, FL.fclEscala1 = I.fclEscala1
, FL.fclPrecio1 = I.fclPrecio1
, FL.fclUnidades1 = I.fclUnidades1
, FL.fclEscala2 = I.fclEscala2
, FL.fclPrecio2 = I.fclPrecio2
, FL.fclUnidades2 = I.fclUnidades2
, FL.fclEscala3 = I.fclEscala3
, FL.fclPrecio3 = I.fclPrecio3
, FL.fclUnidades3 = I.fclUnidades3
, FL.fclEscala4 = I.fclEscala4
, FL.fclPrecio4 = I.fclPrecio4
, FL.fclUnidades4 = I.fclUnidades4
, FL.fclEscala5 = I.fclEscala5
, FL.fclPrecio5 = I.fclPrecio5
, FL.fclUnidades5 = I.fclUnidades5
, FL.fclEscala6 = I.fclEscala6
, FL.fclPrecio6 = I.fclPrecio6
, FL.fclUnidades6 = I.fclUnidades6
, FL.fclEscala7 = I.fclEscala7
, FL.fclPrecio7 = I.fclPrecio7
, FL.fclUnidades7 = I.fclUnidades7
, FL.fclEscala8 = I.fclEscala8
, FL.fclPrecio8 = I.fclPrecio8
, FL.fclUnidades8 = I.fclUnidades8
, FL.fclEscala9 = I.fclEscala9
, FL.fclPrecio9 = I.fclPrecio9
, FL.fclUnidades9 = I.fclUnidades9
, FL.fcltotal = I.fcltotal
, FL.fclTrfSvCod = I.fclTrfSvCod
, FL.fclTrfCod = I.fclTrfCod
, FL.fclUnidades = I.fclUnidades
, FL.fclPrecio = I.fclPrecio
, FL.fclImpuesto = I.fclImpuesto
, FL.fclBase = I.fclBase
, FL.fclImpImpuesto = I.fclImpImpuesto
, FL.fclFecLiq = I.fclFecLiq
, FL.fclUsrLiq = I.fclUsrLiq
, FL.fclCtsUds = I.fclCtsUds
, FL.fclObs = I.fclObs
, FL.fclFecLiqImpuesto = I.fclFecLiqImpuesto
, FL.fclUsrLiqImpuesto = i.fclUsrLiqImpuesto
FROM dbo.faclin AS FL
INNER JOIN INSERTED AS I
ON  FL.fclFacCod= I.fclFacCod
AND FL.fclFacPerCod = I.fclFacPerCod
AND FL.fclFacCtrCod = I.fclFacCtrCod
AND FL.fclFacVersion = I.fclFacVersion
AND FL.fclNumLinea = I.fclNumLinea
LEFT JOIN @COBS AS C 
ON  FL.fclFacCod= C.fclFacCod
AND FL.fclFacPerCod = C.fclFacPerCod
AND FL.fclFacCtrCod = C.fclFacCtrCod
AND FL.fclFacVersion = C.fclFacVersion
AND FL.fclNumLinea = C.fclNumLinea
WHERE C.numCobros IS NULL OR C.numCobros=0;



GO


