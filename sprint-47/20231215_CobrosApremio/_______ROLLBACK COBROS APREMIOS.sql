SELECT *
--DELETE
FROM Task_Schedule WHERE tskUser='gmdesousa'

SELECT *  
, COUNT(aprCobrado) OVER(PARTITION BY aprFecRegCobrado)
--UPDATE A SET aprCobrado=0, 	aprFechaFichCobrado=NULL,	aprCobradoAcuama=0,	aprFechaCobradoAcuama=NULL,	aprFecRegCobrado=NULL,	aprFecRegCobradoAcuama=NULL
FROM Apremios AS A
WHERE aprFecRegCobrado BETWEEN '20231215 11:40' AND '20231215 11:50'

SELECT D.*
--DELETE D
FROM cobros  AS C
INNER JOIN coblin AS L
ON L.cblScd = C.cobScd
AND L.cblPpag = C.cobPpag
AND L.cblNum = C.cobNum
INNER JOIN cobLinDes AS D
ON D.cldCblScd = C.cobScd
AND D.cldCblPpag = C.cobPpag
AND D.cldCblNum = C.cobNum
AND D.cldCblLin = L.cblLin
WHERE cobFecReg BETWEEN '20231215 11:40' AND '20231215 11:50' AND coborigen ='Apremio';

SELECT L.*
--DELETE L
FROM cobros  AS C
INNER JOIN coblin AS L
ON L.cblScd = C.cobScd
AND L.cblPpag = C.cobPpag
AND L.cblNum = C.cobNum
WHERE cobFecReg BETWEEN '20231215 11:40' AND '20231215 11:50' AND coborigen ='Apremio';

SELECT C.*
--DELETE C
FROM cobros  AS C
WHERE cobFecReg BETWEEN '20231215 11:40' AND '20231215 11:50' AND coborigen ='Apremio';


