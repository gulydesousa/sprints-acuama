CREATE TABLE dbo.liquidacionesTipos(
  liqTipoId [INT] NOT NULL
, liqTipoDesc VARCHAR(50) NOT NULL 
, liqOrganismoId SMALLINT 
, liqEntidadEmisora VARCHAR(3) NOT NULL
, liqCodTributo VARCHAR(3) NOT NULL
, liqDescripcionTributo VARCHAR(40) NOT NULL
, liqConceptoTributo VARCHAR(2) NOT NULL
, CONSTRAINT [PK_LiquidacionesTipos] PRIMARY KEY (liqTipoId)
, CONSTRAINT [FK_LiquidacionesTipos_Organismo] FOREIGN KEY (liqOrganismoId) REFERENCES organismos(orgCodigo)
);
