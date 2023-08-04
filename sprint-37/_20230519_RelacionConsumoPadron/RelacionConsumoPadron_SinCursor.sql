
/*
DECLARE   @periodoD AS VARCHAR(6) = '202201'
, @periodoH AS VARCHAR(6) = '202301'
, @fechaD AS DATE = NULL
, @fechaH AS DATE = NULL
, @contratoD AS INT = NULL
, @contratoH AS INT = NULL
, @versionD AS INT = NULL
, @versionH AS INT = NULL
, @zonaD AS VARCHAR(4) = NULL
, @zonaH AS VARCHAR(4) = NULL
, @consuMin AS INT = 0
, @consuMax AS INT = 999999999
, @verTodas AS BIT = 1
, @preFactura AS BIT = 0

EXEC [ReportingServices].[RelacionConsumoPadron_SinCursor] 
  @periodoD, @periodoH, @fechaD, @fechaH, @contratoD, @contratoH
, @versionD, @versionH, @zonaD, @zonaH, @consuMin, @consuMax
, @verTodas, @preFactura;

*/

CREATE PROCEDURE [ReportingServices].[RelacionConsumoPadron_SinCursor]
  @periodoD AS VARCHAR(6) = NULL
, @periodoH AS VARCHAR(6) = NULL
, @fechaD AS DATE = NULL
, @fechaH AS DATE = NULL
, @contratoD AS INT = NULL
, @contratoH AS INT = NULL
, @versionD AS INT = NULL
, @versionH AS INT = NULL
, @zonaD AS VARCHAR(4) = NULL
, @zonaH AS VARCHAR(4) = NULL
, @consuMin AS INT = NULL
, @consuMax AS INT = NULL
, @verTodas AS BIT
, @preFactura AS BIT
AS

SET @fechaH = DATEADD(DAY, 1, @fechaH);

--***********************************
--Periodos en consulta
SELECT TOP 6 percod, per = ROW_NUMBER() OVER (ORDER BY percod ASC)
INTO #PER
FROM dbo.periodos 
WHERE (PerCod >= @periodoD OR @periodoD IS NULL) and (PerCod <= @periodoH OR @periodoH IS NULL);

--**** DEBUG ******
--SELECT * FROM #PER
--*****************

