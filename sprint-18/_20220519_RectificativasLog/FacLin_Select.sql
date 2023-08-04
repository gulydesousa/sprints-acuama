ALTER PROCEDURE [dbo].[FacLin_Select]
@codigo smallint = NULL,
@periodo varchar(6) = NULL,
@contrato int = NULL,
@version smallint =NULL,
@numero int = NULL,
@servicioCodigo smallint = NULL,
@tarifaCodigo smallint = NULL
AS
	SET NOCOUNT ON;

	SELECT fclFacCod,fclFacPerCod,fclFacCtrCod,fclFacVersion,fclNumLinea,fclTrfSvCod,fclTrfCod,fclEscala1,fclPrecio1,fclUnidades1,fclEscala2,fclPrecio2,fclUnidades2,fclEscala3,fclPrecio3,fclUnidades3,
	fclEscala4,fclPrecio4,fclUnidades4,fclEscala5,fclPrecio5,fclUnidades5,fclEscala6,fclPrecio6,fclUnidades6,fclEscala7,fclPrecio7,fclUnidades7,fclEscala8,fclPrecio8,fclUnidades8,fclEscala9,
	fclPrecio9,fclUnidades9,fcltotal,fclUnidades,fclPrecio,fclBase,fclImpImpuesto,fclImpuesto, fclFecLiq, fclUsrLiq, fclCtsUds, fclFecLiqImpuesto, fclUsrLiqImpuesto

	FROM [dbo].[faclin] WITH (INDEX(PK_faclin))
	WHERE (@codigo IS NULL OR fclFacCod = @codigo) AND
		  (@periodo IS NULL OR fclFacPerCod = @periodo) AND
		  (@contrato IS NULL OR fclFacCtrCod = @contrato) AND
		  (@version IS NULL OR fclFacVersion = @version) AND
		  (@numero IS NULL OR fclNumLinea = @numero) AND
		  (@servicioCodigo IS NULL OR fclTrfSvCod = @servicioCodigo) AND
		  (@tarifaCodigo IS NULL OR fclTrfCod = @tarifaCodigo)
	ORDER BY fclNumLinea
	OPTION(RECOMPILE);

GO


