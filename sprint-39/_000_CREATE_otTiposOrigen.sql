BEGIN TRY

	ALTER TABLE dbo.ordenTrabajo DROP CONSTRAINT FK_ordenTrabajo_otTipoOrigen;

	ALTER TABLE dbo.ordenTrabajo DROP CONSTRAINT DF_ordenTrabajo_otTipoOrigen;

	ALTER TABLE dbo.ordenTrabajo DROP COLUMN otTipoOrigen;

END TRY
BEGIN CATCH
END CATCH
GO

BEGIN TRY
	DROP TABLE dbo.otTiposOrigen;
END TRY
BEGIN CATCH
END CATCH
GO


CREATE TABLE dbo.otTiposOrigen (
  ottoCodigo VARCHAR(4) NOT NULL
, ottoOrigen VARCHAR(10) NOT NULL CONSTRAINT [DF_ottoOrigen] DEFAULT 'ANY'
, ottoDescripcion VARCHAR(50) NOT NULL 
--OTs anteriores a esta fecha deberán ser consultadas por el origen por defecto.
, ottoFechaInicio DATE  NOT NULL 
, CONSTRAINT [PK_otTiposOrigen] PRIMARY KEY CLUSTERED(ottoCodigo, ottoOrigen) 
);

GO




