/*
DECLARE @periodoD NVARCHAR(6)=N'200901';
DECLARE @periodoH NVARCHAR(6)=N'202104';
DECLARE @fechaD NVARCHAR(4000)='19000101';
DECLARE @fechaH NVARCHAR(4000)='20220131 23:59:59'; --31/01/2022 23:59:59
DECLARE @afecha DATETIME ='20220131 23:59:59'; --31/01/2022 23:59:59
DECLARE @numPeriodos INT=0;
DECLARE @domiciliado NVARCHAR(5)=N'Todos';
DECLARE @apremiadoAyto NVARCHAR(9)=N'TodosAyto'; 
DECLARE @apremiadoAcuama NVARCHAR(5)=N'Todos';
DECLARE @orden NVARCHAR(7)=N'Defecto'
DECLARE @datos NVARCHAR(7)= N'Pagador';


DECLARE @xmlSerCodArray NVARCHAR(4000) = NULL;
DECLARE @contratoD NVARCHAR(4000) = NULL;
DECLARE @contratoH NVARCHAR(4000) = NULL;
DECLARE @ctrTipoVip NVARCHAR(4000)=NULL;
DECLARE @provincia NVARCHAR(1)=NULL;
DECLARE @poblacion NVARCHAR(4000)=NULL;
DECLARE @municipio NVARCHAR(4000)=NULL;
DECLARE @calle NVARCHAR(4000)=NULL;
DECLARE @finca NVARCHAR(4000)=NULL;
DECLARE @zonaD NVARCHAR(4000)=NULL;
DECLARE @zonaH NVARCHAR(4000)=NULL;
DECLARE @clienteD NVARCHAR(4000)=NULL;
DECLARE @clienteH NVARCHAR(4000)=NULL;
DECLARE @cliTipoVip NVARCHAR(4000)=NULL;
DECLARE @fraConServicio NVARCHAR(4000)=NULL;
DECLARE @soloEsteServicioActivo NVARCHAR(4000)=NULL;

EXEC ReportingServices.RelacionDeudaSituacion @xmlSerCodArray, @datos, @fechaD, @fechaH, @contratoD, @afecha, @contratoH, @ctrTipoVip, @provincia, @poblacion, @municipio, @calle, @finca, @periodoD, @periodoH, @zonaD, @zonaH, @clienteD, @clienteH, @cliTipoVip, @fraConServicio, @soloEsteServicioActivo, @domiciliado, @apremiadoAyto, @numPeriodos, @apremiadoAcuama, @orden

*/


ALTER PROCEDURE ReportingServices.RelacionDeudaSituacion
  @xmlSerCodArray nvarchar(4000)
, @datos nvarchar(7)
, @fechaD nvarchar(4000)
, @fechaH nvarchar(4000)
, @contratoD nvarchar(4000)
, @afecha datetime
, @contratoH nvarchar(4000)
, @ctrTipoVip nvarchar(4000)
, @provincia nvarchar(1)
, @poblacion nvarchar(4000)
, @municipio nvarchar(4000)
, @calle nvarchar(4000)
, @finca nvarchar(4000)
, @periodoD nvarchar(6)
, @periodoH nvarchar(6)
, @zonaD nvarchar(4000)
, @zonaH nvarchar(4000)
, @clienteD nvarchar(4000)
, @clienteH nvarchar(4000)
, @cliTipoVip nvarchar(4000)
, @fraConServicio nvarchar(4000)
, @soloEsteServicioActivo nvarchar(4000)
, @domiciliado nvarchar(5)
, @apremiadoAyto nvarchar(9)
, @numPeriodos int
, @apremiadoAcuama nvarchar(5)
, @orden nvarchar(7)
AS


DECLARE @idoc INT
DECLARE @serviciosExcluidos AS TABLE(servicioCodigo SMALLINT) 
DECLARE @servicioFianza INT			 = (SELECT pgsValor FROM parametros WHERE pgsClave = 'SERVICIO_FIANZA')
DECLARE @perInicio		varchar(100) = (SELECT isnull(pgsValor,'') FROM parametros WHERE pgsClave = 'PERIODO_INICIO')
DECLARE @explotacion	varchar(100) = (SELECT pgsValor FROM parametros WHERE pgsClave = 'EXPLOTACION')

