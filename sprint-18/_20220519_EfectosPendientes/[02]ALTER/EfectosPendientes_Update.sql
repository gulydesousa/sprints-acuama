ALTER PROCEDURE [dbo].[EfectosPendientes_Update]
(
	@efePdteCod INT = NULL,
	@efePdteCtrCod INT = NULL,
	@efePdtePerCod VARCHAR(6) = NULL,
	@efePdteFacCod SMALLINT = NULL,
	@efePdteImporte MONEY = NULL,
	@efePdteCCC VARCHAR(20) = NULL,
	@efePdteTitCCC VARCHAR(40) = NULL,
	@efePdteDocIdenCCC VARCHAR(12) = NULL,
	@efePdteFecRemDesde DATETIME = NULL,
	@efePdteUsrCod VARCHAR(10) = NULL,
	@efePdteFecReg DATETIME = NULL,
	@efePdteFecRemesada DATETIME = NULL,
	@efePdteUsrRemesada VARCHAR(10) = NULL,
	@efePdteFecSelRemesa DATETIME = NULL,
	@efePdteUsrSelRemesa VARCHAR(10) = NULL,
	@efePdteFecRechazado DATETIME = NULL,
	@efePdteUsrRechazado VARCHAR(10) = NULL,
	@efePdteScd SMALLINT = NULL,
	@efePdteIban VARCHAR(34) = NULL,
	@efePdteBic VARCHAR(11) = NULL,
	@efePdteDirCta VARCHAR(50) = NULL,
	@efePdtePobCta VARCHAR(40) = NULL,
	@efePdtePrvCta VARCHAR(20) = NULL,
	@efePdteCPosCta VARCHAR(5) = NULL,
	@efePdteNacCta VARCHAR(3) = NULL,
	@efePdteManRef VARCHAR(35) = NULL
	--Efectos No-Domiciliados
	, @efePdteDomiciliado BIT = 1
	--, @efePdteFecVencimiento DATETIME = NULL
	--, @efePdteRegMarcado BIT = NULL
)
AS
	SET NOCOUNT OFF;
UPDATE efectosPendientes 
SET 
		efePdteCod = @efePdteCod,
		efePdteCtrCod = @efePdteCtrCod,
		efePdtePerCod = @efePdtePerCod,
		efePdteFacCod = @efePdteFacCod,
		efePdteImporte = @efePdteImporte,
		efePdteCCC = @efePdteCCC,
		efePdteTitCCC = @efePdteTitCCC,
		efePdteDocIdenCCC = @efePdteDocIdenCCC,
		efePdteFecRemDesde = @efePdteFecRemDesde,
		efePdteUsrCod = @efePdteUsrCod,
		efePdteFecReg = @efePdteFecReg,
		efePdteFecRemesada = @efePdteFecRemesada,
		efePdteUsrRemesada = @efePdteUsrRemesada,
		efePdteFecSelRemesa = @efePdteFecSelRemesa,
		efePdteUsrSelRemesa = @efePdteUsrSelRemesa,
		efePdteFecRechazado = @efePdteFecRechazado,
		efePdteUsrRechazado = @efePdteUsrRechazado,
		efePdteScd=@efePdteScd,
		efePdteIban = @efePdteIban,
		efePdteBic = @efePdteBic,
		efePdteDirCta= @efePdteDirCta,
		efePdtePobCta = @efePdtePobCta,
		efePdtePrvCta = @efePdtePrvCta,
		efePdteCPosCta = @efePdteCPosCta,
		efePdteNacCta = @efePdteNacCta,
		efePdteManRef = @efePdteManRef
		--Efectos No-Domiciliados
		, efePdteDomiciliado = ISNULL(@efePdteDomiciliado, 1)
		--, efePdteFecVencimiento = @efePdteFecVencimiento
		--, efePdteRegMarcado = efePdteRegMarcado
WHERE 
	(@efePdteCod IS NULL OR efePdteCod = @efePdteCod)
AND (@efePdteCtrCod IS NULL OR efePdteCtrCod = @efePdteCtrCod)
AND (@efePdtePerCod IS NULL OR efePdtePerCod = @efePdtePerCod)
AND (@efePdteFacCod IS NULL OR efePdteFacCod = @efePdteFacCod)
AND (@efePdteScd IS NULL OR efePdteScd = @efePdteScd)


GO


