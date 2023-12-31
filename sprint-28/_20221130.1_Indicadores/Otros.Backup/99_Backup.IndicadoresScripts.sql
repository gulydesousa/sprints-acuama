USE [ACUAMA_GUADALAJARA_PRE]
GO
/****** Object:  UserDefinedFunction [Indicadores].[fAplicarParametros]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [Indicadores].[fAplicarParametros]
( @wDesde DATE
, @wHasta DATE
, @mDesde DATE
, @mHasta DATE
, @AGUA INT
, @ALCANTARILLADO INT
, @DOMESTICO INT
, @MUNICIPAL INT
, @INDUSTRIAL INT
, @LECTURANORMAL VARCHAR(2)
, @RECLAMACION VARCHAR(4)
, @INSPECCIONES VARCHAR(250))

RETURNS @RESULT TABLE(indAcr VARCHAR(5)
					, indPeriodicidad CHAR(1)
					, indFuncion VARCHAR(MAX)
					, indFuncionInfo VARCHAR(250)
					, indUnidad VARCHAR(15))
AS
BEGIN

DECLARE @wDesde_ VARCHAR(10);
DECLARE @wHasta_ VARCHAR(10);
DECLARE @wDesdeAnt VARCHAR(10);
DECLARE @wHastaAnt VARCHAR(10);

DECLARE @mDesde_ VARCHAR(10);
DECLARE @mHasta_ VARCHAR(10);
DECLARE @mDesdeAnt VARCHAR(10);
DECLARE @mHastaAnt VARCHAR(10);

DECLARE @aDesde VARCHAR(10);
DECLARE @aHasta VARCHAR(10);


DECLARE @LECTURANORMAL_ VARCHAR(10); 

SELECT @wDesde_			=  '''' + CONVERT(VARCHAR(10), @wDesde, 112) + ''''
	 , @wHasta_			=  '''' + CONVERT(VARCHAR(10), @wHasta, 112) + ''''
	 , @wDesdeAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(WEEK, -1, @wDesde), 112) + ''''
	 , @wHastaAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(WEEK, -1, @wHasta), 112) + ''''
	 
	 , @mDesde_			=  '''' + CONVERT(VARCHAR(10), @mDesde, 112) + ''''
	 , @mHasta_			=  '''' + CONVERT(VARCHAR(10), @mHasta, 112) + ''''
	 , @mDesdeAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(MONTH, -1, @mDesde), 112) + ''''
	 , @mHastaAnt		=  '''' + CONVERT(VARCHAR(10), DATEADD(MONTH, -1, @mHasta), 112) + ''''

	 , @aDesde			=  '''' + CONVERT(VARCHAR(10), DATEADD(YEAR, -1, @mDesde), 112) + ''''
	 , @aHasta			=  '''' + CONVERT(VARCHAR(10), @mHasta, 112) + ''''

	 , @LECTURANORMAL_	= ''''+ @LECTURANORMAL + ''''
	 , @RECLAMACION	= ''''+ @RECLAMACION + ''''
 
	


INSERT INTO @RESULT
SELECT indAcr
, indPeriodicidad
, REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(
  REPLACE(indFuncion, '@fDesdeAnt', IIF(C.indPeriodicidad = 'S', @wDesdeAnt, @mDesdeAnt))
					, '@fHastaAnt', IIF(C.indPeriodicidad = 'S', @wHastaAnt, @mHastaAnt))
					, '@fDesde', IIF(C.indPeriodicidad = 'S', @wDesde_, @mDesde_))
					, '@fHasta', IIF(C.indPeriodicidad = 'S', @wHasta_, @mHasta_))
					, '@AGUA', @AGUA)
					, '@ALCANTARILLADO', @ALCANTARILLADO)
					, '@DOMESTICO', @DOMESTICO)
					, '@MUNICIPAL', @MUNICIPAL)
					, '@INDUSTRIAL', @INDUSTRIAL)
					, '@LECTURANORMAL', @LECTURANORMAL_)
					, '@RECLAMACION', @RECLAMACION)
					, '@INDICADOR', CONCAT('@', indAcr))
					, '@INSPECCIONES', @INSPECCIONES)
					, '@aDesde', @aDesde)
					, '@aHasta', @aHasta)
, indFuncionInfo
, indUnidad
FROM Indicadores.IndicadoresConfig AS C
WHERE C.indActivo=1;


RETURN;



END
GO
/****** Object:  UserDefinedFunction [Indicadores].[fContadores_EdadMedia]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fechaRegistro DATE = '20221001'
SELECT Indicadores.Contadores_EdadMedia(@fechaRegistro)

*/

CREATE FUNCTION [Indicadores].[fContadores_EdadMedia](@fechaRegistro DATE)
RETURNS INT AS
BEGIN  

	DECLARE @RESULT INT;
	
	IF(@fechaRegistro IS NULL) SET @fechaRegistro=dbo.GetAcuamaDate();

	SET @fechaRegistro =DATEADD(DAY, 1, @fechaRegistro);

	SELECT @RESULT = AVG(DATEDIFF(YEAR, C.fechaFabricacion, @fechaRegistro))
	FROM dbo.vContadoresFecFabricacion AS C
	WHERE C.conFecReg < @fechaRegistro;

	RETURN @RESULT
	
END	

GO
/****** Object:  UserDefinedFunction [Indicadores].[fSemanas]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fecha DATE, @semanas INT;
DECLARE @RESULT TABLE (semana INT, fechaD DATE, fechaH DATE);

SELECT * FROM Indicadores.fSemanas(@fecha, @semanas)
*/

CREATE FUNCTION [Indicadores].[fSemanas](@fecha DATE, @semanas INT)
RETURNS @RESULT TABLE (semana INT, fLunes DATE, fDomingo DATE)
AS
BEGIN 

DECLARE @DATEFIRST INT = @@DATEFIRST; 
DECLARE @AHORA DATE = [dbo].[GetAcuamaDate]();
DECLARE @FECHAD DATE;
DECLARE @FECHAH DATE;

--**************************************************************
--Comprobamos que en SQL tengamos el lunes como el primer dia de la semana para continuar
IF (@DATEFIRST <> 1) RETURN;

SET @fecha = ISNULL(@fecha, @AHORA);
SET @semanas = ISNULL(@semanas, 12);

--First Day of Current Week (DATEFIRST)
SELECT @FECHAH = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @fecha), @fecha)
SELECT @FECHAD = DATEADD(WEEK, -@semanas, @FECHAH);


--****************************
INSERT INTO @RESULT
SELECT semana = N.number
, DATEADD(DAY,(N.number-1) *7,  @FECHAD)
, DATEADD(DAY,(N.number *7)-1,  @FECHAD) 
FROM master..spt_values N 
WHERE N.type = 'P' 
AND N.number BETWEEN 1 AND @semanas;

--SELECT * FROM @RESULT;

RETURN;

END
GO
/****** Object:  UserDefinedFunction [Indicadores].[fConsumoFacturaxSemana]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*


DECLARE @fDesde DATE='20220201';
DECLARE @fHasta DATE = '20220301';
DECLARE @srvCod INT = NULL;
DECLARE @esFacturada BIT = NULL;
DECLARE @usos VARCHAR(100) = '1';

SELECT SUM(VALOR) FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @srvCod, @esFacturada, @usos);

SELECT * FROM Indicadores.fConsumoFacturaxSemana (@fDesde, @fHasta, @srvCod, @esFacturada, @usos) ORDER BY SEMANA;
*/

CREATE FUNCTION [Indicadores].[fConsumoFacturaxSemana] 
( @fDesde DATE
, @fHasta DATE
, @srvCod INT = NULL
, @esFacturada BIT = NULL
, @usos VARCHAR(100) = NULL)
RETURNS TABLE 

