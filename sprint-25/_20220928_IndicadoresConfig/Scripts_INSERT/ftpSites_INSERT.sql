SELECT * FROM ftpSites

--ALTER TABLE ftpSites NOCHECK CONSTRAINT ALL
--ALTER TABLE ExcelConsultas NOCHECK CONSTRAINT ALL
--DELETE ftpSites WHERE ftpName='IDbox'
--ALTER TABLE ftpSites CHECK CONSTRAINT ALL
--ALTER TABLE ExcelConsultas CHECK CONSTRAINT ALL

--Protocolo: FTP
--INSERT INTO ftpSites VALUES('IDbox', '62.37.231.5', '21', 'sacyftp', 'QPZwANJgGBepeEvUTr0hcw==', 'Indicadores/', 1, 1, NULL)

--Protocolo: SFTP 
--lLjyMhcv#SoH5LmO7Ai1zc8$SsyfCPO4
--sftp://f1.sacyr.com:999
--cic
INSERT INTO ftpSites VALUES('IDbox', 'f1.sacyr.com', '999', 'cic', 'rJyGpCDhLO/046j1ImCoIGcP6Qz290BZBxWX1iDc66prU6Repp7kxjUi9vyD0efQ', 'IDbox/', 0, 2, NULL)


