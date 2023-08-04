CREATE TYPE dbo.tLiquidaciones_RIBADESELLA AS TABLE
(
	  EJ			CHAR(02)	--Ejercicio
	, ENTEMI		CHAR(03)	--Entidad emisora (Codigo del Ayuntamiento del 001 al 078)
	, AYTO			CHAR(03)	--Ayuntamiento
	, TRIBUTO		CHAR(03)	--Codigo del Tributo según relacion adjunta
	, ANUALIDAD		CHAR(02)	--Año de liquidacion de la deuda
	, NUMLIQ		CHAR(12)	--Nº de Liquidación/recibo del Ayuntamiento. Dato a utilizar en la remision de informacion
	, NOMCER		CHAR(12)	--[*]N. Certificación. Se usara en la remision de información / Puede ser igual al Num de Liquidación
	, PRINCI		CHAR(09)	--Principal (Sin IVA)
	, INIVOL		CHAR(06)	--Inicio de Voluntaria
	, FINVOL		CHAR(06)	--Fin de Voluntaria
	, CONTRI		CHAR(40)	--Contribuyente
	, DNI			CHAR(09)	--Dni
	, SIGLAS		CHAR(02)	--Siglas Dirección
	, LUGAR			CHAR(38)	--Domicilio completo calle+num+esc+planta+puerta
	, POBLACION		CHAR(15)	--Población
	, MUNICIPIO		CHAR(03)	--Codigo de Municipio
	, PROVINCIA		CHAR(02)	--Provincia
	, CPP			CHAR(05)	--Código Postal
	, CONCEPTO		CHAR(20)	--Concepto (Descripción del código de tributo)
	, CLAVE1		CHAR(01)	--En blanco
	, CONYUGE		CHAR(40)	--Cónyuge
	, NIFCON		CHAR(09)	--Nif Cónyuge
	, FECHACER		CHAR(06)	--Fecha Certificación de descubierto
	, DETALLE		CHAR(64)	--Detalle
	, OTRA1			CHAR(64)	--Ampliación Detalle
	, OTRA2			CHAR(78)	--Ampliación Detalle 2
	, LOTE			CHAR(04)	--Lote (Secuencial del Nº de envio)
	, MODONOT		CHAR(01)	--Modo de notificación en voluntaria (C)orreo/(B)OPA
	, FECHALIQ		CHAR(06)	--Fecha Liquidación
	, PERIODO		CHAR(02)	--Periodo (1T,2T,3T,4T,1S,2S,0A,1B,2B…)
	, FECHAFIR		CHAR(06)	--Fecha Firmeza / Obligatorio para Multas (Tributo 256)
	, REPRE			CHAR(40)	--Representante
	, DIREREPRE		CHAR(55)	--Dirección Representante
	, MUNIREPRE		CHAR(03)	--Municipio Representante
	, PROVIREPRE	CHAR(02)	--Provincia Representante
	, CPPREPRE		CHAR(05)	--Código Postal representante
	, IMPENT		CHAR(09)	--Importe ya ingresado si existiera/Sólo si hay importe previo al cargo
	, FINGRE		CHAR(06)	--Fecha del Ingreso si existiera/Sólo si hay importe previo al cargo
	, ORGOFI		CHAR(02)	--Organismo Oficial (00 No, 97 Si)
	, IVA			CHAR(09)	--Iva
	, FECHA_APREMIO CHAR(06)	--Fecha de apremio ddmmaa o 000000/Solamente en caso de nuevo convenio con el EPSTPA. 
	
	, CODAGUA180	CHAR(02)	--Código del subconcepto de agua para tributo 180 (cód = ‘AP’)
	, IMPAGUA180	CHAR(08)	--Importe del subconcepto de agua para el tributo 180/Sólo si se indica CODAGUA180
	, IVAAGUA180	CHAR(08)	--Importe del Iva para el subconcepto de agua para el tributo 180
	
	, CODBASURA180	CHAR(02)	--Código del subconcepto de basura para tributo 180 (cód = ‘BA’)
	, IMPBASURA180	CHAR(08)	--Importe del subconcepto de basura para el tributo 180/Sólo si se indica CODBASURA180

	, CODALC180		CHAR(02)	--Código del subconcepto de alcantarillado para tributo 180 (cód = ‘AL’)
	, IMPALC180		CHAR(08)	--Importe del subconcepto de alcantarillado para el tributo 180 /Sólo si se indica CODALC180
	
	, CODMIN180		CHAR(02)	--Código del subconcepto de mínimo para tributo 180 (cód = ‘MI’)
	, IMPMIN180		CHAR(08)	--Importe del subconcepto de mínimo para el tributo 180 / Sólo si se indica CODMIN180

	, CODTCONT180	CHAR(02)	--Código del subconcepto de tasa de contadores para tributo 180 (cód = ‘CT’)
	, IMPTCONT180	CHAR(08)	--Importe del subconcepto de tasa de contadores para el tributo 180 / Sólo si se indica CODTCONT180
	, IVATCONT180	CHAR(08)	--Importe del iva para el subconcepto de tasa de contadores para el tributo 180
	
	, CODCANON180	CHAR(02)	--Importe del iva para el subconcepto de tasa de contadores para el tributo 180
	, IMPCANON180	CHAR(08)	--Importe del subconcepto de CANON para el tributo 180 / Sólo si se indica CODCANON180

	, CODOTRO1180	CHAR(02)	--Ampliación 1 para nuevo código de  subconcepto de tributo 180 
	, IMPOTRO1180	CHAR(08)	--Ampliación 1 para nuevo Importe de subconcepto de tributo 180 / Sólo si se indica CODOTRO1180

	, CODOTRO2180	CHAR(02)	--Ampliación 2 para nuevo código de  subconcepto de  tributo 180
	, IMPOTRO2180	CHAR(08)	--Ampliación 2 para nuevo Importe de subconcepto de tributo 180 / Sólo si se indica CODOTRO2180

	, PRESCRIPCION	CHAR(03)	--Período de prescripción en meses. Máx 120 meses (10 años) / Sólo para conceptos no tributarios
	
	, PK INT

	--CREATE TYPE does not allow naming of contraints
	, PRIMARY KEY CLUSTERED ([PK] ASC)   
   
   )

GO