AS
RETURN(

WITH U AS(
SELECT DISTINCT(value) FROM dbo.Split(@usos, ',')

), CNS AS(
SELECT --F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   --RN=1: Para contar el consumo una vez por factura
	   RN = ROW_NUMBER() OVER(PARTITION BY  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY FL.fclNumLinea),
	   F.facLecActFec,
	   F.facConsumoFactura, 
	   usoCod = U.value, 
	   SEMANA = (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1
	   
FROM dbo.facturas AS F
INNER JOIN dbo.contratos AS C
ON  C.ctrcod = F.facCtrCod
AND C.ctrversion = F.facCtrVersion
INNER JOIN dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND FL.fclFecLiq IS NULL 
AND F.facFechaRectif IS NULL
AND F.facLecActFec >= @fDesde 
AND F.facLecActFec < @fHasta
AND (@srvCod IS NULL OR FL.fclTrfSvCod = @srvCod)

AND ((@esFacturada IS NULL) OR 
	 
	 (@esFacturada = 1 AND (FL.fclPrecio<>0 OR FL.fclPrecio1<>0 OR FL.fclPrecio2<>0 OR FL.fclPrecio3<>0
	 OR FL.fclPrecio4<>0 OR FL.fclPrecio5<>0 OR FL.fclPrecio6<>0
	 OR FL.fclPrecio7<>0 OR FL.fclPrecio8<>0 OR FL.fclPrecio9<>0)) OR

	 (@esFacturada = 0 AND (FL.fclPrecio=0 AND FL.fclPrecio1=0 AND FL.fclPrecio2=0 AND FL.fclPrecio3=0
	 AND FL.fclPrecio4=0 AND FL.fclPrecio5=0 AND FL.fclPrecio6=0
	 AND FL.fclPrecio7=0 AND FL.fclPrecio8=0 AND FL.fclPrecio9=0))) 

LEFT JOIN U 
ON C.ctrUsoCod = U.value
)

SELECT SEMANA
	 , VALOR = SUM(facConsumoFactura)
FROM CNS
WHERE RN=1 
AND (@usos IS NULL OR usoCod IS NOT NULL )
GROUP BY SEMANA
) 

GO
/****** Object:  UserDefinedFunction [Indicadores].[fContadorCambio]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220201';

SELECT * FROM Indicadores.fContadorCambio (@fDesde, @fHasta)

*/

CREATE FUNCTION [Indicadores].[fContadorCambio] 
( @fDesde DATE, @fHasta DATE)
RETURNS TABLE

--Copiamos la select del informe CD008_ListadoCambiosContadores.rdl
RETURN(
SELECT CC.conCamOtSerCod
	 , CC.conCamOtSerScd
	 , CC.conCamOtNum
FROM dbo.contadorCambio AS CC
	INNER JOIN ordenTrabajo ON conCamOtSerScd = otserscd AND conCamOtSerCod = otsercod AND conCamOtNum = otnum
	INNER JOIN contratos c1 ON otCtrCod = ctrcod AND ctrversion = (SELECT MAX(ctrversion) FROM contratos c2 WHERE c1.ctrcod = c2.ctrcod)
	INNER JOIN inmuebles ON inmcod = ctrinmcod
	INNER JOIN contador contadorIns ON contadorIns.conID = conCamConID
	INNER JOIN marcon marConIns ON marconIns.mcncod = contadorIns.conMcnCod
	LEFT JOIN ctrcon ctrConRet ON ctcCtr = otCtrCod AND ctcOperacion = 'R' AND ctcFec = conCamFecha
	INNER JOIN contador contadorRet ON contadorRet.conID = ctcCon
	INNER JOIN marcon marConRet ON marconRet.mcncod = contadorRet.conMcnCod
	INNER JOIN usos ON ctrUsoCod = usocod
WHERE
    (CC.conCamFecha >= @fDesde) AND (CC.conCamFecha <@fHasta))

GO
/****** Object:  UserDefinedFunction [Indicadores].[fContadoresInstalados]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

SELECT COUNT(ctcCon) FROM dbo.fContratos_ContadoresInstalados('20230201') WHERE ctcCon IS NOT NULL

DECLARE @fecha AS DATE = '20230201';

SELECT * FROM Indicadores.fContadoresInstalados(@fecha)

*/

CREATE FUNCTION [Indicadores].[fContadoresInstalados](@fecha DATE)
RETURNS TABLE AS
RETURN
(
WITH A AS(
SELECT conId
, ctrcod
, conNumSerie
--RN=1: Para quedarnos con la ultima instalacion del contrato
, RN= ROW_NUMBER() OVER(PARTITION BY ctrcod ORDER BY  [I.ctcFec] DESC)
FROM dbo.vCambiosContador
WHERE [I.ctcFec] < @fecha
AND ([R.ctcFec] IS NULL OR [R.ctcFec] >= @fecha)
) 

SELECT conId
, ctrCod
, conNumSerie
FROM A WHERE RN = 1
)

GO
/****** Object:  UserDefinedFunction [Indicadores].[fContratos]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [Indicadores].[fContratos]
( @fDesde DATE
, @fHasta DATE
, @ctrUso INT
, @esDomiciliado BIT)
RETURNS TABLE
AS
RETURN(

WITH CTR AS(
SELECT C.ctrcod
, C.ctrversion
, C.ctrfecreg
, C.ctrfecanu
, C.ctrbaja
, C.ctrTitDocIden
, C.ctrPagDocIden
, Pagador = ISNULL(C.ctrPagDocIden, C.ctrTitDocIden)
, C.ctrIban
, C.ctrUsoCod
, RN = ROW_NUMBER() OVER (Partition BY C.ctrcod ORDER BY C.ctrversion DESC)
FROM dbo.contratos AS C 
WHERE (C.ctrfecreg  < @fHasta) AND 
	  (C.ctrfecanu IS NULL OR C.ctrfecanu >=@fDesde)
) 

SELECT * 
FROM CTR AS C
WHERE RN=1
AND (@ctrUso IS NULL OR C.ctrUsoCod = @ctrUso) 
AND (@esDomiciliado IS NULL OR (@esDomiciliado=1 AND C.ctrIban IS NOT NULL) OR (@esDomiciliado=0 AND C.ctrIban IS NULL)) 
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fDevolucionesBancarias]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SELECT * FROM Indicadores.fDevolucionesBancarias ('20220101', '20220131')

CREATE FUNCTION [Indicadores].[fDevolucionesBancarias]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

SELECT C.cobNum, C.cobScd, C.cobPpag, C.cobFec
FROM dbo.cobros AS C 
WHERE C.cobDevCod IS NOT NULL 
  AND C.cobFec >=@fDesde 
  AND C.cobFec <@fHasta
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fExpedientesCorte]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SELECT * FROM [Indicadores].[fExpedientesCorte] ('20200101', '20220731')

CREATE FUNCTION [Indicadores].[fExpedientesCorte]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(
SELECT excNumExp 
FROM dbo.expedientesCorte 
WHERE excFechaCorte IS NOT NULL  
  AND excfechacierreExp IS NOT NULL
  AND excfechacierreExp >=@fDesde AND excfechacierreExp <@fHasta 
  AND excFechaCorte >=@fDesde AND  excFechaCorte <@fHasta
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fFacturasErroneas]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT * FROM [Indicadores].[fFacturasErroneas] ('20220101', '20220131')

CREATE FUNCTION [Indicadores].[fFacturasErroneas]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS

RETURN(

SELECT DISTINCT facCod, facPerCod, facCtrCod
--SELECT facCod, facPerCod, facCtrCod, facVersion, facSerCod
FROM dbo.facturas AS F
WHERE F.facSerCod IN(SELECT sersercodrelac FROM dbo.series AS S WHERE S.sersercodrelac IS NOT NULL)
AND (F.facFecha >= @fDesde AND F.facfecha <@fHasta)
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fFacturasRangoCnsxSemana]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
DECLARE @cnsDesde INT = 10;
DECLARE @cnsHasta INT = 15;


SELECT * FROM Indicadores.fFacturasRangoCnsxSemana (@fDesde, @fHasta, @cnsDesde, @cnsHasta);
*/

CREATE FUNCTION [Indicadores].[fFacturasRangoCnsxSemana] 
( @fDesde DATE
, @fHasta DATE
, @cnsDesde INT = NULL
, @cnsHasta INT = NULL)
RETURNS TABLE 

AS
RETURN(

WITH FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   F.facLecActFec,
	   facConsumoFactura = ISNULL(F.facConsumoFactura, 0), 
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1
FROM dbo.facturas AS F
WHERE (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta)
  AND (F.facLecActFec >= @fDesde AND F.facLecActFec < @fHasta)
  AND (@cnsDesde IS NULL OR  ISNULL(F.facConsumoFactura, 0) >= @cnsDesde)
  AND (@cnsHasta IS NULL OR  ISNULL(F.facConsumoFactura, 0) <= @cnsHasta)

)
SELECT SEMANA
	 , VALOR = COUNT(facCod)
FROM FACS
GROUP BY SEMANA
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fFacturasxInspeccion]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220201';
--DECLARE @tInspecciones VARCHAR(250) = NULL;
DECLARE @tInspecciones VARCHAR(250) = '1,4,5';