IF @explotacion = 'Soria' 
	set @servicioFianza = null;

IF @xmlSerCodArray IS NOT NULL 
BEGIN
	--Leemos los parámetros del XML
	SET @idoc = NULL

	EXEC sp_xml_preparedocument @idoc OUTPUT, @xmlSerCodArray
	--Insertamos en tabla temporal

	INSERT INTO @serviciosExcluidos(servicioCodigo)
	SELECT value
	FROM   OPENXML (@idoc, '/servicioCodigo_List/servicioCodigo', 2) WITH (value SMALLINT)
	--Liberamos memoria

	EXEC  sp_xml_removedocument @idoc
END


SELECT enFechaFactura = 1
, faccod
, facpercod
, facCtrCod
, facVersion
, facFecha
, facFechaRectif
, facNumero
, sercod
, serdesc
, nombre= CASE @datos
		  WHEN 'Pagador' THEN ISNULL(ctrPagNom, ctrTitNom) 
		  ELSE ctrTitNom END
, direccion = CASE @datos
			  WHEN 'Pagador' THEN ISNULL(ctrPagDir,ctrTitDir)
			  ELSE ctrTitDir END

, importeCobrado = (SELECT ISNULL(SUM(cldImporte),0)
					FROM cobros 
					INNER JOIN coblin ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
					INNER JOIN coblindes ON cldCblScd = cblScd AND cldcblppag = cblppag AND cldcblnum = cblnum AND cldcbllin = cbllin
					WHERE cobCtr=f.facCtrCod AND cblPer=f.facPerCod AND cblFacCod=f.facCod AND 
					((@fechaD IS NULL AND @fechaH IS NULL) OR (cobFecReg between @fechaD and @fechaH))
					AND cobFecReg <=ISNULL(@afecha,dbo.GetAcuamaDate()) 
					AND (@xmlSerCodArray IS NULL OR 
						(@xmlSerCodArray IS NOT NULL AND cldTrfSrvCod not IN (SELECT servicioCodigo FROM @serviciosExcluidos)))
			
						AND (@servicioFianza IS NULL OR cldTrfSrvCod <> @servicioFianza)
					) 

, importeFacturado = (SELECT ISNULL(SUM(fclTotal), 0)
					FROM faclin l where fclFacCod=f.facCod  
					AND fclFacPerCod=f.facPerCod  
					AND fclFacCtrCod=f.facCtrCod
					AND fclFacVersion=f.facVersion
					AND((fclFecLiq>=ISNULL(@afecha,dbo.GetAcuamaDate())) OR (fclFecLiq IS NULL AND fclUsrLiq IS NULL))	
					AND (@xmlSerCodArray IS NULL OR 
						(@xmlSerCodArray IS NOT NULL AND fclTrfSvCod not IN (SELECT servicioCodigo FROM @serviciosExcluidos)))
					AND (@servicioFianza IS NULL OR fclTrfSvCod <> @servicioFianza)
					) 
	 
, consumo = facConsumoFactura
, suministro = (SELECT top 1 inmdireccion FROM inmuebles INNER JOIN contratos ON facCtrCod=ctrcod AND ctrinmcod=inmcod AND facCtrVersion = ctrVersion)
, documentoIdentidadTitular = CASE @datos
							  WHEN 'Pagador' THEN ISNULL(ctrPagDocIden,ctrTitDocIden)
							  ELSE ctrTitDocIden END
, aprCobradoAyto =	case when aprCobrado=0 then 'No' 	
					when aprCobrado=1 then 'Si'
					else '' end
, aprCobradoAcuama = case when aprCobradoAcuama=0 then 'No' 	
           when aprCobradoAcuama=1 then 'Si'
           else '' end
