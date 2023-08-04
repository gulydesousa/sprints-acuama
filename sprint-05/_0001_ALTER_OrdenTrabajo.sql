ALTER TABLE dbo.OrdenTrabajo
ADD otFecRechazo DATETIME NULL;


ALTER TABLE dbo.OrdenTrabajo
ADD otUsuRechazo VARCHAR(10) NULL;

ALTER TABLE [dbo].[ordenTrabajo]  WITH CHECK ADD  CONSTRAINT [FK_ordenTrabajo_usuarioRechazo] FOREIGN KEY(otUsuRechazo)
REFERENCES [dbo].[usuarios] ([usrcod])