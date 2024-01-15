--************************
--SELECT * FROM dbo.vLiquidacionesTributos
--************************

CREATE VIEW dbo.vLiquidacionesTributos
AS

WITH DESCUENTOS AS(
SELECT tribSvcDescuento
FROM dbo.LiquidacionesTributosServicios AS D 
WHERE D.tribSvcDescuento IS NOT NULL
)

SELECT T.liqTipoId
, [ENTEMI] = T.liqEntidadEmisora
, [TRIBUTO] = T.liqCodTributo
, [CONCEPTO_COD] = T.liqConceptoTributo
, [CONCEPTO] = T.liqDescripcionTributo 
, S.svccod
, S.svcdes
, S.svcLiquidable
, S.svctipo
, S.svcOrgCod
, TS.tribSvcDescuento

, [SUBCONCEPTO] = TS.tribCodigo
, [SUBCONCEPTO_COD] = TT.tribConcTributa
, [SUBCONCEPTO_DESC] = TT.tribDescripcion
, [esDescuento]  = IIF(D.tribSvcDescuento IS NULL, 0, 1)
FROM dbo.liquidacionesTipos AS T
INNER JOIN dbo.Servicios AS S
ON S.svcLiquidable = 1
AND (T.liqOrganismoId IS NULL OR S.svcOrgCod= T.liqOrganismoId)
INNER JOIN dbo.LiquidacionesTributosServicios AS TS
ON TS.tribSvcCod=S.svccod
INNER JOIN dbo.LiquidacionesTributos AS TT
ON TT.tribCodigo=TS.tribCodigo
LEFT JOIN DESCUENTOS AS D
ON D.tribSvcDescuento = S.svccod


GO


