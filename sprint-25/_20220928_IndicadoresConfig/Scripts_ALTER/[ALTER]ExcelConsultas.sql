--SELECT * FROM ExcelConsultas
--ALTER TABLE ExcelConsultas DROP COLUMN ExcGestorDocumental;

--ALTER TABLE ExcelConsultas
--ADD ExcLogo VARCHAR(150) NULL;

ALTER TABLE ExcelConsultas
ADD ExcEnvioEmail BIT NULL;

ALTER TABLE ExcelConsultas
ADD ExcFtpSite VARCHAR(100);

ALTER TABLE ExcelConsultas
ADD ExcFtpActivo BIT ;


ALTER TABLE ExcelConsultas
ADD CONSTRAINT FK_ExcelConsultas_FtpSites FOREIGN KEY(ExcFtpSite)
REFERENCES ftpSites(ftpName);


