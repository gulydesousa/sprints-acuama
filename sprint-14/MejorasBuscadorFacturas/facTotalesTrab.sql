CREATE TABLE dbo.facTotalesTrab (
  fcttCod INT NOT NULL
, fcttCtrCod INT NOT NULL
, fcttPerCod VARCHAR(6) NOT NULL
, fcttVersion INT NOT NULL

, CONSTRAINT  PK_facTotalesTrab PRIMARY KEY(fcttCod, fcttCtrCod, fcttPerCod, fcttVersion))