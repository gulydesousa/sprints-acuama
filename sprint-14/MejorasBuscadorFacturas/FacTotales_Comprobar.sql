--EXEC Trabajo.FacTotales_Comprobar
--SELECT * FROm facTotales

CREATE PROCEDURE Trabajo.FacTotales_Comprobar
AS
CREATE TABLE #FACTOTALES (
	[fctCod] [int],
	[fctCtrCod] [int],
	[fctPerCod] [varchar](6),
	[fctVersion] [int],
	[fctActiva] [bit] ,
	[fctBase] [money] ,
	[fctImpuestos] [money] ,
	[fctTotal] [money],

	[fctFacturado] [money],
	[fctCobrado] [money],
	[fctEntregasCta] [money],

	[fctTipoImp1] [decimal](4, 2) ,
	[fctBaseTipoImp1] [money] ,
	
	[fctTipoImp2] [decimal](4, 2) ,
	[fctBaseTipoImp2] [money] ,
	
	[fctTipoImp3] [decimal](4, 2) ,
	[fctBaseTipoImp3] [money] ,
	
	[fctTipoImp4] [decimal](4, 2) ,
	[fctBaseTipoImp4] [money] ,
	
	[fctTipoImp5] [decimal](4, 2) ,
	[fctBaseTipoImp5] [money],

	[fctTipoImp6] [decimal](4, 2) ,
	[fctBaseTipoImp6] [money])



INSERT INTO #FACTOTALES
EXEC FacTotales_Select;


SELECT FT.* 
FROM #FACTOTALES AS FT
LEFT JOIN dbo.facTotales AS T
ON  FT.fctCod = T.fctCod
AND FT.fctCtrCod = T.fctCtrCod 
AND FT.fctPerCod = T.fctPerCod
AND FT.fctVersion = T.fctVersion
WHERE --La factura no está
T.fctCod IS NULL OR
--Hay diferencia en los importes
T.[fctBase] <> FT.[fctBase] OR
T.[fctImpuestos] <> FT.[fctImpuestos] OR
T.[fctTotal] <> FT.[fctTotal] OR
T.[fctFacturado] <> FT.[fctFacturado] OR
T.[fctCobrado] <> FT.[fctCobrado] OR
T.[fctEntregasCta] <> FT.[fctEntregasCta] OR
T.[fctTipoImp1] <> FT.[fctTipoImp1] OR
T.[fctBaseTipoImp1] <> FT.[fctBaseTipoImp1] OR
T.[fctTipoImp2] <> FT.[fctTipoImp2] OR
T.[fctBaseTipoImp2] <> FT.[fctBaseTipoImp2] OR
T.[fctTipoImp3] <> FT.[fctTipoImp3] OR
T.[fctBaseTipoImp3] <> FT.[fctBaseTipoImp3] OR
T.[fctTipoImp4] <> FT.[fctTipoImp4] OR
T.[fctBaseTipoImp4] <> FT.[fctBaseTipoImp4] OR
T.[fctTipoImp5] <> FT.[fctTipoImp5] OR
--T.[fctBaseTipoImp5] <> FT.[fctBaseTipoImp5] OR
T.[fctTipoImp6] <> FT.[fctTipoImp6] OR
T.[fctBaseTipoImp6] <> FT.[fctBaseTipoImp6];

IF OBJECT_ID('tempdb.dbo.#FACTOTALES', 'U') IS NOT NULL 
	DROP TABLE #FACTOTALES;

GO