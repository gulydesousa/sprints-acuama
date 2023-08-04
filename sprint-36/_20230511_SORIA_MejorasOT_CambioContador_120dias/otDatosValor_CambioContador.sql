
--DELETE FROM contador WHERE conID IN (50785,50786,50783)
/*
DECLARE @conCamOtSerScd SMALLINT = 1;
DECLARE @conCamOtSerCod SMALLINT = 80;
DECLARE @conCamOtNum INT --= 14698;

EXEC dbo.otDatosValor_CambioContador @conCamOtSerScd, @conCamOtSerCod,  @conCamOtNum;
*/

ALTER PROCEDURE dbo.otDatosValor_CambioContador
  @conCamOtSerScd SMALLINT
, @conCamOtSerCod SMALLINT
, @conCamOtNum INT

AS

--********************************************
--Sprint#34: "Mejoras Pantalla cambio de contador Soria"
--********************************************

SET NOCOUNT ON;

DECLARE @OT_TIPO_CC VARCHAR(4)='';
SELECT @OT_TIPO_CC = pgsvalor FROM dbo.parametros AS P WHERE P.pgsClave='OT_TIPO_CC';

WITH VAL AS(
--Datos complementarios para el cambio de contador:
--OT rechazada
--Tipo de OT: Cambio de contador
SELECT OT.otserscd
, OT.otsercod
, OT.otnum
, OT.otCtrCod
, D.odtCodigo 
, D.odtDescripcion
, V.otdvValor
, [Col] = CASE D.odtCodigo
			WHEN 603 THEN '_conNumSerie'		
			WHEN 604 THEN '_conMcnDes'
			WHEN 605 THEN '_conMdlDes'
			WHEN 606 THEN '_conDiametro'
			WHEN 607 THEN '_conCaudal'
			WHEN 600 THEN '_conCamLecRet'
			WHEN 608 THEN '_conCamLecIns'
			WHEN 609 THEN '_conCamPrecinto'

		END
FROM dbo.ordenTrabajo AS OT
INNER JOIN dbo.otDatosValor AS V
ON  OT.otserscd = V.otdvOtSerScd
AND OT.otsercod = V.otdvOtSerCod
AND OT.otnum = V.otdvOtNum
INNER JOIN dbo.otDatos AS D
ON D.odtCodigo=V.otdvOdtCodigo
WHERE OT.otFecRechazo IS NOT NULL
AND OT.otottcod = @OT_TIPO_CC
AND (@conCamOtSerScd IS NULL OR OT.otserscd = @conCamOtSerScd)
AND (@conCamOtSerCod IS NULL OR OT.otsercod = @conCamOtSerCod)
AND (@conCamOtNum IS NULL OR OT.otnum= @conCamOtNum)

), MyPivot AS(
--Pivotamos las filas a columnas

SELECT * FROM 
(SELECT otserscd, otsercod, otnum, otCtrCod, otdvValor, Col FROM VAL) AS T
PIVOT 
(MAX(otdvValor) FOR Col IN ([_conCamLecRet],
							[_conNumSerie],
							[_conMcnDes],
							[_conMdlDes],
							[_conDiametro],
							[_conCaudal],
							[_conCamLecIns],
							[_conCamPrecinto]))AS PP

), RESULT AS( 
--Seleccionamos las filas como columnas y las enlazamos con la tabla contadores, marca, modelo por descripcion

SELECT P.*
, [_conMcncod] = M.mcncod
, [_conMdlCod]= MM.mdlCod
, C.conID, C.conDiametro, C.conCaudal, C.conClcCod, C.conComFec, C.conFecReg
, C.conMcnCod
, C.conMdlCod
, MC.mcndes
, MMC.mdlDes
--CN>1: Hay multiples coincidencias por Serie, Marca o Modelo
, CN=COUNT(P.otnum) OVER(PARTITION BY P.otserscd, P.otsercod, P.otnum)
--RN=1: Para quedarnos siempre con un único contador
, RN = ROW_NUMBER() OVER(PARTITION BY P.otserscd, P.otsercod, P.otnum ORDER BY conID, M.mcncod, MM.mdlMcnCod, MM.mdlCod)
FROM MyPivot AS P

LEFT JOIN dbo.contador AS C
ON C.conNumSerie = P._conNumSerie

LEFT JOIN dbo.marcon AS MC
ON MC.mcncod = C.conMcnCod
LEFT JOIN  dbo.modcon AS MMC
ON MMC.mdlCod = C.conMdlCod

LEFT JOIN dbo.marcon AS M
ON M.mcndes = P._conMcnDes
LEFT JOIN dbo.modcon AS MM
ON ((M.mcncod IS NOT NULL AND MM.mdlMcnCod = M.mcncod) OR (M.mcncod IS NULL)) 
AND MM.mdlDes = P._conMdlDes
)

SELECT --conID y ctrCod del Nuevo Contador: para ver si el contador nuevo está instalado en otro contrato.
	   [Nuevo_ctcCon] = R.conID 
	 , [Nuevo_ctcCtr] = IIF(CC.opInstalacion IS NOT NULL AND CC.opRetirada IS NULL, CC.ctrCod, NULL) 
	 --conID y ctrCod del contrato asociado a la OT.
	 , [Instalado_ctcCon] = C0.conId
	 , [Instalado_ctcCtr] = [otCtrCod]
	 , [conCamConID] = R.conID
	 --**********************************
	 ,[otCtrCod]
	, [conCamOtSerScd] = otserscd
	, [conCamOtSerCod] = otsercod
	, [conCamOtNum] = otnum
	, [conCamFecha] = NULL
	, [conCamFecReg]= NULL
	, [conCamLecIns] = _conCamLecIns
	, [conCamLecRet] = _conCamLecRet
	, [conCamConsumoAFacturar] = NULL
	, [conCamUsr] = NULL
	, [conCamPrecinto] = CAST(_conCamPrecinto AS BIT)
	, [conCamValidoParaFacturar] = NULL
	, [conCamFacturado]  = NULL
	, [conCamConsumoPagadoPrevio] = NULL
	--*****************************************************
	--Si el contador existe tomamos los datos del contador
	--Si el contador no existe tomamos los datos de la OT
	, [conNumSerie] = _conNumSerie
	, [conClcCod] = IIF(R.conID IS NULL, 9999, conClcCod)
	, [conFecReg] = conFecReg
	, [conDiametro]= IIF(R.conID IS NULL, R._conDiametro, R.conDiametro)
	, [conCaudal] = IIF(conCaudal IS NULL, CAST(REPLACE(_conCaudal, ',', '.') AS DECIMAL(7,2)), conCaudal)
	, [conMcnCod] = IIF(conMcnCod IS NULL, _conMcnCod, conMcnCod)
	, [conMcnDes] = IIF(R.conID IS NULL, _conMcnDes, mcndes)
	, [conMdlCod] = IIF(conMdlCod IS NULL, _conMdlCod, conMdlCod)
	, [conMdlDes] = IIF(R.conID IS NULL, _conMdlDes, mdlDes)
	, CN
	FROM RESULT AS R
	LEFT JOIN vCambiosContador AS CC
	ON CC.conId = R.conID
	AND CC.esUltimaInstalacion=1 
	LEFT JOIN vCambiosContador AS C0
	ON C0.ctrCod = otCtrCod
	AND C0.esUltimaInstalacion=1 

	WHERE RN=1;

GO

--SELECT * FROM vCambiosContador