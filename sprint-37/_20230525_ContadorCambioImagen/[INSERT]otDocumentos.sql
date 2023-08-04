
--SELECT * FROM dbo.otDocumentos

--SELECT * into tt FROM otDocumentos 
----INSERT INTO otDocumentos SELECT 1, 80, 22995, 'CCR', *, 'prueba imagen retirada'  FROM ACUAMA_RIBADESELLA_DESA.dbo.imagenes
----INSERT INTO otDocumentos SELECT 1, 80, 22997, 'CCR', *, 'prueba imagen retirada'  FROM ACUAMA_RIBADESELLA_DESA.dbo.imagenes

--INSERT INTO dbo.otDocumentos (otdSerScd,otdSerCod,otdNum, otdTipoCodigo, otdDocumento, otdDescripcion)   SELECT * FROM tt


/*
--SELECT * INTO tt FROM otDocumentos 

INSERT INTO dbo.otDocumentos (otdSerScd, otdSerCod, otdNum, otdTipoCodigo, otdFechaReg, otdDocumento)
SELECT otdSerScd, otdSerCod, otdNum, otdTipoCodigo, otdFechaReg, otdDocumento FROM tt

*/