SELECT * FROM Indicadores.fFacturasxInspeccion (@fDesde, @fHasta, @tInspecciones)
*/

CREATE FUNCTION [Indicadores].[fFacturasxInspeccion]
( @fDesde DATE
, @fHasta DATE
, @tInspecciones VARCHAR(250) = NULL)
RETURNS TABLE 

AS
RETURN(


--Inspecciones para filtrar
WITH I (facInspeccion) AS (
SELECT DISTINCT(value) FROM dbo.Split(@tInspecciones, ',')

--Facturas no rectificadas por fecha de inspección
), FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion
	 , facInspeccion = ISNULL(F.facInspeccion, '')
FROM dbo.facturas AS F 
WHERE  F.facLecInspectorFec >= @fDesde 
   AND F.facLecInspectorFec < @fHasta
   AND F.facFechaRectif IS NULL)

SELECT  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facInspeccion
FROM FACS AS F 
LEFT JOIN I
ON I.facInspeccion = F.facInspeccion
WHERE (@tInspecciones IS NULL OR @tInspecciones = '' OR I.facInspeccion IS NOT NULL)
  
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fFacturaxSemana]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
DECLARE @cnsDesde INT = NULL;
DECLARE @cnsHasta INT = NULL;
DECLARE @srvCod INT = NULL;
DECLARE @incilec VARCHAR(MAX) = '10, 11, 12, 14 ';

SELECT * FROM Indicadores.fFacturaxSemana (@fDesde, @fHasta, @cnsDesde, @cnsHasta, @srvCod, @incilec);

*/

CREATE FUNCTION [Indicadores].[fFacturaxSemana] 
( @fDesde DATE
, @fHasta DATE
, @cnsDesde INT = NULL
, @cnsHasta INT = NULL
, @srvCod INT = NULL
, @incilec VARCHAR(MAX) = NULL)
RETURNS TABLE 

AS
RETURN(

WITH IL (inlCod) AS (

SELECT DISTINCT(value) FROM dbo.Split(@incilec, ',')

), CNS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   F.facLecActFec,
	   facConsumoFactura = ISNULL(F.facConsumoFactura, 0), 
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1,
	   inlCod	= I.inlCod
FROM dbo.facturas AS F
LEFT JOIN IL AS I 
ON I.inlCod = ISNULL(F.facInsInlCod, '')

WHERE F.facFechaRectif IS NULL
AND F.facLecActFec >= @fDesde 
AND F.facLecActFec < @fHasta
AND (@cnsDesde IS NULL OR  ISNULL(F.facConsumoFactura, 0) >= @cnsDesde)
AND (@cnsHasta IS NULL OR  ISNULL(F.facConsumoFactura, 0) <= @cnsDesde)
AND (@incilec IS NULL OR I.inlCod IS NOT NULL)

), FL AS(
SELECT F.*
--RN=1: Para quedarnos con una ocurrencia por factura y servicio
, RN= ROW_NUMBER() OVER (PARTITION  BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion ORDER BY FL.fclNumLinea)
, fclTrfSvCod = ISNULL(FL.fclTrfSvCod, 0)
FROM CNS AS F
LEFT JOIN dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND FL.fclTrfSvCod = ISNULL(@srvCod, 0))

SELECT SEMANA
	 , VALOR = COUNT(facConsumoFactura)
FROM FL
WHERE RN=1
AND (@srvCod IS NULL OR fclTrfSvCod = @srvCod)
GROUP BY SEMANA
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fIncidenciasLecturaxSemana]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
--DECLARE @incilec VARCHAR(MAX) = NULL;	--Trae todas 
--DECLARE @incilec VARCHAR(MAX) = '';	--Trae todas 
--DECLARE @incilec VARCHAR(MAX) = ',';	--Sin incidencia de lectura
DECLARE @incilec VARCHAR(MAX) = '10,14, 11';	--Con incidencia de lectura

SELECT * FROM Indicadores.fIncidenciasLecturaxSemana (@fDesde, @fHasta, @incilec);
*/


CREATE FUNCTION [Indicadores].[fIncidenciasLecturaxSemana] 
( @fDesde DATE
, @fHasta DATE
, @incilec VARCHAR(MAX) = NULL)
RETURNS TABLE 

AS
RETURN(

WITH IL (inlCod) AS (

SELECT DISTINCT(value) FROM dbo.Split(@incilec, ',')

), FACS AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero,
	   F.facLecActFec, 
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1,
	   F.facInsInlCod
FROM dbo.facturas AS F
LEFT JOIN IL AS I 
ON I.inlCod = ISNULL(F.facInsInlCod, '')

WHERE (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta)
  AND (F.facLecActFec >= @fDesde AND F.facLecActFec < @fHasta)
  AND (@incilec IS NULL OR @incilec = '' OR I.inlCod IS NOT NULL))

SELECT SEMANA
	 , VALOR = COUNT(facCod)
FROM FACS
GROUP BY SEMANA

)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fMediaRespuestasReclamaciones]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SELECT * FROM Indicadores.fContratos ('20220101', '20220131', NULL, 1)

CREATE FUNCTION [Indicadores].[fMediaRespuestasReclamaciones]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

select sum(datediff(D,rclFecReg, rclFecCierre))/count(*) as media from reclamaciones where rclGRecCod = 'RS'

and reclamaciones.rclFecReclama >=@fDesde and reclamaciones.rclFecReclama <@fHasta


)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fPosiblesCortes]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SELECT * FROM [Indicadores].[fPosiblesCortes] ('20220101', '20230131')

CREATE FUNCTION [Indicadores].[fPosiblesCortes]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

SELECT E.excNumExp, E.excFechaReg
FROM dbo.expedientesCorte AS E 
WHERE E.excFechaCorte IS NULL  
  AND E.excfechacierreExp IS NULL
  AND E.excFechaReg >=@fDesde 
  AND E.excFechaReg < @fHasta


)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fReclamaciones]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT * FROM Indicadores.fReclamaciones ('20220101', '20220131', '11')

CREATE FUNCTION [Indicadores].[fReclamaciones]
( @fDesde DATE
, @fHasta DATE
, @greclamacion VARCHAR(4) = NULL)
RETURNS TABLE
AS
RETURN(

SELECT R.rclCod, R.rclGRecCod
FROM dbo.reclamaciones AS R
WHERE R.rclFecReclama >= @fDesde AND R.rclFecReclama<@fHasta
AND (@greclamacion IS NULL OR R.rclGRecCod = @greclamacion)
)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fRectificativasxSemana]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fDesde DATE='20210101';
DECLARE @fHasta DATE = '20210201';
DECLARE @RectificaCns BIT = 1;

SELECT * FROM Indicadores.fRectificativasxSemana (@fDesde, @fHasta, @RectificaCns)
*/

CREATE FUNCTION [Indicadores].[fRectificativasxSemana] 
( @fDesde DATE
, @fHasta DATE
, @RectificaCns BIT = NULL)

RETURNS TABLE 

