--EXEC otTiposOrigen_Select '00'

CREATE PROCEDURE otTiposOrigen_Select @ottoCodigo VARCHAR(10)=NULL
AS

SELECT * 
FROM dbo.otTiposOrigen
WHERE @ottoCodigo IS NULL 
   OR @ottoCodigo='' 
   OR ottoCodigo=@ottoCodigo;

GO