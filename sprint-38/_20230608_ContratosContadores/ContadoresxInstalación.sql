/*  
--DELETE ExcelPerfil WHERE ExPCod='000/023'
--DELETE ExcelConsultas WHERE ExcCod='000/023'
--DROP PROCEDURE [InformesExcel].[ContadoresxInstalación]
****** CONFIGURACION ******   
INSERT INTO ExcelConsultas VALUES(  
  '000/023'   
, 'Contadores F.Instalación'   
, 'Contadores por fecha de instalación'  
, '1'  
, '[InformesExcel].[ContadoresxInstalacion]'  
, '000'  
, 'Contadores instalados en el rango de fechas indicado. Incluye el emplazamiento, zona, ruta y el contador retirado.'  
, NULL
, NULL
, NULL
, NULL)  
  
INSERT INTO ExcelPerfil VALUES('000/023', 'root', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/023', 'jefAdmon', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/023', 'jefeExp', 3, NULL)  
INSERT INTO ExcelPerfil VALUES('000/023', 'direcc', 3, NULL)  
*/

/*
DECLARE @p_params NVARCHAR(MAX);  
DECLARE @p_errId_out INT;  
DECLARE @p_errMsg_out NVARCHAR(2048);  
  
SET @p_params= '<NodoXML><LI><FecDesde>20230101</FecDesde><FecHasta>20240101</FecHasta></LI></NodoXML>'  
  
  
EXEC [InformesExcel].[ContadoresxInstalacion] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;  
*/  
  
  
CREATE PROCEDURE [InformesExcel].[ContadoresxInstalacion] 
 @p_params NVARCHAR(MAX),  
 @p_errId_out INT OUTPUT,   
 @p_errMsg_out NVARCHAR(2048) OUTPUT  
AS  

 --**********  
 --PARAMETROS:   
 --[1]FecDesde: fecha dede  
 --[2]FecHasta: fecha hasta  
 --**********  
  
 SET NOCOUNT ON;     
 BEGIN TRY  
   
 --********************  
 --INICIO: 2 DataTables  
 -- 1: Parametros del encabezado (FecDesde, FecHasta)  
 -- 2: Datos  
 --********************  
  
 --DataTable[1]:  Parametros  
 DECLARE @xml AS XML = @p_params;  
 DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL);  
  
 INSERT INTO @params  
 SELECT  FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL   
         ELSE M.Item.value('FecDesde[1]', 'DATE') END  
    , fInforme     = GETDATE()  
    , FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL   
         ELSE M.Item.value('FecHasta[1]', 'DATE') END  
 FROM @xml.nodes('NodoXML/LI')AS M(Item);  
   
 UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta)  
 OUTPUT DELETED.*;  
   
 --********************  
 --VALIDAR PARAMETROS  
 --Fechas obligatorias  
  
 IF EXISTS(SELECT 1 FROM @params WHERE FecDesde IS NULL OR FecHasta IS NULL)  
  THROW 50001 , 'La fecha ''desde'' y ''hasta'' son requeridos.', 1;  
 IF EXISTS(SELECT 1 FROM @params WHERE FecDesde>FecHasta)  
  THROW 50002 , 'La fecha ''hasta'' debe ser posterior a la fecha ''desde''.', 1;  
   
 --********************  
 --DataTable[2]:  Grupos  
 SELECT *   
 FROM (VALUES ('Instalaciones de contador'))   
 AS DataTables(Grupo);  
   
 --********************  
 

SELECT [Zona] = C.ctrzoncod
	 , [Ruta] = FORMATMESSAGE('%s.%s.%s.%s.%s.%s'
			--FORMATMESSAGE('%010s.%010s.%010s.%010s.%010s'
										 , ISNULL(C.ctrRuta1, '')
										 , ISNULL(C.ctrRuta2, '')
										 , ISNULL(C.ctrRuta3, '')
										 , ISNULL(C.ctrRuta4, '')
										 , ISNULL(C.ctrRuta5, '')
										 , ISNULL(C.ctrRuta6, ''))
	, [Contrato] = CC.ctrCod
	, [Emplazamiento] = UPPER(E.emcdes)
	, [F.Instalación] = CC.[I.ctcFec]
	, [Contador Instalado]= CC.conNumSerie
	, [Contador Retirado]= CC.[conNumSerie.Anterior]

	, [Ultima Instalación] = CC.esUltimaInstalacion
	, [F.Retirada] = CC.[R.ctcFec]

--, T.conCamUsr
--, OT.otEplCod
--, OT.otEplCttCod
FROM vCambiosContador AS CC
INNER JOIN @params AS P 
ON CC.[I.ctcFec]>=P.FecDesde AND CC.[I.ctcFec]<P.FecHasta
INNER JOIN vContratosUltimaVersion AS V
ON V.ctrCod = CC.ctrCod
INNER JOIN dbo.contratos AS C
ON  V.ctrcod = C.ctrCod
AND V.ctrversion = C.ctrversion
LEFT JOIN dbo.emplaza AS E
ON E.emccod = C.ctremplaza
--LEFT JOIN dbo.contadorCambio AS T
--ON T.conCamConID = CC.conId AND T.conCamFecha = CC.[I.ctcFec]
--LEFT JOIN dbo.ordenTrabajo AS OT
--ON  OT.otserscd = T.conCamOtSerScd
--AND OT.otsercod = T.conCamOtSerCod
--AND OT.otnum = T.conCamOtNum
ORDER BY C.ctrzoncod, [Ruta], CC.ctrCod, CC.[I.RN];

 END TRY  
  
 BEGIN CATCH  
  SELECT  @p_errId_out = ERROR_NUMBER()  
    ,  @p_errMsg_out= ERROR_MESSAGE();  
 END CATCH  
  
  
  
  