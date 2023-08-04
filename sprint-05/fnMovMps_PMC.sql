
CREATE FUNCTION fnMovMps_PMC 
(
	  @mpscod varchar(20)
	, @mmpalm varchar(4) = NULL
)
RETURNS MONEY
AS
BEGIN

DECLARE @cantStock DECIMAL(15,2);
DECLARE @pmc MONEY;
DECLARE @stockNegativo BIT; 
DECLARE @hayMovimientos BIT;

--EXEC [dbo].[MovMps_CalcularStockPmc] @mpscod
--, @cantStock OUTPUT
--, @pmc OUTPUT
--, @stockNegativo OUTPUT
--, @hayMovimientos OUTPUT
--, @calcularPMC=1
--, @fechaCorteReg = NULL, @fechaCorteOp=NULL
--, @codAlmInicial=@mmpalm, @codAlmFinal=NULL
	
		SET @pmc = 0	
	-- **CALCULAR PMC ** --
		DECLARE @mmpuds AS DECIMAL(11,2) --unidades
		DECLARE @mmpprecio AS MONEY --precio de coste
		DECLARE @tmvtip AS varchar(1) --Tipo de movimiento (E o S)
		DECLARE @mmpdto1 AS DECIMAL(4,2)
		DECLARE @mmpdto2 AS DECIMAL(4,2)

		--Cursor para recorrer los movimientos deseados
		DECLARE _CURSOR CURSOR FOR
		SELECT mmpuds = ISNULL(M.mmpuds,0)
			 , mmpprecio = ISNULL(M.mmpprecio,0)
			 , tmvtip = TM.tmvtip
			 , mmpdto1 = ISNULL(M.mmpdto1,0)
			 , mmpdto2 = ISNULL(M.mmpdto2,0)
		FROM dbo.movmps AS M
		INNER JOIN tiposmov  AS TM
		ON M.mmptmv = TM.tmvcod
		WHERE TM.tmvtip in ('E','S')				--sólo tipos Entrada ó Salida
		AND M.mmpmpscod = @mpscod					--filtro por mps
		AND (@mmpalm IS NULL OR M.mmpalm = @mmpalm)	--filtro por almacen
		AND M.mmpmpstip = 'M'						--sólo tipo 'MATERIAL'
		ORDER BY M.mmpfecha, TM.tmvtip				--ordeno por fecha de operación y tipo de movimiento (primero entradas y luego salidas)
		
		OPEN _CURSOR
		FETCH NEXT FROM _CURSOR
		INTO @mmpuds, @mmpprecio, @tmvtip, @mmpdto1, @mmpdto2
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @tmvtip = 'E'
			BEGIN
				SET @cantStock = @cantStock + @mmpuds;

				--Evitar calculo PMC negativo
				IF @mmpuds < 0
					SET @mmpuds = @mmpuds * -1;
				IF @mmpprecio < 0
					SET @mmpprecio = @mmpprecio * -1;

				--Aplicamos los descuentos al precio
				SET @mmpprecio = (@mmpprecio)-(@mmpprecio*(@mmpdto1/100))-((@mmpprecio)-(@mmpprecio*(@mmpdto1/100)))*(@mmpdto2/100);
				
				--Calculo el PMC
				IF @cantStock <> 0 
					SET @pmc = (((@cantStock - @mmpuds)*@pmc) + (@mmpuds*@mmpprecio)) / @cantStock;
			END
			ELSE --@tmvtip = 'S'
				SET @cantStock = @cantStock - @mmpuds;

			IF @cantStock < 0 --Si el stock es negativo "activamos el flag stockNegativo"
				SET @stockNegativo = 1;

			IF @hayMovimientos = 0
				SET @hayMovimientos = 1;
				
			FETCH NEXT FROM _CURSOR
			INTO @mmpuds, @mmpprecio, @tmvtip, @mmpdto1, @mmpdto2
		END

		CLOSE _CURSOR
		DEALLOCATE _CURSOR
	-- **FIN CALCULAR PMC ** --
	
	--Si el pmc es 0 o null se OBTIENE el valor del precio de coste de la tabla mps
	IF (@pmc IS NULL OR @pmc = 0)
		SET @pmc = (SELECT ISNULL(M.mpsPrecioCoste, 0) FROM dbo.mps AS M WHERE M.mpscod = @mpscod)
	
	RETURN @pmc;

END
GO

