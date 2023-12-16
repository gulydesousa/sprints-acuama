--DELETE FROM ExcelPerfil WHERE ExpCod='000/020'
--DELETE FROM ExcelConsultas WHERE ExcCod='000/020'

INSERT INTO ExcelConsultas VALUES(
  '000/020'	
, 'Contratos por Ruta'	
, 'Catastro: Contratos por Ruta'
, '21'
, '[InformesExcel].[RelacionContratosPorRuta]'
, '000'
, 'CC011_RelacionContratosPorRuta: Corresponde a la selección disponible desde Catastro/Contratos por Ruta.<br>Incluye información de los emplazamientos.'
, NULL, NULL, NULL, NULL
)

INSERT INTO ExcelPerfil VALUES('000/020', 'root', 3, NULL)
INSERT INTO ExcelPerfil VALUES('000/020', 'direcc', 3, NULL)
INSERT INTO ExcelPerfil VALUES('000/020', 'tecnica', 3, NULL)
INSERT INTO ExcelPerfil VALUES('000/020', 'Tecnica2', 3, NULL)

