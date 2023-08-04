ALTER PROCEDURE [dbo].[Mandatos_Select]
	 @manRef VARCHAR(35) = NULL
	,@manFecFirma DATETIME = NULL
	,@manFecUltMod DATETIME = NULL
	,@manSecuencia VARCHAR(4) = NULL
	,@manLocalidad VARCHAR(40) = NULL
	,@manEstadoActual SMALLINT = NULL
	,@manTipoPago SMALLINT = NULL
	,@sinEfectoPdte BIT = NULL
	,@manFecUltUso DATETIME = NULL
AS
	SET NOCOUNT OFF;

SELECT manCtrCod, manCtrVersion, 
	   manEfePdteCod, manEfePdteFacCod, manEfePdtePerCod, manEfePdteScd,
	   manRef, manFecFirma, manLocalidad, manIdnAcr, manorigen, manTipoPago,manSecuencia, manEstadoActual,
	   manFecUltMod, manFecUltUso,
       manDocIden AS docIden,
       manNombre AS nombre,
       manDireccion AS direccion,
       manProvincia AS provincia,
       manPoblacion AS poblacion,
       manCPostal AS cpostal,      
      (SELECT ncndes FROM naciones WHERE ncnCod = manNacion) AS nacion,
       manIban AS iban,
       manBic  AS bic
	   , manNacion
  FROM mandatos
  WHERE (@manRef IS NULL OR @manRef=manRef)
	  AND (@manFecFirma IS NULL OR @manFecFirma=manFecFirma)
	  AND (@manFecUltUso IS NULL OR @manFecUltUso=manFecUltUso)
	  AND (@manFecUltMod IS NULL OR @manFecUltMod=manFecUltMod)
	  AND (@manSecuencia IS NULL OR @manSecuencia=manSecuencia)
      AND (@manLocalidad IS NULL OR @manLocalidad=manLocalidad)
      AND (@manEstadoActual IS NULL OR @manEstadoActual=manEstadoActual)
      AND (@manTipoPago IS NULL OR @manTipoPago=manTipoPago)
      --AND (@sinEfectoPdte IS NULL OR @sinEfectoPdte = 0 OR (@sinEfectoPdte = 1 AND manEfePdtCod IS NULL))
  ORDER BY manFecFirma DESC

GO


