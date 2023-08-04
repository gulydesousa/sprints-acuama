--SELECT * FROm ExcelConsultas WHERE ExcDescCorta LIKE '%sit%'

--Excel_Excelconsultas.InformeSituacionTarifa_AVG

SELECT * FROM errorLog order by erlFecha DESC
--dbo.InformeSituacionTrf_AVG
--Excel_Excelconsultas.InformeSituacionTarifa_AVG
--010/001


DECLARE 	@p_errId_out INT 
DECLARE @p_errMsg_out NVARCHAR(MAX)
EXEC [dbo].[Excel_Excelconsultas.InformeSituacionTarifa_AVG] '<NodoXML><LI><FecDesde>01/03/2023</FecDesde><FecHasta>27/03/2023</FecHasta></LI></NodoXML>', @p_errId_out OUT,  @p_errMsg_out OUT


--dbo.InformeSituacionTrf_AVG

EXEC dbo.InformeSituacionTrf_AVG '20230321', '20230322', '000001', '202301', 1, 0, 1, 1

EXEC dbo.InformeSituacionTrf_AVG '20230301', '20230331', '000001', '202301', 1, 0, 1, 1

SELECT * FROm tarifas WHERE LEN(trfdes)>60 


