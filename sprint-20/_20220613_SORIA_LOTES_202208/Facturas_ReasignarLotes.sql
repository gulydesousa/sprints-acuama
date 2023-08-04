/*
DECLARE @zona VARCHAR(4)= '0611'
DECLARE @periodo VARCHAR(6)='202208'
DECLARE @factxLote INT = 500;

EXEC Facturas_ReasignarLotes @zona, @periodo

*/

CREATE PROCEDURE Facturas_ReasignarLotes 
  @zona VARCHAR(4)
, @periodo VARCHAR(6)
, @factxLote INT = 500

AS

DECLARE @PERZONA AS TABLE(facPerCod VARCHAR(6), faczoncod VARCHAR(4),  faclote INT, przlnreg INT);

--Se aborta el proceso si la zona no está abierta
IF NOT EXISTS(SELECT 1 FROM perzona WHERE przcodzon=@zona AND przcodper=@periodo AND przcierrereal IS NULL)
RETURN;


--Se aborta el proceso si no se mandan los parametros
IF (COALESCE(@zona, @periodo) IS NULL)
RETURN;


WITH F AS(
SELECT F.facCod
, F.facPercod
, F.facCtrCod
, F.facVersion
, F.facLote
, RN = ROW_NUMBER() OVER (ORDER BY ctrRuta1, ctrRuta2, ctrRuta3, ctrRuta4, ctrRuta5)

FROM dbo.facturas  AS F 
INNER JOIN dbo.contratos AS C
ON C.ctrCod= F.facCtrCod
AND C.ctrversion = F.facCtrVersion
WHERE F.faczoncod = @zona  AND F.facPerCod = @periodo
AND F.facFechaRectif IS NULL)


UPDATE FF SET FF.facLote = FLOOR(RN/(@factxLote+1)) +1
--SELECT F.*, FLOOR(RN/(@factxLote+1)), FF.facLote
FROM F
INNER JOIN dbo.facturas AS FF
ON F.facCod = FF.facCod
AND F.facPerCod= FF.facpercod
AND F.facCtrCod = FF.facCtrCod
AND F.facVersion = FF.facVersion;
	
INSERT INTO @PERZONA
SELECT FF.facPerCod, FF.faczoncod,  faclote, COUNT(faclote)
FROM dbo.facturas AS FF
WHERE FF.faczoncod = @zona AND FF.facPerCod = @periodo
GROUP BY FF.facPerCod, FF.faczoncod,  faclote;

--SELECT * 
UPDATE L SET L.przlnreg = LL.przlnreg
FROM perzonalote AS L
INNER JOIN @PERZONA AS  LL
ON  L.przlcodper = LL.facPerCod
AND L.przlcodzon = LL.faczoncod
AND L.przllote = LL.faclote;
	
INSERT INTO perzonalote(przlcodzon, przlcodper, przllote, przlnreg)
SELECT LL.faczoncod, LL.facPerCod, LL.faclote, LL.przlnreg
FROM perzonalote AS L
RIGHT JOIN @PERZONA AS  LL
ON  L.przlcodper = LL.facPerCod
AND L.przlcodzon = LL.faczoncod
AND L.przllote = LL.faclote
WHERE L.przlcodper IS NULL;
	
SELECT * FROM perzonalote WHERE przlcodper=@periodo AND przlcodzon=@zona;
SELECT * FROm facturas WHERE facPerCod=@periodo AND facZonCod=@zona;

GO