AS
RETURN(

WITH FAC AS(
SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero, F.facFecha, F.facSerCod, 
	   F.facLecActFec,
	   facConsumoFactura= ISNULL(F.facConsumoFactura, 0), 
	   SEMANA = (DATEDIFF(DAY, @fDesde, facLecActFec)/7)+1
FROM dbo.facturas AS F
WHERE F.facLecActFec >= @fDesde 
  AND F.facLecActFec < @fHasta
  AND F.facFechaRectif IS NULL
  AND F.facFecha IS NOT NULL

), FAC0 AS(
SELECT  F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, F.facNumero, F.facConsumoFactura
, facVersion_Rectificada = F0.facVersion, facNumero_Rectificada = F0.facNumero, facConsumo_Rectificada = ISNULL(F0.facConsumoFactura, 0)
, F.SEMANA
--RN= 1: Por garantizar que hay una sola rectificativa por factura
, RN = ROW_NUMBER() OVER(PARTITION BY  F0.facCod, F0.facPerCod, F0.facCtrCod ORDER BY F0.facVersion DESC)
FROM FAC AS F
INNER JOIN facturas AS F0 
ON  F.facCod = F0.facCod
AND F.facPerCod = F0.facPerCod
AND F.facCtrCod = F0.facCtrCod
AND F0.facFechaRectif IS NOT NULL
AND F0.facFechaRectif = F.facFecha
AND F0.facSerieRectif = F.facSerCod
AND F0.facNumeroRectif = F.facNumero
)

SELECT SEMANA
	 , VALOR = COUNT(facConsumoFactura)
FROM FAC0
WHERE RN=1 
AND ( (@RectificaCns IS NULL) 
   OR (@RectificaCns=1 AND facConsumoFactura<>facConsumo_Rectificada) 
   OR (@RectificaCns=0 AND facConsumoFactura=facConsumo_Rectificada))
GROUP BY SEMANA
) 

GO
/****** Object:  UserDefinedFunction [Indicadores].[fRespuestasReclamaciones]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--SELECT * FROM greclamacion
--SELECT [VALOR] = AVG(dRespuesta) FROM [Indicadores].[fRespuestasReclamaciones]('20220101', '20221201', @RECLAMACION) WHERE rclFecCierre IS NOT NULL

CREATE FUNCTION [Indicadores].[fRespuestasReclamaciones]
( @fDesde DATE
, @fHasta DATE
, @rclGRecCod VARCHAR(4)
)
RETURNS TABLE
AS
RETURN(

SELECT rclCod, rclGRecCod, rclFecReg, rclFecCierre, dRespuesta = DATEDIFF(DAY, rclFecReg, rclFecCierre) + 0.00
FROM dbo.reclamaciones AS R 
WHERE R.rclFecReclama >=@fDesde 
  AND R.rclFecReclama <@fHasta
  AND (@rclGRecCod IS NULL OR @rclGRecCod='' OR rclGRecCod=@rclGRecCod)

)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fServiciosCuotasxSemana]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fDesde DATE='20220101';
DECLARE @fHasta DATE = '20220301';
DECLARE @srvCod AS VARCHAR(25) = '1,23'
DECLARE @incilec VARCHAR(MAX) = '10, 11, 12, 14 ';

SELECT * FROM [Indicadores].[fServiciosCuotasxSemana] (@fDesde, @fHasta, @srvCod);

*/
CREATE FUNCTION [Indicadores].[fServiciosCuotasxSemana] 
( @fDesde DATE
, @fHasta DATE
, @srvCod AS VARCHAR(25))
RETURNS TABLE 


AS
RETURN(

WITH SVC(svcCod) AS(
--Servicios que buscamos
SELECT [value] FROM dbo.Split(@srvCod, ',')

), FACS AS(

SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion,
	   SEMANA	= (DATEDIFF(DAY, @fDesde, facFecha)/7)+1	 
FROM dbo.facturas AS F
WHERE (F.facFechaRectif IS NULL OR F.facFechaRectif>=@fHasta)
  AND (F.facFecha IS NOT NULL AND F.facFecha>= @fDesde AND F.facFecha < @fHasta) 

), FL AS(
SELECT F.*
, FL.fclTrfSvCod 
--RN=1: Para quedarnos con una ocurrencia por factura y servicio
, RN= ROW_NUMBER() OVER (PARTITION  BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, FL.fclTrfSvCod ORDER BY FL.fclNumLinea)
FROM FACS AS F
INNER JOIN  dbo.faclin AS FL
ON F.facCod = FL.fclFacCod
AND F.facPerCod = FL.fclFacPerCod
AND F.facCtrCod = FL.fclFacCtrCod
AND F.facVersion = FL.fclFacVersion
AND (FL.fclFecLiq IS NULL OR FL.fclFecLiq>=@fHasta)
INNER JOIN SVC AS S
ON S.svcCod = FL.fclTrfSvCod)

SELECT SEMANA
 , VALOR = COUNT(fclTrfSvCod) 
FROM FL
WHERE RN=1
GROUP BY SEMANA

)
GO
/****** Object:  UserDefinedFunction [Indicadores].[fUsuariosActivosOV]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT * FROM [Indicadores].[fUsuariosActivosOV] ('20220101', '20220131')

CREATE FUNCTION [Indicadores].[fUsuariosActivosOV]
( @fDesde DATE
, @fHasta DATE
)
RETURNS TABLE
AS
RETURN(

WITH CTR AS(
SELECT ctrCod, ctrVersion
, ctrTitDocIden = RTRIM(LTRIM(ISNULL(ctrTitDocIden, '')))
, ctrPagDocIden = RTRIM(LTRIM(ISNULL(ctrPagDocIden, '')))
--RN=1: Para la última versión del contrato
, RN= ROW_NUMBER() OVER (PARTITION BY ctrCod ORDER BY ctrVersion DESC)
FROM dbo.contratos AS C
WHERE C.ctrfecreg < DATEADD(DAY, 1, @fDesde) 
 AND (C.ctrfecanu IS NULL OR C.ctrfecanu < @fDesde)

), DOCS AS(
--Combinaciones de titulares y pagadores en la ultima version de contrato
SELECT DISTINCT ctrTitDocIden = RTRIM(LTRIM(ISNULL(ctrTitDocIden, '')))
              , ctrPagDocIden = RTRIM(LTRIM(ISNULL(ctrPagDocIden, '')))
FROM CTR AS C 
WHERE RN=1

), DOCIDEN AS(
--Documentos de identidad diferentes bien sea titular o pagador en los contratos
SELECT DISTINCT id= ctrTitDocIden FROM DOCS
UNION 
SELECT DISTINCT id = ctrPagDocIden FROM DOCS
)


--Usuarios de la OV que aparecen como titular o pagador en algun contrato activo en el rango de fechas
SELECT usrLogin
FROM dbo.online_Usuarios AS U
INNER JOIN DOCIDEN AS D
ON D.id = U.usrLogin

)
GO
/****** Object:  StoredProcedure [Indicadores].[Facturas_ConDeuda]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE @fecha DATE = '20220201'
DECLARE @minDeuda MONEY = 0.01;
DECLARE @diasVencimiento INT = 120;
DECLARE @usos VARCHAR(MAX) = '4';
DECLARE @tipoSalida TINYINT = 0;
DECLARE @periodosConsumo BIT = 0

DECLARE @result INT;

EXEC Indicadores.Facturas_ConDeuda @fecha, @minDeuda, @diasVencimiento, @usos, @periodosConsumo, @tipoSalida,  @result OUTPUT;

SELECT @result
*/

CREATE PROCEDURE [Indicadores].[Facturas_ConDeuda](
@fecha DATE
, @minDeuda MONEY
, @diasVencimiento INT
, @usos VARCHAR(MAX)
, @periodosConsumo BIT
, @tipoSalida TINYINT
, @result INT OUTPUT)
AS 

--********
--@tipoSalida: 0 => Detalle por factura
--@tipoSalida: 1 => Numero de facturas
--@tipoSalida: 2 => Numero de distintos contratos

