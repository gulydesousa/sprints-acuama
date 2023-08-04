using System;
using BO.Facturacion;
using System.Data;
using BO.Comun;
using BO.Resources;
using System.Collections;
using DL.Comun;

namespace DL.Facturacion
{
    public class cFacturaDeudaEstadosDL : dSimpleBD<cFacturaDeudaEstadoBO>
    {
        
        /// <summary>
        /// Obtiene el nombre de la tabla con la que trabajamos
        /// </summary>
        protected override string GetTableName()
        {
            return "facDeudaEstados";
        }

      
        protected override cFacturaDeudaEstadoBO RellenarEntidad(DataRow datos)
        {
            cFacturaDeudaEstadoBO estado = new cFacturaDeudaEstadoBO();

            estado.Codigo = GetDbInt(datos["fdeCod"]);
            estado.Descripcion = GetDbNullableString(datos["fdeDescripcion"]);
            estado.Condicion = GetDbNullableString(datos["fdeCondicion"]);
            estado.ToolTip = GetDbNullableString(datos["fdeToolTip"]);

            return estado;
        }


        public bool Obtener(ref cFacturaDeudaEstadoBO estadoDeuda, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();
            dParamsCollection parametros = new dParamsCollection();

            try
            {
                string sqlCommand = "FacDeudaEstados_Select";

                if(estadoDeuda.Codigo.HasValue)
                    parametros.Add(new dParameter("codigo", SqlDbType.TinyInt, estadoDeuda.Codigo, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    if (datos.Tables[0].Rows.Count > 0)
                    {
                        estadoDeuda = RellenarEntidad(datos.Tables[0].Rows[0]);
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                    {
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
                    }
                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtener);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            finally
            {
                if (datos != null)
                    datos.Dispose();
            }

            return resultado;
        }


        public bool ObtenerTodos(ref cBindableList<cFacturaDeudaEstadoBO> estadosDeuda, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();
            dParamsCollection parametros = new dParamsCollection();

            try
            {
                string sqlCommand = "FacDeudaEstados_Select";

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    respuesta.Resultado = datos.Tables[0].Rows.Count > 0 ? ResultadoProceso.OK : ResultadoProceso.SinRegistros;
                    foreach (DataRow r in datos.Tables[0].Rows)
                    {
                        cFacturaDeudaEstadoBO item = RellenarEntidad(r);
                        estadosDeuda.Add(item);
                    }
                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtener);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            finally
            {
                if (datos != null)
                    datos.Dispose();
            }

            return resultado;
        }



        protected override bool SoloUnRegistro(ParametrosBase parametros, out string registro)
        {
            throw new NotImplementedException();
        }

        protected override dParamsCollection AgregaParametros(ParametrosBase parametros)
        {
            throw new NotImplementedException();
        }
    }
}
