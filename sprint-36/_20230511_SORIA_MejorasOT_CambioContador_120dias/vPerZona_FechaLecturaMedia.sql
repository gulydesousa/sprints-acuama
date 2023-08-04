--SELECT * FROM dbo.vPerZona_FechaLecturaMedia WHERE facZonCod='0321' ORDER BY facctrcod Desc

ALTER VIEW dbo.vPerZona_FechaLecturaMedia 
AS
WITH LEC AS(
--Prefacturas: Zonas abiertas
SELECT  F.faccod, F.facCtrcod, F.facPerCod, F.facVersion, F.facZonCod, F.facLecAct, F.facLecActFec, facLecLector, facLecLectorFec, F.facLecInlCod, I.inmcalle
, ctrRuta = FORMATMESSAGE('%s .%s .%s .%s .%s .%s', ISNULL(C.ctrRuta1, ''), ISNULL(C.ctrRuta2, ''), ISNULL(C.ctrRuta3, ''), ISNULL(C.ctrRuta4, ''), ISNULL(C.ctrRuta5, ''), ISNULL(C.ctrRuta6, ''))
--Fecha media de lectura en toda la calle y zona
, fecLector_calle = AVG(CONVERT(FLOAT, facLecLectorFec)) OVER(PARTITION BY facPerCod, facZonCod, inmcalle)
, fecLector_zona  = AVG(CONVERT(FLOAT, facLecLectorFec)) OVER(PARTITION BY F.facPerCod, F.facZonCod)
--*************************
, CN = COUNT(facPerCod) OVER(PARTITION BY facPerCod, facZonCod) --Facturas por zona
, LC = SUM(IIF(facLecLectorFec IS NOT NULL, 1, 0)) OVER(PARTITION BY facPerCod, facZonCod) -- Lecturas por Zona
--Numero de facturas por calle
--, CN = COUNT(facPerCod) OVER(PARTITION BY facPerCod, facZonCod, inmcalle)
--, RN = ROW_NUMBER() OVER(PARTITION BY facPerCod, facZonCod, inmcalle ORDER BY facCtrcod)
FROM dbo.perzona AS Z
--Prefacturas
INNER JOIN dbo.facturas AS F
ON  F.facPerCod = Z.przcodper
AND F.facZonCod = Z.przcodzon
AND F.facFecha IS NULL
INNER JOIN dbo.contratos AS C
ON C.ctrcod = F.facCtrCod
AND C.ctrversion = F.facCtrVersion
INNER JOIN dbo.inmuebles AS I
ON C.ctrinmcod = I.inmcod
--Zonas abiertas
WHERE Z.przcierrereal IS NULL 

), CNS AS(
--Facturas de consumo cerradas
SELECT F.facCtrCod
	 , numFacturas = COUNT(F.facCtrCod)
FROM dbo.facturas AS F 
WHERE F.facFechaRectif IS NULL 
  AND F.facNumero IS NOT NULL
  AND LEFT(F.facPerCod, 2) IN ('19', '20') 
GROUP BY  F.facCtrCod)

SELECT L.facCod
, L.facCtrCod
, L.facPerCod
, L.facVersion
, L.facZonCod
, L.facLecAct
, L.facLecActFec
, L.facLecLector
, L.facLecLectorFec
, L.facLecInlCod
, L.inmcalle
, L.ctrRuta
, [ZonaFacturas] = L.CN
, [ZonaFacLeidas] = L.LC
, [Zona%AvanceLectura] = CAST((L.LC*100.00)/L.CN AS NUMERIC(10,2))
, numFacturas = ISNULL(C.numFacturas, 0)
, fecLector_calle = CAST(L.fecLector_calle AS datetime)
, fecLector_zona  = CAST(L.fecLector_zona AS datetime)
, fecLector_AVG   = CAST(CAST(COALESCE(fecLector_calle , fecLector_zona) AS DATETIME) AS DATE)
FROM LEC AS L
LEFT JOIN CNS AS C
ON L.facCtrCod = C.facCtrCod;

GO