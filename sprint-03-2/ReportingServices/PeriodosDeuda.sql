/*
DECLARE @periodoDev NVARCHAR(4000)
, @listaDevoluciones NVARCHAR(4000)
, @xmlSerCodArray NVARCHAR(4000)
, @contrato INT = 7829
, @periodoD NVARCHAR(4000)
, @tipoProcedimiento NVARCHAR(6) = 'CARTAS'
, @periodoH NVARCHAR(4000)

EXEC ReportingServices.PeriodosDeuda @periodoDev, @listaDevoluciones, @xmlSerCodArray, @contrato, @periodoD, @tipoProcedimiento, @periodoH;
*/

CREATE PROCEDURE ReportingServices.PeriodosDeuda
( @periodoDev NVARCHAR(4000)
, @listaDevoluciones NVARCHAR(4000)
--, @xmlSerCodArray NVARCHAR(4000)
, @contrato INT
, @periodoD NVARCHAR(4000)
, @tipoProcedimiento NVARCHAR(6)
, @periodoH NVARCHAR(4000))

AS


--CREAMOS TABLA DE DEVOLUCIONES (donde insertaremos los datos del XML de devoluciones, si nos llega por parámetro)
DECLARE @tDevoluciones AS TABLE(
	CodigoContrato INT,
	CodigoPeriodo VARCHAR(6),
	CodigoFactura SMALLINT,
	Importe DECIMAL(16,2)
	
	/*Descomentar cuando todos los ficheros XML de devoluciones vengan con CodigoFactura (por ejemplo el 01/03/2013): 
	PRIMARY KEY(CodigoContrato, CodigoPeriodo, CodigoFactura)*/
)

DECLARE @idoc INT

--SI ME LLEGA EL XML CON LAS DEVOLUCIONES, LO INSERTO EN LA TABLA DE DEVOLUCIONES
IF @listaDevoluciones IS NOT NULL BEGIN
	EXEC sp_xml_preparedocument @idoc OUTPUT, @listaDevoluciones
	INSERT INTO @tDevoluciones(CodigoContrato, CodigoPeriodo, CodigoFactura, Importe)
	SELECT CodigoContrato, CodigoPeriodo, CodigoFactura, Importe
	FROM OPENXML (@idoc, '/cDevolucionesBO_List/cDevolucionesBO',2) WITH
	(
		CodigoContrato INT,
		CodigoPeriodo VARCHAR(6),
		Importe DECIMAL(16,2),
		CodigoFactura SMALLINT
	)
	
	--Liberamos memoria
	EXEC  sp_xml_removedocument @idoc
END

IF @xmlSerCodArray IS NOT NULL BEGIN
	--Creamos una tabla en memoria donde se van a insertar todos los valores
	DECLARE @serviciosExcluidos AS TABLE(servicioCodigo SMALLINT) 
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

SELECT 
	f.facSerScdCod, f.facSerCod, f.facNumero,
	f.facCtrCod,f.facPerCod,f.facFecha
	--Si es una devolución (recibimos @listaDevoluciones) hay que restar el importe de la devolución al cobrado, a menos que ya se haya restado (es decir, que exista el cobro (la devolución) porque ya se había cargado el fichero)
	--***************
	--Ante el aumento en la precisión el el coblin, redondeamos a 2 decimales.
	, importeCobrado = ROUND(
	ISNULL(importeCobrado, 0) - (CASE WHEN @listaDevoluciones IS NOT NULL AND 
										   Importe IS NOT NULL AND
									       NOT EXISTS(SELECT cobNum 
											          FROM cobros
											          INNER JOIN coblin ON cobScd = cblScd AND cobPpag = cblPpag AND cobNum = cblNum
											          WHERE cobCtr = f.facCtrCod AND
												            cblPer = f.facPerCod AND
												            cblFacCod = f.facCod AND
												            cobImporte = -Importe AND
												            cobOrigen = 'Devolucion')
							     THEN Importe
							     ELSE 0
						         END), 2)
	, importeFacturado = ROUND(ISNULL(importeFacturado,0), 2) 
	--***************
