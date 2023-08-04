--SELECT * FROM parametros AS P  WHERE pgsclave='NOTIFICACIONES_TEST'
--SELECT * FROM vEmailNotificaciones

ALTER VIEW dbo.vEmailNotificaciones
AS

WITH CTR AS(
SELECT C.ctrcod
, C.ctrVersion
, C.ctrtitCod
, C.ctrTitDocIden
, C.ctrPagDocIden
, C.ctrEmail
, CC.climail
, ovTitularMail = OT.usrEMail
, ovPagadorMail = OP.usrEMail
, emailName = CASE WHEN C.ctrEmail  IS NOT NULL THEN C.ctrTitNom
				 WHEN CC.climail  IS NOT NULL THEN CC.cliNom
				 WHEN OT.usrEMail IS NOT NULL THEN OT.usrNombre
				 WHEN OP.usrEMail IS NOT NULL THEN OT.usrNombre
				 ELSE '' END
, emailTo   =  COALESCE(C.ctrEmail, CC.climail, OT.usrEMail, OP.usrEMail, '')
, emailTest =  ISNULL(P.pgsvalor, '')
--**************************
--RN=1: Ultima version del contrato
, RN= ROW_NUMBER() OVER (PARTITION BY ctrcod ORDER BY ctrversion DESC) 
, Ruta = FORMATMESSAGE('%010s.%010s.%010s.%010s.%010s.%010s', ISNULL(ctrRuta1, '0'), ISNULL(ctrRuta2, 0), ISNULL(ctrRuta3, '0'), ISNULL(ctrRuta4, '0'), ISNULL(ctrRuta5, 0), ISNULL(ctrRuta6, '0'))
--**************************
FROM dbo.contratos AS C 
LEFT JOIN dbo.clientes AS CC
ON C.ctrtitCod = CC.clicod
LEFT JOIN online_Usuarios AS OT
ON OT.usrLogin=C.ctrTitDocIden
LEFT JOIN online_Usuarios AS OP
ON OP.usrLogin=C.ctrPagDocIden
LEFT JOIN dbo.parametros AS P
ON P.pgsclave = 'NOTIFICACIONES_TEST' AND (P.pgsvalor IS NULL OR P.pgsvalor <>'')
)

SELECT [contrato.ctrCod]	= ctrcod
, [contrato.ctrVersion]		= ctrVersion
, [contrato.ctrtitCod]		= ctrtitCod
, [contrato.ctrTitDocIden]	= ctrTitDocIden
, [contrato.ctrPagDocIden]	= ctrPagDocIden
, [contrato.ctrEmail]		= ctrEmail
, [contrato.ctrRuta]		= Ruta
, [cliente.climail]			= climail
, ovTitularMail
, ovPagadorMail 
, emailName
--Cambiamos el mail para evitar que en otros entornos de mande el correo
, [emailTo]		= IIF(LEN(emailTo)>0 AND (LEN(emailTest)>0 OR @@SERVERNAME<>'SQLPRO42')  , emailTest, emailTo)
, [emailTo*]	= emailTo 
FROM CTR;

GO