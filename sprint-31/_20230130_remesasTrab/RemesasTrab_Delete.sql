ALTER PROCEDURE [dbo].[RemesasTrab_Delete] 
@remUsrCod VARCHAR(10) = NULL,
@remCtrcod INT = NULL,
@remPerCod INT = NULL,
@remFacCod SMALLINT = NULL,
@remEfePdteCod INT = NULL,
@soloCobrados BIT = NULL

, @programacionPdte BIT = NULL
, @tskType SMALLINT = NULL
, @tskNumber INT = NULL

AS 

SET NOCOUNT ON; 

	DECLARE @remTrab AS TABLE(remUsrCod VARCHAR(10), remCtrCod INT, remPerCod VARCHAR(6), remFacCod INT, remEfePdteCod INT, remSerScdCod SMALLINT)
	
	INSERT INTO @remTrab
	SELECT R1.remUsrCod
	, R1.remCtrCod
	, R1.remPerCod
	, R1.remFacCod
	, R1.remEfePdteCod
	, R1.remSerScdCod
	FROM dbo.remesasTrab AS R1
	LEFT JOIN efectosPendientes ON efePdteCod = remEfePdteCod AND efePdteCtrCod = remCtrCod AND efePdteFacCod = remFacCod AND efePdtePerCod = remPerCod AND efePdteScd = remSerScdCod 
	WHERE (@remUsrCod IS NULL OR remUsrCod = @remUsrCod) AND
	(remCtrCod = @remCtrCod OR @remCtrCod IS NULL) AND
	(remPerCod = @remPerCod OR @remPerCod IS NULL) AND
	(remFacCod = @remFacCod OR @remFacCod IS NULL) AND
	(remEfePdteCod = @remEfePdteCod OR @remEfePdteCod IS NULL) AND
	(@soloCobrados IS NULL OR @soloCobrados = 0 OR 
	(@soloCobrados = 1 AND
		(
			remFacTotal <= remPagado OR 
			ISNULL(efePdteImporte, remFacTotal - remPagado) > (remFacTotal - remPagado) OR 
			efePdteFecRechazado IS NOT NULL OR efePdteFecRemesada IS NOT NULL OR
			EXISTS(SELECT remCtrCod FROM remesasTrab r2 WHERE r2.remEfePdteCod <> 0 AND r1.remCtrCod = r2.remCtrCod AND r1.remPerCod = r2.remPerCod AND r1.remFacCod = r2.remFacCod AND r1.remEfePdteCod = r2.remEfePdteCod)
		)
	))

	AND ((@programacionPdte IS NULL) OR 
		 (@programacionPdte=1 AND (r1.[remTskType] IS NULL AND r1.[remTskNumber] IS NULL)) OR 
		 (@programacionPdte=0 AND (r1.[remTskType] IS NOT NULL AND r1.[remTskNumber] IS NOT NULL)))

	AND (@tskType IS NULL	OR r1.[remTskType]	=@tskType)
	AND (@tskNumber IS NULL OR r1.[remTskNumber]=@tskNumber)


	BEGIN TRAN
	BEGIN TRY
		DELETE T
		FROM @remTrab AS T1
		INNER JOIN dbo.remesasTrab AS T
		ON T1.remUsrCod = T.remUsrCod		
		AND T1.remCtrCod = T.remCtrCod
		AND T1.remPerCod = T.remPerCod
		AND T1.remFacCod = T.remFacCod
		AND T1.remEfePdteCod = T.remEfePdteCod;

		UPDATE T SET efePdteFecSelRemesa=NULL, efePdteUsrSelRemesa=NULL
		FROM @remTrab AS T1
		INNER JOIN dbo.efectosPendientes AS T
		ON T1.remEfePdteCod = T.efePdteCod
		AND T1.remCtrCod = T.efePdteCtrCod
		AND T1.remPerCod = T.efePdtePerCod
		AND T1.remFacCod = T.efePdteFacCod
		AND T1.remSerScdCod = T.efePdteScd;

	END TRY
	BEGIN CATCH
	 IF @@TRANCOUNT > 0  ROLLBACK TRANSACTION;  
	END CATCH

	IF @@TRANCOUNT > 0  COMMIT TRANSACTION;  



GO


