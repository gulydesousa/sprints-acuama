--DROP TABLE MelillaCatastro.correspondencias
--SELECT * FROM MelillaCatastro.correspondencias

CREATE TABLE MelillaCatastro.correspondencias (
contrato INT, 
inmueble INT,
inmrefcatastral VARCHAR(25),
REFCATASTRAL VARCHAR(25),
inmDireccion VARCHAR(250),
CAM_DIRECCION VARCHAR(250),	
[ctr.activosxdir.] INT,
titular VARCHAR(25),
CAM_NIF	 VARCHAR(25),
[ctr.activosxtit.] INT,	
Caso VARCHAR(40),
Orden INT, 
fechaRegistro DATETIME DEFAULT GETDATE())


