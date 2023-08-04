CREATE TYPE dbo.tLiquidaciones_RIBADESELLA AS TABLE
(
	  EJ			CHAR(02)	--Ejercicio
	, ENTEMI		CHAR(03)	--Entidad emisora (Codigo del Ayuntamiento del 001 al 078)
	, AYTO			CHAR(03)	--Ayuntamiento
	, TRIBUTO		CHAR(03)	--Codigo del Tributo seg�n relacion adjunta
	, ANUALIDAD		CHAR(02)	--A�o de liquidacion de la deuda
	, NUMLIQ		CHAR(12)	--N� de Liquidaci�n/recibo del Ayuntamiento. Dato a utilizar en la remision de informacion
	, NOMCER		CHAR(12)	--[*]N. Certificaci�n. Se usara en la remision de informaci�n / Puede ser igual al Num de Liquidaci�n
	, PRINCI		CHAR(09)	--Principal (Sin IVA)
	, INIVOL		CHAR(06)	--Inicio de Voluntaria
	, FINVOL		CHAR(06)	--Fin de Voluntaria
	, CONTRI		CHAR(40)	--Contribuyente
	, DNI			CHAR(09)	--Dni
	, SIGLAS		CHAR(02)	--Siglas Direcci�n
	, LUGAR			CHAR(38)	--Domicilio completo calle+num+esc+planta+puerta
	, POBLACION		CHAR(15)	--Poblaci�n
	, MUNICIPIO		CHAR(03)	--Codigo de Municipio
	, PROVINCIA		CHAR(02)	--Provincia
	, CPP			CHAR(05)	--C�digo Postal
	, CONCEPTO		CHAR(20)	--Concepto (Descripci�n del c�digo de tributo)
	, CLAVE1		CHAR(01)	--En blanco
	, CONYUGE		CHAR(40)	--C�nyuge
	, NIFCON		CHAR(09)	--Nif C�nyuge
	, FECHACER		CHAR(06)	--Fecha Certificaci�n de descubierto
	, DETALLE		CHAR(64)	--Detalle
	, OTRA1			CHAR(64)	--Ampliaci�n Detalle
	, OTRA2			CHAR(78)	--Ampliaci�n Detalle 2
	, LOTE			CHAR(04)	--Lote (Secuencial del N� de envio)
	, MODONOT		CHAR(01)	--Modo de notificaci�n en voluntaria (C)orreo/(B)OPA
	, FECHALIQ		CHAR(06)	--Fecha Liquidaci�n
	, PERIODO		CHAR(02)	--Periodo (1T,2T,3T,4T,1S,2S,0A,1B,2B�)
	, FECHAFIR		CHAR(06)	--Fecha Firmeza / Obligatorio para Multas (Tributo 256)
	, REPRE			CHAR(40)	--Representante
	, DIREREPRE		CHAR(55)	--Direcci�n Representante
	, MUNIREPRE		CHAR(03)	--Municipio Representante
	, PROVIREPRE	CHAR(02)	--Provincia Representante
	, CPPREPRE		CHAR(05)	--C�digo Postal representante
	, IMPENT		CHAR(09)	--Importe ya ingresado si existiera/S�lo si hay importe previo al cargo
	, FINGRE		CHAR(06)	--Fecha del Ingreso si existiera/S�lo si hay importe previo al cargo
	, ORGOFI		CHAR(02)	--Organismo Oficial (00 No, 97 Si)
	, IVA			CHAR(09)	--Iva
	, FECHA_APREMIO CHAR(06)	--Fecha de apremio ddmmaa o 000000/Solamente en caso de nuevo convenio con el EPSTPA. 
	
	, CODAGUA180	CHAR(02)	--C�digo del subconcepto de agua para tributo 180 (c�d = �AP�)
	, IMPAGUA180	CHAR(08)	--Importe del subconcepto de agua para el tributo 180/S�lo si se indica CODAGUA180
	, IVAAGUA180	CHAR(08)	--Importe del Iva para el subconcepto de agua para el tributo 180
	
	, CODBASURA180	CHAR(02)	--C�digo del subconcepto de basura para tributo 180 (c�d = �BA�)
	, IMPBASURA180	CHAR(08)	--Importe del subconcepto de basura para el tributo 180/S�lo si se indica CODBASURA180

	, CODALC180		CHAR(02)	--C�digo del subconcepto de alcantarillado para tributo 180 (c�d = �AL�)
	, IMPALC180		CHAR(08)	--Importe del subconcepto de alcantarillado para el tributo 180 /S�lo si se indica CODALC180
	
	, CODMIN180		CHAR(02)	--C�digo del subconcepto de m�nimo para tributo 180 (c�d = �MI�)
	, IMPMIN180		CHAR(08)	--Importe del subconcepto de m�nimo para el tributo 180 / S�lo si se indica CODMIN180

	, CODTCONT180	CHAR(02)	--C�digo del subconcepto de tasa de contadores para tributo 180 (c�d = �CT�)
	, IMPTCONT180	CHAR(08)	--Importe del subconcepto de tasa de contadores para el tributo 180 / S�lo si se indica CODTCONT180
	, IVATCONT180	CHAR(08)	--Importe del iva para el subconcepto de tasa de contadores para el tributo 180
	
	, CODCANON180	CHAR(02)	--Importe del iva para el subconcepto de tasa de contadores para el tributo 180
	, IMPCANON180	CHAR(08)	--Importe del subconcepto de CANON para el tributo 180 / S�lo si se indica CODCANON180

	, CODOTRO1180	CHAR(02)	--Ampliaci�n 1 para nuevo c�digo de  subconcepto de tributo 180 
	, IMPOTRO1180	CHAR(08)	--Ampliaci�n 1 para nuevo Importe de subconcepto de tributo 180 / S�lo si se indica CODOTRO1180

	, CODOTRO2180	CHAR(02)	--Ampliaci�n 2 para nuevo c�digo de  subconcepto de  tributo 180
	, IMPOTRO2180	CHAR(08)	--Ampliaci�n 2 para nuevo Importe de subconcepto de tributo 180 / S�lo si se indica CODOTRO2180

	, PRESCRIPCION	CHAR(03)	--Per�odo de prescripci�n en meses. M�x 120 meses (10 a�os) / S�lo para conceptos no tributarios
	
	, PK INT

	--CREATE TYPE does not allow naming of contraints
	, PRIMARY KEY CLUSTERED ([PK] ASC)   
   
   )

GO


