ALTER PROCEDURE [dbo].[Cobros_Select] 
@cobScd smallint = NULL,
@cobPpag smallint = NULL,
@cobNum int = NULL,
@cobctr int = NULL,
@periodoD VARCHAR(6) = NULL,
@periodoH VARCHAR(6) = NULL,
@fechaRegD DATETIME = NULL,
@fechaRegH DATETIME = NULL,
@desdePeriodoInicio BIT  = NULL,
@cblPer VARCHAR(6) = NULL,
@cobFechaCobro DATETIME = NULL,
@cobImporte MONEY = NULL,
@cobMpcDato1 VARCHAR(40) = NULL,
@cobMpcDato2 VARCHAR(40) = NULL,
@cobMpcDato3 VARCHAR(40) = NULL,
@cobFecReg DATETIME = NULL,
@usuario VARCHAR(10) = NULL,
@cobComCodigo SMALLINT = NULL,
@agtCobCodigo SMALLINT = NULL,
@cobOrigen VARCHAR(20) = NULL,
@desgloseCobroNumero INT = NULL -- Se obtienen los desgloses del punto de pago que se indica menores a este número de cobro

AS 
	SET NOCOUNT ON; 

	DECLARE @PERIODO_INICIO AS VARCHAR(6) = '';
	SELECT @PERIODO_INICIO = P.pgsValor 
	FROM dbo.parametros AS P 
	WHERE P.pgsClave = 'PERIODO_INICIO';
	
	

SELECT  C.[cobScd]
      , C.[cobPpag]
      , C.[cobNum]
      ,[cobFecReg]
      ,[cobUsr]
      ,[cobFec]
      ,[cobCtr]
      ,[cobNom]
      ,[cobDocIden]
      ,[cobImporte]
      ,[cobMpc]
      ,[cobMpcDato1]
      ,[cobMpcDato2]
      ,[cobMpcDato3]
      ,[cobMpcDato4]
      ,[cobMpcDato5]
      ,[cobMpcDato6]
	  ,[cobConcepto]
	  ,[cobDevCod]
	  ,[cobFecContabilizacion]
	  ,[cobUsrContabilizacion]
	  ,[cobComCodigo]
	  ,[cobFecUltMod]
	  ,[cobUsrUltMod]
	  ,[cobOrigen]
FROM dbo.[cobros] AS C 

WHERE (@cobScd IS NULL OR C.cobScd=@cobScd)
  AND (@cobPpag IS NULL OR C.cobPpag=@cobPpag)
  AND (@cobNum IS NULL OR C.cobNum=@cobNum)
  AND (@cobctr IS NULL OR C.cobCtr=@cobctr)
  AND (@fechaRegD IS NULL OR C.cobFecReg>=@fechaRegD)
  AND (@fechaRegH IS NULL OR C.cobFecReg<=@fechaRegH)

AND((@periodoD IS NULL AND @periodoH IS NULL AND @desdePeriodoInicio IS NULL) OR EXISTS(
	SELECT C.cobNum
	FROM dbo.coblin AS CL
	WHERE  C.cobScd=CL.cblScd AND C.cobPpag=CL.cblPpag AND C.cobNum=CL.cblNum  
	  AND (@periodoD IS NULL OR CL.cblper >= @periodoD) 
	AND (@periodoH IS NULL OR CL.cblper <= @periodoH) 
	AND (@desdePeriodoInicio <> 1 OR CL.cblper >= @PERIODO_INICIO OR cblper like '0000%' OR cblper = '999999')
)) AND
(@cblPer IS NULL OR EXISTS (SELECT C.cobNum 
									   FROM dbo.coblin AS CL 
									   WHERE C.cobScd	= CL.cblScd AND 
											 C.cobPpag	= CL.cblPpag AND 
											 C.cobNum	= CL.cblNum AND 
											 CL.cblPer	= @cblPer
							)
)AND
(@cobFechaCobro IS NULL OR C.cobFec = @cobFechaCobro) AND
(@cobImporte IS NULL OR C.cobImporte = @cobImporte) AND
(@cobMpcDato1 IS NULL OR C.cobMpcDato1 = @cobMpcDato1) AND
(@cobMpcDato2 IS NULL OR C.cobMpcDato2 = @cobMpcDato2) AND
(@cobMpcDato3 IS NULL OR C.cobMpcDato3 = @cobMpcDato3) AND
(@cobFecReg IS NULL OR C.cobFecReg <= @cobFecReg) AND
(@usuario IS NULL OR C.cobUsr= @usuario) AND
(@cobComCodigo IS NULL OR C.cobComCodigo = C.cobComCodigo) AND
(@agtCobCodigo IS NULL OR EXISTS( SELECT agtCobCodigo
										 FROM dbo.agentesCobro
										 INNER JOIN dbo.comisiones ON comCodigo = cobComCodigo AND comAgtCobCodigo = @agtCobCodigo
								 )
) AND
(@cobOrigen IS NULL OR C.cobOrigen = @cobOrigen) AND
(@desgloseCobroNumero IS NULL OR (@desgloseCobroNumero IS NOT NULL AND C.cobNum < @desgloseCobroNumero))

OPTION(RECOMPILE);


GO


