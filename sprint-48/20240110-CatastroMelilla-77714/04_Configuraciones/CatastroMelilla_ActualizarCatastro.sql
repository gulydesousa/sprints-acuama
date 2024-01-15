DELETE FROM ExcelPerfil WHERE ExPCod='100/004'
DELETE FROM ExcelConsultas WHERE ExcCod='100/004'


INSERT INTO ExcelConsultas VALUES (
  '100/004', 'Catastro Melilla'
, 'Catastro-Inmuebles: Melilla'
, 21
, '[MelillaCatastro].[ActualizarCatastro]'
, 'CSV+'
, 'Catastro de Melilla relacionado con las direcciones de los inmuebles de acuama.'
, NULL, NULL, NULL, NULL)

INSERT INTO ExcelPerfil VALUES
('100/004', 'root', 3, NULL ),
('100/004', 'direcc', 3, NULL );


