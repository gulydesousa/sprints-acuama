/*
DECLARE @cblScd SMALLINT=1
DECLARE @cblPpag SMALLINT=4
DECLARE @cblNum INT=1

DECLARE @cblLin SMALLINT=1
DECLARE @DEBUG BIT = 1

EXEC  dbo.CobLinDes_GenerarDesglosePrioritario @cblScd, @cblPpag, @cblNum, @cblLin, @DEBUG
*/

ALTER PROCEDURE [dbo].[CobLinDes_GenerarDesglosePrioritario]
  @cblScd SMALLINT
, @cblPpag SMALLINT
, @cblNum INT
, @cblLin SMALLINT
, @DEBUG BIT = 0 

AS

	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	PRINT '*** dbo.CobLinDes_GenerarDesglosePrioritario ***';
	DECLARE @ACUAMA_INICIO DATETIME = '19800101';
	SELECT @ACUAMA_INICIO = pgsvalor FROM parametros WHERE pgsclave='ACUAMA_INICIO' AND NOT pgsvalor IS NULL AND LEN(pgsvalor) >1 ;

	DECLARE @CBL AS [dbo].tCoblinPK;
	DECLARE @FCL AS [dbo].tFaclinPK;
	DECLARE @COBRADO AS [dbo].tFaclinCobrado;
	DECLARE @DEUDA AS TABLE(
	  fclFacCod		SMALLINT NOT NULL
	, fclFacPerCod  VARCHAR(6) NOT NULL
	, fclFacCtrCod	INT NOT NULL
	, fclFacVersion SMALLINT NOT NULL
	, fclNumLinea	INT NOT NULL
	, fclTrfSvCod	SMALLINT NOT NULL
	, fclTrfCod		SMALLINT NOT NULL
	, fclFecLiq		DATETIME NULL
	, svcOrgCod		INT
	, fcltotal		MONEY
	, orgTotal		MONEY
	, cobTotalxLiq	MONEY	 
	--**************************************
	, factor		AS	CAST(CASE 
							 WHEN svcOrgCod IS NULL THEN 1
							 WHEN orgTotal IS NULL  THEN 1
							 WHEN orgTotal = 0  THEN 1
							 WHEN [CN_PDTES]!=0 AND [RN]>[CN_PDTES] THEN 1
							 ELSE CAST(fcltotal AS DECIMAL(12, 4)) / orgTotal  
							 END
							 AS DECIMAL(12, 4))
	, cldTotal		MONEY NULL
	, cldDeuda		AS		 IIF(fclFecLiq IS NULL, fcltotal, 0) - ISNULL(cldTotal, 0)
	, [DR_ORG]		INT
	, [RN]			INT
	, [CN_PDTES]	INT
	, [@cblImporte]	MONEY
	, [@cldImporte] MONEY
	, [@facTotal] MONEY
	, [@cobTotal] MONEY);

	DECLARE @repartirLiq MONEY = 0;
	DECLARE @cblImporte MONEY;		--Variable:  Total de la linea de cobro pendiente a repartir en el desglose
	DECLARE @cblImporte_ MONEY;		--Constante: Importe de la linea de cobro a repartir en el desglose
	
	DECLARE @cblCobrado_ MONEY;		--Constante: Total de las lineas previamente cobradas
	DECLARE @facTotal_ MONEY;		--Constante: Total de la factura
	DECLARE @facDeuda_ MONEY		--Constante: Total deuda de la factura
	
	
	DECLARE @break BIT = 0;			--Variable: Se usa para abandonar el loop de los resultados (desglose de lineas de cobros)
	DECLARE @CN_PDTES INT;
	
	--***************************
	--[01] @CBL: Datos de la linea de cobro que se procesará
	INSERT INTO @CBL (cobScd, cobPpag, cobNum, cblLin
	, cblImporte
	, cobFecReg, cobFec
	, facCod, facCtrCod, facPerCod, facVersion)
	--OUTPUT '@CBL', INSERTED.*
	SELECT C.cobScd, C.cobPpag, C.cobNum, CL.cblLin
		 , CL.cblImporte
		 , C.cobFecReg, C.cobFec
		 , CL.cblFacCod, C.cobCtr, CL.cblPer, CL.cblFacVersion
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON C.cobScd = CL.cblScd
	AND C.cobPpag = CL.cblPpag
	AND C.cobNum = CL.cblNum
	AND C.cobScd = @cblScd
	AND C.cobPpag = @cblPpag
	AND C.cobNum = @cblNum
	AND CL.cblLin = @cblLin
	--Entregas a cuentas no tendrá nunca desglose
	WHERE  CL.cblPer<>'999999';

	--**************************************
	--Sale en el TraceError.log si hay fallo
	DECLARE @MSG AS VARCHAR(250);
	SELECT @MSG = FORMATMESSAGE('**** facCod:%i, facCtrCod:%i, facPerCod=%s, facVersion:%i ****', facCod, facCtrCod, facPerCod, facVersion) FROM @CBL;
	PRINT @MSG;
	--**************************************

	--[02]TOTAL DE LA LINEA DE COBRO	
	SELECT @cblImporte = cblImporte  
		 , @cblImporte_= cblImporte 
	FROM @CBL;

	--***************************
	--[11]@cblCobrado_: Totalizamos las lineas de cobros previos
	SELECT @cblCobrado_ = ISNULL(SUM(CL.cblImporte), 0)
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON C.cobScd = CL.cblScd
	AND C.cobPpag = CL.cblPpag
	AND C.cobNum = CL.cblNum
	INNER JOIN @CBL AS F
	ON  F.facCod = CL.cblFacCod
	AND F.facPerCod = CL.cblPer
	AND F.facCtrCod = C.cobCtr
	AND F.facVersion = CL.cblFacVersion
	AND C.cobFecReg < F.cobFecReg;

	--****************************
	--[21]@FCL: Total de las lineas de la factura que se cobra en la linea @CBL
	INSERT INTO @FCL(fclFacCod, fclFacPerCod, fclFacCtrCod, fclFacVersion, fclNumLinea
				   , fclTrfSvCod, fclTrfCod
				   , fclFecLiq, svcOrgCod				   
				   , fcltotal
				   , [@facTotal] ) 
	--OUTPUT '@FCL', INSERTED.*
	SELECT FL.fclFacCod, FL.fclFacPerCod, FL.fclFacCtrCod, FL.fclFacVersion, FL.fclNumLinea
		 , FL.fclTrfSvCod, FL.fclTrfCod
		 --La fecha de liquidación se muestra si es anterior al cobro
		 , [fclFecLiq] = IIF(FL.fclFecLiq IS NULL OR FL.fclFecLiq > C.cobFec, NULL , FL.fclFecLiq)
		 , S.svcOrgCod
		 , FL.fcltotal 
		 --Totaliza las lineas no liquidadas a fecha del cobro
		, [@facTotal] = SUM(FL.fcltotal* IIF(FL.fclFecLiq IS NOT NULL AND FL.fclFecLiq <= C.cobFec, 0, 1)) OVER()
	FROM  dbo.faclin AS FL
	INNER JOIN @CBL AS C
	ON FL.fclFacCod = C.facCod
	AND FL.fclFacPerCod = C.facPerCod
	AND FL.fclFacCtrCod = C.facCtrCod
	AND FL.fclFacVersion = C.facVersion
	INNER JOIN dbo.servicios AS S
	ON S.svccod = FL.fclTrfSvCod;

	--[22]Total facturado
	SELECT @facTotal_ = ROUND(MAX([@facTotal]), 2)
		--El importe del cobro es igual al importe de la factura: Recorreremos todas las lineas 	
		 , @break = IIF(ABS(ROUND(@cblImporte_, 2)) = ABS(@facTotal_), 0, 1)
	FROM @FCL;

	--[23]Total deuda
	SELECT @facDeuda_ = @facTotal_ - ROUND(@cblCobrado_, 2);
	
	--******D E B U G *********
	--SELECT [@facTotal_]=@facTotal_, [@cblCobrado_]=@cblCobrado_, [@facDeuda_]=@facDeuda_, [@cblImporte]=@cblImporte, [@break] = @break;


	--*****************************
	--[31]@COBRADO: Obtengo los cobros previos por linea de factura
	INSERT INTO @COBRADO (fclFacCod, fclFacCtrCod, fclFacPerCod, fclFacVersion, fclNumLinea
						, [cldTotal], [numCobros])
	--OUTPUT '@COBRADO', INSERTED.*
	SELECT FL.fclFacCod	, FL.fclFacCtrCod, FL.fclFacPerCod, FL.fclFacVersion, FL.fclNumLinea
	, [cldTotal]  = SUM(CLD.cldImporte)
	, [numCobros] = COUNT(CLD.cldCblLin)
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON C.cobScd = CL.cblScd
	AND C.cobPpag = CL.cblPpag
	AND C.cobNum = CL.cblNum
	INNER JOIN dbo.cobLinDes AS CLD
	ON CLD.cldCblPpag = CL.cblPpag
	AND CLD.cldCblScd = CL.cblScd
	AND CLD.cldCblNum = CL.cblNum
	AND CLD.cldCblLin = CL.cblLin
	INNER JOIN @FCL AS FL
	ON  FL.fclFacCod = CL.cblFacCod
	AND FL.fclFacPerCod = CL.cblPer
	AND FL.fclFacCtrCod = C.cobCtr
	AND FL.fclFacVersion = CL.cblFacVersion
	AND CLD.cldFacLin = FL.fclNumLinea
	LEFT JOIN @CBL AS CC
	ON  CL.cblScd  = CC.cobScd
	AND CL.cblPpag = CC.cobPpag
	AND CL.cblNum  = CC.cobNum
	AND CL.cblLin  = CC.cblLin
	WHERE CC.cobScd IS NULL
	AND C.cobFecReg < (SELECT MAX(cobFecReg) FROM @CBL)
	GROUP BY FL.fclFacCod, FL.fclFacCtrCod, FL.fclFacPerCod, FL.fclFacVersion, FL.fclNumLinea;

	

	--*******************************
	--****** COBRO REVETIDO *********
	--*******************************
	--Si existe un cobro previo por el mismo importe con signo diferente 
	--@cobroRevertido=1
	--Haremos la distribución exactamente igual a la anterior, pero con signo diferente.
	DECLARE @revertidoPorLiquidacion TINYINT = NULL;
	DECLARE @cobroRevertido BIT = 0;

	--Si la fecha del cobro es la misma de la liquidación de alguna de las lineas
	--Se trata de un cobro revertido por la liquidación...
	--y lo tratamos como cobro revertido cuando es la primera linea del cobro  
	--@revertidoPorLiquidacion=1
	SELECT @revertidoPorLiquidacion = MAX(C.cblLin)	
	FROM @CBL AS C
	INNER JOIN @FCL AS F
	ON F.fclFecLiq IS NOT NULL
	AND C.facCod = F.fclFacCod
	AND C.facPerCod = F.fclFacPerCod
	AND C.facCtrCod = F.fclFacCtrCod
	AND C.facVersion = F.fclFacVersion
	AND C.cobFecReg = F.fclFecLiq;



	WITH REV AS(
	--Cobros anteriores por el mismo importe con signo diferente
	SELECT  CC.facCod, CC.facCtrCod, CC.facPerCod, CC.facVersion
		, CLD.cldFacLin, CLD.cldTrfSrvCod, CLD.cldTrfCod
		, CLD.cldImporte 
		--DR=1: Para quedarnos con una de las lineas de cobros, si hubiera mas de una.
		, DR = DENSE_RANK() OVER (ORDER BY C.cobFec DESC, C.cobFecReg DESC, C.cobNum DESC, C.cobScd, C.cobPpag, CL.cblLin)
	FROM dbo.cobros AS C
	INNER JOIN dbo.coblin AS CL
	ON C.cobScd = CL.cblScd
	AND C.cobPpag = CL.cblPpag
	AND C.cobNum = CL.cblNum
	AND C.cobFecReg>=@ACUAMA_INICIO
	INNER JOIN  @CBL AS CC
	ON  C.cobCtr = CC.facCtrCod
	AND CL.cblPer = CC.facPerCod
	AND CL.cblFacVersion = CC.facVersion
	AND CL.cblFacCod = CC.facCod
	AND C.cobFec <= CC.cobFec
	AND C.cobFecReg<CC.cobFecReg
	AND CL.cblImporte = -1*CC.cblImporte
	AND (@revertidoPorLiquidacion IS NULL OR @revertidoPorLiquidacion=1)
	INNER JOIN dbo.cobLinDes AS CLD
	ON CL.cblScd = CLD.cldCblScd
	AND CL.cblPpag = CLD.cldCblPpag
	AND CL.cblNum = CLD.cldCblNum
	AND CL.cblLin = CLD.cldCblLin)

	INSERT INTO @DEUDA (fclFacCod, fclFacCtrCod, fclFacPerCod, fclFacVersion
					  , fclNumLinea, fclTrfSvCod, fclTrfCod, [@cldImporte], [@facTotal])
	
	--OUTPUT '@DEUDA (1)', INSERTED.*
	SELECT  facCod, facCtrCod, facPerCod, facVersion
		  , cldFacLin, cldTrfSrvCod, cldTrfCod
		  , cldImporte *-1
		  , @facTotal_
	FROM REV WHERE DR=1;

	SET @cobroRevertido = IIF(@@ROWCOUNT>0, 1, 0);
	
	--******D E B U G *********
	--SELECT 'DEBUG', [@cobroRevertido] = @cobroRevertido, [@revertidoPorLiquidacion]=@revertidoPorLiquidacion;


	--***************************
	--******   @DEUDA   *********
	--***************************
	INSERT INTO @DEUDA(fclFacCod, fclFacCtrCod, fclFacPerCod, fclFacVersion, fclNumLinea
					, fclTrfSvCod, fclTrfCod
					, fclFecLiq, svcOrgCod
					, fcltotal
					, cldTotal
					, [@facTotal])
	--OUTPUT '@DEUDA (2)', INSERTED.*
	SELECT F.fclFacCod, F.fclFacCtrCod, F.fclFacPerCod, F.fclFacVersion, F.fclNumLinea
	, F.fclTrfSvCod, F.fclTrfCod
	, F.fclFecLiq, F.svcOrgCod
	, F.fcltotal
	, C.cldTotal
	, @facTotal_
	FROM @FCL AS F
	LEFT JOIN @COBRADO AS C
	ON F.fclFacCod = C.fclFacCod
	AND F.fclFacPerCod = C.fclFacPerCod
	AND F.fclFacCtrCod = C.fclFacCtrCod
	AND F.fclFacVersion = C.fclFacVersion
	AND F.fclNumLinea = C.fclNumLinea
	--Si revierte un cobro anterior (@cobroRevertido=1), omitimos los calculos 
	WHERE @cobroRevertido=0;


	WITH CTE AS(
	SELECT fclFacCod, fclFacCtrCod, fclFacPerCod, fclFacVersion, fclNumLinea
	--Agrupamos las lineas por organismo
	, DR_ORG = DENSE_RANK() OVER(ORDER BY svcOrgCod ASC) 	
	--Establecemos una prioridad de los cobros por organismo y linea por importe de deuda
	, CN = COUNT(fclFacCod) OVER()
	, RN = ROW_NUMBER() OVER (ORDER BY
	   CASE WHEN @revertidoPorLiquidacion=2  THEN IIF(fclFecLiq IS NULL, 0, 1)
	   ELSE IIF([cldDeuda]<>0, 0, 1) END
	 , svcOrgCod
	 , IIF(fclFecLiq IS NULL, 0, 1000) 
	 --Se ordenan según el signo de cobro y la deuda para saldar antes las de signos opuestos
	 , CASE WHEN SIGN(@cblImporte) = -1 AND SIGN([cldDeuda]) = -1 THEN 1
		    WHEN SIGN(@cblImporte) = -1 AND SIGN([cldDeuda]) = 1 THEN 2
		    WHEN SIGN(@cblImporte) = 1 AND SIGN([cldDeuda]) = -1 THEN 1
		    WHEN SIGN(@cblImporte) = 1 AND SIGN([cldDeuda]) = 1 THEN 2
		ELSE 1 END
	, fclTrfSvCod
	, fclNumLinea)
	--***************************************		
	  
	, CN_PDTES  = SUM(IIF([cldDeuda]=0, 0, 1)) OVER()
	, CN_NOLIQU = SUM(IIF(D.[fclFecLiq] IS NULL OR  D.[fclFecLiq]>C.[cobfecReg], 1, 0)) OVER()
	--, ORG_TOTAL = SUM(fclTotal) OVER(PARTITION BY IIF(svcOrgCod IS NULL OR D.[fclFecLiq]<=C.[cobfecReg], 0, 1) )
	, ORG_TOTAL = SUM(fclTotal) OVER(PARTITION BY CASE  WHEN svcOrgCod IS NULL THEN 0 
							    WHEN  D.[fclFecLiq]<=C.[cobfecReg] THEN 1 
							    ELSE 100 END)
	--Total Cobrado agrupando por en liquidadas/no liquidadas
	, LIQ_COBTOTAL = SUM(cldTotal) OVER(PARTITION BY IIF(D.[fclFecLiq]<=C.[cobfecReg], 1 , 0))
							      
	, COBTOTAL = SUM(cldTotal) OVER(PARTITION BY  IIF(D.[fclFecLiq] IS NOT NULL AND  D.[fclFecLiq]<=C.[cobfecReg], 1, 0))

	FROM @DEUDA AS D
	LEFT JOIN @CBL AS C
	ON  D.fclFacCod = C.facCod
	AND D.fclFacPerCod = C.facPerCod
	AND D.fclFacCtrCod = C.facCtrCod
	AND D.fclFacVersion = C.facVersion
	)

	UPDATE D
	SET D.DR_ORG = C.DR_ORG
	  , D.RN = C.RN
	  , D.CN_PDTES = CASE WHEN @revertidoPorLiquidacion IS NULL THEN C.CN_PDTES 
			 WHEN @revertidoPorLiquidacion= 1 THEN CN
			 WHEN @revertidoPorLiquidacion= 2 THEN CN_NOLIQU
			 ELSE C.CN_PDTES END
	  , D.[orgTotal] = ORG_TOTAL
	  , D.[cobTotalxLiq] = LIQ_COBTOTAL
	  , D.[@cobTotal] = COBTOTAL
	--OUTPUT ' DEUDA(3)', INSERTED.*
	FROM CTE AS C
	INNER JOIN @DEUDA AS D
	ON C.fclFacCod = D.fclFacCod
	AND C.fclFacCtrCod = D.fclFacCtrCod
	AND C.fclFacPerCod = D.fclFacPerCod
	AND C.fclFacVersion = D.fclFacVersion
	AND C.fclNumLinea = D.fclNumLinea;

	SELECT @CN_PDTES = MAX(CN_PDTES) FROM @DEUDA;
	

	--*****************************************
	--******   DESGLOSE PRIORITARIO   *********
	--*****************************************	
	DECLARE @RN INT = 0;
	DECLARE @REPARTIR MONEY = NULL;
	DECLARE @RN_REPARTIR INT = NULL;
	DECLARE @CLD_LINEAS INT;
	DECLARE @COBTOTAL MONEY;


	
	SELECT @CLD_LINEAS = COUNT(*)
	    , @COBTOTAL = MAX(IIF(RN=1 AND fclFecLiq IS NULL, [@cobTotal], NULL))
	FROM @DEUDA;
	
	IF @revertidoPorLiquidacion = 2
	BEGIN
		SELECT @cblImporte = SUM(cldImporte)*-1
		FROM dbo.cobLinDes AS CLD
		WHERE CLD.cldCblScd = @cblScd
			AND CLD.cldCblPpag = @cblPpag
			AND CLD.cldCblNum = @cblNum
			AND CLD.cldCblLin = 1;
		--***************************************
		--La liquidación implica repartir el importe cobrado sobrante entre las lineas no liquidadas
		SET @repartirLiq = ISNULL(@cblImporte, 0)- ISNULL(@COBTOTAL, 0);
		SET @cblImporte = @repartirLiq
		--***************************************
	END







	
	--******************************
	--******   RESULTADO   *********
	--******************************	
	--Si revierte un cobro anterior (@cobroRevertido=1), omitimos los calculos 
	WHILE (1=1 AND @cobroRevertido=0)
	BEGIN	
		
		--******************************
		--Si hay un cambio de organismo: Repartimos el importe restante proporcionalmente en las lineas restantes.
		SELECT @REPARTIR = @cblImporte
			 , @RN_REPARTIR = RN
			 , @break = IIF(@facDeuda_<>0 OR CN_PDTES<>0, 1, 0)
		FROM @DEUDA AS D
		WHERE RN=@RN+1 AND @REPARTIR IS NULL AND svcOrgCod IS NOT NULL;
		
		--******D E B U G *********
		--SELECT 'DEBUG' 
		--	 , [@REPARTIR] = @REPARTIR, [@RN_REPARTIR]=@RN_REPARTIR
		--	 , [@cblImporte]=@cblImporte, [@cblImporte_]=@cblImporte_
		--	 , [@break]= @break, [@facTotal_]= @facTotal_
		--	 , [@facDeuda_]=@facDeuda_, [@CLD_LINEAS]=@CLD_LINEAS
		--	 , [@revertidoPorLiquidacion] = @revertidoPorLiquidacion
		--	 , [@cobroRevertido] = @cobroRevertido;
		--******************************
		UPDATE D SET
		  [@cblImporte]= @cblImporte
		 ,[@cldImporte] =  CASE WHEN @cblImporte = 0 THEN 0
							--****************************************************
							--Cuando es un revertido por liquidación:
							--La primera linea devuelve todo lo cobrado por linea
							WHEN @revertidoPorLiquidacion IS NOT NULL AND @revertidoPorLiquidacion=1  THEN  D.cldTotal*-1 
							--La segunda linea intenta volver a cobrar. Cobrando lo mismo en las que no se han liquidado
							WHEN @revertidoPorLiquidacion IS NOT NULL AND @revertidoPorLiquidacion=2 AND @repartirLiq=0 THEN  D.cldTotal								
							--****************************************************
							
							--Cuando los servicios estan asociados a un organismo, se distribuye el importe de manera proporcional, aunque la factura esté pagada
							WHEN CN_PDTES=0 AND @REPARTIR IS NOT NULL AND @REPARTIR <> @facTotal_ AND RN<>@CLD_LINEAS THEN @REPARTIR*factor
							--Si es la ultima linea le dejamos el restante
							WHEN CN_PDTES=0 AND @REPARTIR IS NOT NULL AND @REPARTIR <> @facTotal_ AND RN=@CLD_LINEAS THEN @cblImporte
						
							
							--Nos limitamos a poner el importe de cada linea
							WHEN @break=0 THEN fcltotal*SIGN(@cblImporte_)*IIF(fclFecLiq IS NULL, 1, 0)
							
							--Si el importe del cobro es el mismo de la deuda: Nos limitamos a poner el importe pendiente de cada linea
							WHEN @facDeuda_=@cblImporte_ THEN cldDeuda
													
							--Si no hay lineas pendientes ponemos todo el cobro en la primera linea
							WHEN CN_PDTES=0  AND RN = 1 THEN @cblImporte
							
							--Cuando los servicios estan asociados a un organismo, se distribuye el importe restante de manera proporcional							
							WHEN @REPARTIR IS NOT NULL AND  RN<CN_PDTES THEN @REPARTIR*factor
							WHEN @REPARTIR IS NOT NULL AND  RN=CN_PDTES THEN @cblImporte
							
							--Si llegamos a la ultima linea pendiente de cobro y conseguimos saldar la ultima linea
							WHEN RN=CN_PDTES AND ROUND(@cblImporte_ - @cblImporte + cldDeuda, 2) = ROUND(@cblImporte_, 2)  THEN cldDeuda

							WHEN RN=CN_PDTES THEN  @cblImporte
							
							--*************************************
							
						
							--Aplicamos valor absoluto para comparar bien dos importes negativos.
							WHEN SIGN(@cblImporte) = SIGN(cldDeuda) AND ABS(@cblImporte)>ABS(cldDeuda) THEN  cldDeuda
												
							WHEN SIGN(@cblImporte) = SIGN(cldDeuda) THEN  @cblImporte					
											
							WHEN SIGN(@cblImporte) > SIGN(cldDeuda) THEN  cldDeuda
							
							WHEN SIGN(@cblImporte) < SIGN(cldDeuda) THEN  @cblImporte

							ELSE @cblImporte
							END
							
		FROM @DEUDA AS D 
		LEFT JOIN dbo.coblindes AS CLD
		ON @revertidoPorLiquidacion IS NOT NULL 
		AND CLD.cldCblScd = @cblScd
		AND CLD.cldCblPpag = @cblPpag
		AND CLD.cldCblNum = @cblNum
		AND CLD.cldCblLin = @revertidoPorLiquidacion-1
		AND CLD.cldFacLin = D.fclNumLinea
		WHERE RN=@RN+1;
		
		--Pendiente de repartir
		SELECT @RN=RN
			 , @cblImporte  = [@cblImporte]-[@cldImporte]  
		FROM @DEUDA AS D WHERE RN=@RN+1;

		--Se acabaron las lineas
		IF NOT EXISTS(SELECT 1 FROM @DEUDA WHERE RN>@RN)
			BREAK; 
		--Recorremos todas las lineas si o si		
		ELSE IF (@break=0)
			SET @break=0;	
		--Paramos en la última linea pendiente
		ELSE IF(@RN>=@CN_PDTES) 
		BEGIN
			--Antes de finalizar..
			--Actualizamos el total a repartir si la linea liquidada tenía cobros
			UPDATE D 
			SET [@cldImporte] = [@cldImporte]+cldTotal
			FROM @DEUDA AS D
			WHERE @revertidoPorLiquidacion IS NOT NULL AND  @revertidoPorLiquidacion=2 AND fclFecLiq IS NULL;
			BREAK;
		END
			 
	END

	SELECT [cblScd] = @cblScd
		 , [cblPpag] = @cblPpag
		 , [cblNum] = @cblNum
		 , [cblLin] = @cblLin
		 , D.fclNumLinea
		 , D.fclTrfSvCod
		 , D.fclTrfCod
		 , cldImporte = ISNULL([@cldImporte], 0)		 
	FROM @DEUDA AS D ORDER BY RN;


	IF (@DEBUG=1)
	SELECT * FROM @DEUDA AS D ORDER BY RN;


	--*****************************************
	--Si no sabemos que esta haciendo en PRO en el coblindes
	--Descomentar y mirar el traceerror.log 
	/*
	DECLARE @input AS VARCHAR(250);
	DECLARE CUR CURSOR FOR	
	SELECT FORMATMESSAGE('%i, %i, %i, %i, %i', @cblScd, @cblPpag, @cblNum, @cblLin, D.fclNumLinea)
	FROM @DEUDA AS D;
	OPEN CUR
	FETCH NEXT FROM CUR INTO @input
		WHILE @@FETCH_STATUS = 0 
		BEGIN
			PRINT '*****' + @input;
			FETCH NEXT FROM CUR INTO @input
		END
	CLOSE CUR
	DEALLOCATE CUR;
	*/
	--*****************************************
GO


