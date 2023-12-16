/*

INSERT INTO ExcelConsultas VALUES (
  '100/004', 'Catastro Melilla'
, 'Catastro-Inmuebles: Melilla'
, 0
, '[InformesExcel].[CatastroInmuebles_Melilla]'
, '000'
, 'Catastro de Melilla relacionado con las direcciones de los inmuebles de acuama.'
, NULL, NULL, NULL, NULL)

INSERT INTO ExcelPerfil VALUES
('100/004', 'root', 3, NULL ),
('100/004', 'direcc', 3, NULL )


--DELETE FROM ExcelPerfil WHERE ExPCod='100/005'
--DELETE FROM ExcelConsultas WHERE ExcCod='100/005'

*/

/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>'

EXEC [InformesExcel].[CatastroInmuebles_Melilla] @p_params, @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

CREATE PROCEDURE [InformesExcel].[CatastroInmuebles_Melilla]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS
	SET NOCOUNT ON;   
	BEGIN TRY
		
		--DataTable[1]:  Parametros
		DECLARE @xml AS XML = @p_params;
		DECLARE @params TABLE (fInforme DATETIME);

		INSERT INTO @params
		SELECT  fInforme= GETDATE()
		FROM @xml.nodes('NodoXML/LI')AS M(Item);

		SELECT * FROM @params;

			--********************
			--DataTable[2]:  Grupos
			SELECT * 
			FROM (VALUES ('REFERENCIAS CATASTRALES')
					   , ('CATASTRO MELILLA')
					   , ('CONTRATOS ACTIVOS')) 
			AS DataTables(Grupo);
	
			--'Coincidencias por Dirección'			
			WITH DIR AS(
			SELECT C.ctrinmcod, C.ctrTitDocIden, C.ctrTitNom,  C.inmDireccion, C.inmrefcatastral
				 , R.NIF, R.DIRECCION, R.NOMBRE, R.REFCATASTRAL
			FROM vContratosActivos AS C
			INNER JOIN vCatastro AS R
			ON  C.esActivo=1 
			AND C.DIRECCION = R.DIRECCION 
			AND C.cnCtrActivosxDireccion=1 
			AND R.RefsxDireccion=1)

			--Coincidencias por el NIF del titular
			, NIF AS(
			SELECT C.ctrinmcod, C.ctrTitDocIden, C.ctrTitNom,  C.inmDireccion, C.inmrefcatastral
				 , R.NIF, R.DIRECCION, R.NOMBRE, R.REFCATASTRAL
			FROM vContratosActivos AS C
			INNER JOIN vCatastro AS R
			ON  C.esActivo=1 
			AND R.DocIdenText=C.ctrTitDocIden 
			AND R.RefsxPropietario = 1 
			AND C.cnCtrActivosxTitular = 1
			AND R.DIRECCION <> C.DIRECCION)

			--REFERENCIAS CATASTRALES
			SELECT D.NIF, D.ctrTitDocIden
			, D.NOMBRE, D.ctrTitNom 
			, D.REFCATASTRAL, I.inmrefcatastral
			, D.DIRECCION, I.inmDireccion
			, [Err_Ref] = CASE  WHEN I.inmrefcatastral IS NOT NULL AND  I.inmrefcatastral<>D.REFCATASTRAL THEN  'KO'
								WHEN I.inmrefcatastral IS NOT NULL THEN 'OK'
								ELSE 'NUEVA' END
			, [Caso] = 1
			FROM dbo.inmuebles AS I
			INNER JOIN DIR AS D
			ON I.inmcod = D.ctrinmcod

			UNION ALL

			SELECT D.NIF, D.ctrTitDocIden
			, D.NOMBRE, D.ctrTitNom 
			, D.REFCATASTRAL, I.inmrefcatastral
			, D.DIRECCION, I.inmDireccion

			, [Err_Ref] = CASE  WHEN I.inmrefcatastral IS NOT NULL AND  I.inmrefcatastral<>D.REFCATASTRAL THEN  'KO'
								WHEN I.inmrefcatastral IS NOT NULL THEN 'OK'
								ELSE 'NUEVA' END
			, [Caso]=2
			FROM dbo.inmuebles AS I
			INNER JOIN NIF AS D
			ON I.inmcod = D.ctrinmcod;

			--'CATASTRO MELILLA'
			WITH C AS(SELECT * FROM dbo.vCatastro)
			
			SELECT C.NIF	, [DocIdent] = C.DocIdenText 
				, C.NOMBRE	, C.NombreText
				, C.DIRECCION
				, C.REFCATASTRAL
				, [Dir.Repetida] = CAST(IIF(RefsxDireccion>1, 1, 0) AS BIT)
			FROM C
			ORDER BY DIRECCION;

			
			--'CONTRATOS ACTIVOS'
			SELECT A.ctrcod, A.ctrversion, A.ctrTitDocIden, A.ctrTitNom, A.ctrinmcod, A.inmDireccion
			, A.inmrefcatastral
			, A.REFCATASTRAL
			, [Dir.Repetida] = cnCtrActivosxDireccion
			FROM vContratosActivos AS A 
			WHERE A.esActivo=1;


	END TRY
	BEGIN CATCH
		SELECT  @p_errId_out = ERROR_NUMBER()
			 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH
