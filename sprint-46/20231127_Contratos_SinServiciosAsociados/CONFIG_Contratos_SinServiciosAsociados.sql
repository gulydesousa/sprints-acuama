--DELETE FROM ExcelPerfil WHERE ExPCod='000/014'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/014'
SELECT * FROM ExcelConsultas WHERE ExcCod='000/014'
SELECT * FROM ExcelPerfil WHERE ExPCod='000/014'

INSERT INTO dbo.ExcelConsultas
OUTPUT INSERTED.*
VALUES ('000/014',	'Contratos sin Servicios', 'Contratos activos sin "Servicios por Contrato" asociados', 0, '[InformesExcel].[Contratos_SinServiciosAsociados]', '001', 'Listado de contratos activos para los que no existe ningún servicio (activo o no) en el histórico de servicios por contrato.', NULL, NULL, NULL, NULL);

INSERT INTO ExcelPerfil 
OUTPUT INSERTED.*
VALUES
('000/014', 'root', 3, NULL),
('000/014', 'direcc', 3, NULL)