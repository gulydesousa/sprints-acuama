--*********************
--PRUEBAS: TIEMPO REMESA POR CONTRATO
--*********************
SELECT INICIO		= MIN([cobFecReg]) 
, FIN				= MAX([cobFecReg])
, SEGUNDOS			= DATEDIFF(SECOND, MIN([cobFecReg]), MAX([cobFecReg]))
, COBROS			= COUNT(*) 
, TIEMPO_POR_COBRO	= CONVERT(float, DATEDIFF(SECOND, MIN([cobFecReg]), (MAX([cobFecReg])))/ CONVERT(FLOAT,COUNT(*))) 
FROM [dbo].[cobros]
WHERE cobFec >='20220104' AND cobOrigen ='Remesa'  AND  cobConcepto LIKE '%Remesa: 402%'


SELECT * FROM facTotalesTrab WITH(NOLOCK)