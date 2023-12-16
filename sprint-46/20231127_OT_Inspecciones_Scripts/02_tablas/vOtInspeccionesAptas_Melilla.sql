--SELECT * FROM  otInspeccionesContratos_Melilla WHERE INSPECCION=3100
--SELECT * FROM vOtInspecciones_Melilla WHERE objectid=3100
ALTER VIEW vOtInspecciones_Melilla 
AS

SELECT  I.objectid
, ctrcod = ISNULL(C.[CONTRATO ABONADO], I.ctrcod)
, I.contrato
, [Apta] = V.otdvValor
, C.[CONTRATO ABONADO]
, I.fecha_y_hora_de_entrega_efectiv 
--RN=1: para quedarnos con la última inspeccion de cada contrato
, RN = ROW_NUMBER() OVER (PARTITION BY ISNULL(C.[CONTRATO ABONADO], I.ctrcod) ORDER BY  I.fecha_y_hora_de_entrega_efectiv DESC)
FROM otInspecciones_Melilla AS I 
INNER JOIN dbo.otDatosValor AS V
ON V.otdvOtSerCod = I.otisercod
AND V.otdvOtSerScd = I.otiserscd
AND V.otdvOtNum = I.otinum
LEFT JOIN  otInspeccionesContratos_Melilla AS C
ON C.INSPECCION =I.objectid AND C.[CONTRATO ABONADO]<>I.contrato;

GO