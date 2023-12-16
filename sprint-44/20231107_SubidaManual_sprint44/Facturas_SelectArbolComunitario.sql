/*
DECLARE @contratoComunitario INT = 51195;
DECLARE @periodo VARCHAR(6) = '202301';
DECLARE @soloUltimaVersion BIT = 1;

EXEC dbo.Facturas_SelectArbolComunitario @contratoComunitario , @periodo, @soloUltimaVersion;
*/

CREATE PROCEDURE dbo.Facturas_SelectArbolComunitario
  @contratoComunitario AS INT
, @periodo AS VARCHAR(6)
, @soloUltimaVersion AS BIT = 1
AS
	SET NOCOUNT ON;

	--Todas las facturas de un contrato y sus contratos hijos
	DECLARE @codZona AS VARCHAR(4);
	DECLARE @raiz AS INT;
	DECLARE @tArbolComunitario AS dbo.tArbolComunitario;

	SELECT @codZona = facZonCod 
	FROM dbo.facturas AS F 
	WHERE F.facPerCod=@periodo
	AND F.facCtrCod= @contratoComunitario;

	--Obtenemos el nodo raíz del contrato comunitario
	EXEC [dbo].[Contratos_ObtenerRaiz] @contratoComunitario, @raiz OUTPUT;
	SET @raiz =  ISNULL(@raiz, @contratoComunitario);

	--Calculamos el arbol comunitario de ese contrato
	INSERT INTO @tArbolComunitario
	EXEC dbo.Contratos_ObtenerArbolComunitario @codZona, @raiz;

	SELECT F.* , A.ctrComunitario
	INTO #FAC
	FROM dbo.facturas AS F
	INNER JOIN @tArbolComunitario AS A
	ON A.ctrCod  = F.facCtrCod
	WHERE F.facPerCod=@periodo
	AND (@soloUltimaVersion=0 OR  F.facFechaRectif IS NULL)
	

	IF(NOT EXISTS(SELECT facCtrCod FROM #FAC)) 
	INSERT INTO #FAC	
	SELECT F.* , NULL
	FROM dbo.facturas AS F
	WHERE F.facPerCod=@periodo
	AND facCtrCod = @contratoComunitario
	AND (@soloUltimaVersion=0 OR  F.facFechaRectif IS NULL);

	SELECT * FROM #FAC ORDER BY facCtrCod, facPerCod, facCod, facVersion;

	DROP TABLE IF EXISTS #FAC;
	--IF OBJECT_ID('tempdb..#FAC') IS NOT NULL DROP TABLE #FAC;   
GO
