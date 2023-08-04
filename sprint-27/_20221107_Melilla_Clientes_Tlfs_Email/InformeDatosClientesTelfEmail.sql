ALTER PROCEDURE [dbo].[InformeDatosClientesTelfEmail]
	 @clienteD		int			= NULL
	,@clienteH		int			= NULL
	,@zonaD			varchar(4)	= NULL
	,@zonaH			varchar(4)	= NULL
	,@telefonos		BIT			= NULL
	,@emails		BIT			= NULL
	,@veranulados	BIT			= 0	 -- si es 1 veremos tambien los contratos anulados
	,@verusronline	BIT			= 0  -- si es 1 mostrara los datos de la tabla online_Usuarios
	,@sinContrato	BIT			= NULL  -- si tiene valor 1 veremos clientes sin contrato o con todos sus contratos anulados
as
	
	create table #tempResult (	clicod int,clinom varchar(250),clidociden varchar(250),climail varchar(250)
								,clireftelf1 varchar(250),clitelefono1 varchar(250),clireftelf2 varchar(250),clitelefono2 varchar(250),clireftelf3 varchar(250),clitelefono3 varchar(250)
								,ctrcod int,ctrversion  smallint,ctrTitCod  int,ctrTitNom  varchar(250),ctrTitDocIden varchar(250),ctrEmail varchar(250)
								,ctrFaceMail varchar(250),ctrTlfRef1  varchar(250),ctrTlf1  varchar(250),ctrTlfRef2  varchar(250),ctrTlf2 varchar(250),ctrTlfRef3 varchar(250),ctrTlf3 varchar(250)
								,ctrfecanu datetime ,zoncod varchar(4),zondes varchar(250)
								,usrLogin varchar(250),usrNombre varchar(250),usrTfno1 varchar(250),usrTfno2 varchar(250),usrEMail varchar(250),veronline bit
							 )

	DECLARE @sql				as varchar(max)	= '',
			@where				as varchar(max)	= '',
			@whereCli			as varchar(max)	= '',
			@whereCtr			as varchar(max)	= '',
			@leftOnline			as varchar(max)	= '',
			@veronline			as varchar(max)	= '',
			@innerJoinContratos	bit				= 0;

	if @verusronline= 1
		
		begin
		
			set @veronline = '
			,usrLogin
			,usrNombre
			,REPLACE(LTRIM(RTRIM(usrTfno1)),'' '','''') usrTfno1
			,REPLACE(LTRIM(RTRIM(usrTfno2)),'' '','''') usrTfno2
			,LTRIM(RTRIM(usrEMail))						usrEMail
			,1											veronline'

			set @leftOnline= 'left join online_Usuarios on usrLogin = clidociden'
		end

	else
		set @veronline = '
			,null usrLogin
			,null usrNombre
			,null usrTfno1
			,null usrTfno2
			,null usrEMail
			,0	  veronline'		

	if @veranulados = 0 or @sinContrato = 1
		set @whereCtr+= dbo.SetJoinDinamically('ctrfecanu',null,null,null,1,null)

	
	SET @where = CASE WHEN @sinContrato IS NULL 
					  THEN ''
					  WHEN @sinContrato = 1	
					  THEN 'WHERE ctrcod IS NULL'
					  ELSE 'WHERE ctrcod IS NOT NULL' 
				 END;
	
	IF (@sinContrato = 0)
	BEGIN
					
		if @zonaD is not null set @whereCtr+= dbo.SetJoinDinamically('ctrzoncod','>=',@zonaD,null,null,null)
		if @zonaH is not null set @whereCtr+= dbo.SetJoinDinamically('ctrzoncod','<=',@zonaH,null,null,null)
		if @zonaD is not null or @zonaH is not null set @innerJoinContratos = 1
		
	END
	
	if @emails is not null
		set @whereCli+= dbo.SetJoinDinamically('climail',null,null,null,iif(@emails=0,1,0),null)

	if @clienteD is not null set @whereCli+= dbo.SetJoinDinamically('clicod','>=',null,null,@clienteD,null)
	if @clienteH is not null set @whereCli+= dbo.SetJoinDinamically('clicod','<=',null,null,@clienteH,null)
	
	if @telefonos is not null
		
		begin
			
			if @telefonos = 1
				set @whereCli+= char(10) + 'AND (clitelefono1 is not null or clitelefono2 is not null or clitelefono3 is not null)'
			else
				set @whereCli+= char(10) + 'AND clitelefono1 is null AND clitelefono2 is null AND clitelefono3 is null'
		end
		
	
	if @whereCtr <> ''
		set @whereCtr = dbo.SetWhereDinamically(@whereCtr,default);

	if @whereCli <> ''
		set @whereCli = dbo.SetWhereDinamically(@whereCli,default);

					
	set @sql='
	with cte1
	as (
		select	clicod
				,clinom
				,clidociden		
				,LTRIM(RTRIM(climail))	climail
				,clireftelf1,REPLACE(LTRIM(RTRIM(clitelefono1)),'' '','''') clitelefono1
				,clireftelf2,REPLACE(LTRIM(RTRIM(clitelefono2)),'' '','''') clitelefono2
				,clireftelf3,REPLACE(LTRIM(RTRIM(clitelefono3)),'' '','''') clitelefono3
				-----------------------------------------------------------------------------------
		from clientes {@whereCli}
	),
	cte2
	as (
		select	 ctrcod
				,ctrversion
				,ctrTitCod
				,ctrTitNom
				,ctrTitDocIden				
				,LTRIM(RTRIM(ctrEmail))									ctrEmail
				,LTRIM(RTRIM(ctrFaceMail))								ctrFaceMail
				,ctrTlfRef1,REPLACE(LTRIM(RTRIM(ctrTlf1)),'' '','''')	ctrTlf1 
				,ctrTlfRef2,REPLACE(LTRIM(RTRIM(ctrTlf2)),'' '','''')	ctrTlf2 
				,ctrTlfRef3,REPLACE(LTRIM(RTRIM(ctrTlf3)),'' '','''')	ctrTlf3
				-----------------------------------------------------------------------------------
				,ctrfecanu
				,zoncod
				,coalesce(zondes,''sin zona'') zondes
		from contratos		
		inner join zonas on zoncod = ctrzoncod {@whereCtr}
	),
	cte3
	as (
		select   clicod,clinom
				,clidociden	,climail
				,clireftelf1,clitelefono1,clireftelf2,clitelefono2,clireftelf3,clitelefono3
				-----------------------------------------------------------------------------------
				,ctrcod,ctrversion
				,ctrTitCod,ctrTitNom,ctrTitDocIden			
				,ctrEmail,ctrFaceMail
				,ctrTlfRef1,ctrTlf1,ctrTlfRef2,ctrTlf2,ctrTlfRef3,ctrTlf3
				-----------------------------------------------------------------------------------
				,ctrfecanu,zoncod,zondes
				{veronline}
		from cte1
		{join} join cte2 on ctrTitCod = clicod		
		{leftOnline}
		{where}
	)
	
	select * from cte3'

	set @sql= replace(@sql,'{veronline}',@veronline)
	set @sql= replace(@sql,'{leftOnline}',@leftOnline)
	set @sql= replace(@sql,'{@whereCli}',@whereCli)
	set @sql= replace(@sql,'{@whereCtr}',@whereCtr)
	set @sql= replace(@sql,'{join}',iif(@innerJoinContratos=1,'inner','left'))
	set @sql= replace(@sql,'{where}',@where)

	print @sql

	insert into #tempResult
	exec (@sql)

	select	clicod,clinom,clidociden,climail
			,clireftelf1,clitelefono1,clireftelf2,clitelefono2,clireftelf3,clitelefono3
			,ctrcod,ctrversion,ctrTitCod,ctrTitNom,ctrTitDocIden,ctrEmail,ctrFaceMail
			,ctrTlfRef1,ctrTlf1,ctrTlfRef2,ctrTlf2,ctrTlfRef3,ctrTlf3	
			,ctrfecanu,zoncod,zondes
			,usrLogin,usrNombre,usrTfno1,usrTfno2,usrEMail,veronline
	from #tempResult
	order by clicod,zoncod,ctrcod,ctrversion

	drop table #tempResult

/*

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=1

exec InformeDatosClientesTelfEmail @veranulados=1,@verusronline=1

exec InformeDatosClientesTelfEmail @clienteD=1,@clienteH=6,@veranulados=0

exec InformeDatosClientesTelfEmail @clienteD=1,@clienteH=6,@veranulados=1

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0,@telefonos=1

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0,@telefonos=0

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0,@emails=1

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0,@emails=0

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0,@clienteD=60

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0,@clienteH=60

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0,@clienteD=60,@clienteH=600

exec InformeDatosClientesTelfEmail @veranulados=1,@verusronline=0,@clienteD=1,@clienteH=6,@telefonos=null,@emails=null

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=0, @zonaD=1,@zonaH=1

exec InformeDatosClientesTelfEmail @veranulados=0,@verusronline=1, @zonaD=3,@zonaH=5

exec InformeDatosClientesTelfEmail @clienteD=1,@clienteH=6,@veranulados=0

exec InformeDatosClientesTelfEmail @clienteD=1,@clienteH=6,@veranulados=0,@zonaD=1,@zonaH=1

exec InformeDatosClientesTelfEmail @clienteD=1,@clienteH=6,@veranulados=0,@zonaD=1,@zonaH=1,@sinContrato=1

drop index idx_contratos_telfEmail on contratos

CREATE NONCLUSTERED INDEX idx_contratos_telfEmail
ON [dbo].[contratos] ([ctrfecanu],[ctrzoncod])
INCLUDE ([ctrcod],[ctrversion],[ctrTitCod],[ctrTitDocIden],[ctrTitNom],[ctrTlf1],[ctrTlfRef1],[ctrTlf2],[ctrTlfRef2],[ctrTlf3],[ctrTlfRef3],[ctrEmail],[ctrFaceMail])

CREATE NONCLUSTERED INDEX idx_clientes_telfEmail
ON [dbo].[clientes] ([climail])
INCLUDE ([clicod],[clinom],[clidociden],[clitelefono1],[clireftelf1],[clitelefono2],[clireftelf2],[clitelefono3],[clireftelf3])
*/
GO


