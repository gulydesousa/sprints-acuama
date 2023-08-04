--********************
--VALDALIGA: CONTRATOS FECHA ALTA
/*
DECLARE @p_params NVARCHAR(MAX);
DECLARE @p_errId_out INT;
DECLARE @p_error_out INT;
DECLARE @p_errMsg_out   NVARCHAR(MAX);

SET @p_params= '<NodoXML><LI><FecDesde></FecDesde><FecHasta></FecHasta></LI></NodoXML>'

EXEC [InformesExcel].[ContratosxFechaAlta] @p_params, @p_error_out OUTPUT, @p_errMsg_out OUTPUT;
*/


DELETE ExcelPerfil WHERE ExPCod='000/420';
DELETE ExcelConsultas WHERE ExcCod='000/420';

INSERT INTO dbo.ExcelConsultas VALUES
('000/420', 'Contratos fecha alta', 'Contratos por fecha alta y cambios de titular', 1, '[InformesExcel].[ContratosxFechaAlta]', '005', 
'Retorna los contratos por la fecha de alta y los servicios de consumo de vigencia mas reciente.<br><b>Cambio Titularidad </b> <u><i>esRaíz:</i></u> Contrato inicial, <u><i>#Titulares:</i></u> total cambios de titularidad, <u><i>CtrRaíz:</i></u> Contrato inicial si el contrato viene de un cambio de titularidad,  <u><i>Ctr.Nivel:</i></u> 1 para el contrato más reciente.');

INSERT INTO ExcelPerfil VALUES ('000/420', 'admon', 3, NULL);
INSERT INTO ExcelPerfil VALUES ('000/420', 'root', 3, NULL);
INSERT INTO ExcelPerfil VALUES ('000/420', 'jefeExp', 3, NULL);


UPDATE E SET
ExcAyuda='Retorna los contratos por la fecha de alta y los servicios de consumo de vigencia mas reciente.<br><b>Cambio Titularidad </b> <u><i>esRaíz:</i></u> Contrato inicial, <u><i>#Titulares:</i></u> total cambios de titularidad, <u><i>CtrRaíz:</i></u> Contrato inicial si el contrato viene de un cambio de titularidad,  <u><i>Ctr.Nivel:</i></u> 1 para el contrato más reciente.'
FROM dbo.ExcelConsultas AS E WHERE ExcCod='000/420'
--********************