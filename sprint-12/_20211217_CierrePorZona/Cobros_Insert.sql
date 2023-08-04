ALTER PROCEDURE [dbo].[Cobros_Insert]
(
		 @cobScd  smallint
		,@cobPpag smallint
		,@cobUsr varchar(10)
		,@cobFec datetime
		,@cobCtr int
		,@cobNom varchar(40)
		,@cobDocIden varchar(14)
		,@cobImporte money
		,@cobMpc smallint
		,@cobMpcDato1 varchar(40)
		,@cobMpcDato2 varchar(40)
		,@cobMpcDato3 varchar(40)
		,@cobMpcDato4 varchar(40)
		,@cobMpcDato5 varchar(40)
		,@cobMpcDato6 varchar(40)
		,@cobConcepto varchar(50)
		,@cobDevCod varchar(4) = NULL
		,@cobFecContabilizacion datetime = NULL
		,@cobUsrContabilizacion varchar(10) = NULL
		,@cobComCodigo SMALLINT = NULL
		,@cobNum int output
		,@cobOrigen varchar(20) = NULL
		,@cobFecReg datetime = NULL
)
AS
	SET NOCOUNT OFF;

	--***********************
	--Hacemos el insert en una sola operacion para ver si conseguimos sortear estos fallos que nos han salido en el cierre masivo v2.0
	--KO1. Infracción de la restricción PRIMARY KEY 'PK_cobros'. No se puede insertar una clave duplicada en el objeto 'dbo.cobros'. El valor de la clave duplicada es (1, 99, 3210).;2021-12-15 10:40:29
	--KO2. El recuento de transacciones después de EXECUTE indica un número no coincidente de instrucciones BEGIN y COMMIT. Recuento anterior = 1, recuento actual = 0.;2021-12-15 14:52:02
	--KO3. Ha ocurrido un error insertando la cabecera del cobro;2021-12-15 15:12:50
	--***********************
	DECLARE @RESULT INT = 0;

	--/*
	
	EXEC @cobNum = dbo.Cobros_IncrementarNumerador @cobScd, @cobPpag;
	
	INSERT INTO dbo.cobros
	SELECT    @cobScd
			, @cobPpag
			, @cobNum
			, cobFecReg = ISNULL(@cobFecReg, dbo.GetAcuamaDate())
			, @cobUsr
			, @cobFec
			, @cobCtr
			, @cobNom
			, @cobDocIden
			, @cobImporte
			, @cobMpc
			, @cobMpcDato1, @cobMpcDato2, @cobMpcDato3, @cobMpcDato4, @cobMpcDato5, @cobMpcDato6
			, @cobConcepto
			, @cobDevCod
			, @cobFecContabilizacion
			, @cobUsrContabilizacion
			, @cobComCodigo
			, cobFecUltMod = NULL
			, cobUsrUltMod = NULL
			, @cobOrigen
	WHERE @cobNum >= 0;
	
	--[99]Cobro Insertado
	SELECT @RESULT = IIF(@@ROWCOUNT=0, 1, 0);	
	RETURN @RESULT;

	--*/

	/*
	SELECT @cobNum = ISNULL(MAX(cobNum),0) + 1 FROM cobros WHERE cobScd=@cobScd AND cobPpag=@cobPpag

	INSERT INTO cobros (cobScd,cobPpag,cobNum,cobFecReg,cobUsr,cobFec,cobCtr,cobNom,cobDocIden,cobImporte,cobMpc,cobMpcDato1,cobMpcDato2,cobMpcDato3,cobMpcDato4,cobMpcDato5,cobMpcDato6,cobConcepto,cobDevCod,cobFecContabilizacion,cobUsrContabilizacion,cobComCodigo, cobOrigen)
	VALUES( @cobScd,@cobPpag,@cobNum,ISNULL(@cobFecReg,GETDATE()),@cobUsr,@cobFec,@cobCtr,@cobNom,@cobDocIden,@cobImporte,@cobMpc,@cobMpcDato1,@cobMpcDato2,@cobMpcDato3,@cobMpcDato4,@cobMpcDato5,@cobMpcDato6,@cobConcepto,@cobDevCod,@cobFecContabilizacion,@cobUsrContabilizacion, @cobComCodigo, @cobOrigen)

	RETURN @@ERROR
	*/

	
GO
/*
TRUNCATE TABLE cobrosNum;
GO


INSERT INTO cobrosNum
SELECT scdcod, ppagCod, cbnNumero FROM dbo.vCobrosNumerador;
GO


SELECT * FROM cobrosNum WHERE cbnNumero>0

*/