--SELECT * FROM registroEntradasTipo

--INSERT INTO registroEntradasTipo OUTPUT INSERTED.*
SELECT ISNULL(MAX(regEntTipCod), 0)+1 
, 'Emisi�n de notific.'
, 1
FROM registroEntradasTipo