
/*
DECLARE @contrato INT = 22096;
DECLARE @periodo VARCHAR(6) = '202102';		
DECLARE @version SMALLINT= 1;
DECLARE @codigo SMALLINT = 1;
DECLARE @fechaHasta DATETIME = NULL;

EXEC [dbo].[Informe_COMUN_CF010_EmisionFactTOTALES] @contrato, @periodo, @version, @codigo, @fechaHasta;

*/
CREATE PROCEDURE [dbo].[Informe_COMUN_CF010_EmisionFactTOTALES]
(
	@contrato INT =NULL,
	@periodo VARCHAR(6) = NULL,		
	@version SMALLINT =NULL,
	@codigo SMALLINT = NULL,
	@fechaHasta DATETIME = NULL
)
AS
	SET NOCOUNT OFF;

	WITH FACS AS(
	--[01]Factura con los filtros
	SELECT F.faccod
		 , F.facPercod
		 , F.facCtrCod
		 , F.facVersion
		 , CAST(F.facFecha AS DATE) AS facFecha
		 , F.facSerCod
		 , F.facNumero
		 , F.facFecReg
		 , F.facFechaRectif
		 , F.facNumeroRectif
		 , F.facSerieRectif
		 , ctrFace = ISNULL(C.ctrFace, 0)
		 , PP.perAvisoPago
		 , P.pgsvalor  AS fecLineas2Decimales
		 , PV.pgsvalor AS diasPagoVoluntario
		 , IIF(P.pgsvalor IS NOT NULL AND F.facFecReg>=P.pgsvalor, 2, 4) AS [precision]
	FROM dbo.facturas AS F
	INNER JOIN dbo.periodos AS PP
	ON PP.percod = F.facPerCod
	LEFT JOIN dbo.contratos AS C
	ON  C.ctrCod = F.facCtrCod
	AND C.ctrVersion = F.facCtrVersion
	LEFT JOIN dbo.parametros AS P
	ON P.pgsclave = 'LINEAS_2DECIMALES'
	LEFT JOIN dbo.parametros AS PV
	ON PV.pgsclave = 'DIAS_PAGO_VOLUNTARIO'
	WHERE F.facCod = @codigo
	  AND F.facPerCod = @periodo
	  AND F.facCtrCod = @contrato
	  AND (@version IS NULL OR F.facVersion = @version)

	), F0 AS (
	--[02]Factura original
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion  AS facVersion
	, F0.facVersion AS facVersionOriginal
	, F0.facNumero AS facNumeroOriginal
	, F0.facSerCod AS facSerieOriginal
	, F0.facFecha AS facFechaOriginal
	FROM FACS AS F
	INNER JOIN dbo.facturas AS F0
	ON  F.facNumero IS NOT NULL
	AND F.facCod = F0.facCod
	AND F.facPerCod = F0.facPerCod
	AND F.facCtrCod = F0.facCtrCod  
	AND F.facFecha = CAST(F0.facFechaRectif AS DATE)  
	AND F.facSerCod = F0.facSerieRectif  
	AND F.facNumero = F0.facNumeroRectif

	), FTI AS(
	--[03]Total lineas por Tipo Impositivo
	SELECT F.faccod
		 , F.facPercod
		 , F.facCtrCod
		 , F.facVersion
		 , FL.fclImpuesto
		 , SUM(FL.fclBase) AS base
		 , _totaliva = CAST(SUM(ROUND(FL.fclBase*FL.fclImpuesto*0.01, 4)) AS MONEY) 
		 , totaliva  = ROUND(CAST(SUM(ROUND(FL.fclBase*FL.fclImpuesto*0.01, 4)) AS MONEY) , IIF(ctrFace=1, 2, 4))
	FROM FACS AS F
	INNER JOIN dbo.faclin AS FL
	ON  F.facCod = FL.fclFacCod 
	AND F.facPerCod = FL.fclFacPerCod 
	AND F.facCtrCod = FL.fclFacCtrCod 
	AND F.facVersion= FL.fclFacVersion
	WHERE (@fechaHasta IS NOT NULL AND FL.fclFecLiq>=@fechaHasta) OR 
		  (FL.fclFecLiq IS NULL AND FL.fclUsrLiq IS NULL)
	GROUP BY F.faccod
		   , F.facPercod
		   , F.facCtrCod
		   , F.facVersion
		   , FL.fclImpuesto
		   , F.ctrFace)
	   	  	
	SELECT F.facCod
	, F.facCtrCod
	, F.facPerCod
	, F.facVersion
	, F.facFecReg
	, F.facFechaRectif
	, F.facNumero
	, FL.base
	, FL.fclImpuesto
	, FL.totaliva
	, ROUND(SUM(FL.base + FL.totaliva) OVER (PARTITION BY F.facCod, F.facCtrCod, F.facPerCod, F.facVersion), 2) AS totalFacturado
	, diasPagoVoluntarioPorDefecto = F.diasPagoVoluntario
	, F.perAvisoPago
	, [avisoPago] = F.perAvisoPago
	, F0.facVersionOriginal
	, esFacturaRectificada = IIF(F.facFechaRectif IS NULL, 0, 1) 
	, numeroRectificada = F0.facNumeroOriginal
	, serieRectificada = F0.facSerieOriginal
	, facFechaRectificada = F0.facFechaOriginal
	FROM FACS AS F
	INNER JOIN FTI AS FL
	ON  FL.facCod = F.facCod
	AND FL.facPerCod = F.facPerCod
	AND FL.facCtrCod = F.facCtrCod
	AND FL.facVersion = F.facVersion
	LEFT JOIN F0
	ON  F.facCod = F0.facCod
	AND F.facPerCod = F0.facPerCod
	AND F.facCtrCod = F0.facCtrCod
	AND F.facVersion = F0.facVersion
	ORDER BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, FL.fclImpuesto;

GO


