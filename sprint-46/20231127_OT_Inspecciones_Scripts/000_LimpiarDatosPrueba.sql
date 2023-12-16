DELETE FROM otDatosValor WHERE otdvOdtCodigo=2001;

DELETE FROM  otInspeccionesContratos_Melilla;

DELETE FROM otInspecciones_Melilla;

DISABLE TRIGGER [ordenTrabajo_DeleteCascada] ON ordenTrabajo;
DELETE FROM ordenTrabajo WHERE otTipoOrigen='INSPMASIVO';
ENABLE TRIGGER [ordenTrabajo_DeleteCascada] ON ordenTrabajo;


--DROP TABLE otInspeccionesContratos_Melilla
--DROP TABLE otInspecciones_Melilla
--DROP TABLE otInspeccionesApto_Melilla