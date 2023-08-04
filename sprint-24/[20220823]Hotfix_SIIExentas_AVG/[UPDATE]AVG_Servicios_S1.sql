USE ACUAMA_AVG;
GO
--***************************************************
/*
SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal
FROM servicios AS S WHERE ISNULL(svcFacSujNoExe, '')=''

SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal
FROM servicios AS S WHERE ISNULL(svcFacSujNoExe, '')='' AND ISNULL(svccauExVal, '')='' 
*/
--***************************************************
--El valor por defecto debe ser "S1"
--Ya que si no tiene ninguno de estos dos valores ser� No-Sujeta

SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal, svcImpTipo, svcOrgCod
--UPDATE S SET svcFacSujNoExe='S1', svccauExVal='' 
FROM servicios AS S 
WHERE ISNULL(svcFacSujNoExe, '')='' AND ISNULL(svccauExVal, '')='';

SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal, svcImpTipo, svcOrgCod
--UPDATE S SET svcFacSujNoExe='', svccauExVal='E6' 
FROM servicios AS S 
WHERE svcImpTipo=3;

  
SELECT svccod, svcdes, svcFacSujNoExe, svccauExVal, svcOrgCod FROM servicios ORDER BY svcOrgCod, svcFacSujNoExe, svccauExVal;