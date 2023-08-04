ALTER PROCEDURE [dbo].[Informe_SORIA_CF010_EmisionFactLINEAS]
(
	@periodo varchar(6) = NULL,		
	@zona varchar(4)=NULL,
	@codigo SMALLINT =NULL,
	@contrato INT =NULL,
	@version SMALLINT =NULL,
	@fechaHasta datetime = NULL
)
AS
	SET NOCOUNT OFF;

BEGIN


SELECT [fclFacPerCod] ,[fclFacCtrCod]  ,[fclFacVersion]  ,[fclNumLinea]  ,[fclEscala1]  ,[fclPrecio1]  ,[fclUnidades1]  ,[fclEscala2]  ,[fclPrecio2]  ,[fclUnidades2]
      ,[fclEscala3]  ,[fclPrecio3]  ,[fclUnidades3]  ,[fclEscala4]  ,[fclPrecio4]  ,[fclUnidades4]  ,[fclEscala5]  ,[fclPrecio5]  ,[fclUnidades5]  ,[fclEscala6]  ,[fclPrecio6]
      ,[fclUnidades6]  ,[fclEscala7]  ,[fclPrecio7]  ,[fclUnidades7]  ,[fclEscala8]  ,[fclPrecio8]  ,[fclUnidades8]  ,[fclEscala9]  ,[fclPrecio9]  ,[fclUnidades9]
      ,ROUND([fcltotal],2) [fcltotal],[fclTrfSvCod]  ,[fclTrfCod]  ,[fclUnidades]  ,[fclPrecio], fclImpuesto, fclBase,
svcdes,
(select pgsvalor from parametros where pgsclave='TLEGAL') as textoLegal,
(select pgsvalor from parametros where pgsclave='POBLACION_POR_DEFECTO') as poblacion,
(select pgsvalor from parametros where pgsclave='CIF_AYUNTAMIENTO') as cifAyuntamiento,
trvlegalavb, trvlegal,
(CASE WHEN fclTrfSvCod = 3 THEN ROW_NUMBER() OVER (PARTITION BY fclTrfSvCod ORDER BY fclTrfSvCod) ELSE NULL END) AS primerSvcRSU,
trfdes
, UU.usocod
, UU.usodes
FROM dbo.faclin AS FL
--***********************************
INNER JOIN dbo.facturas AS FF
ON  FF.faccod = FL.fclFacCod
AND FF.facPerCod = FL.fclFacPerCod
AND FF.facCtrCod = FL.fclFacCtrCod
AND FF.facVersion = FL.fclFacVersion
LEFT JOIN dbo.contratos AS CC
ON CC.ctrcod = FF.facCtrCod
AND CC.ctrversion = FF.facCtrVersion
LEFT JOIN dbo.usos AS UU
ON UU.usocod = CC.ctrUsoCod
--***********************************
INNER JOIN servicios ON fclTrfSvCod=svccod
INNER JOIN tarifas ON trfsrvcod=svccod AND trfCod=fclTrfCod
LEFT JOIN perzona ON przcodper=@periodo AND przcodzon=@zona
LEFT JOIN tarval ON trvsrvcod = fclTrfSvCod AND 
		    trvtrfcod = fclTrfCod AND 
		    trvfecha = (SELECT MAX(trvfecha) 
			        FROM tarval 
			        WHERE trvsrvcod = fclTrfSvCod AND 
			              trvtrfcod = fclTrfCod AND 
				     ((przfPeriodoD IS NULL OR (trvFechaFin >= przfPeriodoD OR trvFechaFin IS NULL))) AND
				     (przfPeriodoH IS NULL OR trvFecha <= przfPeriodoH))
where fclFacCod = @codigo 
and fclFacPerCod = @periodo
and fclFacCtrCod = @contrato
and fclFacVersion = @version
AND((fclFecLiq>=@fechaHasta) OR	(fclFecLiq IS NULL AND fclUsrLiq IS NULL))	

order by svcorden, fclNumLinea


END
GO


