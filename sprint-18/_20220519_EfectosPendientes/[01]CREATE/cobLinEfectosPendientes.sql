
CREATE TABLE [dbo].[cobLinEfectosPendientes](
	[cleCblScd] [SMALLINT] NOT NULL,
	[cleCblPpag] [SMALLINT] NOT NULL,
	[cleCblNum] [INT] NOT NULL,
	[cleCblLin] [SMALLINT] NOT NULL,

	[clefePdteCod] [INT] NOT NULL,
	[clefePdteCtrCod] [INT] NOT NULL,
	[clefePdtePerCod] [VARCHAR](6) NOT NULL,
	[clefePdteFacCod] [SMALLINT] NOT NULL,
	[clefePdteScd] [SMALLINT] NOT NULL,

	[clefePdteRemesa] [INT] NULL,
	[clefePdteFechaRemesa] [DATETIME],

	CONSTRAINT [PK_cobLinEfectosPendientes] PRIMARY KEY CLUSTERED 
	(
		[cleCblScd] ASC,
		[cleCblPpag] ASC,
		[cleCblNum] ASC,
		[cleCblLin] ASC,
		[clefePdteCod] ASC,
		[clefePdteCtrCod] ASC,
		[clefePdtePerCod] ASC,
		[clefePdteFacCod] ASC,
		[clefePdteScd] ASC
	)
)

GO


ALTER TABLE [dbo].[cobLinEfectosPendientes]  WITH CHECK 
ADD  CONSTRAINT [FK_cobLinEfectosPendientes_coblin] 
FOREIGN KEY([clefePdteScd], [cleCblPpag], [cleCblNum], [cleCblLin])
REFERENCES [dbo].[coblin] ([cblScd], [cblPpag], [cblNum], [cblLin])
GO

ALTER TABLE [dbo].[cobLinEfectosPendientes] 
CHECK CONSTRAINT [FK_cobLinEfectosPendientes_coblin]
GO

ALTER TABLE [dbo].[cobLinEfectosPendientes]  WITH CHECK ADD 
CONSTRAINT [FK_cobLinEfectosPendientes_efectosPendientes] 
FOREIGN KEY([clefePdteCod], [clefePdteCtrCod], [clefePdtePerCod], [clefePdteFacCod], [cleCblScd])
REFERENCES [dbo].[efectosPendientes] ([efePdteCod], [efePdteCtrCod], [efePdtePerCod], [efePdteFacCod], [efePdteScd])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[cobLinEfectosPendientes] CHECK CONSTRAINT [FK_cobLinEfectosPendientes_efectosPendientes]
GO


