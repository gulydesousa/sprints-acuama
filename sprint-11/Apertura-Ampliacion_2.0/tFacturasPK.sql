CREATE TYPE dbo.tFacturasPK AS TABLE(
  facCod	 INT NOT NULL
, facPerCod  VARCHAR(6) NOT NULL
, facCtrCod  INT NOT NULL
, facVersion INT NOT NULL
--CREATE TYPE does not allow naming of contraints
, PRIMARY KEY  (facCod, facPerCod, facCtrCod, facVersion )   
)