--********
--[01] Parametros de configuración
--********
DECLARE @BARCODE_FECHAVTO INT =  1;
DECLARE @DIAS_PAGO_VOLUNTARIO INT =  0;
DECLARE @DIAS_VTO_C57_POR_DEFECTO INT =  0; 
DECLARE @SCD_REMESA INT = 0;

SELECT @BARCODE_FECHAVTO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='BARCODE_FECHAVTO'; --1:SegunFactura, 2:SiempreFuturo, 3:SinFecha
SELECT @DIAS_PAGO_VOLUNTARIO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='DIAS_PAGO_VOLUNTARIO';
SELECT @DIAS_VTO_C57_POR_DEFECTO = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='DIAS_VTO_C57_POR_DEFECTO';
SELECT @SCD_REMESA = p.pgsvalor FROM dbo.parametros AS P WHERE P.pgsclave='SOCIEDAD_REMESA';


SELECT @usos = ISNULL(@usos, ''), @tipoSalida = ISNULL(@tipoSalida, 0);

BEGIN TRY
	--********
	--[02] #FACS: FACTURAS x USO
	--********
	WITH U AS(
	SELECT DISTINCT(value) 
	FROM dbo.Split(@usos, ',') 
	WHERE [value] IS NOT NULL

	), FACS AS(
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion 
	, C.ctrUsoCod
	, facScd	 = IIF(@SCD_REMESA > 0, @SCD_REMESA, F.facSerScdCod)
	, facFecha	 = CAST(F.facFecha AS DATE)
	, facTotal	 = CAST(0 AS MONEY)
	, facCobrado = CAST(0 AS MONEY)
	, facDeuda	 = CAST(0 AS MONEY)
	, fecVto	 = CAST(NULL AS DATE)
	, RN		 = ROW_NUMBER() OVER(PARTITION BY F.facCod, F.facPerCod, F.facCtrCod ORDER BY F.facVersion  DESC)
	FROM dbo.facturas AS F 
	INNER JOIN dbo.vContratosUltimaVersion AS V
	ON V.ctrCod = F.facCtrCod
	INNER JOIN dbo.contratos AS C
	ON  C.ctrcod = V.ctrCod
	AND C.ctrversion = V.ctrVersion
	LEFT JOIN U
	ON C.ctrUsoCod = U.[value]
	WHERE (facFecha IS NOT NULL) 
	  AND (facFecha < @fecha)
	  AND (F.facFechaRectif IS NULL OR F.facFechaRectif>= @fecha)
	  AND (@usos = '' OR (U.[value] IS NOT NULL))
	  AND (@periodosConsumo IS NULL OR @periodosConsumo = IIF(LEFT(F.facPerCod, 1) NOT IN ('0', '9'), 1, 0)))

	SELECT facCod, facPerCod, facCtrCod, facVersion
	, facScd
	, ctrUsoCod
	, facFecha
	, fecVto
	, facTotal
	, facCobrado
	, facDeuda
	INTO #FACS 
	FROM FACS 
	WHERE RN=1
	OPTION (OPTIMIZE FOR UNKNOWN);

	--********
	--[03]fclTotal: Totales por factura
	--********
	WITH FACT AS(
	SELECT F.facCod, F.facPerCod, F.facCtrCod, F.facVersion, fclTotal = SUM(fclTotal) 
	FROM dbo.faclin AS FL
	INNER JOIN #FACS AS F
	ON F.facCod = FL.fclFacCod
	AND F.facPerCod = FL.fclFacPerCod
	AND F.facCtrCod = FL.fclFacCtrCod
	AND F.facVersion = FL.fclFacVersion
	AND (FL.fclFecLiq IS NULL OR  FL.fclFecLiq>@fecha)
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)

	UPDATE F SET facTotal = T.fclTotal
	FROM #FACS AS F
	INNER JOIN FACT AS T
	ON  F.facCod	= T.facCod 
	AND F.facPerCod = T.facPerCod 
	AND F.facCtrCod = T.facCtrCod
	AND F.facVersion= T.facVersion
	OPTION (OPTIMIZE FOR UNKNOWN);

	--********
	--[04]cblImporte: Total cobrado por cabecera de factura
	--********
	WITH COBT AS(
	SELECT F.facCod
	, F.facPerCod
	, F.facCtrCod
	, F.facVersion
	, cblImporte = SUM(CL.cblImporte)
	FROM dbo.cobros AS C 
	INNER JOIN dbo.coblin AS CL 
	ON  C.cobScd = CL.cblScd 
	AND C.cobPpag = CL.cblPpag 
	AND C.cobNum =CL.cblNum
	AND C.cobFec < @fecha
	INNER JOIN #FACS AS F
	ON F.facCod = CL.cblFacCod
	AND F.facPerCod = CL.cblPer
	AND F.facCtrCod = C.cobCtr
	AND F.facVersion = CL.cblFacVersion
	GROUP BY F.facCod, F.facPerCod, F.facCtrCod, F.facVersion)

	UPDATE F 
	SET facCobrado = T.cblImporte
	  , facDeuda = ROUND(F.facTotal, 2) - ROUND(T.cblImporte, 2)
	FROM #FACS AS F
	INNER JOIN COBT AS T
	ON  F.facCod	= T.facCod 
	AND F.facPerCod = T.facPerCod 
	AND F.facCtrCod = T.facCtrCod
	AND F.facVersion= T.facVersion
	OPTION (OPTIMIZE FOR UNKNOWN);


	--********
	--[05]fecVto: Fecha de vencimiento con el mismo criterio usado en el codigo de barras en:
	--ReportingServices.CF010_EmisionFacTotales_CodigoBarras
	--********
	UPDATE F SET 
	fecVto = CASE @BARCODE_FECHAVTO 
			   --1:SegunFactura
			   WHEN 1 THEN
			   CASE WHEN P.perFecFinPagoVol IS NOT NULL THEN P.perFecFinPagoVol
					WHEN F.facFecha IS NOT NULL			THEN DATEADD(DAY, @DIAS_PAGO_VOLUNTARIO, F.facFecha)
					WHEN F.facFecha IS NULL				THEN DATEADD(DAY, @DIAS_PAGO_VOLUNTARIO, @fecha)
					ELSE ISNULL(F.facFecha, @fecha) 
					END 
			   --2:SiempreFuturo
			   WHEN 2 THEN 
			   CASE WHEN P.perFecFinPagoVol IS NOT NULL AND P.perFecFinPagoVol > @fecha THEN  P.perFecFinPagoVol  
					WHEN SS.scdDiasVtoC57 IS NOT NULL AND SS.scdDiasVtoC57 > 0			THEN  DATEADD(DAY, SS.scdDiasVtoC57 , @fecha)
					WHEN @DIAS_VTO_C57_POR_DEFECTO > 0									THEN  DATEADD(DAY, @DIAS_VTO_C57_POR_DEFECTO, @fecha)
					ELSE NULL
					END
			   --3: Sin Fecha
			   ELSE NULL END

	FROM #FACS AS F
	INNER JOIN dbo.periodos AS P
	ON P.percod = F.facPerCod
	LEFT JOIN dbo.sociedades AS SS
	ON SS.scdcod = F.facScd
	WHERE @diasVencimiento IS NOT NULL
	OPTION (OPTIMIZE FOR UNKNOWN);


	--********
	--[10]#RESULT: Facturas que cumplen los filtros.
	--********
	SELECT * 
	, [DiasPostVencimiento] = IIF(fecVto IS NULL, 0, DATEDIFF(DAY, fecVto, @fecha))
	INTO #RESULT
	FROM #FACS AS F
	WHERE F.facTotal > 0 
		AND F.facDeuda <> 0
		AND (@minDeuda IS NULL OR F.facDeuda>=@minDeuda)
		AND (@diasVencimiento IS NULL OR IIF(fecVto IS NULL, 0, DATEDIFF(DAY, fecVto, @fecha)) > @diasVencimiento);


	--********
	--[99]Salida por tipo.
	--********
	IF (@tipoSalida = 0)
	BEGIN
		SELECT * 
		FROM #RESULT ORDER BY facDeuda DESC;

		SELECT @result= @@ROWCOUNT;
	END
	ELSE IF(@tipoSalida = 1)
	BEGIN	
		SELECT @result = COUNT(*) FROM #RESULT;
	END
	ELSE IF(@tipoSalida = 2)
	BEGIN
		SELECT @result = COUNT(DISTINCT facCtrCod) FROM #RESULT;
	END

	END TRY

	BEGIN CATCH
	END CATCH
	

	IF OBJECT_ID('tempdb..#FACS') IS NOT NULL DROP TABLE #FACS;
	IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL DROP TABLE #RESULT;

