/*
DECLARE @codigoContratoD INT;
DECLARE @codigoContratoH INT;
DECLARE @fechaD DATE;
DECLARE @fechaH DATE;
DECLARE @periodoD VARCHAR(6) = '202101';
DECLARE @periodoH VARCHAR(6) = '202104';
DECLARE @repLegal VARCHAR(80);
DECLARE @zonaD VARCHAR(4) ='3';
DECLARE @zonaH VARCHAR(4) ='3';

EXEC [ReportingServices].[HistoricoConsumoContratoDetallado_Comun] @codigoContratoD, @codigoContratoH, @fechaD, @fechaH, @periodoD, @periodoH, @repLegal, @zonaD, @zonaH
*/


ALTER PROCEDURE [ReportingServices].[HistoricoConsumoContratoDetallado_Comun]
@codigoContratoD INT,
@codigoContratoH INT,
@fechaD DATE,
@fechaH DATE,
@periodoD VARCHAR(6),
@periodoH VARCHAR(6),
@repLegal VARCHAR(80),
@zonaD VARCHAR(4),
@zonaH VARCHAR(4)
AS


DECLARE @HIST AS TABLE(
  facCod SMALLINT
, facPerCod VARCHAR(6)
, facCtrCod INT
, facVersion SMALLINT
, TotalFactura MONEY)

INSERT INTO @HIST (facCod, facPerCod, facCtrCod, facVersion, TotalFactura)
EXEC [ReportingServices].[HistoricoConsumoContrato] @codigoContratoD, @codigoContratoH, @fechaD, @fechaH, @periodoD, @periodoH, @repLegal, @zonaD, @zonaH

SELECT F.facCtrCod
, C.ctrPagNom
, C.ctrTitNom
, I.inmdireccion
, facFecha = ISNULL(F.facFecha, F.facLecActFec)
, F.facLecActFec
, F.facPerCod
, F.facLecAnt
, F.facLecLector
, F.facLecInlCod
, inlDesLector = lector.inlDes
, F.facLecInspector
, F.facInsInlCod
, inlDesInspector = inspector.inlDes
, facLecAct
, F.facConsumoFactura
, H.TotalFactura
FROM @HIST AS H
INNER JOIN dbo.facturas AS F
	ON  F.facCod= H.facCod
	AND F.facPerCod = H.facPerCod
	AND F.facCtrCod = H.facCtrCod
	AND F.facVersion = H.facVersion
INNER JOIN dbo.contratos AS C 
	ON  C.ctrcod = F.facctrcod 
	AND C.ctrversion = F.facctrversion
INNER JOIN dbo.inmuebles AS I 
	ON I.inmcod = C.ctrinmcod
INNER JOIN dbo.zonas AS Z
	ON F.facZonCod=Z.zonCod
INNER JOIN dbo.periodos AS P
	ON F.facPerCod=P.percod
LEFT JOIN dbo.incilec AS lector 
	ON lector.inlcod = F.facLecInlCod
LEFT JOIN dbo.incilec AS inspector 
	ON inspector.inlcod = F.facInsInlCod

ORDER BY F.facPerCod, F.facVersion;


GO



