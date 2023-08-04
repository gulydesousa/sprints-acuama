--EXEC Sociedades_SelectPorDefecto 
CREATE PROCEDURE Sociedades_SelectPorDefecto 
AS

--Id de la sociedad por defecto
DECLARE @scdCod INT = 1;
SELECT @scdCod = pgsvalor FROM parametros WHERE pgsclave = 'SOCIEDAD_POR_DEFECTO';

DECLARE @cobConcepto VARCHAR(50) = '';
SELECT TOP 1 @cobConcepto = C.cobConcepto 
FROM dbo.cobros AS C 
WHERE C.cobOrigen='Remesa' 
ORDER BY C.cobFecReg DESC;

DECLARE @i INT = LEN('Remesa:__');
DECLARE @j INT = CHARINDEX('.', @cobConcepto); --Remesa: 424. Fecha: 25/04/2022
DECLARE @ultimaRemesa VARCHAR(50) = '';
DECLARE @iUltimaRemesa INT = 0;

SELECT @ultimaRemesa = SUBSTRING(@cobConcepto, @i, @j-@i);
SELECT @iUltimaRemesa = TRY_PARSE(@ultimaRemesa AS INT);

SELECT S.scdNif
,  S.scdNom
, S.scdDom
, S.scdPob
, S.scdPrv
, S.scdCpost
, scdTlf1= ISNULL(S.scdTlf1, '')
, scdTlf2= ISNULL(S.scdTlf2, '')
, scdTlf3= ISNULL(S.scdTlf3, '')
, scdFax= ISNULL(S.scdFax, '')
, AcuamaDateTime = dbo.GetAcuamaDate()
, B.banCod
, B.banIban
, B.banNumRem
, UltimaRemesa = IIF(B.banNumRem=@iUltimaRemesa, 1, 0) 
FROM dbo.sociedades AS S
LEFT JOIN dbo.bancos AS B
ON B.banScd = S.scdcod
AND B.banRemesar=1
LEFT JOIN dbo.ppagos AS P
ON P.ppagCod = B.banPpag
WHERE S.scdcod=@scdCod AND P.ppagActivo=1
--FIRST: Para quedarnos con el que tiene la remesa mas reciente
ORDER BY IIF(B.banNumRem=@iUltimaRemesa, 1, 0) DESC
		, B.banNumRem DESC;
GO

