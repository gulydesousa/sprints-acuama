--SELECT * FROM otDatos WHERE odtCodigo=2001
DELETE FROM otDatos WHERE odtCodigo=2001

INSERT INTO otDatos 
OUTPUT INSERTED.*
VALUES (2001, 'Inspecci�n: Apto ', 2);