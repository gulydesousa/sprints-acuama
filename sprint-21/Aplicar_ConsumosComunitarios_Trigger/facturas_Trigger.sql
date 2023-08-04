ALTER TRIGGER [dbo].[facturas_Trigger]
ON [dbo].[facturas]
AFTER UPDATE 
AS
IF UPDATE(facEnvSERES)
BEGIN
	UPDATE [dbo].[facturas] SET facFecEmisionSERES = GETDATE() FROM  Inserted WHERE [facturas].facCod = Inserted.facCod
	and [facturas].facPerCod = Inserted.facPerCod and [facturas].facCtrCod=Inserted.facCtrCod and [facturas].facVersion =Inserted.facVersion
	AND [facturas].facCtrVersion= Inserted.facCtrVersion AND [facturas].facSerScdCod = Inserted.facSerScdCod
	AND [facturas].facSerCod=Inserted.facSerCod	and [facturas].facEnvSERES = 'E' 
	AND [facturas].facNumero = Inserted.facNumero	
END







--...................................................
--Dejaremos una traza si hay cambio en los consumos
DECLARE @params		AS VARCHAR(500)  = 'facCod:%i, facPerCod:%s, facCtrCod:%i, facVersion=%i';
DECLARE @msg		AS VARCHAR(4000) = 'facConsumoFactura:%i, facCnsFinal:%i, facCnsComunitario:%i';
DECLARE @antes		AS VARCHAR(500)	 = NULL;
DECLARE @despues	AS VARCHAR(500)  = NULL;

SELECT @params  = FORMATMESSAGE(@params, I.facCod, I.facPerCod, I.facCtrCod, I.facVersion)
	 , @antes   = FORMATMESSAGE(@msg, D.facConsumoFactura, D.facCnsFinal, D.facCnsComunitario)
	 , @despues = FORMATMESSAGE(@msg, I.facConsumoFactura, I.facCnsFinal, I.facCnsComunitario)
FROM DELETED AS D
INNER JOIN INSERTED AS I
ON  D.facCod = I.facCod
AND D.facPerCod = I.facPerCod
AND D.facCtrCod = I.facCtrCod
AND D.facVersion = I.facVersion
AND (D.facConsumoFactura <> I.facConsumoFactura OR D.facCnsFinal <> I.facCnsFinal OR D.facCnsComunitario <> I.facCnsComunitario);

--...................................................
--Para evitar la ejecución de este paso del trigger cuando CONTEXT_INFO = 0x55555
DECLARE @CINFO VARBINARY(128) 
SET @CINFO		= (SELECT CONTEXT_INFO());


--******************************************
--Se pasará el consumo factura al consumo final
--De esta manera aplicar consumos comunitarios puede dar por sentado que 
--el calculo de los consumos comunitarios se hará con el nuevo consumo de la factura
--Tasks_Facturas_AplicarConsumosComunitarios CONTEXT_INFO = 0x55555
--******************************************
DECLARE @NESTLEVEL INT;
SET @NESTLEVEL  = (SELECT TRIGGER_NESTLEVEL());

IF (@NESTLEVEL <= 1 AND  (@CINFO IS NULL OR @CINFO <> 0x55555)) 
BEGIN
	UPDATE F SET F.facCnsFinal = I.facConsumoFactura
	FROM DELETED AS D
	INNER JOIN INSERTED AS I
		ON  D.facCod = I.facCod
		AND D.facPerCod = I.facPerCod
		AND D.facCtrCod = I.facCtrCod
		AND D.facVersion = I.facVersion
		--Prefacturas
		AND I.facNumero IS NULL
		--Hay cambio en el consumo factura
		AND ISNULL(D.facConsumoFactura, 0) <> ISNULL(I.facConsumoFactura, 0)
		AND ISNULL(D.facCnsFinal, 0) = ISNULL(I.facCnsFinal, 0)
	INNER JOIN dbo.vContratosUltimaVersion AS C
		--Es una factura de un contrato padre
		ON D.facCtrCod = C.ctrCod
		AND C.numHijosComunitarios > 0	
	INNER JOIN dbo.perzona AS P
		--Se han aplicado los consumos comunitarios al menos una vez
		ON P.przcodper  = I.facPerCod
		AND P.przcodzon = I.facZonCod
		AND P.przFecIniCnsCom IS NOT NULL
	INNER JOIN dbo.facturas AS F 
		ON  F.facCod = I.facCod
		AND F.facPerCod = I.facPerCod
		AND F.facCtrCod = I.facCtrCod
		AND F.facVersion = I.facVersion;
	--...................................................
	--Dejamos una traza facCnsFinal=facConsumoFactura
	IF (@@ROWCOUNT=1)
	BEGIN	
		SELECT @despues = FORMATMESSAGE(@msg, I.facConsumoFactura, I.facConsumoFactura, I.facCnsComunitario)
		FROM DELETED AS D
		INNER JOIN INSERTED AS I
		ON  D.facCod = I.facCod
		AND D.facPerCod = I.facPerCod
		AND D.facCtrCod = I.facCtrCod
		AND D.facVersion = I.facVersion;
	END
END


--...................................................
--Dejamos la traza de las lecturas con el antes y despues
IF (LEN(@antes) > 0)
BEGIN
	SELECT @msg = CONCAT('ANTES:   ', @antes, ' DESPUES: ', @despues);
	EXEC Trabajo.errorLog_Insert 'facturas_Trigger', @params,  @msg;
END
--...................................................
GO

