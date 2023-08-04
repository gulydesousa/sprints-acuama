ALTER PROCEDURE [dbo].[Tasks_Remesas_Seleccion] 
@usuario VARCHAR(14),
@sociedad SMALLINT,
@zonaDesde VARCHAR(4) = NULL,
@zonaHasta VARCHAR(4) = NULL,
@periodoDesde VARCHAR(6) = NULL,
@periodoHasta VARCHAR(6) = NULL,
@contratoDesde INT = NULL,
@contratoHasta INT = NULL,
@serieDesde SMALLINT = NULL,
@serieHasta SMALLINT = NULL,
@numFacturaDesde VARCHAR(20) = NULL,
@numFacturaHasta VARCHAR(20) = NULL,
@bancoDesde SMALLINT = NULL,
@bancoHasta SMALLINT = NULL,
@verPendientes BIT = NULL,
@verRemesados BIT = NULL,
@remVersionCtrCCC VARCHAR(2), -- Indica si el CCC se coge de la versión de la factura 'VF' o de la última versión del contrato 'UV'
@sinEfectosPdtes BIT = NULL, --Indica si se deben insertar facturas que tengan efectos pendientes a remesar
@regAfectados INTEGER OUT, --Registros insertados

/*El servicio windows ha de establecer los siguientes parámetros.
  Si se desea llamar a este procedimiento desde otro lugar que no sea el servicio windows
  no se ha de pasar los siguientes parámetros*/
@tskUser VARCHAR(10) = NULL, --Usuario que ejecuta la tarea
@tskType SMALLINT = NULL, --Tipo de tarea
@tskNumber INT = NULL --Número de tarea

