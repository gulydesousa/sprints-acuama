--SELECT * FROM ordenTrabajo
BEGIN TRY
	ALTER TABLE dbo.ordenTrabajo DROP CONSTRAINT FK_ordenTrabajo_otTipoOrigen;

	ALTER TABLE dbo.ordenTrabajo DROP CONSTRAINT DF_ordenTrabajo_otTipoOrigen;

	ALTER TABLE dbo.ordenTrabajo DROP COLUMN otTipoOrigen;
END TRY
BEGIN CATCH
END CATCH
GO

/*
ALTER TABLE dbo.ordenTrabajo 
ADD otTipoOrigen VARCHAR(10) NULL;
GO 
*/

ALTER TABLE dbo.ordenTrabajo 
ADD CONSTRAINT DF_ordenTrabajo_otTipoOrigen DEFAULT ('ANY')  FOR otTipoOrigen WITH VALUES;

UPDATE dbo.ordenTrabajo  SET otTipoOrigen='ANY';


ALTER TABLE dbo.ordenTrabajo  
ALTER COLUMN  otTipoOrigen VARCHAR(10) NOT NULL;


ALTER TABLE dbo.ordenTrabajo
ADD CONSTRAINT FK_ordenTrabajo_otTipoOrigen
FOREIGN KEY(otottcod, otTipoOrigen) 
REFERENCES otTiposOrigen(ottoCodigo, ottoOrigen);


SELECT otTipoOrigen FROM ordenTrabajo