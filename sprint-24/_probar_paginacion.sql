SELECT cblScd, cblPpag, cblNum, COUNT(cblLin) FROM coblin
GROUP BY cblScd, cblPpag, cblNum
ORDER BY COUNT(cblLin) DESC
