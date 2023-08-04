CREATE TRIGGER tgrcobLinEfectosPendientes_Delete
ON [dbo].[cobLinEfectosPendientes]
FOR DELETE 
AS
SET NOCOUNT ON;

UPDATE E
SET efePdteFecRemesada = NULL
  , efePdteUsrRemesada = NULL
FROM DELETED AS D
INNER JOIN dbo.efectosPendientes AS E
ON E.efePdteCod		= D.clefePdteCod
AND E.efePdteCtrCod = D.clefePdteCtrCod
AND E.efePdtePerCod = D.clefePdtePerCod
AND E.efePdteFacCod = D.clefePdteFacCod
AND E.efePdteScd	= D.clefePdteScd;

GO