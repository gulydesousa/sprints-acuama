ALTER PROCEDURE [dbo].[RemesasTrab_Exists]    
@remEfePdteCod SMALLINT = NULL,
@remUsrCod VARCHAR(10) = NULL,
@remFacCod SMALLINT = NULL,
@remCtrCod INT = NULL,
@remPerCod VARCHAR(6) = NULL,
@soloConflictos BIT = NULL

, @programacionPdte BIT = NULL
, @tskType SMALLINT = NULL
, @tskNumber INT = NULL

, @exists BIT OUTPUT 
 
AS SET NOCOUNT ON;   
  
IF EXISTS (SELECT remEfePdteCod FROM dbo.remesasTrab AS r1
		   WHERE (@remEfePdteCod = remEfePdteCod OR @remEfePdteCod IS NULL) AND
				 (@remUsrCod = remUsrCod OR @remUsrCod IS NULL) AND
				 
				 (@tskType IS NULL	 OR r1.[remTskType]	=@tskType) AND
				 (@tskNumber IS NULL OR r1.[remTskNumber]=@tskNumber) AND
				 ((@programacionPdte IS NULL) OR 
				  (@programacionPdte=1 AND (r1.[remTskType] IS NULL AND r1.[remTskNumber] IS NULL)) OR 
				  (@programacionPdte=0 AND (r1.[remTskType] IS NOT NULL AND r1.[remTskNumber] IS NOT NULL))
				 ) AND

				 (@remFacCod = remFacCod OR @remFacCod IS NULL) AND
				 (@remCtrCod = remCtrCod OR @remCtrCod IS NULL) AND
				 (@remPerCod = remPerCod OR @remPerCod IS NULL) AND
				 (@soloConflictos IS NULL OR @soloConflictos = 0 OR
				 (@soloConflictos = 1 AND remEfePdteCod <> 0 AND  
				  EXISTS(SELECT remCtrCod FROM remesasTrab r2
   				 		 WHERE  r1.remCtrCod = r2.remCtrCod AND 
							    r1.remFacCod = r2.remFacCod AND 
							    r1.remPerCod = r2.remPerCod AND 
							    r1.remUsrCod = r2.remUsrCod AND 
							    r2.remEfePdteCod = 0))))
	SET @exists=1  
ELSE   
	SET @exists=0





GO