, @porUsuario BIT = 1
AS 
	SET NOCOUNT ON; 

	DECLARE @periodoInicio AS VARCHAR(6) --Periodo inicio de explotación
	SELECT @periodoInicio = pgsValor FROM parametros WHERE pgsClave = 'PERIODO_INICIO'

	DECLARE @CANCEL AS BIT

	--Contiene el código del error
	DECLARE @myError int

	BEGIN TRANSACTION

	INSERT INTO remesasTrab(remUsrCod, remCtrCod, remPerCod, remFacCod, remEfePdteCod, remZonCod, remPerTipo,
							remSerCod, remSerScdCod, remFacNumero, remFacTotal, remPagado, remVersionCtrCCC)
	SELECT 
	    @usuario,
	    facCtrCod, 
		facPerCod, 
		facCod,
		0, -- 0 por defecto cuando se insertar en remesasTrab un efecto desde la factura, cuando es desde la tabla efectosPendientes se pone su codigo
		facZonCod, 
		perTipo, 
		facSerCod, 
		facSerScdCod, 
		facNumero,
		remFacTotal = ROUND(ISNULL(ftfImporte, 0), 2),
		remPagado = ROUND(ISNULL(ftcImporte, 0), 2),
		@remVersionCtrCCC
	FROM facturas f
		INNER JOIN contratos ON facCtrCod = ctrCod 
			AND ctrVersion = CASE @remVersionCtrCCC WHEN 'VF' THEN facCtrVersion ELSE (SELECT MAX(ctrVersion) FROM contratos cSub WHERE cSub.ctrCod = contratos.ctrCod) END
		INNER JOIN periodos ON perCod = facPerCod
		--PARA CALCULAR TOTALES
		LEFT JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod=facCod AND ftfFacPerCod=facPerCod  AND ftfFacCtrCod=facCtrCod AND ftfFacVersion=facVersion
		LEFT JOIN fFacturas_TotalCobrado(NULL) ON ftcCtr = ctrCod AND ftcScd = facSerScdCod AND ftcFacCod = facCod aND ftcPer = facPerCod
	WHERE
		facFechaRectif IS NULL AND --Sólo facturas NO anuladas (y por tanto últimas versiones)
		--El cliente debe tener domiciliado el pago
		ctrIBAN IS NOT NULL AND ctrBIC IS NOT NULL AND		
		(facSerScdCod = @sociedad OR @sociedad IS NULL) AND
		(facSerCod >= @serieDesde OR @serieDesde IS NULL) AND
		(facSerCod <= @serieHasta OR @serieHasta IS NULL) AND
		(facPerCod >= @periodoDesde OR @periodoDesde IS NULL) AND
		(facPerCod <= @periodoHasta OR @periodoHasta IS NULL) AND
		(facCtrCod >= @contratoDesde OR @contratoDesde IS NULL) AND
		(facCtrCod <= @contratoHasta OR @contratoHasta IS NULL) AND
		(facNumero >= @numFacturaDesde OR @numFacturaDesde IS NULL) AND
		(facNumero <= @numFacturaHasta OR @numFacturaHasta IS NULL) AND
		(@bancoDesde IS NULL OR LEFT(ctrCCC,4) >= @bancoDesde) AND 
		(@bancoHasta IS NULL OR LEFT(ctrCCC,4) <= @bancoHasta) AND
		(facFechaRemesa IS NOT NULL OR @verPendientes = 1 OR @verPendientes IS NULL) AND
		(facFechaRemesa IS NULL OR @verRemesados = 1 OR @verRemesados IS NULL) AND
		(ctrZonCod >= @zonaDesde OR @zonaDesde IS NULL) AND
		(ctrZonCod <= @zonaHasta OR @zonaHasta IS NULL) AND
		
		--Sólo remesaremos facturas con empresa, serie, número y fecha
		facFecha IS NOT NULL AND
		ISNULL(facSerScdCod, 0) <> 0 AND
		ISNULL(facSerCod, 0) <> 0 AND
		facNumero IS NOT NULL AND
		
		--Sólo remesaremos las facturas cuyo periodo sea mayor o igual que el periodo de inicio de la explotación
		((facPerCod >= @periodoInicio OR facPerCod LIKE '0000%') OR @periodoInicio IS NULL) AND
		
		--Solo seleccionamos las facturas que no estén apremiadas
		NOT EXISTS(SELECT aprFacCtrCod 
				   FROM apremios
				   WHERE
						facCtrCod = aprFacCtrCod AND
						facCod = aprFacCod AND
						facPerCod = aprFacPerCod
				   ) AND
		
		--Sólo seleccionamos las facturas que no estén ya en remesasTrab
		NOT EXISTS(SELECT remUsrCod 
					FROM remesasTrab 
					WHERE remSerScdCod = @sociedad AND
						  (@porUsuario=0 OR remUsrCod = @usuario) AND 
						  remCtrCod = facCtrCod AND 
						  remPerCod = facPerCod AND
						  remFacCod = facCod AND
						  remEfePdteCod = 0) AND -- 0 por defecto cuando se insertar en remesasTrab un efecto desde la factura, cuando es desde la tabla efectosPendientes se pone su codigo
	
		(@sinEfectosPdtes IS NULL OR @sinEfectosPdtes = 0 OR
			(@sinEfectosPdtes = 1 AND
			 NOT EXISTS(SELECT efePdteCod 
						FROM   efectosPendientes 
						WHERE  efePdteScd = @sociedad AND
							   efePdteCtrCod = facCtrCod AND 
							   efePdtePerCod = facPerCod AND
							   efePdteFacCod = facCod AND
							   efePdteFecRechazado IS NULL AND efePdteFecRemesada IS NULL)
			)		
		) AND
	
		--El cliente tiene que deber dinero para que aparezca aquí
		ROUND(ISNULL(ftfImporte, 0), 2) > ROUND(ISNULL(ftcImporte, 0), 2) AND
		--Solo se pueden remesar contratos que NO tengan activa la factura electrónica
		facEnvSERES IS NULL

	SELECT @myError = @@ERROR, @regAfectados = @@ROWCOUNT

	--COMPROBAR ERROR
	IF @myError <> 0
		GOTO HANDLE_ERROR

	--OPERACIONES EN MODO TAREA (ejecución desde el servicio windows):
	IF @tskUser IS NOT NULL AND @tskType IS NOT NULL AND @tskNumber IS NOT NULL
	BEGIN
		--COMPROBAR SI EL USUARIO DESEA CANCELAR LA OPERACIÓN
		EXEC @CANCEL = Task_Schedule_CHECK_STOP @tskUser, @tskType, @tskNumber
		IF @CANCEL = 1 BEGIN CLOSE c DEALLOCATE c
			GOTO CANCEL END
	END

	COMMIT TRANSACTION

	RETURN 0

HANDLE_ERROR:
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	SET @regAfectados = 0
	RETURN @myError

CANCEL:
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	SET @regAfectados = 0
	RETURN 0

GO


