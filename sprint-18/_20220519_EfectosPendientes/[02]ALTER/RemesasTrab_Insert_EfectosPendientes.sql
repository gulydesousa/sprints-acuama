ALTER PROCEDURE [dbo].[RemesasTrab_Insert_EfectosPendientes]
(
	@remUsrCod VARCHAR(14),
	@remSerScdCod SMALLINT,
	@regAfectados INTEGER OUT --Registros insertados
)
AS
	SET NOCOUNT ON;

DECLARE @periodoInicio AS VARCHAR(6) --Periodo inicio de explotación
SELECT  @periodoInicio = pgsValor FROM parametros WHERE pgsClave = 'PERIODO_INICIO'

--Contiene el código del error
DECLARE @myError int

BEGIN TRANSACTION

INSERT INTO remesasTrab(remUsrCod, remCtrCod, remPerCod, remEfePdteCod, remFacCod, remZonCod, remPerTipo,
						remSerCod, remSerScdCod, remFacNumero, remFacTotal, remPagado, remVersionCtrCCC)
	SELECT 
	    @remUsrCod,
	    efePdteCtrCod, 
		efePdtePerCod,
		efePdteCod, 
		efePdteFacCod,
		facZonCod, 
		perTipo, 
		facSerCod, 
		facSerScdCod, 
		facNumero,
		ISNULL(ftfImporte, 0),
		ISNULL(ftcImporte, 0),
		'EP'
	FROM efectosPendientes e1
		INNER JOIN facturas ON efePdteFacCod = facCod AND efePdtePerCod = facPerCod AND efePdteCtrCod = facCtrCod AND  facSerScdCod = efePdteScd
		INNER JOIN periodos ON perCod = efePdtePerCod
		LEFT JOIN fFacturas_TotalFacturado(NULL, 0, NULL) ON ftfFacCod=facCod AND ftfFacPerCod=facPerCod  AND ftfFacCtrCod=facCtrCod AND ftfFacVersion=facVersion
		LEFT JOIN fFacturas_TotalCobrado(NULL) ON ftcCtr = efePdteCtrCod AND ftcScd = facSerScdCod AND ftcFacCod = efePdteFacCod aND ftcPer = efePdtePerCod
	WHERE
		--Solo facturas NO anuladas (y por tanto últimas versiones)
		facFechaRectif IS NULL AND 
		
		--Solo remesaremos facturas con empresa, serie, número y fecha
		facFecha IS NOT NULL AND
		ISNULL(facSerScdCod, 0) <> 0 AND
		ISNULL(facSerCod, 0) <> 0 AND
		facNumero IS NOT NULL AND
		
		--Solo remesaremos las facturas cuyo periodo sea mayor o igual que el periodo de inicio de la explotación
		((efePdtePerCod >= @periodoInicio OR efePdtePerCod LIKE '0000%') OR @periodoInicio IS NULL) AND
		
		--Solo seleccionamos las facturas que no estén ya en remesasTrab
		NOT EXISTS(SELECT remUsrCod 
					FROM remesasTrab 
					WHERE remUsrCod = @remUsrCod AND 
						  remCtrCod = efePdteCtrCod AND 
						  remPerCod = efePdtePerCod AND
						  remFacCod = efePdteFacCod AND
						  remEfePdteCod = efePdteCod AND
						  remSerScdCod = @remSerScdCod) AND
		
		(@remSerScdCod = efePdteScd) AND				  
		--EL importe del efecto debe ser menor o igual al importe pendiente
		ISNULL(efePdteImporte, 0) <= (ISNULL(ftfImporte, 0) - ISNULL(ftcImporte, 0)) AND
		
		--Solo seleccionamos los efectos pendientes que no este rechazados ni remesados
		efePdteFecRechazado IS NULL AND
		efePdteFecRemesada IS NULL AND
		
		
		--Solo seleccionados efectos pendientes con fecha menor o igual a hoy
		efePdteFecRemDesde <= GETDATE() AND
		
		ISNULL((SELECT SUM(efePdteImporte) FROM efectosPendientes e2 WHERE efePdteFecRechazado IS NULL AND efePdteFecRemesada IS NULL AND e2.efePdteCtrCod = e1.efePdteCtrCod AND e2.efePdteFacCod = e1.efePdteFacCod AND e2.efePdtePerCod = e1.efePdtePerCod AND e2.efePdteFecRemDesde <= GETDATE()  GROUP BY efePdtefacCod, efePdtePerCod, efePdteCtrCod), 0) <= (ISNULL(ftfImporte, 0) - ISNULL(ftcImporte, 0))

		AND E1.efePdteDomiciliado = 1;

SELECT @myError = @@ERROR, @regAfectados = @@ROWCOUNT

--COMPROBAR ERROR
IF @myError <> 0
	GOTO HANDLE_ERROR

COMMIT TRANSACTION

RETURN 0

HANDLE_ERROR:
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	SET @regAfectados = 0
	RETURN @myError
		







GO


