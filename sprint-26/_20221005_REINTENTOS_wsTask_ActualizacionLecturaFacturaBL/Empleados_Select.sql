/*
SELECT * 
--UPDATE P SET pgsValor='neoris_gmdesousa@sacyr.com'
FROM  dbo.parametros  AS P WHERE P.pgsclave = 'NOTIFICACIONES_TEST'

DECLARE @codigo smallint = NULL;
DECLARE @contratista smallint = NULL;
DECLARE @lector bit = NULL;
DECLARE @inspector bit = NULL;
DECLARE @docIden varchar(14) = NULL;
DECLARE  @soloConUsuario bit = NULL;

EXEC [dbo].[Empleados_Select]
*/


ALTER PROCEDURE [dbo].[Empleados_Select] 
@codigo smallint = NULL,
@contratista smallint = NULL, --Código de contratista
@lector bit = NULL,
@inspector bit = NULL,
@docIden varchar(14) = NULL,
@soloConUsuario bit = NULL --True: Solo empleados que tengan usuarios, False o NULL: Todos
AS 
SET NOCOUNT ON; 

SELECT eplcod, eplcttcod, eplnom, epldom, eplpob, eplprv, eplnacion, eplcpost, eplnif, epltlf1, epltlf2
, [eplmail] = IIF(LEN(E.eplmail)>0 AND @@SERVERNAME<>'SQLPRO42', P.pgsValor, E.eplmail)
, eplfoto, eplLector, eplInspector
FROM dbo.empleados AS E
LEFT JOIN dbo.parametros  AS P
ON P.pgsclave = 'NOTIFICACIONES_TEST'
WHERE
	(eplcod = @codigo OR @codigo IS NULL) AND
	(eplcttcod = @contratista OR @contratista IS NULL) AND
	(eplLector = @lector OR @lector IS NULL) and
	(eplInspector = @inspector OR @inspector IS NULL) AND
	(eplnif = @docIden OR @docIden IS NULL) AND
	(@soloConUsuario IS NULL OR @soloConUsuario = 0 OR (@soloConUsuario = 1 AND EXISTS(SELECT usrcod FROM usuarios WHERE usreplcttcod=eplcttcod AND usreplcod=eplcod AND (usrFechaBaja IS NULL OR usrFechaBaja>=GETDATE()))))

GO