FROM facturas f
	LEFT JOIN (SELECT cobCtr,ISNULL(SUM(cblImporte),0) - 
								CASE WHEN (@xmlSerCodArray IS NOT NULL AND 
										  (SELECT ROUND(ISNULL(SUM(fclTotal),0)	,2)
														FROM facturas f 
														INNER JOIN faclin ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
														WHERE facSerCod IS NOT NULL AND facSerScdCod IS NOT NULL AND facNumero IS NOT NULL AND
															  facVersion = (SELECT MAX(facVersion) FROM facturas fSub WHERE f.facCtrCod = fSub.facCtrCod AND f.facPerCod = fSub.facPerCod AND f.facCod = fSub.facCod) AND
															 (fclFecLiq IS NULL AND fclUsrLiq IS NULL)
																 AND f.facCtrCod = cobCtr 
																 AND f.facCod = cblFacCod 
																 AND f.facPerCod = cblPer
												GROUP BY facCtrCod,facCtrVersion,facPerCod,facCod, facSerScdCod) 
												<>  (SELECT ISNULL(SUM(cblImporte),0) 
															FROM cobros c2
															INNER JOIN coblin cl2 ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
															WHERE c2.cobCtr = c.cobCtr AND
																  cl2.cblPer = cl.cblPer AND
																  cl2.cblFacCod = cl.cblFacCod
														GROUP BY cobCtr, cblPer, cblFacCod
													)
												)
												THEN ( SELECT SUM(ISNULL(cobroRepartido,0)) FROM 
																(SELECT ISNULL(ROUND(
																		 (
																		 (SELECT ROUND(ISNULL(fclTotal,0),2)
																				 FROM facturas 
																				 INNER JOIN faclin ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
																				 WHERE fclFecLiq IS NULL AND fclUsrLiq IS NULL AND 
																					   facCtrCod = @contrato AND
																					   facPerCod = cblPer AND
																					   fclTrfSvCod = servicioCodigo
																		 )
																		 / 
																		(SELECT ROUND(ISNULL(SUM(fclTotal),0),2)
																				 FROM facturas 
																				 INNER JOIN faclin ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
																				 WHERE fclFecLiq IS NULL AND fclUsrLiq IS NULL AND 
																					   facCtrCod = @contrato AND
																					   facPerCod = cblPer
																		)
																		)*(SELECT ISNULL(SUM(cblImporte),0) 
																				FROM cobros c2
																				INNER JOIN coblin cl2 ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
																				WHERE c2.cobCtr = c.cobCtr AND
																					  cl2.cblPer = cl.cblPer AND
																					  cl2.cblFacCod = cl.cblFacCod
																			GROUP BY cobCtr, cblPer, cblFacCod), 2),0) AS cobroRepartido 
																	FROM @serviciosExcluidos) AS T
													) 
											ELSE 0
											END AS importeCobrado, cblPer, cblFacCod
				FROM cobros c
				INNER JOIN coblin cl ON cobScd=cblScd AND cobPpag=cblPpag AND cobNum=cblNum
			GROUP BY cobCtr, cblPer, cblFacCod) AS tc
				 ON cobCtr = facCtrCod AND cblPer = facPerCod AND cblFacCod = facCod
	INNER JOIN (SELECT facCtrCod, facPerCod, facVersion, facCod, 
				ROUND( ISNULL(SUM(fclTotal),0), 2)AS importeFacturado
				 FROM facturas f INNER JOIN faclin ON fclFacPerCod = facPerCod  AND fclFacCtrCod = facCtrCod AND fclFacVersion = facVersion AND fclFacCod = facCod
				 WHERE fclFecLiq IS NULL AND fclUsrLiq IS NULL AND facCtrCod = @contrato AND
				       (@xmlSerCodArray IS NULL OR fclTrfSvCod NOT IN (SELECT servicioCodigo 
											      FROM @serviciosExcluidos))
				 GROUP BY facCtrCod, facPerCod, facVersion, facCod) as tf
				 ON tf.facCtrCod=f.facCtrCod AND tf.facPerCod=f.facPerCod AND tf.facVersion=f.facVersion AND tf.facCod=f.facCod
	LEFT JOIN @tDevoluciones ON CodigoContrato = f.facCtrCod AND CodigoPeriodo = f.facPerCod AND CodigoFactura = f.facCod
WHERE 
facFechaRectif IS NULL
AND ((f.facPerCod IN (SELECT DISTINCT value FROM dbo.Split(ISNULL(@periodoDev,''), ';')) AND f.facCtrCod=@contrato) OR 
(@tipoProcedimiento <> 'EXPEDIENTES' AND
	 ISNULL(importeFacturado, 0) > ISNULL(importeCobrado, 0) AND 
	 f.facVersion = (SELECT MAX(facVersion) FROM facturas fSub where fSub.facPerCod = f.facPerCod AND fSub.facCtrCod = f.facCtrCod AND f.facCod=fSub.facCod) AND
	 f.facCtrCod = @contrato AND
	(f.facPerCod >= @periodoD OR @periodoD IS NULL) AND
	(f.facPerCod <= @periodoH OR @periodoH IS NULL) AND
	--(f.facFecReg <=@excFecReg OR @excFecReg IS NULL) AND
	(facSerScdCod IS NOT NULL AND facSerCod IS NOT NULL AND facNumero IS NOT NULL)	
))
AND (f.facPerCod >= (SELECT pgsvalor FROM parametros WHERE pgsclave='PERIODO_INICIO') OR f.facPerCod like '0000%')
--***************
--Ante el aumento en la precisión el el coblin, redondeamos a 2 decimales.
AND ROUND(ISNULL(importeFacturado, 0), 2)> ROUND((ISNULL(importeCobrado, 0) - (CASE WHEN @listaDevoluciones IS NOT NULL AND 
																		 Importe IS NOT NULL AND
																			NOT EXISTS(SELECT cobNum 
																				 FROM cobros
																				 INNER JOIN coblin ON cobScd = cblScd AND cobPpag = cblPpag AND cobNum = cblNum
																				 WHERE cobCtr = f.facCtrCod AND
																					cblPer = f.facPerCod AND
																					cblFacCod = f.facCod AND
																					cobImporte = -Importe AND
																					cobOrigen = 'Devolucion')
																		THEN Importe
																		ELSE 0
																 END
																)
								  ), 2)
--***************

ORDER BY f.facCtrCod,f.facPerCod;

GO