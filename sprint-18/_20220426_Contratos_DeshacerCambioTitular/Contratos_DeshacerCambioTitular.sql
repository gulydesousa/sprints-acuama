--EXEC Contratos_DeshacerCambioTitular @ctrCod=3666306 

CREATE PROCEDURE Contratos_DeshacerCambioTitular @ctrCod INT
AS

DECLARE @fechaAnulacion DATETIME;
DECLARE @ctrNuevo AS VARCHAR(15);

BEGIN TRY

WITH CTR AS(
SELECT *
, RN = ROW_NUMBER() OVER (PARTITION BY ctrCod ORDER BY ctrVersion DESC) 
FROM dbo.contratos 
WHERE ctrCod= @ctrCod)


SELECT @fechaAnulacion=ctrfecanu
	 , @ctrNuevo = ctrNuevo
FROM CTR WHERE RN=1;

IF @fechaAnulacion IS NOT NULL AND @ctrNuevo IS NOT NULL
BEGIN
	BEGIN TRAN;

	--SELECT * 
	UPDATE CS SET ctsfecbaj=NULL
	OUTPUT DELETED.*
	FROM dbo.contratoServicio AS CS
	WHERE ctsctrcod= @ctrCod AND  ctsfecbaj=@fechaAnulacion

	--SELECT * 
	UPDATE C SET ctrfecanu=NULL
				, ctrusrcodanu=NULL
				, ctrbaja=0
				, ctrObs='Se revierte el cambio de titular: '+ @ctrNuevo
				, ctrFecSolBaja=NULL
				, ctrNuevo=NULL
	OUTPUT DELETED.*
	FROM dbo.contratos AS C 
	WHERE ctrCod=@ctrCod AND ctrfecanu=@fechaAnulacion;
	COMMIT;
END
END TRY

BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber  
         , ERROR_SEVERITY() AS ErrorSeverity  
         , ERROR_STATE() AS ErrorState  
         , ERROR_PROCEDURE() AS ErrorProcedure  
         , ERROR_LINE() AS ErrorLine  
         , ERROR_MESSAGE() AS ErrorMessage;  
  
    IF @@TRANCOUNT > 0  
        ROLLBACK TRANSACTION;  

END CATCH

GO