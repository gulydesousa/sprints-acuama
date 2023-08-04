ALTER PROCEDURE [dbo].[EfectosPendientes_Insert]
(
	@efePdteCod INT = NULL OUTPUT,
	@efePdteCtrCod INT,
	@efePdtePerCod VARCHAR(6),
	@efePdteFacCod SMALLINT,
	@efePdteImporte MONEY,
	@efePdteCCC VARCHAR(20) = NULL,
	@efePdteTitCCC VARCHAR(40) = NULL,
	@efePdteDocIdenCCC VARCHAR(12) = NULL,
	@efePdteFecRemDesde DATETIME,
	@efePdteUsrCod VARCHAR(10),
	@efePdteFecReg DATETIME = NULL,
	@efePdteFecRemesada DATETIME = NULL,
	@efePdteUsrRemesada VARCHAR(10) = NULL,
	@efePdteFecSelRemesa DATETIME = NULL,
	@efePdteUsrSelRemesa VARCHAR(10) = NULL,
	@efePdteFecRechazado DATETIME = NULL,
	@efePdteUsrRechazado VARCHAR(10) = NULL,
	@efePdteScd SMALLINT,
	@efePdteIban VARCHAR(34) = NULL,
	@efePdteBic VARCHAR(11) = NULL,
	@efePdteDirCta VARCHAR(50) = NULL,
	@efePdtePobCta VARCHAR(40) = NULL,
	@efePdtePrvCta VARCHAR(20) = NULL,
	@efePdteCPosCta VARCHAR(5) = NULL,
	@efePdteNacCta VARCHAR(3) = NULL,
	@efePdteManRef VARCHAR(35) = NULL
	--Efectos No-Domiciliados
	, @efePdteDomiciliado BIT = NULL
	--, @efePdteFecVencimiento DATETIME = NULL
	--, @efePdteRegMarcado BIT = 0
)
AS
	SET NOCOUNT OFF;

SET @efePdteCod = ISNULL(@efePdteCod, (SELECT ISNULL(MAX(efePdteCod),0) + 1 FROM efectosPendientes WHERE @efePdteCtrCod=efePdteCtrCod AND @efePdteFacCod=efePdteFacCod AND @efePdtePerCod=efePdtePerCod AND @efePdteScd=efePdteScd))

INSERT INTO efectosPendientes 
		(efePdteCod,
		 efePdteCtrCod,
		 efePdtePerCod,
		 efePdteFacCod,
		 efePdteImporte,
		 efePdteCCC,
		 efePdteTitCCC,
		 efePdteDocIdenCCC,
		 efePdteFecRemDesde,
		 efePdteUsrCod,
		 efePdteFecReg,
		 efePdteFecRemesada,
		 efePdteUsrRemesada,
		 efePdteFecSelRemesa,
		 efePdteUsrSelRemesa,
		 efePdteFecRechazado,
		 efePdteUsrRechazado,
		 efePdteScd,
		 efePdteIban,
		 efePdteBic,
		 efePdteDirCta,
		 efePdtePobCta,
		 efePdtePrvCta,
		 efePdteCPosCta,
		 efePdteNacCta,
		 efePdteManRef
		 --Efectos No-Domiciliados
		 , efePdteDomiciliado
		 --, efePdteFecVencimiento
		 --, efePdteRegMarcado
		 )
 VALUES 
		(@efePdteCod,
		 @efePdteCtrCod,
		 @efePdtePerCod,
		 @efePdteFacCod,
		 @efePdteImporte,
		 @efePdteCCC,
		 @efePdteTitCCC,
		 @efePdteDocIdenCCC,
		 @efePdteFecRemDesde,
		 @efePdteUsrCod,
		 ISNULL(@efePdteFecReg,GETDATE()),
		 @efePdteFecRemesada,
		 @efePdteUsrRemesada,
		 @efePdteFecSelRemesa,
		 @efePdteUsrSelRemesa,
		 @efePdteFecRechazado,
		 @efePdteUsrRechazado,
		 @efePdteScd,
		 @efePdteIban,
		 @efePdteBic,
		 @efePdteDirCta,
		 @efePdtePobCta,
		 @efePdtePrvCta,
		 @efePdteCPosCta,
		 @efePdteNacCta,
		 @efePdteManRef
		 --Efectos No-Domiciliados
		 , @efePdteDomiciliado
		 --, @efePdteFecVencimiento
		 --, @efePdteRegMarcado
		 )

GO


