CREATE PROCEDURE [dbo].[CobLinEfectosPendientes_Insert]
  @cleCblScd SMALLINT
, @cleCblPpag SMALLINT 
, @cleCblNum INT 
, @cleCblLin SMALLINT 
, @clefePdteCod INT 
, @clefePdteCtrCod INT 
, @clefePdtePerCod VARCHAR(6)
, @clefePdteFacCod SMALLINT 
, @clefePdteScd SMALLINT 
, @clefePdteRemesa INT = NULL
, @clefePdteFechaRemesa DATETIME = NULL
AS
	SET NOCOUNT OFF;

    INSERT INTO cobLinEfectosPendientes( 
	  cleCblScd
	, cleCblPpag
	, cleCblNum
	, cleCblLin
	, clefePdteCod
	, clefePdteCtrCod
	, clefePdtePerCod
	, clefePdteFacCod
	, clefePdteScd
	, clefePdteRemesa
	, clefePdteFechaRemesa)

	VALUES(	
	 @cleCblScd
	, @cleCblPpag
	, @cleCblNum
	, @cleCblLin
	, @clefePdteCod
	, @clefePdteCtrCod
	, @clefePdtePerCod
	, @clefePdteFacCod
	, @clefePdteScd
	, @clefePdteRemesa
	, @clefePdteFechaRemesa);

GO