--***********************************
--Aplicamos los filtros a las facturas
SELECT F.facCod
, F.facPerCod
, F.facCtrCod
, F.facVersion
, F.facCtrVersion
, F.facconsumofactura
, FL.fclnumLinea
, FL.fcltrfcod
, FL.fclTrfSvCod
--RN_FAC=1: Para quedarnos con una sola factura por periodo
, RN_FAC = DENSE_RANK() OVER(PARTITION BY F.facCod, F.facCtrCod, F.facPerCod ORDER BY F.facCod DESC, F.facVersion DESC)
--RN_LIN=1: Para quedarnos con una sola linea por periodo
, RN_FCL = ROW_NUMBER() OVER(PARTITION BY  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY FL.fcltrfcod DESC)
, CN_FCL = COUNT(FL.fcltrfcod) OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)
, P.per
INTO #FACS
FROM dbo.facturas AS F 
INNER JOIN #PER AS P
ON P.percod = F.facPerCod
INNER JOIN dbo.faclin AS FL
ON FL.fclfaccod = F.faccod 
AND FL.fclfacpercod = F.facpercod 
AND FL.fclfacversion = F.facversion 
AND FL.fclfacctrcod = F.facctrcod 
AND FL.fcltrfsvcod = 1
WHERE(facVersion >= @versionD  OR @versionD IS NULL)
and (facVersion <= @versionH OR @versionH IS NULL)
and (facZonCod >= @zonaD  OR @zonaD IS NULL)
and (facZonCod <= @zonaH OR @zonaH IS NULL)
and (facFecha>= @fechaD OR @fechaD IS NULL)
and (facFecha < @fechaH OR @fechaH IS NULL)
and (facCtrCod>= @contratoD OR @contratoD IS NULL)
and (facCtrCod<= @contratoH OR @contratoH IS NULL)
and (facFechaRectif IS NULL OR (facFechaRectif>=@fechaH) OR @verTodas=1)   -- verTodas junto con las rectificadas
and ( (facNumero is not null and @preFactura=0) OR  (@preFactura=1) )-- Si @preFactura es 0 entonces saca las facturas definitivas y si es 1 saca todas junto con las preFACTURAS
AND((fclFecLiq>=@fechaH) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	
and (@consuMin IS NULL OR @consuMin<=facConsumoFactura)
and (@consuMax IS NULL OR @consuMax>=facConsumoFactura);


--***********************************
--Conformamos el resultado final

WITH RESULT AS(
--Nos quedamos con una factura y una linea por periodo
SELECT * 
FROM #FACS 
WHERE RN_FAC=1	--Ultima factura
AND RN_FCL=1	--Línea con mayor codigo de tarifa

), CTRS AS(
--Ordenamos los contratos por version para luego quedarnos con el de mayor version
SELECT facCtrCod
, facCtrVersion
, RN= ROW_NUMBER() OVER (PARTITION BY facCtrCod ORDER BY facCtrVersion DESC)
FROM RESULT AS R

), CTR AS(
--Ultima version de cada contato con los datos de contrato como los necesitaremos para el informe
SELECT [contrato]  = CC.ctrcod
	 , [documento] = ISNULL(CC.ctrPagDocIden, CC.ctrTitDocIden)
	 , [cliente]   = ISNULL(CC.ctrPagNom, CC.ctrTitNom)
	 , [direccion] = I.inmDireccion
	 , [diametro]  = F.conDiametro
FROM CTRS AS C
INNER JOIN dbo.contratos AS CC
ON  C.RN = 1 --Ulima version
AND CC.ctrcod = C.facCtrCod
AND CC.ctrVersion = C.facCtrVersion
INNER JOIN dbo.inmuebles AS I
ON I.inmcod = CC.ctrinmcod
LEFT JOIN fContratos_ContadoresInstalados(NULL) AS F 
ON F.ctcCtr = CC.ctrcod

), TAR AS(
--Ordenamos las lineas por contrato para quedarnos con la del periodo mas reciente 
SELECT R.facCtrCod
, R.facPerCod
, [tarifa] = R.fclTrfCod
, [servicio] = R.fclTrfSvCod
--RN=1 para quedarnos con la tarifa de agua aplicada al periodo mas reciente
, RN= ROW_NUMBER() OVER(PARTITION BY facCtrCod ORDER BY per DESC) 
FROM RESULT AS R)


SELECT C.contrato
, C.documento
, C.cliente
, T.tarifa 
, C.direccion
, C.diametro

, [periodo1] = R1.facPerCod
, [consumo1] = R1.facConsumoFactura

, [periodo2] = R2.facPerCod
, [consumo2] = R2.facConsumoFactura

, [periodo3] = R3.facPerCod
, [consumo3] = R3.facConsumoFactura

, [periodo4] = R4.facPerCod
, [consumo4] = R4.facConsumoFactura

, [periodo5] = R5.facPerCod
, [consumo5] = R5.facConsumoFactura

, [periodo6] = R6.facPerCod
, [consumo6] = R6.facConsumoFactura

, [trfcod] = T.tarifa 
, [trfdes] = TT.trfdes
--************************************
--Contratos diferentes, el mas reciente
FROM CTR AS C 
--************************************
--Ultima tarifa de agua aplicada
LEFT JOIN TAR AS T 
ON T.facCtrCod = C.contrato
AND T.RN=1 --RN=1 para quedarnos con la tarifa de agua aplicada al periodo mas reciente
--************************************
--Descripción de la tarifa
LEFT JOIN tarifas AS TT
ON TT.trfcod = T.tarifa
AND TT.trfsrvcod = T.servicio
--************************************
--Consumo por periodo
LEFT JOIN RESULT AS R1
ON R1.per = 1 AND R1.facCtrCod = C.contrato
LEFT JOIN RESULT AS R2
ON R2.per = 2 AND R2.facCtrCod = C.contrato
LEFT JOIN RESULT AS R3
ON R3.per = 3 AND R3.facCtrCod = C.contrato
LEFT JOIN RESULT AS R4
ON R4.per = 4 AND R4.facCtrCod = C.contrato
LEFT JOIN RESULT AS R5
ON R5.per = 5 AND R5.facCtrCod = C.contrato
LEFT JOIN RESULT AS R6
ON R6.per = 6 AND R6.facCtrCod = C.contrato
--ORDER BY contrato;
ORDER BY tarifa, direccion;

DROP TABLE IF EXISTS #PER;
DROP TABLE IF EXISTS #FACS;
GO


