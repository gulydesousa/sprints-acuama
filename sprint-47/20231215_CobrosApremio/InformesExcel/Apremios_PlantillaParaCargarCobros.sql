/*
INSERT INTO dbo.ExcelConsultas
VALUES ('400/001',	'Apremios Plantilla Cobros', 'Plantilla para la carga de cobros de apremios', 0, '[InformesExcel].[Apremios_PlantillaParaCargarCobros]', 'CSV+', 'Se obtienen los datos en el formato requerido para la carga masiva de cobros.', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil
VALUES('400/001', 'root', 5, NULL)
*/


/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_errMsg_out NVARCHAR(2048);

SET @p_params= '<NodoXML><LI></LI></NodoXML>';

EXEC [InformesExcel].[Apremios_PlantillaParaCargarCobros] @p_params,  @p_errId_out OUTPUT, @p_errMsg_out OUTPUT;
*/

ALTER PROCEDURE [InformesExcel].[Apremios_PlantillaParaCargarCobros]
	@p_params NVARCHAR(MAX),
	@p_errId_out INT OUTPUT, 
	@p_errMsg_out NVARCHAR(2048) OUTPUT
AS

	SET NOCOUNT ON;   

	--DataTable[1]:  Parametros
	DECLARE @xml AS XML = @p_params;
	
	DECLARE @params TABLE (fInforme DATETIME);

	INSERT INTO @params
	OUTPUT INSERTED.*	
	SELECT fInforme = GETDATE()
	FROM @xml.nodes('NodoXML/LI')AS M(Item);

	BEGIN TRY
		--*****************************
		--Explotación actual
		DECLARE @explo AS INT;
		SELECT @explo = pgsvalor FROM parametros WHERE pgsclave='EXPLOTACION_CODIGO';

		DECLARE @strExplo AS VARCHAR(4)= @explo * 100;


		--*****************************
		--Facturas de apremios: Actualizamos los totales de las facturas, por si acaso
		DECLARE @fctActualizacion AS DATE;
		DECLARE @hoy AS DATE = GETDATE();

		DECLARE @FACS AS dbo.tFacturasPK;

		INSERT INTO @FACS(facCod, facPerCod, facCtrCod, facVersion)
		SELECT A.aprFacCod, A.aprFacPerCod, A.aprFacCtrCod, A.aprFacVersion 
		FROM dbo.apremios AS A;

		SELECT @fctActualizacion=MIN(T.fctActualizacion) 
		FROM facTotales AS T
		INNER JOIN @FACS AS F
		ON T.fctCod= F.facCod
		AND T.fctPerCod = F.facPerCod
		AND T.fctCtrCod = F.facCtrCod
		AND T.fctVersion = F.facVersion;

		EXEC FacTotales_Update @FACS; 
	
		--*****************************
		--Trabajo.apremiosODS: El recibo de apremios no tiene nada que ver con el numero de factura de acuama
		--Hacemos un proceso para encontralos por coincidencia
		DECLARE @COINCIDENCIAS AS dbo.tApremios_ObtenerCoincidenciasOds;

		INSERT INTO @COINCIDENCIAS
		EXEC Apremios_ObtenerCoincidenciasOds;
		
		--*****************************
		--Grupos de resultados
		--*****************************
		SELECT * 
		FROM (VALUES ('Checklist para la carga de cobro de apremios') 
				    , ('Pendientes De Cobro')
					, ('Recibo Sin Coincidencia En Apremios')
				   ) 
		AS DataTables(Grupo);

		--*****************************
		--RESULTADO 0: Información
		--*****************************

		SELECT * 
		FROM (VALUES 
			('', '1', 'El usuario debe solicitar a "soporte de acuama" la carga del fichero excel de cobros por apremios suministrado por el Ayuntamiento de Guadalajara.'),
			('', '1.1', 'Datos mínimamente requeridos: EJERCICIO, FECHA(del Cobro), PRINCIPAL(importe del cobro), NOMBRE (Títular), RECIBO (Nº Factura).'),
			('', '1.2', 'Destino: Trabajo.apremiosODS'),
			('', '2', 'Generar el informe excel desde Cobros/Informes/Informes Excel/Apremios Plantilla Cobros.'),
			('', '3', 'Guardar el fichero 1_Pendientesdecobro_____.csv en formato ".ODS". Este es el fichero de entrada para el paso siguiente.'),
			('', '4', 'Generar cobros para los apremios desde la opción de menu Cobros/Apremios/Cobros por apremio.'),
			('', '4.1', 'El proceso tarda más de 10 minutos procesando un fichero de 7.000 registros, no debe cambiar de ventana mientras se realiza el proceso.'),
			('', '4.2', 'Al finalizar presenta la opción de enviar los resultados a un informe excel, recomendamos aceptar la tarea.'),			
			('', '5', 'Se dispone de dos listados adicionales para validar los resultados del proceso:'),
			('', '5.1', 'Cobros/Informes/Informes Excel/Cobros por fecha registro. Filtrar por tipo cobro: Apremios'),
			('', '5.2', 'Cobros/Informes/Informes Excel/Cobrado por apremios. Comprobar que las ultimas dos columnas tengan solo OK')
			)
				AS Info([Check],Paso, Acción);


		--*****************************
		--RESULTADO 1: Coincidencias pendientes de enviar
		--*****************************
		SELECT [Anio] = C.EJERCICIOS
		, [Numero] = C.facNumero
		, [FechaRegAyto] = C.FECHA
		, [Titular] = C.ctrTitNom
		, [Importe] = C.PRINCIPAL
		, [ContratoCodigo] = C.facCtrCod
		, [PeriodoCodigo] = C.facPerCod
		--------------------------------
		, EJERCICIOS
		, RECIBO
		, FECHA
		, [IMP.] = IMPORTE
		, NOMBRE
		, DEMORA
		, RECARGO
		, PRINCIPAL
		, COSTAS
		--------------------------------
		, fctFacturado
		, fctCobrado
		, fctDeuda
		, [NumParciales] = COUNT(ID) OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion) 
		, [IndiceParcial]= ROW_NUMBER() OVER (PARTITION BY facCod, facPerCod, facCtrCod, facVersion ORDER BY FECHA, ID)
		FROM @COINCIDENCIAS AS C
		WHERE facCtrCod IS NOT NULL
		ORDER BY Anio, PeriodoCodigo, ContratoCodigo, Numero;

		--*****************************
		--RESULTADO 2: Sin Coincidencias enviadas
		--*****************************
		SELECT X.EJERCICIOS
		, X.RECIBO
		, X.[V/E]
		, X.[T.I.]
		, X.FECHA
		, X.IMPORTE
		, X.NOMBRE
		, X.[C.I.]
		, X.DEMORA
		, X.RECARGO
		, X.PRINCIPAL
		, X.COSTAS
		FROM @COINCIDENCIAS AS X
		WHERE X.facCtrCod IS NULL
		ORDER BY X.NOMBRE, X.EJERCICIOS, X.RECIBO

		
		

	END TRY
	BEGIN CATCH

	SELECT  @p_errId_out = ERROR_NUMBER()
		 ,  @p_errMsg_out= ERROR_MESSAGE();
	END CATCH

	--Borramos tablas temporales
	DROP TABLE IF EXISTS #APREMIOS;
	DROP TABLE IF EXISTS #COINCIDENCIAS;
GO


