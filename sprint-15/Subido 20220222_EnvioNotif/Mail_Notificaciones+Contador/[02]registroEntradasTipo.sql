--SELECT * FROM registroEntradasTipo

--INSERT INTO registroEntradasTipo OUTPUT INSERTED.*
SELECT ISNULL(MAX(regEntTipCod), 0)+1 
, 'Emisión de notific.'
, 1
FROM registroEntradasTipo