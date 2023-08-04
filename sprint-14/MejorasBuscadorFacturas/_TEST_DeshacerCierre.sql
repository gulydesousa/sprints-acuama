DECLARE @periodo AS VARCHAR(6) = '202201';
--DECLARE @zona AS VARCHAR(4) 
--SET @zona= 'AM01';
--SET @zona= 'AM02';
--SET @zona= 'AM03';
--SET @zona= 'AZ01';
--SET @zona= 'AZ02';
--SET @zona= 'AZ03';
--SET @zona= 'NA01';
--SET @zona= 'NA02';
--SET @zona= 'NA03';
--SET @zona= 'RO01';
--SET @zona= 'RO02';
--SET @zona= 'RO03';
--DECLARE @cobfecha AS datetime = '20211201'

--Borrar cierre del periodo
UPDATE F SET facNumero=NULL, facSerScdCod=NULL, facSerCod=NULL, facFecha=NULL,  facEnvSERES=NULL
FROM facturas AS F
WHERE facPerCod=@periodo AND facNumero IS NOT NULL;

DELETE F
FROM facSIIDesgloseFactura AS F
WHERE fclSiifacPerCod=@periodo  


DELETE F
FROM facSII AS F
WHERE fcSiifacPerCod=@periodo


DELETE CLD
FROM cobros AS C
INNER JOIN coblin AS CL
ON C.cobNum = CL.cblNum
AND C.cobScd = CL.cblScd
AND C.cobPpag = CL.cblPpag
INNER JOIN cobLinDes AS CLD
ON CLD.cldCblNum = CL.cblNum
AND CLD.cldCblPpag = CL.cblPpag
AND CLD.cldCblScd = CL.cblScd
AND CLD.cldCblLin = CL.cblLin
WHERE cl.cblPer=@periodo

DECLARE @COBS AS TABLE(cblScd INT, cblPPag INT, cblNum INT);


DELETE CL
OUTPUT DELETED.cblScd, DELETED.cblPpag, DELETED.cblNum INTO @COBS
FROM cobros AS C
INNER JOIN coblin AS CL
ON C.cobNum = CL.cblNum
AND C.cobScd = CL.cblScd
AND C.cobPpag = CL.cblPpag
WHERE cl.cblPer=@periodo

DELETE C
FROM cobros AS C
INNER JOIN @COBS AS X
ON X.cblNum = C.cobNum
AND X.cblPPag = C.cobPpag
AND X.cblScd = C.cobScd


UPDATE P SET przCierreNReg=0, przCierreReal=NULL
FROM perzona AS P WHERE przcodper=@periodo;


UPDATE Z SET zonPerCod=NULL
FROM zonas AS Z 



--DELETE faclin where fclfacpercod=@periodo;
--DELETE facturas  where facpercod=@periodo;