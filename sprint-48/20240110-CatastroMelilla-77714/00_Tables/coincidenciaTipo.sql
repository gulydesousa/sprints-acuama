--DROP TABLE MelillaCatastro.coincidenciaTipo
CREATE TABLE MelillaCatastro.coincidenciaTipo(
[ctId] SMALLINT NOT NULL, 
[ctDescripcion] VARCHAR(40) NOT NULL,
[ctPrecedencia] TINYINT NOT NULL,
CONSTRAINT [PK_Trabajo_catastroCoincidencias] PRIMARY KEY([ctId]),
)
GO
/*
--DELETE FROM MelillaCatastro.coincidenciaTipo
INSERT INTO MelillaCatastro.coincidenciaTipo VALUES
(100, 'Direcci�n', 30), 
(200, 'NIF', 60),
(201, 'NIF y Calle', 50),
(202, 'NIF, Calle y Finca', 40),
(203, 'NIF y Direcci�n', 20),
(204, 'NIF, Direcci�n y Nombre del titular', 10),
(300, 'Referencias catastrales', 70);

GO
*/