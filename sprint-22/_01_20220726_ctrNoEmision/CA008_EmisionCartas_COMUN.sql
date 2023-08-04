--EXEC ReportingServices.CA008_EmisionCartas_COMUN  @tipoProcedimiento=N'EXPEDIENTES', @fRegistroD='20220715'

CREATE PROCEDURE  ReportingServices.CA008_EmisionCartas_COMUN
  @tipoProcedimiento VARCHAR(15) = NULL
, @numPeriodosD INT = NULL		, @numPeriodosH INT = NULL
, @periodoD VARCHAR(6) = NULL	, @periodoH VARCHAR(6)= NULL
, @contratoD INT = NULL			, @contratoH INT = NULL
, @impDeudaD MONEY = NULL		, @impDeudaH MONEY = NULL
, @domiciliado BIT = NULL
, @esServicioMedido BIT = NULL
, @orden VARCHAR(50) = NULL

, @xmlIncLecUltFac	NVARCHAR(MAX)= NULL
, @xmlIncLecAlgunaFac	NVARCHAR(MAX)= NULL

, @zonaD  VARCHAR(4)= NULL		, @zonaH  VARCHAR(4)= NULL
, @ruta1D VARCHAR(10)= NULL		, @ruta1H VARCHAR(10)= NULL
, @ruta2D VARCHAR(10)= NULL		, @ruta2H VARCHAR(10)= NULL
, @ruta3D VARCHAR(10)= NULL		, @ruta3H VARCHAR(10)= NULL
, @ruta4D VARCHAR(10)= NULL		, @ruta4H VARCHAR(10)= NULL
, @ruta5D VARCHAR(10)= NULL		, @ruta5H VARCHAR(10)= NULL
, @ruta6D VARCHAR(10)= NULL		, @ruta6H VARCHAR(10)= NULL

, @tieneFCarta BIT= NULL
, @incluirEfectosPendientes BIT= NULL
, @tieneFCierre BIT= NULL
, @estado VARCHAR(10)= NULL
, @importeMinimoDevolucion MONEY= NULL
, @bancoCodigo SMALLINT= NULL
, @incluirClientesVip BIT= NULL

, @xmlRepresentantesArray	NVARCHAR(MAX)= NULL
, @xmlSerCodArray			NVARCHAR(MAX)= NULL
, @listaContratos			NVARCHAR(MAX)= NULL

, @cobroFecReg DATETIME= NULL
, @tieneFCorte BIT= NULL
, @soloDevoluciones BIT= NULL
, @numeroD INT= NULL				, @numeroH INT= NULL
, @motcierreD INT= NULL				, @motcierreH INT= NULL
, @otNumeroD INT= NULL				, @otNumeroH INT= NULL
, @otSerieD INT= NULL				, @otSerieH INT= NULL
, @otSociedadD INT= NULL			, @otSociedadH INT= NULL
, @fCierreD DATETIME= NULL			, @fCierreH DATETIME= NULL
, @fCorteD DATETIME= NULL			, @fCorteH DATETIME= NULL
, @fOrdenTrabajoD DATETIME= NULL	, @fOrdenTrabajoH DATETIME= NULL
, @fRegistroD DATETIME= NULL		, @fRegistroH DATETIME= NULL
, @fCartaD DATETIME= NULL			, @fCartaH DATETIME= NULL
, @listaDevoluciones NTEXT= NULL
, @totalFacturaD INT= NULL
, @fechaFacturaD DATETIME= NULL		, @fechaFacturaH DATETIME= NULL
, @excluirNoEmitir BIT=1

AS


--*****************************************
--Catastro_CA009_EmisionCartas
IF @tipoProcedimiento='CARTAS' 
	EXEC dbo.CartasEmision_Select @numPeriodosD, @periodoD, @periodoH, @contratoD, @contratoH, 
								  @impDeudaD, @impDeudaH, @domiciliado, @esServicioMedido, @orden, 
								  @xmlIncLecUltFac, @xmlIncLecAlgunaFac, @zonaD, @zonaH, @ruta1D, @ruta1H, 
								  @ruta2D, @ruta2H, @ruta3D, @ruta3H, @ruta4D, @ruta4H, @ruta5D, @ruta5H, 
								  @ruta6D, @ruta6H, @incluirEfectosPendientes, @numPeriodosH, @incluirClientesVip, 
								  @estado, @xmlSerCodArray, @importeMinimoDevolucion, @bancoCodigo, @cobroFecReg,
								  @soloDevoluciones, @xmlRepresentantesArray, @listaContratos,
								  @excluirNoEmitir;

--*****************************************
--Cobros_Controles_ctrExpedientesCortePRINT
ELSE IF @tipoProcedimiento='EXPEDIENTES' 
	EXEC dbo.CartasExpCorte_Select	@numPeriodosD, @contratoD, @contratoH, @tieneFCarta, 
									@tieneFCierre, @tieneFCorte, @numeroD, @numeroH, @motcierreD, 
									@motcierreH, @otNumeroD, @otNumeroH, @otSerieD, @otSerieH, 
									@otSociedadD, @otSociedadH, @fCierreD, @fCierreH, @fCorteD, 
									@fCorteH, @fOrdenTrabajoD, @fOrdenTrabajoH,  @fRegistroD, 
									@fRegistroH, @fCartaD, @fCartaH, @impDeudaD, @impDeudaH, @orden,
									@xmlRepresentantesArray,-- @estado
									@excluirNoEmitir;

--*****************************************
--Cobros_Controles_ctrDevolucionesC19PRINT
ELSE IF @tipoProcedimiento='DEVOLUCIONES' 
	EXEC dbo.CartasDevoluciones_Select @listaDevoluciones, @orden, @xmlRepresentantesArray
									 , @excluirNoEmitir;

--*****************************************
--Contabilidad_AC017_347
ELSE IF @tipoProcedimiento='347' 
	EXEC dbo.CartasClientes347_Select @totalFacturaD, @fechaFacturaD, @fechaFacturaH, @xmlRepresentantesArray
									, @excluirNoEmitir;

--*****************************************
ELSE
	EXEC dbo.CartasEmision_Select @numPeriodosD, @periodoD, @periodoH, @contratoD, @contratoH, 
								  @impDeudaD, @impDeudaH, @domiciliado, @esServicioMedido, @orden, 
								  @xmlIncLecUltFac, @xmlIncLecAlgunaFac, @zonaD, @zonaH, @ruta1D, @ruta1H, 
								  @ruta2D, @ruta2H, @ruta3D, @ruta3H, @ruta4D, @ruta4H, @ruta5D, @ruta5H, 
								  @ruta6D, @ruta6H, @incluirEfectosPendientes, @numPeriodosH, @incluirClientesVip, 
								  @estado, @xmlSerCodArray, @importeMinimoDevolucion, @bancoCodigo, @cobroFecReg,
								  @soloDevoluciones, @xmlRepresentantesArray, @listaContratos,
								  @excluirNoEmitir;
GO	
	
