/*
DECLARE @codigoContratoD INT --= 3;
DECLARE @codigoContratoH INT --= 3;
DECLARE @fechaD DATE;
DECLARE @fechaH DATE;
DECLARE @periodoD VARCHAR(6) = '202101';
DECLARE @periodoH VARCHAR(6)-- = '202104';
DECLARE @repLegal VARCHAR(80);
DECLARE @zonaD VARCHAR(4) ='3';
DECLARE @zonaH VARCHAR(4) ='3';

EXEC [ReportingServices].[HistoricoConsumoContrato_Melilla] @codigoContratoD, @codigoContratoH, @fechaD, @fechaH, @periodoD, @periodoH, @repLegal, @zonaD, @zonaH
*/


ALTER PROCEDURE [ReportingServices].[HistoricoConsumoContrato_Melilla]
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
EXEC [ReportingServices].[HistoricoConsumoContrato] @codigoContratoD, @codigoContratoH, @fechaD, @fechaH, @periodoD, @periodoH, @repLegal, @zonaD, @zonaH;

WITH FAC AS(
SELECT H.*
, F.facctrversion
, F.facConsumoFactura
, F.facLecActFec
, F.facZonCod
, facFecha = ISNULL(F.facFecha, F.facLecActFec)
FROM @HIST AS H
INNER JOIN dbo.facturas AS F
	ON  F.facCod= H.facCod
	AND F.facPerCod = H.facPerCod
	AND F.facCtrCod = H.facCtrCod
	AND F.facVersion = H.facVersion

), CONT AS(
SELECT F.*
, CC.ctcCon
--(RN=1) el último contador instalado
, RN = ROW_NUMBER() OVER (PARTITION BY facCtrCod, facPerCod, facCod, facVersion ORDER BY CC.ctcFec DESC)
FROM FAC AS F
--Contadores Instalados
LEFT JOIN dbo.ctrcon AS CC
ON CC.ctcCtr = F.facCtrCod
AND (CAST(CC.ctcFecReg AS DATE) <= F.facLecActFec) --contadores instalado a la fecha de lectura
AND CC.ctcOperacion = 'I')


SELECT F.facCtrCod
, facFecha = ISNULL(F.facFecha, F.facLecActFec)
, F.facPerCod
, F.facConsumoFactura
, Z.zondes
, P.perdes
, I.inmdireccion
, C.ctrPagNom
, C.ctrTitNom 
, F.TotalFactura
, F.facZonCod
, F.facVersion
, F.ctcCon
, F.RN
, CC.conNumSerie
FROM CONT AS F
INNER JOIN dbo.contratos AS C 
	ON  F.RN=1
	AND C.ctrcod = F.facctrcod 
	AND C.ctrversion = F.facctrversion
INNER JOIN dbo.vContratosUltimaVersion AS c3
	ON c3.ctrCod= F.facCtrCod
INNER JOIN dbo.inmuebles AS I 
	ON I.inmcod = c3.ctrinmcod
INNER JOIN dbo.zonas AS Z
	ON F.facZonCod=Z.zonCod
INNER JOIN dbo.periodos AS P
	ON F.facPerCod=P.percod
LEFT JOIN dbo.contador AS CC
ON F.ctcCon = CC.conID
ORDER BY facCtrCod, F.facPerCod, F.facCod, F.facVersion;

GO