GO
/****** Object:  StoredProcedure [InformesExcel].[Indicadores]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
****** CONFIGURACION ******
DROP PROCEDURE [InformesExcel].[Indicadores_Acuama] 
DELETE ExcelPerfil WHERE ExPCod='000/900'
DELETE ExcelConsultas WHERE ExcCod='000/900'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/900',	'Indicadores: Acuama', 'Consulta de Indicadores', 20, '[InformesExcel].[Indicadores]', '000', 'Informe preliminar para la consulta de los indicadores: Mensuales y Semanales a la fecha indicada como parámetro', NULL);

INSERT INTO ExcelPerfil
SELECT '000/900', prfcod , 3, NULL FROM Perfiles

*/

/*

DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha></Fecha><Semanas>12</Semanas></LI></NodoXML>';

EXEC [InformesExcel].[Indicadores] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/


CREATE PROCEDURE [InformesExcel].[Indicadores]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--**********
	--PARAMETROS: 
	--[1]Fecha: Fecha
	--NULL=>Recuperamos las ayudas hasta la fecha actual
	--**********

	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (Fecha)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (Fecha DATE NULL, Semanas INT NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT Fecha	= CASE WHEN M.Item.value('Fecha[1]', 'DATE') = '19000101' THEN dbo.GetAcuamaDate()
					  ELSE M.Item.value('Fecha[1]', 'DATE') END
					  
		, Semanas   = CASE WHEN M.Item.value('Semanas[1]', 'INT') = 0 THEN 12
						ELSE M.Item.value('Semanas[1]', 'INT') END

		 , fInforme = GETDATE() 
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	DECLARE @fecha DATE;
	SELECT @fecha = Fecha from @params;
	
	--***** V A R I A B L E S ******
	--***** * S E M A N A L * ******
	CREATE TABLE #FSEMANAS   (semana INT
							 , fLunes DATE
							 , fDomingo DATE
							 , _fLunes AS DATEADD(DAY, 1, fDomingo));

	DECLARE @wDesde DATE;
	DECLARE @wHasta DATE;
	DECLARE @Semanas INT;
	DECLARE @AGUA INT = 1;
	DECLARE @ALCANTARILLADO INT = 0;
	DECLARE @DOMESTICO INT = 1;
	DECLARE @MUNICIPAL INT = 3;
	DECLARE @INDUSTRIAL INT = 4;
	DECLARE @LECTURANORMAL VARCHAR(25) = '1, ';
	DECLARE @RECLAMACION VARCHAR(4) = '11';
	
	SELECT @Semanas = Semanas FROM @params;

	DECLARE @USOS AS VARCHAR(50);
	SELECT @USOS = COALESCE(@USOS + ',', '') + CAST(U.usocod AS VARCHAR(5))
	FROM dbo.usos AS U;

	
	DECLARE @INSPECCIONES VARCHAR(250);
	WITH I AS (SELECT DISTINCT facInspeccion FROM facturas WHERE facInspeccion IS NOT NULL )
	SELECT @INSPECCIONES = COALESCE(@INSPECCIONES+ ',' , '') + CAST(facInspeccion AS VARCHAR(5)) 
	FROM  I ;

	DECLARE @RESULT INT = NULL;

	DECLARE @INDICADORES AS [Indicadores].[tIndicadores_Semanal];

	
	--***** V A R I A B L E S ******
	--***** * M E N S U A L * ******
	DECLARE @mDesde DATE;
	DECLARE @mHasta DATE;
	DECLARE @mesHasta VARCHAR(8);

	SELECT @mHasta = DATEADD(DAY, -DAY(@fecha), @fecha);
	SELECT @mesHasta = FORMAT(@mHasta, 'yyyyMMdd');

	SELECT @mDesde = DATEADD(DAY, 1-DAY(@mHasta), @mHasta)
		 , @mHasta = DATEADD(DAY, 1, @mHasta);
	
	--******************************
	DECLARE @INDICADOR AS VARCHAR(5);
	DECLARE @FN AS VARCHAR(MAX);
	DECLARE @PER AS  VARCHAR(1);
	DECLARE @UD AS  VARCHAR(15);
	DECLARE @DML AS VARCHAR(500);
	DECLARE @EXEC AS VARCHAR(MAX);
	

	--******************************
	SELECT @AGUA = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE P.pgsclave= 'SERVICIO_AGUA';

	--Buscamos el alcantarillado por la explotación
	SELECT @ALCANTARILLADO = svccod 
	FROM dbo.servicios AS S
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND S.svcdes='Alcantarillado');

	--Buscamos el uso por la explotación
	SELECT @DOMESTICO = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='DOMESTICO');

	--Buscamos el uso por la explotación
	SELECT @MUNICIPAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='MUNICIPAL');
	
	SELECT @INDUSTRIAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='INDUSTRIAL');
	
	SELECT @LECTURANORMAL = CONCAT(I.inlcod, ', ')
	FROM dbo.incilec AS I
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND I.inldes='LECTURA NORMAL');

	SELECT @RECLAMACION = R.grecod
	FROM dbo.greclamacion AS R
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND R.grecod='RS');



	--******************************
	INSERT INTO #FSEMANAS
	SELECT * FROM Indicadores.fSemanas(@Fecha, @Semanas);


	IF (@@ROWCOUNT= 0) RETURN;

	SELECT @wDesde = MIN(fLunes)
		 , @wHasta = DATEADD(DAY, 1, MAX(fDomingo))
	FROM #FSEMANAS;
	--******************************
	


	--******** P A R A M E T R O S ************
	--DataTable[1]:  Parametros 
	SELECT 
	  [Semanas] = (SELECT COUNT(*) FROM #FSEMANAS)
	, [Semanal Desde] = @wDesde
	, [Semanal Hasta] = DATEADD(DAY, -1, @wHasta)
	, fInforme 
	, [Mes] = UPPER(FORMAT(@mDesde, 'MMMyyyy'))
	, [Mes Desde] = @mDesde
	, [Mes Hasta] = DATEADD(D, -1, @mHasta)
	, [Fecha]
	FROM @params


	--******  P L A N T I L L A S  ******
	DECLARE @UPDATE AS VARCHAR(250) = 
	'UPDATE I SET I.[INDICADOR] = FN.VALOR FROM ([FN]) AS FN INNER JOIN #IND_SEMANAL AS I ON I.SEMANA = FN.SEMANA';
	
	DECLARE @INSERT AS VARCHAR(250) = 
	'INSERT INTO #IND_MENSUAL SELECT ''[INDICADOR]'', ([FN]), ''[UNIDAD]'';';

	DECLARE @INSERT_RESULT AS VARCHAR(250) = 
	'DECLARE @[INDICADOR] VARCHAR(25); ' +
	'[FN];' +
	'INSERT INTO #IND_MENSUAL SELECT ''[INDICADOR]'', @[INDICADOR], ''[UNIDAD]'';';
	
	DECLARE @SELECT_UDS AS VARCHAR(MAX) = 
	'SELECT SEMANA, [F.Desde], [F.Hasta]';
	
	--Necesitaremos una tabla temporal para poder hacerlo por cursor.
	SELECT * INTO #IND_SEMANAL FROM @INDICADORES;
	CREATE  TABLE #IND_MENSUAL (INDICADOR VARCHAR(5), VALOR VARCHAR(25), UNIDAD VARCHAR(15)); 

	INSERT INTO #IND_SEMANAL([SEMANA], [F.Desde], [F.Hasta])
	SELECT semana, fLunes, fDomingo FROM #FSEMANAS;

	
	--******** C U R S O R *********
	SELECT indAcr
	, indFuncion

	, DML= CASE WHEN indPeriodicidad='S' THEN @UPDATE
				WHEN UPPER(LTRIM(indFuncion)) LIKE 'SELECT%' THEN @INSERT
				ELSE @INSERT_RESULT END
	, indUnidad
	, indPeriodicidad
	INTO #CUR
	FROM Indicadores.fAplicarParametros (@wDesde, @wHasta
									   , @mDesde, @mHasta
									   , @AGUA, @ALCANTARILLADO
									   , @DOMESTICO, @MUNICIPAL, @INDUSTRIAL
									   , @LECTURANORMAL
									   , @RECLAMACION
									   , @INSPECCIONES);

	
	--********* G R U P O S **********************
	--DataTable[2]:  Nombre de Grupos 
	SELECT * 
	FROM (VALUES('INDICADORES'), ('SEMANALES'), ('MENSUALES'), ('INFO_PRUEBAS')) 
	AS DataTables(Grupo);

	
		
	
	

	--********* R E S U L T **********************
	--Rellenamos las tablas temporales (#IND_SEMANAL, #IND_MENSUAL)
	DECLARE IND CURSOR FOR 
	SELECT * FROM #CUR;
	OPEN IND
	FETCH NEXT FROM IND INTO @INDICADOR, @FN, @DML, @UD, @PER;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		
		SET @EXEC =  REPLACE(REPLACE(REPLACE(@DML, '[INDICADOR]', @INDICADOR), '[FN]', @FN), '[UNIDAD]', @UD);					
		
		BEGIN TRY
			EXEC(@EXEC);
		END TRY
		BEGIN CATCH
			EXEC Trabajo.errorLog_Insert '[InformesExcel].[Indicadores_Acuama]', @INDICADOR, @EXEC;
		END CATCH
		
		--***********************************************************
		--El nombre de la columna de los semanales informa la unidad
		IF (@PER = 'S')
			SET @SELECT_UDS =  @SELECT_UDS + FORMATMESSAGE(', [%s (%s)] = %s', @INDICADOR, @UD, @INDICADOR);


		FETCH NEXT FROM IND INTO @INDICADOR, @FN, @DML, @UD, @PER;
	END

	CLOSE IND;
	DEALLOCATE IND;

	--******************************
	--DataTable[3]:INDICADORES
	--******************************
	SELECT [Indicador]= indAcr
	, [Descripción] = indDescripcion
	, [Periodicidad] = CASE indPeriodicidad 
					   WHEN 'M' THEN 'Mensual' 
					   WHEN 'S' THEN 'Semanal' 
					   ELSE '??' END
	, [Dato] = indFuncionInfo
	, [Activo] = indActivo
	FROM Indicadores.IndicadoresConfig 
	ORDER BY indAcr;

	
	--******************************
	--DataTable[4]:SEMANAL
	--******************************
	--SELECT * FROM #IND_SEMANAL ORDER BY SEMANA;
	EXEC(@SELECT_UDS +' FROM #IND_SEMANAL ORDER BY SEMANA');
	
	--******************************
	--DataTable[5]:MENSUAL
	--******************************
	SELECT M.INDICADOR, M.VALOR, M.UNIDAD, I.indDescripcion 
	FROM #IND_MENSUAL AS M
	LEFT JOIN Indicadores.IndicadoresConfig AS I
	ON I.indAcr = M.INDICADOR	
	ORDER BY INDICADOR;

	--***** D E B U G ********
	--DataTable[6]: DEBUG								
	SELECT C.indAcr, C.indFuncion, C.indUnidad, C.indPeriodicidad, CC.indFuncionInfo
	FROM #CUR AS C
	LEFT JOIN Indicadores.IndicadoresConfig AS CC
	ON CC.indAcr = C.indAcr
	ORDER BY indAcr;		
	--************************
	
END TRY
	

BEGIN CATCH
	IF CURSOR_STATUS('global','IND') >= -1
	BEGIN
	IF CURSOR_STATUS('global','IND') > -1 CLOSE IND;
	DEALLOCATE IND;
	END

	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH


IF OBJECT_ID('tempdb.dbo.#FSEMANAS', 'U') IS NOT NULL 
DROP TABLE #FSEMANAS;

IF OBJECT_ID('tempdb.dbo.#IND_SEMANAL', 'U') IS NOT NULL 
DROP TABLE #IND_SEMANAL;


IF OBJECT_ID('tempdb.dbo.#IND_MENSUAL', 'U') IS NOT NULL 
DROP TABLE #IND_MENSUAL;

IF OBJECT_ID('tempdb.dbo.#CUR', 'U') IS NOT NULL 
DROP TABLE #CUR;



--SELECT @p_errMsg_out;
GO
/****** Object:  StoredProcedure [InformesExcel].[Indicadores_IDbox]    Script Date: 18/11/2022 12:07:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
****** CONFIGURACION ******
DROP PROCEDURE [InformesExcel].[Indicadores_Plantilla] 
DELETE ExcelPerfil WHERE ExPCod='000/901'
DELETE ExcelConsultas WHERE ExcCod='000/901'


INSERT INTO dbo.ExcelConsultas
VALUES ('000/901',	'Indicadores: IDbox', 'Indicadores: Plantilla IDbox', 20, '[InformesExcel].[Indicadores_IDbox]', 'CABECERA-DATOS', '<b>Plantilla IDbox</b>: Indicadores para envio FTP', 'IDbox.jpg');

INSERT INTO ExcelPerfil
SELECT '000/901', prfcod , 3, NULL FROM Perfiles

*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI><Fecha>20221113</Fecha><Semanas></Semanas></LI></NodoXML>';

EXEC [InformesExcel].[Indicadores_IDbox] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[Indicadores_IDbox]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	--**********
	--PARAMETROS: 
	--[1]Fecha: Fecha
	--NULL=>Recuperamos las ayudas hasta la fecha actual
	--**********

	SET NOCOUNT ON;   
	BEGIN TRY
	
	--********************
	--INICIO: 2 DataTables
	-- 1: Parametros del encabezado (Fecha)
	-- 2: Datos
	--********************

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	DECLARE @params TABLE (Fecha DATE NULL, Semanas INT NULL, fInforme DATETIME);

	INSERT INTO @params
	SELECT Fecha	= CASE WHEN M.Item.value('Fecha[1]', 'DATE') = '19000101' THEN dbo.GetAcuamaDate()
					  ELSE M.Item.value('Fecha[1]', 'DATE') END
					  
		, Semanas   = CASE WHEN M.Item.value('Semanas[1]', 'INT') = 0 THEN 12
						ELSE M.Item.value('Semanas[1]', 'INT') END

		 , fInforme = GETDATE() 
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	DECLARE @fecha DATE;
	SELECT @fecha = Fecha from @params;
	
	--***** V A R I A B L E S ******
	--***** * S E M A N A L * ******
	CREATE TABLE #FSEMANAS   (semana INT
							 , fLunes DATE
							 , fDomingo DATE
							 , _fLunes AS DATEADD(DAY, 1, fDomingo));

	DECLARE @wDesde DATE;
	DECLARE @wHasta DATE;
	DECLARE @Semanas INT;
	DECLARE @AGUA INT = 1;
	DECLARE @ALCANTARILLADO INT = 0;
	DECLARE @DOMESTICO INT = 1;
	DECLARE @MUNICIPAL INT = 3;
	DECLARE @INDUSTRIAL INT = 4;
	DECLARE @LECTURANORMAL VARCHAR(25) = '1, ';
	DECLARE @RECLAMACION VARCHAR(4) = '11';
	
	SELECT @Semanas = Semanas FROM @params;

	DECLARE @USOS AS VARCHAR(50);
	SELECT @USOS = COALESCE(@USOS + ',', '') + CAST(U.usocod AS VARCHAR(5))
	FROM dbo.usos AS U;

	
	DECLARE @INSPECCIONES VARCHAR(250);
	WITH I AS (SELECT DISTINCT facInspeccion FROM facturas WHERE facInspeccion IS NOT NULL )
	SELECT @INSPECCIONES = COALESCE(@INSPECCIONES+ ',' , '') + CAST(facInspeccion AS VARCHAR(5)) 
	FROM  I ;

	DECLARE @RESULT INT = NULL;

		
	--***** V A R I A B L E S ******
	--***** * M E N S U A L * ******
	DECLARE @mDesde DATE;
	DECLARE @mHasta_ DATE;	
	DECLARE @mHasta DATE;
	DECLARE @mesHasta VARCHAR(25);

	SELECT @mHasta_ = DATEADD(DAY, -DAY(@fecha), @fecha);
	SELECT @mesHasta = FORMAT(@mHasta_, 'dd/MM/yyyy HH:mm:ss.fff');

	SELECT @mDesde = DATEADD(DAY, 1-DAY(@mHasta_), @mHasta_)
		 , @mHasta = DATEADD(DAY, 1, @mHasta_);
	
	--******************************
	DECLARE @INDICADOR AS VARCHAR(5);
	DECLARE @FN AS VARCHAR(MAX);
	DECLARE @PER AS  VARCHAR(1);
	DECLARE @UD AS  VARCHAR(15);
	DECLARE @DML AS VARCHAR(500);
	DECLARE @EXEC AS VARCHAR(MAX);
	

	--******************************
	SELECT @AGUA = P.pgsvalor 
	FROM dbo.parametros AS P 
	WHERE P.pgsclave= 'SERVICIO_AGUA';

	--Buscamos el alcantarillado por la explotación
	SELECT @ALCANTARILLADO = svccod 
	FROM dbo.servicios AS S
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND S.svcdes='Alcantarillado');

	--Buscamos el uso por la explotación
	SELECT @DOMESTICO = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='DOMESTICO');

	--Buscamos el uso por la explotación
	SELECT @MUNICIPAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='MUNICIPAL');
	
	SELECT @INDUSTRIAL = usocod 
	FROM dbo.usos AS U
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND U.usodes='INDUSTRIAL');
	
	SELECT @LECTURANORMAL = CONCAT(I.inlcod, ', ')
	FROM dbo.incilec AS I
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND I.inldes='LECTURA NORMAL');

	SELECT @RECLAMACION = R.grecod
	FROM dbo.greclamacion AS R
	INNER JOIN dbo.parametros AS P
	ON P.pgsclave = 'EXPLOTACION'
	WHERE (P.pgsvalor = 'Guadalajara' AND R.grecod='RS');


	--******************************
	INSERT INTO #FSEMANAS
	SELECT * FROM Indicadores.fSemanas(@Fecha, @Semanas);


	IF (@@ROWCOUNT= 0) RETURN;

	SELECT @wDesde = MIN(fLunes)
		 , @wHasta = DATEADD(DAY, 1, MAX(fDomingo))
	FROM #FSEMANAS;
	--******************************
	


	--******** P A R A M E T R O S ************
	--DataTable[1]:  Parametros 
	SELECT 
	  [Semanas] = (SELECT COUNT(*) FROM #FSEMANAS)
	, [Semanal Desde] = @wDesde
	, [Semanal Hasta] = DATEADD(DAY, -1, @wHasta)
	, fInforme 
	, [Mes] = UPPER(FORMAT(@mDesde, 'MMMyyyy'))
	, [Mes Desde] = @mDesde
	, [Mes Hasta] = DATEADD(D, -1, @mHasta)
	, [Fecha]
	FROM @params

	--******  P L A N T I L L A S  ******	
	DECLARE @SELECTxSEMANA AS VARCHAR(MAX) = 
	'SELECT [Date] = FORMAT(S.[fDomingo], ''dd/MM/yyy HH:mm:ss.fff''), [Value] = ISNULL(F.[VALOR], 0), [State] = ''Normal'' FROM #FSEMANAS AS S  LEFT JOIN ([_FN_]) AS F ON F.SEMANA = S.semana ORDER BY S.[fDomingo]';

	DECLARE @SELECTxMES AS VARCHAR(MAX) = 
	'SELECT [Date] = ''[_MESHASTA_]'', [Value] = ISNULL(F.[VALOR], 0), [State] = ''Normal'' FROM ([_FN_]) AS F';
	
	DECLARE @SELECTxEXEC AS VARCHAR(250) = 
	'DECLARE @[_INDICADOR_] VARCHAR(25); ' +
	'[_FN_];' +
	'SELECT [Date] = ''[_MESHASTA_]'', [Value] = ISNULL(@[_INDICADOR_], 0), [State] = ''Normal'';';
		
	
	--******** INCLUIR MENSUALES *********
	DECLARE @Mensual VARCHAR(1) = '';

	SELECT @Mensual = 'M'  
	FROM #FSEMANAS AS S
	--La ultima semana de los semanales incluye el final del mes
	WHERE S.semana=@Semanas AND @mHasta_ BETWEEN S.fLunes and S.fDomingo ;
	
	--SELECT [@Mensual] = @Mensual;
	   
	--******** C U R S O R *********
	SELECT indAcr
	, indFuncion
	, indUnidad
	, indPeriodicidad
	INTO #CUR
	FROM Indicadores.fAplicarParametros (@wDesde, @wHasta
									   , @mDesde, @mHasta
									   , @AGUA, @ALCANTARILLADO
									   , @DOMESTICO, @MUNICIPAL, @INDUSTRIAL
									   , @LECTURANORMAL
									   , @RECLAMACION
									   , @INSPECCIONES)
	WHERE indPeriodicidad = 'S' OR indPeriodicidad=@Mensual;

	--********* G R U P O S **********************
	--DataTable[2]:  Nombre de Grupos 
	--SELECT [Grupo] = C.indAcr 
	--FROM #CUR AS C
	--ORDER BY indAcr;


	--********* R E S U L T **********************
	--DataTable[4,5]: Indicador (Encabezado, Filas) 
	DECLARE IND CURSOR FOR 
	SELECT * FROM #CUR;
	OPEN IND
	FETCH NEXT FROM IND INTO @INDICADOR, @FN, @UD, @PER;
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		--**********
		--CABECERA:
		SELECT [strSheet]=@INDICADOR
		, V.* 
		FROM Indicadores.vIndicadoresPlantilla AS V 
		WHERE [TAG:]= @INDICADOR;
		--**********
	
		--**********
		--DATOS:
		IF (@PER = 'S')
			SET @EXEC = @SELECTxSEMANA;
		ELSE IF(@FN LIKE 'SELECT%')
			SET @EXEC = @SELECTxMES;
		ELSE 
			SET @EXEC = @SELECTxEXEC;

		SET @EXEC =REPLACE(   
		 			 REPLACE(
					 REPLACE(@EXEC
					, '[_FN_]', @FN)
					, '[_INDICADOR_]', @INDICADOR)
					, '[_MESHASTA_]', @mesHasta);
		
		--SELECT @EXEC;
		EXEC (@EXEC);
		--**********
		
		FETCH NEXT FROM IND INTO @INDICADOR, @FN, @UD, @PER;
	END

	CLOSE IND;
	DEALLOCATE IND;
	

END TRY
	

BEGIN CATCH
	IF CURSOR_STATUS('global','IND') >= -1
	BEGIN
	IF CURSOR_STATUS('global','IND') > -1 CLOSE IND;
	DEALLOCATE IND;
	END

	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
END CATCH


IF OBJECT_ID('tempdb.dbo.#FSEMANAS', 'U') IS NOT NULL 
DROP TABLE #FSEMANAS;

IF OBJECT_ID('tempdb.dbo.#CUR', 'U') IS NOT NULL 
DROP TABLE #CUR;



--SELECT @p_errMsg_out;
GO