, deuda = CAST(NULL AS MONEY)
, numPeriodosDeuda = 0
INTO #FACS
FROM facturas f
INNER JOIN series ON facSerCod=sercod AND facSerScdCod=serscd 
INNER JOIN contratos c ON facCtrCod=ctrCod AND facCtrVersion=ctrVersion
INNER JOIN inmuebles ON inmcod = ctrinmcod
INNER JOIN clientes ON clicod = facCliCod
LEFT JOIN apremios apr ON f.facCod = apr.aprFacCod and f.facCtrCod=apr.aprFacCtrCod and f.facPerCod=apr.aprFacPerCod  and f.facVersion=apr.aprFacVersion
WHERE (facCtrCod>= @contratoD OR @contratoD IS NULL)
and (facCtrCod<= @contratoH OR @contratoH IS NULL)
AND (@ctrTipoVip IS NULL OR ctrTvipCodigo = @ctrTipoVip)
AND (@provincia IS NULL OR @provincia = inmPrvCod)
AND (@poblacion IS NULL OR @poblacion = inmPobCod)
AND (@municipio IS NULL OR @municipio = inmmnccod)
AND (@calle IS NULL OR @calle = inmcllcod)
AND (@finca IS NULL OR @finca = inmfinca)
and(facPerCod >= @periodoD OR @periodoD IS NULL)
and (facPerCod <= @periodoH OR @periodoH IS NULL)
AND (facpercod >= @perInicio OR facpercod like '0000%')
and (facZonCod >= @zonaD  OR @zonaD IS NULL)
and (facZonCod <= @zonaH OR @zonaH IS NULL)
and (facFecha>= @fechaD OR @fechaD IS NULL)
and (facFecha<= @fechaH OR @fechaH IS NULL)
and (facCliCod >= @clienteD OR @clienteD IS NULL)
and (facCliCod <= @clienteH OR @clienteH IS NULL)
AND (@cliTipoVip IS NULL OR cliTvipCodigo = @cliTipoVip)
AND ((facVersion=(SELECT MAX(facVersion) FROM facturas fSub WHERE fSub.facCod = f.facCod and fSub.facPerCod = f.facPerCod and fSub.facCtrCod = f.facCtrCod AND fSub.facFecReg <= ISNULL(@fechaH,dbo.GetAcuamaDate()))))
and ((facFechaRectif IS NULL) or (facFechaRectif > ISNULL(@fechaH,dbo.GetAcuamaDate()) ))
and facNumero is not null


AND (@fraConServicio IS NULL OR (@fraConServicio IS NOT NULL AND
                      EXISTS(SELECT fclFacCtrCod FROM faclin WHERE
				    fclFacCod=facCod AND
				    fclFacPerCod=facPerCod AND
			            fclFacCtrCod=facCtrCod AND
			            fclFacVersion=facVersion AND
				    fclTrfSvCod=@fraConServicio
			    )
		     )
     )
AND (@soloEsteServicioActivo IS NULL OR 
	(
	NOT EXISTS(SELECT ctsctrcod FROM contratoServicio WHERE ctsctrcod=facCtrCod AND ctssrv<>@soloEsteServicioActivo AND ctsfecbaj IS NULL) AND
	EXISTS(SELECT ctsctrcod FROM contratoServicio WHERE ctsctrcod=facCtrCod AND ctssrv=@soloEsteServicioActivo AND ctsfecbaj IS NULL)
     	)
    )

AND (@domiciliado IS NULL OR @domiciliado='Todos' OR 
               (@domiciliado = 'Domiciliados' AND (SELECT cs.ctrIBAN FROM contratos cs WHERE cs.ctrcod = c.ctrcod AND cs.ctrfecanu IS NULL) IS NOT NULL AND (SELECT cs.ctrIBAN FROM contratos cs WHERE cs.ctrcod = c.ctrcod AND cs.ctrfecanu IS NULL)<>'') 
               OR 
               (@domiciliado = 'NoDomiciliados'  AND ((SELECT cs.ctrIBAN FROM contratos cs WHERE cs.ctrcod = c.ctrcod AND cs.ctrfecanu IS NULL) IS NULL OR (SELECT cs.ctrIBAN FROM contratos cs WHERE cs.ctrcod = c.ctrcod AND cs.ctrfecanu IS NULL)='')))

