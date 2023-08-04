


/*  
--DELETE ExcelPerfil WHERE ExPCod='000/023'
--DELETE ExcelConsultas WHERE ExcCod='000/023'
--DROP PROCEDURE [InformesExcel].[ContadoresxInstalación]
****** CONFIGURACION ******   
INSERT INTO ExcelConsultas VALUES(  
  '000/023'   
, 'Contadores F.Instalación'   
, 'Cambios de Contadores por fecha de instalación (última instalación)'
, '102'  
, '[InformesExcel].[ContadoresxInstalacion]'  
, '005'  
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
  
SET @p_params= '<NodoXML><LI><FecDesde>20230101</FecDesde><FecHasta>20240101</FecHasta><Origen>CCMASIVO</Origen></LI></NodoXML>'  
  
 
EXEC [InformesExcel].[ContadoresxInstalacion] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;  
  
*/
  
ALTER PROCEDURE [InformesExcel].[ContadoresxInstalacion] 
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
DECLARE @params TABLE (FecDesde DATE NULL, fInforme DATETIME, FecHasta DATE NULL, Origen VARCHAR(250) NULL);  
  
INSERT INTO @params  
SELECT FecDesde = CASE WHEN M.Item.value('FecDesde[1]', 'DATE') = '19000101' THEN NULL   
		ELSE M.Item.value('FecDesde[1]', 'DATE') END  
, fInforme     = GETDATE()  
, FecHasta = CASE WHEN M.Item.value('FecHasta[1]', 'DATE') = '19000101' THEN NULL   
		ELSE M.Item.value('FecHasta[1]', 'DATE') END  
, Origen = M.Item.value('Origen[1]', 'VARCHAR(250)')
		
FROM @xml.nodes('NodoXML/LI')AS M(Item);  
   
UPDATE @params SET FecHasta = DATEADD(DAY, 1, FecHasta) 
OUTPUT DELETED.FecDesde, DELETED.FecHasta, DELETED.fInforme, DELETED.Origen;  
   
DECLARE @ORIGEN AS VARCHAR(250);
SELECT @ORIGEN= origen FROM @params AS P;
   
   
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
 FROM (VALUES ('Contador Instalado'), ('Contador Retirado'), ('Contadores'))   
 AS DataTables(Grupo);  
   
 --********************  


WITH CAMBIOS AS(
SELECT CC.ctrCod
	, CC.conId
	, CC.[I.ctcFec]
	, CC.[conId.Anterior]
	, CC.[R.ctcFec]
	, CC.Origen
	, O.[value]
	, CC.esUltimaInstalacion
	--RN=1: Ultimo cambio de contador para el contrato
	, RN = ROW_NUMBER() OVER (PARTITION BY CC.ctrCod ORDER BY CC.[I.ctcFec] DESC)
	--RN_CC=1: Ultimo cambio de contador para el contrato y tipo seleccionado.
	, RN_CC = ROW_NUMBER() OVER (PARTITION BY CC.ctrCod ORDER BY IIF(O.[value] IS NULL, 1, 0), CC.[I.ctcFec] DESC)
	
	--CN: Cuantos cambios del origen requerido hay para cada contrato
	, CN = COUNT(O.[value]) OVER (PARTITION BY CC.ctrCod)

FROM vCambiosContador AS CC
INNER JOIN @params AS P 
ON CC.[I.ctcFec]>=P.FecDesde AND CC.[I.ctcFec]<P.FecHasta
LEFT JOIN dbo.Split(@ORIGEN, ',') AS O
ON CC.Origen = O.[value] OR
   (O.value='ANY' AND CC.Origen IN('Desconocido', 'TPL')))


SELECT RN= ROW_NUMBER() OVER( ORDER BY ctrCod) 
, ctrCod
, conId
, [conId.Anterior]
, [I.ctcFec]
, [R.ctcFec]
, Origen
, esUltimaInstalacion
INTO #CAMBIOS
FROM CAMBIOS 
WHERE RN_CC=1 AND CN>0;



--[1]DATOS CONTRATO:
SELECT [Contrato] = CC.ctrCod 
	 , [Zona] = CC.ctrzoncod
	 , [Ruta] = --FORMATMESSAGE('%010s.%010s.%010s.%010s.%010s'
				FORMATMESSAGE('%s.%s.%s.%s.%s.%s'
							, ISNULL(CC.ctrRuta1, '')
							, ISNULL(CC.ctrRuta2, '')
							, ISNULL(CC.ctrRuta3, '')
							, ISNULL(CC.ctrRuta4, '')
							, ISNULL(CC.ctrRuta5, '')
							, ISNULL(CC.ctrRuta6, '')) 
	, [Emplazamiento] = UPPER(E.emcdes)
	, [Inmueble] = I.inmDireccion
	, [Origen CC] = C.Origen
	, [Última Instalación] = C.esUltimaInstalacion

	
FROM #CAMBIOS AS C
INNER JOIN vContratosUltimaVersion AS V
ON V.ctrCod = C.ctrCod
INNER JOIN dbo.contratos AS CC
ON  V.ctrcod = CC.ctrCod
AND V.ctrversion = CC.ctrversion
LEFT JOIN dbo.emplaza AS E
ON E.emccod = CC.ctremplaza
LEFT JOIN dbo.inmuebles AS I
ON I.inmcod = CC.ctrinmcod
ORDER BY RN;


--[2]DATOS CONTADOR INSTALADO:
SELECT conNumSerie = ISNULL(CC.conNumSerie, ' ')
, [Caudal] = CC.conCaudal
, [Diametro] = CC.conDiametro
, [Marca] = MA.mcndes
, [Modelo] = MO.mdlDes
, [F.Instalación] = C.[I.ctcFec]
FROM #CAMBIOS AS C
LEFT JOIN dbo.contador AS CC
ON CC.conID = C.conId
LEFT JOIN dbo.marcon AS MA
ON CC.conMcnCod = MA.mcncod
LEFT JOIN dbo.modcon AS MO
ON CC.conMcnCod = MO.mdlMcnCod
AND CC.conMdlCod = MO.mdlCod
ORDER BY RN;


--[3]DATOS CONTADOR RETIRADO:
SELECT conNumSerie = ISNULL(CC.conNumSerie, ' ')
, [Caudal] = CC.conCaudal
, [Diametro] = CC.conDiametro
, [Marca] = MA.mcndes
, [Modelo] = MO.mdlDes
FROM #CAMBIOS AS C
LEFT JOIN dbo.contador AS CC
ON CC.conID = C.[conId.Anterior]
LEFT JOIN dbo.marcon AS MA
ON CC.conMcnCod = MA.mcncod
LEFT JOIN dbo.modcon AS MO
ON CC.conMcnCod = MO.mdlMcnCod
AND CC.conMdlCod = MO.mdlCod
ORDER BY RN;


END TRY  
  
BEGIN CATCH  
  SELECT  @p_errId_out = ERROR_NUMBER()  
    ,  @p_errMsg_out= ERROR_MESSAGE();  
END CATCH  
  
  
DROP TABLE IF EXISTS #CAMBIOS;

GO  