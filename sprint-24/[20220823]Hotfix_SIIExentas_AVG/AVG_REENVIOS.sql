DECLARE @faccod INT
DECLARE @facPerCod VARCHAR(6)
DECLARE @facCtrcod INT
DECLARE @facVersion INT


DECLARE CUR CURSOR FOR 


	WITH SII AS(
	--Todos los envios al SII ordenados por numero de envio
	SELECT *
	,RN= ROW_NUMBER() OVER (PARTITION BY fcSiiFacPerCod, fcSiiFacCtrCod, fcSiiFacVersion ORDER BY  fcSiiNumEnvio DESC) 
	FROM facSII

	), ULT AS(
	--Ultimo Envio
	SELECT facCod, facPerCod, facCtrCod, facVersion, fcSiiLoteID, fcSiiNumEnvio, fcSiicodErr
	FROM facturas AS F
	INNER JOIN SII AS S
	ON F.facCod = S.fcSiiFacCod
	AND F.facPerCod = S.fcSiiFacPerCod
	AND F.facCtrCod = S.fcSiiFacCtrCod
	AND F.facVersion = S.fcSiiFacVersion
	AND RN=1 

	), LOTE AS(
	--Ultimo envio con el error 1219: exenta
	SELECT facCod, facPerCod, facCtrCod, facVersion, fcSiiLoteID
	, DR = DENSE_RANK() OVER(ORDER BY fcSiiLoteID)
	FROM ULT
	WHERE fcSiicodErr='1219')

	--***********************
	--Seleccionamos lotes enteros
	--***********************
	SELECT faccod, facPerCod, facCtrcod, facVersion FROM LOTE WHERE DR<2

ORDER BY facpercod
OPEN CUR;

FETCH NEXT FROM CUR INTO @faccod, @facPerCod, @facCtrcod, @facVersion

WHILE @@FETCH_STATUS = 0
    BEGIN
		--SELECT F.facFecUltimoReenvioSII, facCtrCod
        UPDATE F SET F.facFecUltimoReenvioSII=GETDATE()
		FROM dbo.facturas AS F WHERE facCod = @faccod AND facPerCod= @facpercod AND  facCtrCod = @facCtrcod AND facVersion = @facVersion
		
		FETCH NEXT FROM CUR INTO @faccod, @facPerCod, @facCtrcod, @facVersion
    END;

CLOSE CUR;

DEALLOCATE CUR;