AND (@apremiadoAyto IS NULL OR @apremiadoAyto='TodosAyto' OR 
               (@apremiadoAyto = 'CobradosAyto' AND (SELECT a.aprCobrado FROM apremios a WHERE a.aprFacCtrCod = f.facCtrCod AND a.aprFacCod= f.facCod and a.aprFacPerCod= f.facPerCod and  	a.aprFacVersion= f.facVersion ) =1) 
               OR 
               (@apremiadoAyto = 'NoCobradosAyto'  AND ((SELECT a.aprCobrado FROM apremios a WHERE a.aprFacCtrCod = f.facCtrCod AND a.aprFacCod= f.facCod and a.aprFacPerCod= f.facPerCod and a.aprFacVersion= f.facVersion ) =0)))

AND (@apremiadoAcuama IS NULL OR @apremiadoAcuama='Todos' OR 
               (@apremiadoAcuama = 'Cobrados' AND (SELECT a.aprCobradoAcuama FROM apremios a WHERE a.aprFacCtrCod = f.facCtrCod AND a.aprFacCod= f.facCod and a.aprFacPerCod= f.facPerCod and  	a.aprFacVersion= f.facVersion ) =1) 
               OR 
               (@apremiadoAcuama = 'NoCobrados'  AND ((SELECT a.aprCobradoAcuama FROM apremios a WHERE a.aprFacCtrCod = f.facCtrCod AND a.aprFacCod= f.facCod and a.aprFacPerCod= f.facPerCod and a.aprFacVersion= f.facVersion ) =0)))


--[01]Deuda de la factura
UPDATE #FACS SET deuda = ROUND(importeFacturado, 2) - ROUND(importeCobrado, 2);

--[02]Contamos los periodo con deuda
WITH PER AS(
SELECT faccod
, facpercod
, facCtrCod
, facVersion
, deuda
, rn_deuda = ROW_NUMBER() OVER (PARTITION BY facCtrCod, facpercod ORDER BY deuda DESC) 
FROM #FACS AS F

), NUM AS(
SELECT faccod
, facpercod
, facCtrCod
, facVersion
, numPeriodosDeuda = SUM(IIF(rn_deuda=1 AND deuda>0, 1, 0)) OVER (PARTITION BY facCtrCod)
FROM PER)

UPDATE F 
SET  F.numPeriodosDeuda=N.numPeriodosDeuda
FROM NUM AS N
INNER JOIN #FACS AS F
ON  F.faccod = N.faccod
AND F.facpercod  = N.facpercod
AND F.facCtrCod  = N.facCtrCod
AND F.facVersion = N.facVersion
AND N.numPeriodosDeuda>0;


--[03]Facturas con deuda
WITH RESULT AS(
SELECT faccod
	 , facpercod
	 , facCtrCod
	 , facVersion
	 , importeFacturado
	 , importeCobrado
	 , deuda
	 , esDeudaReal = CAST(IIF(deuda=0, 0,  1) AS BIT)

	 , facFecha
	 , facFechaRectif
	 , facNumero
	 , sercod
	 , serdesc
	 , nombre
	 , direccion
	 , suministro
	 , documentoIdentidadTitular
	 , aprCobradoAyto
	 , aprCobradoAcuama
	 , consumo
	 , numPeriodosDeuda
	 , RN = ROW_NUMBER() OVER (PARTITION BY IIF(deuda=0, 0,  1) ORDER BY facPerCod, facCtrCod)
	 , CN = COUNT(facPerCod) OVER (PARTITION BY IIF(deuda=0, 0,  1))

	 , deuda_total = SUM(importeFacturado-importeCobrado) OVER (PARTITION BY IIF(deuda=0, 0,  1))
FROM #FACS
WHERE importeFacturado <> importeCobrado
AND (@numPeriodos IS NULL OR numPeriodosDeuda>=@numPeriodos))

SELECT * 
FROM RESULT
--Con esto evitamos mandar al report las facturas sin deuda real (la deuda viene en los decimales 3 y 4)
--WHERE esDeudaReal = 1 OR (esDeudaReal=0 AND RN=1)
ORDER BY 
CASE @orden WHEN 'Defecto'	THEN facCtrCod  END ASC,
CASE @orden WHEN 'Defecto'	THEN facPerCod  END ASC,
CASE @orden WHEN 'Calle'	THEN direccion  END asc,
CASE @orden WHEN 'Importe'	THEN (importeFacturado - importeCobrado) END DESC;


IF OBJECT_ID('tempdb..#FACS', 'U') IS NOT NULL
DROP TABLE dbo.#FACS;

GO