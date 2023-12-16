--SELECT * FROM Task_Types WHERE tskTType=751
--DELETE FROM Task_Types WHERE tskTType=751

IF (NOT EXISTS (SELECT * FROM Task_Types WHERE tskTType=751))
	INSERT INTO Task_Types 
	OUTPUT INSERTED.*
	VALUES(751, 'EntradaOTInspecciones', 0)
ELSE
	SELECT * FROM Task_Types WHERE tskTType=751
