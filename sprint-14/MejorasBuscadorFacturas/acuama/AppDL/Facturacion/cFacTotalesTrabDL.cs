using BO.Comun;
using BO.Facturacion;
using BO.Resources;
using DL.Comun;
using System;
using System.Data;

namespace DL.Facturacion
{
    public class cFacTotalesTrabDL : dBD
    {
        private DataTable FacturasPK(cBindableList<cFacturaBO> facs)
        {
            DataTable table = new DataTable();
            table.Columns.Add("facCod", typeof(int));
            table.Columns.Add("facPerCod", typeof(string));
            table.Columns.Add("facCtrCod", typeof(int));
            table.Columns.Add("facVersion", typeof(int));

            foreach (cFacturaBO id in facs)
            {
                DataRow row = table.NewRow();
                row["facCod"] = id.FacturaCodigo;
                row["facPerCod"] = id.PeriodoCodigo;
                row["facCtrCod"] = id.ContratoCodigo;
                row["facVersion"] = id.Version;

                table.Rows.Add(row);
            }
            return table;
        }

        public bool Insertar(cBindableList<cFacturaBO> facturas, out cRespuesta respuesta)
        {
            bool resultado = false;

            try
            {
                respuesta = new cRespuesta();
                
                
                string sqlCommand = "dbo.FacTotalesTrab_InsertFacturas";

                dValidator validador = new dValidator();

                dParamsCollection spParams = new dParamsCollection();
                dParameter pFacturas = new dParameter("facturas", SqlDbType.Structured, ParameterDirection.Input);
                pFacturas.Valor = FacturasPK(facturas);
               
                resultado = ExecSPWithParams(sqlCommand, ref spParams);

                if (!resultado)
                {
                    validador.AddCustomMessage(Resource.errorLineasNoInsertadas);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        public bool Borrar(out cRespuesta respuesta)
        {
            bool resultado;
            respuesta = new cRespuesta();
           
            try
            {
                dValidator validador = new dValidator();
                int regAfectados;
                string sqlCommand = "FacTotalesTrab_Delete";
                
                resultado = ExecSP(sqlCommand, out regAfectados);
                if (!resultado)
                {
                    validador.AddCustomMessage(Resource.errorNoBorrarVarios);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
                else if (regAfectados == 0)
                {
                    resultado = false;
                    validador.AddCustomMessage(Resource.errorNoBorrarVarios);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }
    }
}
