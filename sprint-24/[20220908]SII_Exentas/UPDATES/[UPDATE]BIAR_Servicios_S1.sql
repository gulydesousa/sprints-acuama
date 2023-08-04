USE ACUAMA_BIAR;
GO
--***************************************************
/*
SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal, svcOrgCod
FROM servicios AS S WHERE ISNULL(svcFacSujNoExe, '')=''

SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal, svcOrgCod
FROM servicios AS S WHERE ISNULL(svcFacSujNoExe, '')='' AND ISNULL(svccauExVal, '')='' 
*/
--***************************************************
--El valor por defecto debe ser "S1"
--Ya que si no tiene ninguno de estos dos valores será No-Sujeta

SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal
--UPDATE S SET svcFacSujNoExe='S1', svccauExVal='' 
FROM servicios AS S 
WHERE ISNULL(svcFacSujNoExe, '')='' AND ISNULL(svccauExVal, '')=''
  AND svccod IN (0, 1, 7);


SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal, svcOrgCod FROM servicios ORDER BY svcOrgCod, svcFacSujNoExe, svccauExVal;