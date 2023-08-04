
ALTER TABLE dbo.efectosPendientes
ALTER COLUMN efePdteTitCCC VARCHAR(40) NULL;

ALTER TABLE dbo.efectosPendientes
ALTER COLUMN efePdteDocIdenCCC VARCHAR(12) NULL;

ALTER TABLE dbo.efectosPendientes
ALTER COLUMN efePdteDirCta VARCHAR(200) NULL;

ALTER TABLE dbo.efectosPendientes 
ADD efePdteDomiciliado BIT NOT NULL
CONSTRAINT efePdteDomiciliado_Default DEFAULT(1);  

/*
ALTER TABLE dbo.efectosPendientes
ADD efePdteFecVencimiento DATETIME NULL;

*/

/*
ALTER TABLE dbo.efectosPendientes
ADD efePdteRegMarcado BIT NOT NULL
CONSTRAINT efePdteRegMarcado_Default DEFAULT(0); 

ALTER TABLE  dbo.efectosPendientes DROP CONSTRAINT efePdteRegMarcado_Default
ALTER TABLE  dbo.efectosPendientes DROP COLUMN efePdteRegMarcado;
*/

/*
ALTER TABLE dbo.efectosPendientes
ADD efePdteAutorizado INT NULL;

ALTER TABLE dbo.efectosPendientes
ADD CONSTRAINT efectosPendienteAutorizados_FK FOREIGN KEY(efePdteAutorizado) REFERENCES dbo.efectosPendienteAutorizados (epaCod);
*/

/*
ALTER TABLE dbo.efectosPendientes
ADD efePdteAutorizadoRol VARCHAR(5) NULL;

ALTER TABLE dbo.efectosPendientes
ADD CONSTRAINT efePdteAutorizadoRoles_FK FOREIGN KEY(efePdteAutorizadoRol) REFERENCES dbo.efectosPendientesAutorizadosRoles (epaRolCod);

*/

/*
ALTER TABLE dbo.efectosPendientes
ADD CONSTRAINT efePdteDomiciliado_Default
DEFAULT 1 FOR efePdteDomiciliado WITH VALUES;  
*/
