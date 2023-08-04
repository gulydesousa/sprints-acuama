

DELETE FROM ExcelPerfil WHERE ExPCod= '000/820'
DELETE FROM ExcelConsultas WHERE ExcCod='000/820'
DROP PROCEDURE [InformesExcel].[CobrosxDesglose]


DELETE FROM ExcelPerfil WHERE ExPCod= '000/810'
DELETE FROM ExcelConsultas WHERE ExcCod='000/810'
DROP PROCEDURE [InformesExcel].[CobrosxFacLiquidacion]

DELETE FROM ExcelPerfil WHERE ExPCod= '000/800'
DELETE FROM ExcelConsultas WHERE ExcCod='000/800'
DROP PROCEDURE [InformesExcel].[CobrosImporteLineasxDesglose]


INSERT INTO dbo.ExcelConsultas
VALUES ('000/800',	'Cobros Validar Desgloses', 'Cobros: Validar Desgloses', 1, '[InformesExcel].[Cobros_Validar]', '000', 'Para identificar los cobros en los que hay errores en los importes desglosados por líneas.');

INSERT INTO ExcelPerfil
VALUES('000/800', 'root', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/800', 'jefeExp', 5, NULL)

INSERT INTO ExcelPerfil
VALUES('000/800', 'jefAdmon', 5, NULL)
/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><FecDesde>20201201</FecDesde><FecHasta>20211231</FecHasta></LI></NodoXML>'


EXEC [InformesExcel].[Cobros_Validar] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/