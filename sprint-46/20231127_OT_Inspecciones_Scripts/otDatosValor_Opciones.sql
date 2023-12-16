--EXEC dbo.otDatosValor_Opciones 2001


ALTER PROCEDURE dbo.otDatosValor_Opciones @codigo INT AS
SET NOCOUNT ON
SELECT DISTINCT otdvOdtCodigo,  otdvValor FROM dbo.otdatosValor WHERE otdvOdtCodigo=@codigo;

GO