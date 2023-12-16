--SELECT * FROM  vOtInspecciones_Melilla WHERE ctrcod=2812

ALTER VIEW vOtInspecciones_Melilla 
AS

--El contrato de la inspeccion lo determina la tabla contratos
SELECT I.objectid
, ctrcod = ISNULL(C.[CONTRATO ABONADO], I.ctrcod)
, [CTRCOD_INSPECCION] = I.ctrcod
, Apta = V.otdvValor
, I.fecha_y_hora_de_entrega_efectiv 
, I.servicio
, I.zona
, C.[CONTRATO ABONADO]
, zonCod = CAST(LTRIM(RTRIM(REPLACE(UPPER(I.zona), 'ZONA',  ''))) AS INT)
--RN=1: Para quedarnos con la inspección mas reciente del contrato
, RN = ROW_NUMBER() OVER (PARTITION BY ISNULL(C.[CONTRATO ABONADO], I.ctrcod) ORDER BY  I.fecha_y_hora_de_entrega_efectiv DESC, objectid DESC)
, CN = COUNT(I.objectid) OVER (PARTITION BY ISNULL(C.[CONTRATO ABONADO], I.ctrcod))
, CHECKED = SUM(IIF(V.otdvValor IN ('SI', 'APTO 100%'), 1, 0)) OVER (PARTITION BY ISNULL(C.[CONTRATO ABONADO], I.ctrcod))
, INSPECCION_GENERAL = IIF(C.[CONTRATO ABONADO] IS NULL OR C.[CONTRATO ABONADO] = I.ctrcod, 1, 0) 
, NUM_ABONADOS = COUNT(C.[CONTRATO ABONADO] ) OVER (PARTITION BY objectid)
FROM otInspecciones_Melilla AS I 
LEFT JOIN dbo.otInspeccionesContratos_Melilla AS C
ON I.objectid = C.INSPECCION
INNER JOIN dbo.otDatosValor AS V
ON V.otdvOtSerCod = I.otisercod
AND V.otdvOtSerScd = I.otiserscd
AND V.otdvOtNum = I.otinum

GO