--FAC_APERTURA centraliza todo dejando otros parametros obsoletos 
DELETE FROM parametros WHERE pgsclave='FAC.APERTURA';
DELETE FROM parametros WHERE pgsclave='FACTOTALES';
DELETE FROM parametros WHERE pgsclave='OBTENER_CABECERA';
DELETE FROM parametros WHERE pgsclave='FAC_APERTURA';


DROP TABLE facDeudaEstados;
DROP TABLE facTotalesTrab;
DROP TABLE dbo.facTotales;


DROP PROCEDURE FacDeudaEstados_Select;

DROP PROCEDURE FacTotales_Select;
DROP PROCEDURE FacTotales_SelectPorFiltro;
DROP PROCEDURE FacTotales_Update
DROP PROCEDURE FacTotales_Delete


DROP PROCEDURE FacTotalesTrab_Delete
DROP PROCEDURE FacTotalesTrab_DeleteFacturas
DROP PROCEDURE FacTotalesTrab_Insert
DROP PROCEDURE FacTotalesTrab_InsertFacturas


DROP PROCEDURE Trabajo.Parametros_ERRORLOG;
DROP PROCEDURE Trabajo.Parametros_FACAPERTURA;
DROP PROCEDURE Trabajo.Parametros_FAC_APERTURA;
DROP PROCEDURE Trabajo.Parametros_FACTOTALES;

DROP TRIGGER trgFacturas_FacTotalesInsert
DROP TRIGGER trgFacturas_FacTotalesDelete
DROP TRIGGER trgFacLin_FacTotalesUpdate
DROP TRIGGER trgCoblin_FacTotalesUpdate
DROP TRIGGER trgFacTotalesTrab_FacTotalesUpdate
GO

DISABLE TRIGGER facturas_DeleteInstead ON facturas;
DISABLE TRIGGER faclin_DeleteInstead ON faclin;
DISABLE TRIGGER faclin_UpdateInstead ON faclin;

TRUNCATE TABLE ErrorLog;
