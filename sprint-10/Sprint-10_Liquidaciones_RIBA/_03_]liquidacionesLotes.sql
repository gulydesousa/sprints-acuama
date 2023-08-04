ALTER TABLE [dbo].[liquidacionesLotes]
ADD liqLoteFacturas INT NULL;

ALTER TABLE [dbo].[liquidacionesLotes]
ADD liqLoteBaseTotal MONEY NULL;

ALTER TABLE [dbo].[liquidacionesLotes]
ADD liqLoteImpuestoTotal MONEY NULL;