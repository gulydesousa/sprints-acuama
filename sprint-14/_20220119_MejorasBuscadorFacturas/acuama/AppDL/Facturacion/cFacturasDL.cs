using BO.Almacen;
using BO.Catastro;
using BO.Comun;
using BO.Facturacion;
using BO.Resources;
using BO.Sistema;
using BO.Tasks;
using DL.Comun;
using System;
using System.Collections;
using System.Data;

namespace DL.Facturacion
{
    public class cFacturasDL : dBD
    {
        public enum TipoDeuda
        {
              Cobrada = 0
            , PendienteCobro = 1
            , SobreCobrada = -1
        }

        /// <summary>
        /// Obtiene todos los registros
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerTodos(ref cBindableList<cFacturaBO> facturas, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;

            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_Select";

                resultado = ExecSP(storedProcedure, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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

        /// <summary>
        /// Obtiene todos los registros por la selecion elegida
        /// </summary>
        /// <param name="seleccion">Objeto Selección que contiene los parámetros de selección</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>facturas</returns>
        public cBindableList<cFacturaBO> Obtener(cFacturasSeleccionBO seleccion, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            DataSet datos = null;

            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, seleccion.Zona, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, seleccion.Periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("soloCnsComunitarioMayorAlFinal", SqlDbType.Bit, seleccion.SoloCnsComunitarioMayorAlFinal, ParameterDirection.Input));

                if (ExecSPWithParams(storedProcedure, ref parametros, out datos))
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            finally
            {
                if (datos != null)
                    datos.Dispose();
            }

            return facturas;
        }

        /// <summary>
        /// Obtiene las últimas versiones de las facturas
        /// </summary>
        /// <param name="contratoCodigo">(opcional) Código del contrato</param>
        /// <param name="versionContratoHasta">Máxima versión del contrato</param>
        /// <param name="numRegistros">(opcional) Max. número de registros a obtener</param>
        /// <param name="periodoCodigo">(opcional) Código del periodo</param>
        /// <returns>Lista de facturas</returns>
        public cBindableList<cFacturaBO> ObtenerUltimasVersiones(short? facturaCodigo, string periodoCodigo, int? contratoCodigo, short? versionContratoHasta, int? numRegistros, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();

            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, facturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("versionContratoHasta", SqlDbType.SmallInt, versionContratoHasta, ParameterDirection.Input));
                parametros.Add(new dParameter("numRegistros", SqlDbType.Int, numRegistros, ParameterDirection.Input));
                parametros.Add(new dParameter("ultimaVersion", SqlDbType.Bit, true, ParameterDirection.Input));

                resultado = ExecSPWithParams(storedProcedure, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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

            return facturas;
        }

        /// <summary>
        /// Obtiene facturas por cliente y contrato
        /// </summary>
        /// <param name="contratoCodigo">Código del contrato (opcional)</param>
        /// <param name="docIdenCliente">Documento de Identidad del cliente (opcional)</param>
        /// <param name="ultimaVersion">True = Obtiene últimas versiones de la factura, Flase todas (opcional)</param>
        /// <param name="versionContratoHasta">Máxima versión del contrato (opcional)</param>
        /// <param name="fechaOnline">Si se establece este parámetro, sólo se obtendrán las facturas que deban ser visibles en la oficina online para esta fecha</param>
        /// <returns>Lista de facturas</returns>
        public cBindableList<cFacturaBO> ObtenerPorContratoYCliente(int? contratoCodigo, short? versionContratoHasta, string docIdenCliente, bool? ultimaVersion, DateTime? fechaOnline, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();

            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_SelectPorContratoYCliente";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("versionContratoHasta", SqlDbType.SmallInt, versionContratoHasta, ParameterDirection.Input));
                parametros.Add(new dParameter("docIdenCliente", 10, SqlDbType.VarChar, docIdenCliente, ParameterDirection.Input));
                parametros.Add(new dParameter("ultimaVersion", SqlDbType.Bit, ultimaVersion, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaOnline", SqlDbType.DateTime, fechaOnline, ParameterDirection.Input));

                resultado = ExecSPWithParams(storedProcedure, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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

            return facturas;
        }

        /// <summary>
        /// Genera las líneas del desglose de la factura indicada
        /// </summary>
        /// <param name="codigo">Código de la factura</param>
        /// <param name="periodoCodigo">Código del periodo de la factura</param>
        /// <param name="contratoCodigo">Código del contrato del periodo</param>
        /// <param name="version">Versión de la factura</param>
        /// <returns>Objeto respuesta</returns>
        public cRespuesta GenerarDesgloseDeLineasFactura(short codigo, string periodoCodigo, int contratoCodigo, short version)
        {
            cRespuesta respuesta = new cRespuesta();
            try
            {
                dParamsCollection dbParams = new dParamsCollection();
                dbParams.Add(new dParameter("codigoFactura", SqlDbType.SmallInt, codigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("contrato", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("versionFactura", SqlDbType.SmallInt, version, ParameterDirection.Input));

                if (!ExecSPWithParams("Tasks_Facturas_GenerarDesgloseLineas", ref dbParams))
                    cExcepciones.ControlarER(new Exception(Resource.errorProducidoError), TipoExcepcion.Informacion, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta;
        }

        /// <summary>
        /// Realiza el desglose de líneas de facturas
        /// </summary>
        public cRespuesta GenerarDesgloseDeLineasFacturas(string zona, string periodo, bool generarRectifSiPerZonaCerrado, short? sociedadRectificativa, short? serieRectificativa, string usuarioCodigo, string taskUser, ETaskType? taskType, int? taskNumber, out int lineasDesglosadas, out int lineasGeneradas)
        {
            cRespuesta respuesta = new cRespuesta();

            lineasDesglosadas = lineasGeneradas = 0;

            dParamsCollection parametros = new dParamsCollection();
            parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
            parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));

            parametros.Add(new dParameter("generarRectificativaSiPerZonaCerrado", SqlDbType.Bit, generarRectifSiPerZonaCerrado, ParameterDirection.Input));
            parametros.Add(new dParameter("sociedadRectificativa", SqlDbType.SmallInt, sociedadRectificativa, ParameterDirection.Input));
            parametros.Add(new dParameter("serieRectificativa", SqlDbType.SmallInt, serieRectificativa, ParameterDirection.Input));
            parametros.Add(new dParameter("usuarioCodigo", 10, SqlDbType.VarChar, usuarioCodigo, ParameterDirection.Input));

            parametros.Add(new dParameter("tskUser", 10, SqlDbType.VarChar, taskUser, ParameterDirection.Input));
            parametros.Add(new dParameter("tskType", SqlDbType.SmallInt, taskType, ParameterDirection.Input));
            parametros.Add(new dParameter("tskNumber", SqlDbType.Int, taskNumber, ParameterDirection.Input));

            parametros.Add(new dParameter("lineasDesglosadas", SqlDbType.Int, ParameterDirection.Output));
            parametros.Add(new dParameter("lineasGeneradas", SqlDbType.Int, ParameterDirection.Output));

            if (ExecSPWithParams("Tasks_Facturas_GenerarDesgloseLineas", ref parametros))
            {
                lineasDesglosadas = Convert.ToInt32(parametros.Get("lineasDesglosadas").Valor);
                lineasGeneradas = Convert.ToInt32(parametros.Get("lineasGeneradas").Valor);
            }
            else
                respuesta.Resultado = ResultadoProceso.Error;

            return respuesta;
        }

        /// <summary>
        /// Aplicación de diferidos en una factura concreta (rectificativas de Canal)
        /// </summary>
        /// <param name="factura">Factura rectificativa en la que queremos aplicar diferidos</param>
        /// <param name="diferidosAplicados">Nº de diferidos que se han aplicado a la factura</param>
        /// <param name="respuesta"></param>
        /// <returns></returns>
        public bool AplicacionDiferidosEnRectificativa(cFacturaBO factura, out int diferidosAplicados, out cRespuesta respuesta)
        {
            bool resultado = false;
            diferidosAplicados = 0;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            string sqlCommand = "Diferidos_Agrupados_Aplicar_Rectif";

            dParamsCollection parametros = new dParamsCollection();
            parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, factura.ZonaCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("difPeriodoAplicacion", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("facCod", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("facVersion", SqlDbType.SmallInt, factura.Version, ParameterDirection.Input));
            parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("numRegistros", SqlDbType.Int, ParameterDirection.Output));
            resultado = ExecSPWithParams(sqlCommand, ref parametros);
            if (resultado)
            {
                diferidosAplicados = Convert.ToInt32(parametros.Get("numRegistros").Valor);
                respuesta.Resultado = ResultadoProceso.OK;
            }
            else
                respuesta.Resultado = ResultadoProceso.Error;

            return resultado;
        }

        public bool CierreAgrupandoDiferidos(cFacturaBO factura, out string log, out cRespuesta respuesta)
        {
            bool resultado = false;
            log = string.Empty;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            string sqlCommand = "Facturas_Cierre_Diferidos";

            dParamsCollection parametros = new dParamsCollection();
            parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("contrato", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("versionFactura", SqlDbType.SmallInt, factura.Version, ParameterDirection.Input));
            parametros.Add(new dParameter("Log", 4000, SqlDbType.VarChar, ParameterDirection.Output));
            resultado = ExecSPWithParams(sqlCommand, ref parametros);
            if (resultado)
            {
                log = GetDbNullableString(parametros.Get("Log").Valor);
                respuesta.Resultado = ResultadoProceso.OK;
            }
            else
                respuesta.Resultado = ResultadoProceso.Error;

            return resultado;
        }

        /// <summary>
        /// Realiza el campo del impuesto de las facturas según la fecha pasada por parámetro (null = ahora)
        /// </summary>
        public cRespuesta CambioImpuesto(string zona, string periodo, DateTime? fecha, bool incluirFacturasCerradas, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasInsertadas)
        {
            cRespuesta respuesta = new cRespuesta();
            facturasInsertadas = 0;

            dParamsCollection parametros = new dParamsCollection();
            parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
            parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
            parametros.Add(new dParameter("fecha", SqlDbType.DateTime, fecha, ParameterDirection.Input));
            parametros.Add(new dParameter("incluirFacturasCerradas", SqlDbType.Bit, incluirFacturasCerradas, ParameterDirection.Input));
            parametros.Add(new dParameter("tskUser", 10, SqlDbType.VarChar, taskUser, ParameterDirection.Input));
            parametros.Add(new dParameter("tskType", SqlDbType.SmallInt, taskType, ParameterDirection.Input));
            parametros.Add(new dParameter("tskNumber", SqlDbType.Int, taskNumber, ParameterDirection.Input));
            parametros.Add(new dParameter("facturasModificadas", SqlDbType.Int, ParameterDirection.Output));

            if (ExecSPWithParams("Tasks_Facturas_CambioImpuesto", ref parametros))
                facturasInsertadas = Convert.ToInt32(parametros.Get("facturasModificadas").Valor);
            else
                respuesta.Resultado = ResultadoProceso.Error;

            return respuesta;
        }

        /// <summary>
        /// Realiza el proceso de asignación de consumos
        /// </summary>
        public cRespuesta AsignarConsumos(string zonaD, string zonaH, DateTime fechaLecturaFactura, int orden1, int? orden2, int? orden3, int? orden4, int? cnsValorDefinido, int? rutaAgrupada, int? loteD, int? loteH, string ruta1, string ruta2, string ruta3, string ruta4, string ruta5, string ruta6, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasAfectadas)
        {
            facturasAfectadas = 0;
            cRespuesta respuesta = new cRespuesta();
            dParamsCollection parametros = new dParamsCollection();

            parametros.Add(new dParameter("zonaD", 4, SqlDbType.VarChar, zonaD, ParameterDirection.Input));
            parametros.Add(new dParameter("zonaH", 4, SqlDbType.VarChar, zonaH, ParameterDirection.Input));
            parametros.Add(new dParameter("fechaLecturaFactura", SqlDbType.DateTime, fechaLecturaFactura, ParameterDirection.Input));

            parametros.Add(new dParameter("orden1", SqlDbType.Int, orden1, ParameterDirection.Input));
            parametros.Add(new dParameter("orden2", SqlDbType.Int, orden2, ParameterDirection.Input));
            parametros.Add(new dParameter("orden3", SqlDbType.Int, orden3, ParameterDirection.Input));
            parametros.Add(new dParameter("orden4", SqlDbType.Int, orden4, ParameterDirection.Input));

            parametros.Add(new dParameter("CnsValorDefinido", SqlDbType.Int, cnsValorDefinido, ParameterDirection.Input));
            parametros.Add(new dParameter("rutaAgrupada", SqlDbType.Int, rutaAgrupada, ParameterDirection.Input));

            parametros.Add(new dParameter("facturasAfectadas", SqlDbType.Int, ParameterDirection.Output));

            parametros.Add(new dParameter("loteD", SqlDbType.Int, loteD, ParameterDirection.Input));
            parametros.Add(new dParameter("loteH", SqlDbType.Int, loteH, ParameterDirection.Input));

            parametros.Add(new dParameter("ruta1", 10, SqlDbType.VarChar, ruta1, ParameterDirection.Input));
            parametros.Add(new dParameter("ruta2", 10, SqlDbType.VarChar, ruta2, ParameterDirection.Input));
            parametros.Add(new dParameter("ruta3", 10, SqlDbType.VarChar, ruta3, ParameterDirection.Input));
            parametros.Add(new dParameter("ruta4", 10, SqlDbType.VarChar, ruta4, ParameterDirection.Input));
            parametros.Add(new dParameter("ruta5", 10, SqlDbType.VarChar, ruta5, ParameterDirection.Input));
            parametros.Add(new dParameter("ruta6", 10, SqlDbType.VarChar, ruta6, ParameterDirection.Input));

            parametros.Add(new dParameter("tskUser", 10, SqlDbType.VarChar, taskUser, ParameterDirection.Input));
            parametros.Add(new dParameter("tskType", SqlDbType.SmallInt, taskType, ParameterDirection.Input));
            parametros.Add(new dParameter("tskNumber", SqlDbType.Int, taskNumber, ParameterDirection.Input));

            if (ExecSPWithParams("Tasks_Facturas_AsignarConsumos", ref parametros))
                facturasAfectadas = Convert.ToInt32(parametros.Get("facturasAfectadas").Valor);

            return respuesta;
        }

        /// <summary>
        /// Obtiene un registro
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool Obtener(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                //En la aplicación puede haber sitios que llamen a este método sin pasar alguna propiedad (el código, por ejemplo), en ese caso no podemos ejecutar "SelectPorPK" porque no devolvería factura alguna
                string sqlCommand = factura.FacturaCodigo.HasValue && !String.IsNullOrEmpty(factura.PeriodoCodigo) && factura.ContratoCodigo.HasValue && factura.Version.HasValue ? "Facturas_SelectPorPK" : "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("versionFactura", SqlDbType.SmallInt, factura.Version, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    if (datos.Tables[0].Rows.Count > 0)
                    {
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        /// <summary>
        /// Obtiene un registro de la tabla Facturas con ultima versión
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerUltimaVersion(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                string sqlCommand = "Facturas_SelectUltimaVersion";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    if (datos.Tables[0].Rows.Count > 0)
                    {
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
        /// <summary>
        /// Obtiene un registro de la tabla Facturas con ultima versión
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerUltimaVersionSOA(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                string sqlCommand = "Facturas_SelectUltimaVersionSOA";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codExplo", SqlDbType.VarChar, factura.CodExplo, ParameterDirection.Input));
                parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    if (datos.Tables[0].Rows.Count > 0)
                    {
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        /// <summary>
        /// Obtiene las inspecciones que se encuentran pendientes de inspeccionar
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerInspeccionables(ref cBindableList<cFacturaBO> facturas, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_Select";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("soloInspeccionables", SqlDbType.Bit, true, ParameterDirection.Input));

                resultado = ExecSPWithParams(storedProcedure, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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

        /// <summary>
        /// Obtiene las lecturas pendientes
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerPendientesDeLeer(ref cBindableList<cFacturaBO> facturas, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_Select";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("soloPendientesLeer", SqlDbType.Bit, true, ParameterDirection.Input));

                resultado = ExecSPWithParams(storedProcedure, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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

        /// <summary>
        /// Inserta un nuevo registro
        /// </summary>
        /// <param name="factura">objeto a insertar</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool Insertar(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                string sqlCommand = "facturas_insert";

                dValidator validador = new dValidator();

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("facCod", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facCtrVersion", SqlDbType.SmallInt, factura.ContratoVersion, ParameterDirection.Input));
                parametros.Add(new dParameter("facSerScdCod", SqlDbType.SmallInt, factura.SociedadCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facSerCod", SqlDbType.SmallInt, factura.SerieCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facFecha", SqlDbType.DateTime, factura.Fecha, ParameterDirection.Input));
                parametros.Add(new dParameter("facClicod", SqlDbType.Int, factura.ClienteCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facSerieRectif", SqlDbType.SmallInt, factura.SerieRectificativa, ParameterDirection.Input));
                parametros.Add(new dParameter("facNumeroRectif", 20, SqlDbType.VarChar, factura.NumeroRectificativa, ParameterDirection.Input));
                parametros.Add(new dParameter("facFechaRectif", SqlDbType.DateTime, factura.FechaFactRectificativa, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAnt", SqlDbType.Int, factura.LecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAntFec", SqlDbType.DateTime, factura.FechaLecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecLector", SqlDbType.Int, factura.LecturaLector, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecLectorFec", SqlDbType.DateTime, factura.FechaLecturaLector, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecInlCod", 2, SqlDbType.VarChar, factura.LectorIncidenciaLectura, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecInspector", SqlDbType.Int, factura.LecturaInspector, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecInspectorFec", SqlDbType.DateTime, factura.FechaLecturaInspector, ParameterDirection.Input));
                parametros.Add(new dParameter("facInsInlCod", 2, SqlDbType.VarChar, factura.InspectorIncidenciaLectura, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAct", SqlDbType.Int, factura.LecturaFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecActFec", SqlDbType.DateTime, factura.FechaLecturaFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("facConsumoReal", SqlDbType.Int, factura.ConsumoReal, ParameterDirection.Input));
                parametros.Add(new dParameter("facConsumoFactura", SqlDbType.Int, factura.ConsumoFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("facCnsFinal", SqlDbType.Int, factura.ConsumoFinal, ParameterDirection.Input));
                parametros.Add(new dParameter("facCnsComunitario", SqlDbType.Int, factura.ConsumoComunitario, ParameterDirection.Input));
                parametros.Add(new dParameter("facLote", SqlDbType.Int, factura.Lote, ParameterDirection.Input));
                parametros.Add(new dParameter("facLectorEplCod", SqlDbType.SmallInt, factura.LectorCodigoEmpleado, ParameterDirection.Input));
                parametros.Add(new dParameter("facLectorCttCod", SqlDbType.SmallInt, factura.LectorCodigoContratista, ParameterDirection.Input));
                parametros.Add(new dParameter("facInspectorEplCod", SqlDbType.SmallInt, factura.InspectorCodigoEmpleado, ParameterDirection.Input));
                parametros.Add(new dParameter("facInspectorCttCod", SqlDbType.SmallInt, factura.InspectorCodigoContratista, ParameterDirection.Input));
                parametros.Add(new dParameter("facNumeroRemesa", SqlDbType.Int, factura.NumeroRemesa, ParameterDirection.Input));
                parametros.Add(new dParameter("facFechaRemesa", SqlDbType.DateTime, factura.FechaRemesa, ParameterDirection.Input));
                parametros.Add(new dParameter("facZonCod", 4, SqlDbType.VarChar, factura.ZonaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facInspeccion", SqlDbType.Int, factura.Inspeccion, ParameterDirection.Input));
                parametros.Add(new dParameter("facOTNum", SqlDbType.Int, factura.OTNumero, ParameterDirection.Input));
                parametros.Add(new dParameter("facOTSerCod", SqlDbType.SmallInt, factura.OTSerieCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facFecContabilizacion", SqlDbType.DateTime, factura.FechaContabilizacion, ParameterDirection.Input));
                parametros.Add(new dParameter("facFecContabilizacionAnu", SqlDbType.DateTime, factura.FechaContabilizacionAnulada, ParameterDirection.Input));
                parametros.Add(new dParameter("facUsrContabilizacion", 10, SqlDbType.VarChar, factura.UsuarioContabilizacion, ParameterDirection.Input));
                parametros.Add(new dParameter("facUsrReg", 10, SqlDbType.VarChar, factura.UsuarioRegistro, ParameterDirection.Input));
                parametros.Add(new dParameter("facUsrContabilizacionAnu", 10, SqlDbType.VarChar, factura.UsuarioContabilizacionAnulada, ParameterDirection.Input));
                parametros.Add(new dParameter("facVersion", SqlDbType.SmallInt, ParameterDirection.Output));
                parametros.Add(new dParameter("facNumero", 20, SqlDbType.VarChar, ParameterDirection.Output));
                //rectificativa efactura
                parametros.Add(new dParameter("facRazRectcod", 2, SqlDbType.VarChar, factura.RazRectcod, ParameterDirection.Input));
                parametros.Add(new dParameter("facRazRectDescType", 100, SqlDbType.VarChar, factura.RazRectDescType, ParameterDirection.Input));
                parametros.Add(new dParameter("facMeRect", 2, SqlDbType.VarChar, factura.MeRect, ParameterDirection.Input));
                parametros.Add(new dParameter("facMeRectType", 100, SqlDbType.VarChar, factura.MeRectType, ParameterDirection.Input));
                parametros.Add(new dParameter("facEnvSERES", 1, SqlDbType.VarChar, factura.EnvSERES, ParameterDirection.Input));
                parametros.Add(new dParameter("facEnvSAP", SqlDbType.Bit, factura.EnvioSAP, ParameterDirection.Input));
                parametros.Add(new dParameter("facTipoEmit", 2, SqlDbType.VarChar, factura.TipoRect, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);

                if (!resultado)
                {
                    validador.AddCustomMessage(Resource.errorNoInsertado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo, factura.PeriodoCodigo, Resource.contrato, factura.ContratoCodigo, Resource.version, factura.Version)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
                else
                {
                    factura.Version = GetDbNullableShort(parametros.Get("facVersion").Valor);
                    factura.Numero = GetDbNullableString(parametros.Get("facNumero").Valor);
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Actualiza un registro
        /// </summary>
        /// <param name="factura">objeto a actualizar</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool Actualizar(cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                int regafectados = 0;
                string sqlCommand = "Facturas_Update";

                dParamsCollection parametros = new dParamsCollection();

                parametros.Add(new dParameter("original_facCod", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("original_facPerCod", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("original_facCtrCod", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("original_facVersion", SqlDbType.SmallInt, factura.Version, ParameterDirection.Input));
                parametros.Add(new dParameter("facCtrVersion", SqlDbType.SmallInt, factura.ContratoVersion, ParameterDirection.Input));
                parametros.Add(new dParameter("facSerScdCod", SqlDbType.SmallInt, factura.SociedadCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facSerCod", SqlDbType.SmallInt, factura.SerieCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facNumero", 20, SqlDbType.VarChar, factura.Numero, ParameterDirection.Input));
                parametros.Add(new dParameter("facFecha", SqlDbType.DateTime, factura.Fecha, ParameterDirection.Input));
                parametros.Add(new dParameter("facClicod", SqlDbType.Int, factura.ClienteCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facSerieRectif", SqlDbType.SmallInt, factura.SerieRectificativa, ParameterDirection.Input));
                parametros.Add(new dParameter("facNumeroRectif", 20, SqlDbType.VarChar, factura.NumeroRectificativa, ParameterDirection.Input));
                parametros.Add(new dParameter("facFechaRectif", SqlDbType.DateTime, factura.FechaFactRectificativa, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAnt", SqlDbType.Int, factura.LecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAntFec", SqlDbType.DateTime, factura.FechaLecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecLector", SqlDbType.Int, factura.LecturaLector, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecLectorFec", SqlDbType.DateTime, factura.FechaLecturaLector, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecInlCod", 2, SqlDbType.VarChar, factura.LectorIncidenciaLectura, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecInspector", SqlDbType.Int, factura.LecturaInspector, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecInspectorFec", SqlDbType.DateTime, factura.FechaLecturaInspector, ParameterDirection.Input));
                parametros.Add(new dParameter("facInsInlCod", 2, SqlDbType.VarChar, factura.InspectorIncidenciaLectura, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAct", SqlDbType.Int, factura.LecturaFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecActFec", SqlDbType.DateTime, factura.FechaLecturaFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("facConsumoReal", SqlDbType.Int, factura.ConsumoReal, ParameterDirection.Input));
                parametros.Add(new dParameter("facConsumoFactura", SqlDbType.Int, factura.ConsumoFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("facCnsFinal", SqlDbType.Int, factura.ConsumoFinal, ParameterDirection.Input));
                parametros.Add(new dParameter("facCnsComunitario", SqlDbType.Int, factura.ConsumoComunitario, ParameterDirection.Input));
                parametros.Add(new dParameter("facLote", SqlDbType.Int, factura.Lote, ParameterDirection.Input));
                parametros.Add(new dParameter("facLectorEplCod", SqlDbType.SmallInt, factura.LectorCodigoEmpleado, ParameterDirection.Input));
                parametros.Add(new dParameter("facLectorCttCod", SqlDbType.SmallInt, factura.LectorCodigoContratista, ParameterDirection.Input));
                parametros.Add(new dParameter("facInspectorEplCod", SqlDbType.SmallInt, factura.InspectorCodigoEmpleado, ParameterDirection.Input));
                parametros.Add(new dParameter("facInspectorCttCod", SqlDbType.SmallInt, factura.InspectorCodigoContratista, ParameterDirection.Input));
                parametros.Add(new dParameter("facNumeroRemesa", SqlDbType.Int, factura.NumeroRemesa, ParameterDirection.Input));
                parametros.Add(new dParameter("facFechaRemesa", SqlDbType.DateTime, factura.FechaRemesa, ParameterDirection.Input));
                parametros.Add(new dParameter("facZonCod", 4, SqlDbType.VarChar, factura.ZonaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facInspeccion", SqlDbType.Int, factura.Inspeccion, ParameterDirection.Input));
                parametros.Add(new dParameter("facOTSerCod", SqlDbType.SmallInt, factura.OTSerieCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facOTNum", SqlDbType.Int, factura.OTNumero, ParameterDirection.Input));
                parametros.Add(new dParameter("facFecContabilizacion", SqlDbType.DateTime, factura.FechaContabilizacion, ParameterDirection.Input));
                parametros.Add(new dParameter("facFecContabilizacionAnu", SqlDbType.DateTime, factura.FechaContabilizacionAnulada, ParameterDirection.Input));
                parametros.Add(new dParameter("facUsrContabilizacion", 10, SqlDbType.VarChar, factura.UsuarioContabilizacion, ParameterDirection.Input));
                parametros.Add(new dParameter("facUsrReg", 10, SqlDbType.VarChar, factura.UsuarioRegistro, ParameterDirection.Input));
                parametros.Add(new dParameter("facUsrContabilizacionAnu", 10, SqlDbType.VarChar, factura.UsuarioContabilizacionAnulada, ParameterDirection.Input));
                parametros.Add(new dParameter("facObs", 300, SqlDbType.VarChar, factura.Observaciones, ParameterDirection.Input));
                //rectificativa efactura
                parametros.Add(new dParameter("facRazRectcod", 2, SqlDbType.VarChar, factura.RazRectcod, ParameterDirection.Input));
                parametros.Add(new dParameter("facRazRectDescType", 100, SqlDbType.VarChar, factura.RazRectDescType, ParameterDirection.Input));
                parametros.Add(new dParameter("facMeRect", 2, SqlDbType.VarChar, factura.MeRect, ParameterDirection.Input));
                parametros.Add(new dParameter("facMeRectType", 100, SqlDbType.VarChar, factura.MeRectType, ParameterDirection.Input));
                parametros.Add(new dParameter("facEnvSERES", 1, SqlDbType.VarChar, factura.EnvSERES, ParameterDirection.Input));
                parametros.Add(new dParameter("facEnvSAP", SqlDbType.Bit, factura.EnvioSAP, ParameterDirection.Input));
                parametros.Add(new dParameter("facTipoEmit", 2, SqlDbType.VarChar, factura.TipoRect, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out regafectados);
                if (!resultado || regafectados == 0)
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo, factura.PeriodoCodigo, Resource.contrato, factura.ContratoCodigo, Resource.version, factura.Version)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                    resultado = false;
                }

            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;

        }

        /// <summary>
        /// Actualiza un registro
        /// </summary>
        /// <param name="factura">objeto a actualizar</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ActualizarEnvSeres(String sfacSerCod, String sfacnumero, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            if (sfacSerCod == null || sfacnumero == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                int regafectados = 0;
                string sqlCommand = "Facturas_Update_EnvSERES";

                dParamsCollection parametros = new dParamsCollection();

                parametros.Add(new dParameter("Serie", SqlDbType.SmallInt, short.Parse(sfacSerCod), ParameterDirection.Input));
                parametros.Add(new dParameter("Numero", 20, SqlDbType.VarChar, sfacnumero, ParameterDirection.Input));


                resultado = ExecSPWithParams(sqlCommand, ref parametros, out regafectados);
                if (!resultado || regafectados == 0)
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}", Resource.serie, sfacSerCod, Resource.numero, sfacnumero)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                    resultado = false;
                }

            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;

        }

        /// <summary>
        /// Marcar (o desmarca) una factura como remesada
        /// </summary>
        /// <returns>True si todo ha ido bien, false en caso contrario</returns>
        public bool MarcarRemesada(short codigo, int contrato, string periodo, short version, int? numRemesa, DateTime? fechaRemesa, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();

            try
            {
                int regafectados = 0;
                string sqlCommand = "Facturas_MarcarRemesada";

                dParamsCollection parametros = new dParamsCollection();

                parametros.Add(new dParameter("facCod", SqlDbType.SmallInt, codigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, contrato, ParameterDirection.Input));
                parametros.Add(new dParameter("facVersion", SqlDbType.SmallInt, version, ParameterDirection.Input));

                parametros.Add(new dParameter("facNumeroRemesa", SqlDbType.Int, numRemesa, ParameterDirection.Input));
                parametros.Add(new dParameter("facFechaRemesa", SqlDbType.DateTime, fechaRemesa, ParameterDirection.Input));


                resultado = ExecSPWithParams(sqlCommand, ref parametros, out regafectados);
                if (!resultado || regafectados == 0)
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo, periodo, Resource.contrato, contrato, Resource.version, version)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                    resultado = false;
                }

            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;

        }

        /// <summary>
        /// Aplicar los consumos comunitarios (siempre que la zona este aperturada)
        /// </summary>
        /// <param name="periodoCodigo">código del periodo</param>
        /// <param name="zonaCodigo">código de la zona</param>
        /// <param name="usarActualizarFacCtrVersion">True si lo que deseas es uasar y actualizar la última versión del contrato en la factura , False si no</param>
        /// <param name="ctrRaiz">Código del contrato raiz</param>
        /// <returns>Resultado de la operación</returns>
        public cRespuesta AplicarConsumosComunitarios(string periodoCodigo, string zonaCodigo, bool usarYActualizarFacCtrVersion, int? ctrRaiz)
        {
            cRespuesta respuesta = new cRespuesta();
            try
            {
                dValidator validador = new dValidator();
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("ctrZonCod", 4, SqlDbType.VarChar, zonaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("usarYActualizarFacCtrVersion", SqlDbType.Bit, usarYActualizarFacCtrVersion, ParameterDirection.Input));
                parametros.Add(new dParameter("ctrRaizCod", SqlDbType.Int, ctrRaiz, ParameterDirection.Input));
                respuesta.Resultado = ExecSPWithParams("Tasks_Facturas_AplicarConsumosComunitarios", ref parametros) ? ResultadoProceso.OK : ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta;
        }

        /// <summary>
        /// Borra un registro
        /// </summary>
        /// <param name="factura">objeto a borrar</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool Borrar(cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                dValidator validador = new dValidator();
                int regAfectados = 0;
                string sqlCommand = "Facturas_Delete";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("versionFactura", SqlDbType.SmallInt, factura.Version, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out regAfectados);
                if (!resultado)
                {
                    validador.AddCustomMessage(Resource.errorNoBorrado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo, factura.PeriodoCodigo, Resource.contrato, factura.ContratoCodigo, Resource.version, factura.Version)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
                else if (regAfectados == 0)
                {
                    resultado = false;
                    validador.AddCustomMessage(string.Format("{0}. {1}", Resource.errorNoBorrado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo, factura.PeriodoCodigo, Resource.contrato, factura.ContratoCodigo, Resource.version, factura.Version)), Resource.errorNoBorradoCausas));
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

        /// <summary>
        /// Borra las líneas de una factura
        /// </summary>
        /// <param name="factura">factura cuyas líneas se desean eliminar</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool BorrarLineas(cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                dValidator validador = new dValidator();
                int regAfectados = 0;
                string sqlCommand = "FacLin_Delete";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("Original_fclFacCod", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("Original_fclFacPerCod", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("Original_fclFacCtrCod", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("Original_fclFacVersion", SqlDbType.SmallInt, factura.Version, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out regAfectados);
                if (!resultado)
                {
                    validador.AddCustomMessage(Resource.errorLineasFacturaNoBorradas.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo, factura.PeriodoCodigo, Resource.contrato, factura.ContratoCodigo, Resource.version, factura.Version)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
                else if (regAfectados == 0)
                    respuesta.Resultado = ResultadoProceso.SinRegistros;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Construye el filtro para realizar búsquedas
        /// </summary>
        /// <param name="camposBusqueda">Lista ordenada de los textos de los parámetros a filtrar</param>
        /// <returns>Devuelve un string con el filtro a aplicar</returns>
        public string ConstruirFiltroSQL(SortedList camposBusqueda, out cRespuesta respuesta)
        {
            string resultado = String.Empty;

            try
            {
                respuesta = new cRespuesta();
                ArrayList camposBusquedaBD = new ArrayList();

                if (camposBusqueda.Contains("zona"))
                    camposBusquedaBD.Add(new dbField("facZonCod", camposBusqueda["zona"], SqlDbType.VarChar));
                if (camposBusqueda.Contains("periodo"))
                    camposBusquedaBD.Add(new dbField("facPerCod", camposBusqueda["periodo"], SqlDbType.VarChar));
                if (camposBusqueda.Contains("lote"))
                    camposBusquedaBD.Add(new dbField("facLote", camposBusqueda["lote"], SqlDbType.Int));

                if (camposBusqueda.Contains("numero"))
                    camposBusquedaBD.Add(new dbField("facNumero", camposBusqueda["numero"], SqlDbType.VarChar));
                if (camposBusqueda.Contains("serie"))
                    camposBusquedaBD.Add(new dbField("facSerCod", camposBusqueda["serie"], SqlDbType.SmallInt));
                if (camposBusqueda.Contains("sociedad"))
                    camposBusquedaBD.Add(new dbField("facSerScdCod", camposBusqueda["sociedad"], SqlDbType.SmallInt));

                if (camposBusqueda.Contains("inmueble"))
                    camposBusquedaBD.Add(new dbField("ctrinmcod", camposBusqueda["inmueble"], SqlDbType.SmallInt));

                if (camposBusqueda.Contains("contrato"))
                    camposBusquedaBD.Add(new dbField("facCtrCod", camposBusqueda["contrato"], SqlDbType.Int));
                if (camposBusqueda.Contains("cliente"))
                    camposBusquedaBD.Add(new dbField("facCliCod", camposBusqueda["cliente"], SqlDbType.Int));
                if (camposBusqueda.Contains("fechaFac"))
                    camposBusquedaBD.Add(new dbField("facFecha", camposBusqueda["fechaFac"], SqlDbType.DateTime));

                if (camposBusqueda.Contains("version"))
                    camposBusquedaBD.Add(new dbField("facVersion", camposBusqueda["version"], SqlDbType.SmallInt));

                if (camposBusqueda.Contains("otNumero"))
                    camposBusquedaBD.Add(new dbField("facOTNum", camposBusqueda["otNumero"], SqlDbType.Int));

                if (camposBusqueda.Contains("serieOT"))
                    camposBusquedaBD.Add(new dbField("facOTSerCod", camposBusqueda["serieOT"], SqlDbType.SmallInt));

                if (camposBusqueda.Contains("fechaFacReg"))
                    camposBusquedaBD.Add(new dbField("facFecReg", camposBusqueda["fechaFacReg"], SqlDbType.DateTime));

                if (camposBusqueda.Contains("usuarioReg"))
                    camposBusquedaBD.Add(new dbField("facUsrReg", camposBusqueda["usuarioReg"], SqlDbType.VarChar));

                if (camposBusqueda.Contains("activas"))
                {
                    if ((bool)camposBusqueda["activas"])
                        camposBusquedaBD.Add(new dbField("facFechaRectif", DBNull.Value, SqlDbType.VarChar));
                    else
                        camposBusquedaBD.Add(new dbField("facFechaRectif", cConfiguration.kStrFechaMinima + cConfiguration.kSeparadorBuscarRango + cConfiguration.kStrFechaMaxima, SqlDbType.VarChar));
                }

                if (camposBusqueda.Contains("fctTotal"))
                    camposBusquedaBD.Add(new dbField("fctTotal", camposBusqueda["fctTotal"], SqlDbType.Money));

                resultado = dFilterSQLBuilder.ConstruirFiltroSQL(camposBusquedaBD, out respuesta);

            }
            catch (Exception ex)
            {
                resultado = String.Empty;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Obtiene todos los registros según el filtro
        /// </summary>
        /// <param name="facturas">BindableList de Facturas</param>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="pageSize">Número de registros que caben en una página</param>
        /// <param name="pageIndex">Índice de la página a obtener</param>
        /// <param name="totalRowCount">Número de filas que corresponde con el filtro</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerPorFiltro(ref cBindableList<cFacturaBO> facturas, string filtro, int? pageSize, int? pageIndex, bool? soloFacturase, out int totalRowCount, out cRespuesta respuesta, int? estadoDeuda = null)
        {
            totalRowCount = 0;
            bool resultado = false;
            DataSet datos = null;
            try
            {
                respuesta = new cRespuesta();
                string sqlCommand = "Facturas_SelectPorFiltro";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("filtro", 500, SqlDbType.VarChar, filtro, ParameterDirection.Input));

                parametros.Add(new dParameter("pageSize", SqlDbType.Int, pageSize, ParameterDirection.Input));
                parametros.Add(new dParameter("pageIndex", SqlDbType.Int, pageIndex, ParameterDirection.Input));
                parametros.Add(new dParameter("soloFacturase", SqlDbType.Bit, soloFacturase, ParameterDirection.Input));
                
                if(estadoDeuda.HasValue && estadoDeuda > 0)
                    parametros.Add(new dParameter("estadoDeuda", SqlDbType.TinyInt, estadoDeuda, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                    totalRowCount = datos.Tables.Count == 2 ? GetDbInt(datos.Tables[1].Rows[0]["TotalRowCount"]) : datos.Tables[0].Rows.Count;
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

        /// <summary>
        /// 
        /// </summary>
        /// <param name="facturas">BindableList de Facturas</param>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerInspeccionablesPorFiltro(ref cBindableList<cFacturaBO> facturas, string filtro, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            try
            {
                respuesta = new cRespuesta();
                string sqlCommand = "Facturas_SelectPorFiltro";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("soloInspeccionables", SqlDbType.Bit, true, ParameterDirection.Input));
                parametros.Add(new dParameter("filtro", 500, SqlDbType.VarChar, filtro, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        /// <summary>
        /// 
        /// </summary>
        /// <param name="facturas">BindableList de Facturas</param>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerPendientesDeLeerPorFiltro(ref cBindableList<cFacturaBO> facturas, string filtro, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            try
            {
                respuesta = new cRespuesta();
                string sqlCommand = "Facturas_SelectPorFiltro";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("soloPendientesLeer", SqlDbType.Bit, true, ParameterDirection.Input));
                parametros.Add(new dParameter("filtro", 500, SqlDbType.VarChar, filtro, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        private cSimuladorDetalladoBO RellenarEntidadSimulador(DataRow datos, out cRespuesta respuesta)
        {
            cSimuladorDetalladoBO simulador = new BO.Facturacion.cSimuladorDetalladoBO();
            respuesta = new cRespuesta();
            try
            {
                simulador.Servicio = GetDbNullableString(datos["servicio"]);
                simulador.Impuesto = GetDbNullableShort(datos["svcImpuesto"]);
                simulador.ImporteServicio = GetDbNullableDecimal(datos["base"]);
                simulador.ImporteImpuesto = GetDbNullableDecimal(datos["totalImpuesto"]);
                simulador.ImporteTotal = GetDbNullableDecimal(datos["total"]);
                simulador.ConsumoHabDia = GetDbNullableShort(datos["cnsPorHabDia"]);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return simulador;
        }

        private cFacturaBO RellenarEntidad(DataRow datos, out cRespuesta respuesta)
        {
            cFacturaBO factura = new cFacturaBO();
            respuesta = new cRespuesta();
            try
            {
                factura.FacturaCodigo = GetDbNullableShort(datos["facCod"]);
                factura.PeriodoCodigo = GetDbNullableString(datos["facPerCod"]);
                factura.ContratoCodigo = GetDbNullableInt(datos["facCtrCod"]);
                factura.ContratoVersion = GetDbNullableShort(datos["facCtrVersion"]);
                factura.Version = GetDbNullableShort(datos["facVersion"]);
                factura.SerieCodigo = GetDbNullableShort(datos["facSerCod"]);
                factura.SociedadCodigo = GetDbNullableShort(datos["facSerScdCod"]);
                factura.Numero = GetDbNullableString(datos["facNumero"]);
                factura.Fecha = GetDbNullableDateTime(datos["facFecha"]);
                factura.ClienteCodigo = GetDbNullableInt(datos["facCliCod"]);
                factura.SerieRectificativa = GetDbNullableShort(datos["facSerieRectif"]);
                factura.NumeroRectificativa = GetDbNullableString(datos["facNumeroRectif"]);
                factura.FechaFactRectificativa = GetDbNullableDateTime(datos["facFechaRectif"]);
                factura.LecturaAnterior = GetDbNullableInt(datos["facLecAnt"]);
                factura.FechaLecturaAnterior = GetDbNullableDateTime(datos["facLecAntFec"]);
                factura.LecturaLector = GetDbNullableInt(datos["facLecLector"]);
                factura.FechaLecturaLector = GetDbNullableDateTime(datos["facLecLectorFec"]);
                factura.LectorIncidenciaLectura = GetDbNullableString(datos["facLecInlCod"]);
                factura.LecturaInspector = GetDbNullableInt(datos["facLecInspector"]);
                factura.FechaLecturaInspector = GetDbNullableDateTime(datos["facLecInspectorFec"]);
                factura.InspectorIncidenciaLectura = GetDbNullableString(datos["facInsInlCod"]);
                factura.LecturaFactura = GetDbNullableInt(datos["facLecAct"]);
                factura.FechaLecturaFactura = GetDbNullableDateTime(datos["facLecActFec"]);
                factura.ConsumoReal = GetDbNullableInt(datos["facConsumoReal"]);
                factura.ConsumoFactura = GetDbNullableInt(datos["facConsumoFactura"]);
                factura.ConsumoComunitario = GetDbNullableInt(datos["facCnsComunitario"]);
                factura.ConsumoFinal = GetDbNullableInt(datos["facCnsFinal"]);
                factura.Lote = GetDbNullableShort(datos["facLote"]);
                factura.LectorCodigoEmpleado = GetDbNullableShort(datos["facLectorEplCod"]);
                factura.LectorCodigoContratista = GetDbNullableShort(datos["facLectorCttCod"]);
                factura.InspectorCodigoEmpleado = GetDbNullableShort(datos["facInspectorEplCod"]);
                factura.InspectorCodigoContratista = GetDbNullableShort(datos["facInspectorCttCod"]);
                factura.NumeroRemesa = GetDbNullableInt(datos["facNumeroRemesa"]);
                factura.FechaRemesa = GetDbNullableDateTime(datos["facFechaRemesa"]);
                factura.ZonaCodigo = GetDbNullableString(datos["facZonCod"]);
                factura.Inspeccion = GetDbNullableInt(datos["facInspeccion"]);
                factura.FechaRegistro = GetDbNullableDateTime(datos["facFecReg"]);
                factura.OTSerieCodigo = GetDbNullableShort(datos["facOTSerCod"]);
                factura.OTNumero = GetDbNullableInt(datos["facOTNum"]);
                factura.FechaContabilizacion = GetDbNullableDateTime(datos["facFecContabilizacion"]);
                factura.FechaContabilizacionAnulada = GetDbNullableDateTime(datos["facFecContabilizacionAnu"]);
                factura.UsuarioContabilizacion = GetDbNullableString(datos["facUsrContabilizacion"]);
                factura.UsuarioRegistro = GetDbNullableString(datos["facUsrReg"]);
                factura.UsuarioContabilizacionAnulada = GetDbNullableString(datos["facUsrContabilizacionAnu"]);
                factura.RazRectcod = GetDbNullableString(datos["facRazRectcod"]);
                factura.RazRectDescType = GetDbNullableString(datos["facRazRectDescType"]);
                factura.MeRect = GetDbNullableString(datos["facMeRect"]);
                factura.MeRectType = GetDbNullableString(datos["facMeRectType"]);
                factura.EnvSERES = GetDbNullableString(datos["facEnvSERES"]);
                factura.EnvioSAP = GetDbNullableBool(datos["facEnvSAP"]);
                factura.TipoRect = GetDbNullableString(datos["facTipoEmit"]);

                if (datos.Table.Columns.Contains("facFecEmisionSERES"))
                    factura.FecEmisionSERES = GetDbNullableDateTime(datos["facFecEmisionSERES"]);


                respuesta.Resultado = ResultadoProceso.OK;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return factura;
        }

        private cFacturaBO RellenarEntidadSOA(DataRow datos, out cRespuesta respuesta)
        {
            cFacturaBO factura = new cFacturaBO();
            respuesta = new cRespuesta();
            try
            {
                //factura.CodExplo = GetDbNullableShort(datos["facCodExplo"]);
                factura.FacturaCodigo = GetDbNullableShort(datos["facCod"]);
                factura.PeriodoCodigo = GetDbNullableString(datos["facPerCod"]);
                factura.ContratoCodigo = GetDbNullableInt(datos["facCtrCod"]);
                factura.ContratoVersion = GetDbNullableShort(datos["facCtrVersion"]);
                factura.Version = GetDbNullableShort(datos["facVersion"]);
                factura.SerieCodigo = GetDbNullableShort(datos["facSerCod"]);
                factura.SociedadCodigo = GetDbNullableShort(datos["facSerScdCod"]);
                factura.Numero = GetDbNullableString(datos["facNumero"]);
                factura.Fecha = GetDbNullableDateTime(datos["facFecha"]);
                factura.ClienteCodigo = GetDbNullableInt(datos["facCliCod"]);
                factura.SerieRectificativa = GetDbNullableShort(datos["facSerieRectif"]);
                factura.NumeroRectificativa = GetDbNullableString(datos["facNumeroRectif"]);
                factura.FechaFactRectificativa = GetDbNullableDateTime(datos["facFechaRectif"]);
                factura.LecturaAnterior = GetDbNullableInt(datos["facLecAnt"]);
                factura.FechaLecturaAnterior = GetDbNullableDateTime(datos["facLecAntFec"]);
                factura.LecturaLector = GetDbNullableInt(datos["facLecLector"]);
                factura.FechaLecturaLector = GetDbNullableDateTime(datos["facLecLectorFec"]);
                factura.LectorIncidenciaLectura = GetDbNullableString(datos["facLecInlCod"]);
                factura.LecturaInspector = GetDbNullableInt(datos["facLecInspector"]);
                factura.FechaLecturaInspector = GetDbNullableDateTime(datos["facLecInspectorFec"]);
                factura.InspectorIncidenciaLectura = GetDbNullableString(datos["facInsInlCod"]);
                factura.LecturaFactura = GetDbNullableInt(datos["facLecAct"]);
                factura.FechaLecturaFactura = GetDbNullableDateTime(datos["facLecActFec"]);
                factura.ConsumoReal = GetDbNullableInt(datos["facConsumoReal"]);
                factura.ConsumoFactura = GetDbNullableInt(datos["facConsumoFactura"]);
                factura.ConsumoComunitario = GetDbNullableInt(datos["facCnsComunitario"]);
                factura.ConsumoFinal = GetDbNullableInt(datos["facCnsFinal"]);
                factura.Lote = GetDbNullableShort(datos["facLote"]);
                factura.LectorCodigoEmpleado = GetDbNullableShort(datos["facLectorEplCod"]);
                factura.LectorCodigoContratista = GetDbNullableShort(datos["facLectorCttCod"]);
                factura.InspectorCodigoEmpleado = GetDbNullableShort(datos["facInspectorEplCod"]);
                factura.InspectorCodigoContratista = GetDbNullableShort(datos["facInspectorCttCod"]);
                factura.NumeroRemesa = GetDbNullableInt(datos["facNumeroRemesa"]);
                factura.FechaRemesa = GetDbNullableDateTime(datos["facFechaRemesa"]);
                factura.ZonaCodigo = GetDbNullableString(datos["facZonCod"]);
                factura.Inspeccion = GetDbNullableInt(datos["facInspeccion"]);
                factura.FechaRegistro = GetDbNullableDateTime(datos["facFecReg"]);
                factura.OTSerieCodigo = GetDbNullableShort(datos["facOTSerCod"]);
                factura.OTNumero = GetDbNullableInt(datos["facOTNum"]);
                factura.FechaContabilizacion = GetDbNullableDateTime(datos["facFecContabilizacion"]);
                factura.FechaContabilizacionAnulada = GetDbNullableDateTime(datos["facFecContabilizacionAnu"]);
                factura.UsuarioContabilizacion = GetDbNullableString(datos["facUsrContabilizacion"]);
                factura.UsuarioRegistro = GetDbNullableString(datos["facUsrReg"]);
                factura.UsuarioContabilizacionAnulada = GetDbNullableString(datos["facUsrContabilizacionAnu"]);
                factura.RazRectcod = GetDbNullableString(datos["facRazRectcod"]);
                factura.RazRectDescType = GetDbNullableString(datos["facRazRectDescType"]);
                factura.MeRect = GetDbNullableString(datos["facMeRect"]);
                //factura.MeRectType = GetDbNullableString(datos["facMeRectType"]);
                //factura.EnvSERES = GetDbNullableString(datos["facEnvSERES"]);
                //factura.EnvioSAP = GetDbNullableBool(datos["facEnvSAP"]);
                //factura.TipoRect = GetDbNullableString(datos["facTipoEmit"]);

                if (datos.Table.Columns.Contains("facFecEmisionSERES"))
                    factura.FecEmisionSERES = GetDbNullableDateTime(datos["facFecEmisionSERES"]);


                respuesta.Resultado = ResultadoProceso.OK;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return factura;
        }
        /// <summary>
        /// Realización del proceso de calculo del consumo real
        /// </summary>
        /// <param name="facturaBO">Objeto con el cual se realizará el proceso de calculo de consumo real</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <param name="consumoReal">Nº de consumo real de la factura</param>
        /// <param name="lecturaAnterior">Lectura anterior real</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool CalculoConsumoReal(cFacturaBO facturaBO, out int? consumoReal, out int? lecturaAnterior, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;
            consumoReal = null;
            lecturaAnterior = null;
            try
            {
                string sqlCommand = "Facturas_CalculoConsumoReal";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("facLecActFec", SqlDbType.DateTime, facturaBO.FechaLecturaLector, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAntFec", SqlDbType.DateTime, facturaBO.FechaLecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAnt", SqlDbType.Int, facturaBO.LecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, facturaBO.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("consumoReal", SqlDbType.Int, ParameterDirection.Output));
                parametros.Add(new dParameter("lecturaAnterior", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (resultado)
                {
                    consumoReal = GetDbNullableInt(parametros.Get("consumoReal").Valor);
                    lecturaAnterior = GetDbNullableInt(parametros.Get("lecturaAnterior").Valor);
                }
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Realización del proceso de calculo del alto y el bajo
        /// </summary>
        /// <param name="consumoReal">consumo real de la factura</param>
        /// <param name="alto">Máximo consumo estimado</param>
        /// <param name="bajo">Mínimo consumo estimado</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool CalculoConsumoAltoBajo(int consumo, out int? alto, out int? bajo, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;
            alto = null;
            bajo = null;

            try
            {
                string sqlCommand = "Facturas_CalculoConsumoAltoBajo";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("consumo", SqlDbType.Int, consumo, ParameterDirection.Input));
                parametros.Add(new dParameter("alto", SqlDbType.Int, ParameterDirection.Output));
                parametros.Add(new dParameter("bajo", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (resultado)
                {
                    alto = GetDbNullableInt(parametros.Get("alto").Valor);
                    bajo = GetDbNullableInt(parametros.Get("bajo").Valor);
                }
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Realización del proceso de calculo del promedio del mismo periodo del ejercicio anterior
        /// </summary>
        /// <param name="contrato">Código del contrato</param>
        /// <param name="perido">Periodo de la factura</param>
        /// <param name="calcularPromedioDeTarifa">ndica si debe calcularle el consumo a partir de la tarifa si el cálculo de consumo en el mismo periodo del ejercicio anterior es null</param>
        /// <param name="consumoPeriodo">Consumo de un periodo determinado</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool CalculoConsumoMismoPeriodoEjercAnterior(int contratoCodigo, string periodoCodigo, bool calcularPromedioDeTarifa, out int? consumoPeriodo, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;
            consumoPeriodo = null;

            try
            {
                string sqlCommand = "Facturas_CalculoConsumoMismoPeriodoEjercAnterior";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("calcularPromedioDeTarifa", SqlDbType.Bit, calcularPromedioDeTarifa, ParameterDirection.Input));
                parametros.Add(new dParameter("consumoPeriodo", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (resultado)
                    consumoPeriodo = GetDbNullableInt(parametros.Get("consumoPeriodo").Valor);
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Realización del proceso de calculo del consumo promedio
        /// </summary>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="periodoCodigo">Periodo de la factura</param>
        /// <param name="calcularPromedioDeTarifa">ndica si debe calcularle el consumo a partir de la tarifa si el cálculo de consumo promedio es null</param>
        /// <param name="consumoPromedio">Consumo promedio</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool CalculoConsumoPromedio(int contratoCodigo, string periodoCodigo, bool calcularPromedioDeTarifa, out int? consumoPromedio, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;
            consumoPromedio = null;

            try
            {
                string sqlCommand = "Facturas_CalculoConsumoPromedio";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("calcularPromedioDeTarifa", SqlDbType.Bit, calcularPromedioDeTarifa, ParameterDirection.Input));
                parametros.Add(new dParameter("consumoPromedio", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (resultado)
                    consumoPromedio = GetDbNullableInt(parametros.Get("consumoPromedio").Valor);
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Calcula el consumo promedio por diametro y ruta
        /// </summary>
        /// <param name="zonaD">Zona desde</param>
        /// <param name="zonaH">Zona hasta</param>
        /// <param name="diametro">Diámetro del contador</param>
        /// <param name="rutaAgrupada">Ruta por la cual se agrupará</param>
        /// <param name="periodo">Periodo de la factura</param>
        /// <param name="consumoPromedio">Consumo promedio</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool CalculoConsumoPromedioPorDiametroYRuta(string zonaD, string zonaH, short diametro, int rutaAgrupada, string periodo, int? contratoCodigo, out int? consumoPromedio, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;
            consumoPromedio = null;

            try
            {
                string sqlCommand = "Facturas_CalculoConsumoPromedioPorDiametroYRuta";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("zonaD", 4, SqlDbType.VarChar, zonaD, ParameterDirection.Input));
                parametros.Add(new dParameter("zonaH", 4, SqlDbType.VarChar, zonaH, ParameterDirection.Input));
                parametros.Add(new dParameter("diametro", SqlDbType.SmallInt, diametro, ParameterDirection.Input));
                parametros.Add(new dParameter("rutaAgrupada", SqlDbType.Int, rutaAgrupada, ParameterDirection.Input));
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("contratoCodigo", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("consumoPromedio", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (resultado)
                    consumoPromedio = GetDbNullableInt(parametros.Get("consumoPromedio").Valor);
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene el consumo para método de cálculo estimación periodo para AVG.
        /// </summary>
        /// <param name="contrato">Código del contrato</param>
        /// <param name="perido">Periodo de la factura</param>
        /// <param name="consumoPeriodo">Consumo de un periodo determinado</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool CalculoConsumoEstimadoPeriodo_AVG(int contratoCodigo, string periodoCodigo, out int? consumoPeriodo, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;
            consumoPeriodo = null;

            try
            {
                string sqlCommand = "Facturas_CalculoConsumoEstimadoPeriodo_AVG";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("consumoPeriodo", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (resultado)
                    consumoPeriodo = GetDbNullableInt(parametros.Get("consumoPeriodo").Valor);
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene el primer registro de factura sin lectura
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="lector">Booleano que indica que tipo de lectura no debe tener la factura</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerPrimeraSinLectura(ref cFacturaBO factura, bool lector, out cRespuesta respuesta)
        {
            //lector = true, lectura lector debe de estar vacio
            //lector = false, lectura inspector debe de estar vacio

            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, factura.ZonaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("numRegistros", SqlDbType.Int, 1, ParameterDirection.Input));
                parametros.Add(new dParameter("lector", SqlDbType.Bit, lector, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    if (datos.Tables[0].Rows.Count > 0)
                    {
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        /// <summary>
        /// Obtiene los valores de una tarifa 
        /// </summary>
        /// <param name="servicio">Parametro de entrada</param>
        /// <param name="tarifa">Parametro de entrada</param>
        /// <param name="fecPeriodoD">Parametro de entrada</param>
        /// <param name="fecPeriodoH">Parametro de entrada</param>
        /// <param name="fecInicio">Parametro de entrada</param>
        /// <param name="fecFin">Parametro de entrada</param>
        /// <param name="tarvalBO">Objeto de Tarval, Almacena los parametros de salida</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerValoresTarifa(short servicio, short tarifa, DateTime? fecPeriodoD, DateTime? fecPeriodoH, DateTime? fecInicio, DateTime? fecFin, ref cTarvalBO tarvalBO, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado;

            if (tarvalBO == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codigoServicio", SqlDbType.SmallInt, servicio, ParameterDirection.Input));
                parametros.Add(new dParameter("codigoTarifa", SqlDbType.SmallInt, tarifa, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaPeriodoDesde", SqlDbType.DateTime, DBNullIfNull(fecPeriodoD), ParameterDirection.Input));
                parametros.Add(new dParameter("fechaPeriodoHasta", SqlDbType.DateTime, DBNullIfNull(fecPeriodoH), ParameterDirection.Input));
                parametros.Add(new dParameter("fechaInicio", SqlDbType.DateTime, DBNullIfNull(fecInicio), ParameterDirection.Input));
                parametros.Add(new dParameter("fechaFin", SqlDbType.DateTime, DBNullIfNull(fecFin), ParameterDirection.Input));
                parametros.Add(new dParameter("precio1Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio2Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio3Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio4Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio5Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio6Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio7Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio8Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("precio9Out", 16, 6, SqlDbType.Decimal, ParameterDirection.Output));
                parametros.Add(new dParameter("cuotaOut", 16, 4, SqlDbType.Decimal, ParameterDirection.Output));

                resultado = ExecSPWithParams("Facturas_ObtenerValoresTarifa", ref parametros);

                if (resultado)
                {
                    for (int i = 1; i <= tarvalBO.Precios(); i++)
                    {
                        string precioOut = string.Format("{0}{1}{2}", "precio", i.ToString(), "Out");
                        tarvalBO.SetPrecio(i, GetDbDecimal(parametros.Get(precioOut).Valor));
                    }
                    tarvalBO.Cuota = GetDbDecimal(parametros.Get("cuotaOut").Valor);
                }
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas necesarias para realizar la creación de un fichero que se cargará en un TPL
        /// Parámetros necesarios del objeto factura: factura.Zona, factura.Periodo
        /// </summary>
        /// <param name="facturas">BindableList de Facturas</param>
        /// <param name="factura">Factura que contiene la zona, el periodo</param>
        /// <param name="lector">Si lector != null, obtendremos las facuras cuyos lotes estén asignados a ese lector</param>
        /// <param name="loteDesde">Lote desde el cual se quieren obtener facturas</param>
        /// <param name="loteHasta">Lote hasta el cual se quieren obtener facturas</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerParaDescargaTPL(ref cBindableList<cFacturaBO> facturas, cFacturaBO factura, cEmpleadoBO lector, int loteDesde, int loteHasta, bool? incluirCtrSinSerMedAct, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                string storedProcedure = "Facturas_SelectDescargaTPL";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, factura.ZonaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("loteDesde", SqlDbType.Int, loteDesde, ParameterDirection.Input));
                parametros.Add(new dParameter("loteHasta", SqlDbType.Int, loteHasta, ParameterDirection.Input));
                parametros.Add(new dParameter("incluirContratosSinServicioMedidoActivo", SqlDbType.Bit, incluirCtrSinSerMedAct, ParameterDirection.Input));

                if (lector != null)
                {
                    parametros.Add(new dParameter("lectorEplCod", SqlDbType.SmallInt, lector.Codigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("lectorCttCod", SqlDbType.SmallInt, lector.Contratistacod, ParameterDirection.Input));
                }

                resultado = ExecSPWithParams(storedProcedure, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaIterador;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaIterador = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaIterador != null)
                                facturas.Add(facturaIterador);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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

        /// <summary>
        /// Obtiene el Importe Facturado de un contrato en un periodo y una fecha determinada (de la ultima factura)
        /// Si no se indica la version se obtendrá el importe Facturado de la ultima versión de la factura.
        /// </summary>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="periodoCod">Código del Periodo</param>
        /// <param name="version">Código de la Versión (si el valor es null se obtendrá el importe Facturado de la ultima versión)</param>
        /// <param name="fecha">Fecha </param>
        /// <param name="prefacturas">True: Solo prefacturas; False: Ninguna prefactura; NULL: Todas </param>
        /// <param name="periodosSaldo">True: Obtiene el importe facturado solo desde el periodo de inicio del saldo</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>El importe facturado obtenido </returns>
        public decimal ObtenerImporteFacturado(short? codigo, int contratoCod, string periodoCod, short? version, Nullable<DateTime> fecha, bool? prefacturas, bool periodosSaldo, out cRespuesta respuesta, int precision = 2)
        {
            decimal resultado = 0;
            respuesta = new cRespuesta();

            try
            {
                string sqlCommand = "Facturas_ImporteFacturado";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, codigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCod, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCod, ParameterDirection.Input));
                parametros.Add(new dParameter("version", SqlDbType.SmallInt, version, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaRegistroMaxima", SqlDbType.DateTime, fecha, ParameterDirection.Input));
                parametros.Add(new dParameter("prefacturas", SqlDbType.Bit, prefacturas, ParameterDirection.Input));
                parametros.Add(new dParameter("periodosSaldo", SqlDbType.Bit, periodosSaldo, ParameterDirection.Input));
                parametros.Add(new dParameter("impFact", SqlDbType.Money, ParameterDirection.Output));
                parametros.Add(new dParameter("precision", SqlDbType.SmallInt, precision, ParameterDirection.Input));

                if (ExecSPWithParams(sqlCommand, ref parametros))
                {
                    resultado = GetDbDecimal(parametros.Get("impFact").Valor);
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
                
        /// <summary>
        /// Obtiene el Importe Facturado de un contrato en un periodo y una fecha determinada (de la ultima factura)
        /// Si no se indica la version se obtendrá el importe Facturado de la ultima versión de la factura.
        /// </summary>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="periodoCod">Código del Periodo</param>
        /// <param name="version">Código de la Versión (si el valor es null se obtendrá el importe Facturado de la ultima versión)</param>
        /// <param name="fecha">Fecha </param>
        /// <param name="prefacturas">True: Solo prefacturas; False: Ninguna prefactura; NULL: Todas </param>
        /// <param name="periodosSaldo">True: Obtiene el importe facturado solo desde el periodo de inicio del saldo</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>El importe facturado obtenido </returns>
        public decimal ObtenerImporteFacturadoSOA(string codExplo, short? codigo, int contratoCod, string periodoCod, short? version, Nullable<DateTime> fecha, bool? prefacturas, bool periodosSaldo, out cRespuesta respuesta, int precision = 2)
        {
            decimal resultado = 0;
            respuesta = new cRespuesta();

            try
            {
                string sqlCommand = "Facturas_ImporteFacturadoSOA";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codExplo",20, SqlDbType.VarChar, codExplo, ParameterDirection.Input));
                parametros.Add(new dParameter("codigo", SqlDbType.SmallInt, codigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCod, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCod, ParameterDirection.Input));
                parametros.Add(new dParameter("version", SqlDbType.SmallInt, version, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaRegistroMaxima", SqlDbType.DateTime, fecha, ParameterDirection.Input));
                parametros.Add(new dParameter("prefacturas", SqlDbType.Bit, prefacturas, ParameterDirection.Input));
                parametros.Add(new dParameter("periodosSaldo", SqlDbType.Bit, periodosSaldo, ParameterDirection.Input));
                parametros.Add(new dParameter("impFact", SqlDbType.Money, ParameterDirection.Output));
                parametros.Add(new dParameter("precision", SqlDbType.SmallInt, precision, ParameterDirection.Input));

                if (ExecSPWithParams(sqlCommand, ref parametros))
                {
                    resultado = GetDbDecimal(parametros.Get("impFact").Valor);
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
        /// <summary>
        /// Obtiene las facturas pendientes de cobro
        /// Rellena los campos del BO TotalCobrado y TotalFacturado
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="contratoCod">codigo del Contrato</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerPendientesDeCobro(ref cBindableList<cFacturaBO> facturas, int contratoCod, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_SelectPendientesCobro";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCod, ParameterDirection.Input));


                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);

                            //Añadimos campos de este procedimiento
                            facturaBO.TotalCobrado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["cobrado"]);
                            facturaBO.TotalFacturado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["facturado"]);

                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas pendientes de cobro a partir de un cliente
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="clienteCodigo">Código del cliente</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerPendientesDeCobroPorCliente(ref cBindableList<cFacturaBO> facturas, int clienteCodigo, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_SelectPendientesCobroPorCliente";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("clienteCodigo", SqlDbType.Int, clienteCodigo, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas pendientes de cobro de un contrato en concreto
        /// Rellena los campos del BO TotalCobrado y TotalFacturado
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="contratoCod">codigo del Contrato</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerSobreCobradas(ref cBindableList<cFacturaBO> facturas, int contratoCod, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_SelectSobreCobradas";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCod, ParameterDirection.Input));


                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);

                            //Añadimos campos de este procedimiento
                            facturaBO.TotalCobrado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["cobrado"]);
                            facturaBO.TotalFacturado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["facturado"]);

                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }


        public bool ObtenerPorTipoDeuda(ref cBindableList<cFacturaBO> facturas, int contratoCod, TipoDeuda tipoDeuda, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_SelectPorTipoDeuda";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCod, ParameterDirection.Input));
                parametros.Add(new dParameter("tipoDeuda", SqlDbType.Int, tipoDeuda, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);

                            //Añadimos campos de este procedimiento
                            facturaBO.TotalCobrado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["cobrado"]);
                            facturaBO.TotalFacturado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["facturado"]);

                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas por una seleccion
        /// </summary>
        /// <param name="facturas">Litado de facturas</param>
        /// <param name="seleccion">Objeto Selección que contiene los parámetros de selección</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool Obtener(ref cBindableList<cFacturaBO> facturas, cFacturasSeleccionBO seleccion, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("preFactura", SqlDbType.Bit, seleccion.PreFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("ultimaVersion", SqlDbType.Bit, !seleccion.VerTodas, ParameterDirection.Input));
                parametros.Add(new dParameter("verTodas", SqlDbType.Bit, seleccion.VerTodas, ParameterDirection.Input));
                parametros.Add(new dParameter("mostrarFacturasOnline", SqlDbType.Bit, seleccion.MostrarFacturasOnline, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, seleccion.Zona, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, seleccion.Periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("cuales", SqlDbType.VarChar, seleccion.Cuales, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaCob", SqlDbType.DateTime, seleccion.FechaCobro, ParameterDirection.Input));
                parametros.Add(new dParameter("soloFacturasE", SqlDbType.Bit, seleccion.SoloFacturasE, ParameterDirection.Input));
                parametros.Add(new dParameter("xmlPortalCodArray", 1000, SqlDbType.VarChar, seleccion.XmlPortalCodArray, ParameterDirection.Input));
                parametros.Add(new dParameter("serie", SqlDbType.SmallInt, seleccion.SerieCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("sociedad", SqlDbType.SmallInt, seleccion.SociedadCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("numero", 20, SqlDbType.VarChar, seleccion.NumeroFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("totalImporte", SqlDbType.Money, seleccion.TotalImporte, ParameterDirection.Input));

                if (seleccion.Desde != null)
                {
                    parametros.Add(new dParameter("periodoD", 6, SqlDbType.VarChar, seleccion.Desde.Periodo, ParameterDirection.Input));
                    parametros.Add(new dParameter("zonaD", 4, SqlDbType.VarChar, seleccion.Desde.Zona, ParameterDirection.Input));
                    parametros.Add(new dParameter("contratoDesde", SqlDbType.Int, seleccion.Desde.ContratoCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("clienteD", SqlDbType.Int, seleccion.Desde.ClienteCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("inmuebleD", SqlDbType.Int, seleccion.Desde.InmuebleCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("versionD", SqlDbType.SmallInt, seleccion.Desde.Version, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaD", SqlDbType.DateTime, seleccion.Desde.FechaFactura, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaRectifD", SqlDbType.DateTime, seleccion.Desde.FechaRectificativa, ParameterDirection.Input));
                }

                if (seleccion.Hasta != null)
                {
                    parametros.Add(new dParameter("periodoH", 6, SqlDbType.VarChar, seleccion.Hasta.Periodo, ParameterDirection.Input));
                    parametros.Add(new dParameter("zonaH", 4, SqlDbType.VarChar, seleccion.Hasta.Zona, ParameterDirection.Input));
                    parametros.Add(new dParameter("contratoHasta", SqlDbType.Int, seleccion.Hasta.ContratoCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("clienteH", SqlDbType.Int, seleccion.Hasta.ClienteCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("inmuebleH", SqlDbType.Int, seleccion.Hasta.InmuebleCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("versionH", SqlDbType.SmallInt, seleccion.Hasta.Version, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaH", SqlDbType.DateTime, seleccion.Hasta.FechaFactura, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaRectifH", SqlDbType.DateTime, seleccion.Hasta.FechaRectificativa, ParameterDirection.Input));
                }

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        facturas = new cBindableList<cFacturaBO>();
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);

                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
        /// <summary>
        /// Obtiene las facturas por una seleccion
        /// </summary>
        /// <param name="facturas">Litado de facturas</param>
        /// <param name="seleccion">Objeto Selección que contiene los parámetros de selección</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerSOA(ref cBindableList<cFacturaBO> facturas, cFacturasSeleccionBO seleccion, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_SelectSOA";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("codExplo", 3, SqlDbType.VarChar, seleccion.ExploCod, ParameterDirection.Input));
                parametros.Add(new dParameter("preFactura", SqlDbType.Bit, seleccion.PreFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("ultimaVersion", SqlDbType.Bit, !seleccion.VerTodas, ParameterDirection.Input));
                parametros.Add(new dParameter("verTodas", SqlDbType.Bit, seleccion.VerTodas, ParameterDirection.Input));
                parametros.Add(new dParameter("mostrarFacturasOnline", SqlDbType.Bit, seleccion.MostrarFacturasOnline, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, seleccion.Zona, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, seleccion.Periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("cuales", SqlDbType.VarChar, seleccion.Cuales, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaCob", SqlDbType.DateTime, seleccion.FechaCobro, ParameterDirection.Input));
                parametros.Add(new dParameter("soloFacturasE", SqlDbType.Bit, seleccion.SoloFacturasE, ParameterDirection.Input));
                parametros.Add(new dParameter("xmlPortalCodArray", 1000, SqlDbType.VarChar, seleccion.XmlPortalCodArray, ParameterDirection.Input));
                parametros.Add(new dParameter("serie", SqlDbType.SmallInt, seleccion.SerieCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("sociedad", SqlDbType.SmallInt, seleccion.SociedadCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("numero", 20, SqlDbType.VarChar, seleccion.NumeroFactura, ParameterDirection.Input));
                parametros.Add(new dParameter("totalImporte", SqlDbType.Money, seleccion.TotalImporte, ParameterDirection.Input));

                if (seleccion.Desde != null)
                {
                    parametros.Add(new dParameter("periodoD", 6, SqlDbType.VarChar, seleccion.Desde.Periodo, ParameterDirection.Input));
                    parametros.Add(new dParameter("zonaD", 4, SqlDbType.VarChar, seleccion.Desde.Zona, ParameterDirection.Input));
                    parametros.Add(new dParameter("contratoDesde", SqlDbType.Int, seleccion.Desde.ContratoCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("clienteD", SqlDbType.Int, seleccion.Desde.ClienteCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("inmuebleD", SqlDbType.Int, seleccion.Desde.InmuebleCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("versionD", SqlDbType.SmallInt, seleccion.Desde.Version, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaD", SqlDbType.DateTime, seleccion.Desde.FechaFactura, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaRectifD", SqlDbType.DateTime, seleccion.Desde.FechaRectificativa, ParameterDirection.Input));
                }

                if (seleccion.Hasta != null)
                {
                    parametros.Add(new dParameter("periodoH", 6, SqlDbType.VarChar, seleccion.Hasta.Periodo, ParameterDirection.Input));
                    parametros.Add(new dParameter("zonaH", 4, SqlDbType.VarChar, seleccion.Hasta.Zona, ParameterDirection.Input));
                    parametros.Add(new dParameter("contratoHasta", SqlDbType.Int, seleccion.Hasta.ContratoCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("clienteH", SqlDbType.Int, seleccion.Hasta.ClienteCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("inmuebleH", SqlDbType.Int, seleccion.Hasta.InmuebleCodigo, ParameterDirection.Input));
                    parametros.Add(new dParameter("versionH", SqlDbType.SmallInt, seleccion.Hasta.Version, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaH", SqlDbType.DateTime, seleccion.Hasta.FechaFactura, ParameterDirection.Input));
                    parametros.Add(new dParameter("facFechaRectifH", SqlDbType.DateTime, seleccion.Hasta.FechaRectificativa, ParameterDirection.Input));
                }

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        facturas = new cBindableList<cFacturaBO>();
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidadSOA(datos.Tables[0].Rows[i], out respuesta);

                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
        /// <summary>
        /// Obtiene las facturas pendientes de cobro
        /// Rellena los campos del BO TotalCobrado y TotalFacturado
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="ptesCobro">Objeto SeleccionPtesCobro que contiene los parámetros de selección</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerPendientesDeCobro(ref cBindableList<cFacturaBO> facturas, SeleccionPtesCobro ptesCobro, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_SelectPendientesCobro";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contratoD", SqlDbType.Int, ptesCobro.Desde.ContratoD, ParameterDirection.Input));
                parametros.Add(new dParameter("contratoH", SqlDbType.Int, ptesCobro.Hasta.ContratoH, ParameterDirection.Input));
                parametros.Add(new dParameter("periodoD", 6, SqlDbType.VarChar, ptesCobro.Desde.PeriodoD, ParameterDirection.Input));
                parametros.Add(new dParameter("periodoH", 6, SqlDbType.VarChar, ptesCobro.Hasta.PeriodoH, ParameterDirection.Input));
                parametros.Add(new dParameter("importeD", SqlDbType.Money, ptesCobro.Desde.ImporteD, ParameterDirection.Input));
                parametros.Add(new dParameter("importeH", SqlDbType.Money, ptesCobro.Hasta.ImporteH, ParameterDirection.Input));
                // El parámetro 'incilecLecUltFra' se le pueden pasar varias incidencias, separados por ';', ejemplo: 1;2;4
                parametros.Add(new dParameter("xmlIncLecUltFac", SqlDbType.Text, ptesCobro.IncilecLecturaUltimaFactura, ParameterDirection.Input));
                // El parámetro 'incilecLecAlgunaFra' se le pueden pasar varias incidencias, separados por ';', ejemplo: 1;2;4
                parametros.Add(new dParameter("xmlIncLecAlgunaFac", SqlDbType.Text, ptesCobro.IncilecLecturaAlgunaFactura, ParameterDirection.Input));
                // El parámetro 'incilecInspector' se le pueden pasar varias incidencias, separados por ';', ejemplo: 1;2;4
                parametros.Add(new dParameter("xmlIncLecInspec", SqlDbType.Text, ptesCobro.InicilecInspeccion, ParameterDirection.Input));

                parametros.Add(new dParameter("numPeriodosDeuda", SqlDbType.Int, ptesCobro.NumPeriodosDeuda, ParameterDirection.Input));
                parametros.Add(new dParameter("baja", SqlDbType.Bit, ptesCobro.Baja, ParameterDirection.Input));
                parametros.Add(new dParameter("esServicioMedido", SqlDbType.Bit, ptesCobro.EsServicioMedido, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaD", SqlDbType.DateTime, ptesCobro.Desde.FechaD, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaH", SqlDbType.DateTime, ptesCobro.Hasta.FechaH, ParameterDirection.Input));
                parametros.Add(new dParameter("servicioCodigo", SqlDbType.SmallInt, ptesCobro.ServicioCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("zonaD", 4, SqlDbType.VarChar, ptesCobro.Desde.ZonaD, ParameterDirection.Input));
                parametros.Add(new dParameter("zonaH", 4, SqlDbType.VarChar, ptesCobro.Hasta.ZonaH, ParameterDirection.Input));
                parametros.Add(new dParameter("tarifaD", SqlDbType.SmallInt, ptesCobro.Desde.TarifaD, ParameterDirection.Input));
                parametros.Add(new dParameter("tarifaH", SqlDbType.SmallInt, ptesCobro.Hasta.TarifaH, ParameterDirection.Input));
                parametros.Add(new dParameter("usoCodigo", SqlDbType.Int, ptesCobro.UsoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("apremiado", SqlDbType.Bit, ptesCobro.Apremiado, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);

                            //Añadimos campos de este procedimiento
                            facturaBO.TotalCobrado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["cobrado"]);
                            facturaBO.TotalFacturado = GetDbNullableDecimal(datos.Tables[0].Rows[i]["facturado"]);

                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas por contrato
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="contratoBO">codigo del Contrato</param>
        /// <param name="ordenDesc">Determina si se desea que se ordene de forma descendente</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerPorContrato(ref cBindableList<cFacturaBO> facturas, cContratoBO contratoBO, bool? ordenDesc, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoBO.Codigo, ParameterDirection.Input));
                parametros.Add(new dParameter("ordenDesc", SqlDbType.Bit, ordenDesc, ParameterDirection.Input));
                parametros.Add(new dParameter("versionContratoHasta", SqlDbType.SmallInt, DBNullIfZero(contratoBO.Version), ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas por contrato
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="ordenDesc">Determina si se desea que se ordene de forma descendente</param>
        /// <param name="ctrVersionDesde">Versión del contrato desde</param>
        /// <param name="ctrVersionHasta">Versión del contrato hasta</param>
        /// <param name="numeroPeriodos">Número de periodos facturados</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool ObtenerPorContrato(ref cBindableList<cFacturaBO> facturas, int contratoCodigo, bool? ordenDesc, short? ctrVersionDesde, short? ctrVersionHasta, int? numeroPeriodos, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("ordenDesc", SqlDbType.Bit, ordenDesc, ParameterDirection.Input));
                parametros.Add(new dParameter("versionContratoHasta", SqlDbType.SmallInt, ctrVersionHasta, ParameterDirection.Input));
                parametros.Add(new dParameter("versionContratoDesde", SqlDbType.SmallInt, ctrVersionDesde, ParameterDirection.Input));
                parametros.Add(new dParameter("numeroPeriodos", SqlDbType.Int, numeroPeriodos, ParameterDirection.Input));
                parametros.Add(new dParameter("verTodas", SqlDbType.Bit, 1, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas de un periodo y una zona (todas las versiones de factura)
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="zonaCodigo">Código de la zona</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerPorPeriodoYZona(ref cBindableList<cFacturaBO> facturas, string periodoCodigo, string zonaCodigo, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zonaCodigo, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene las facturas de un periodo, una zona y un lote(todas las versiones de factura)
        /// </summary>
        /// <param name="facturas">Lista enlazable</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="zonaCodigo">Código de la zona</param>
        /// <param name="lote">Número del lote</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerPorPeriodoZonaYLote(ref cBindableList<cFacturaBO> facturas, string periodoCodigo, string zonaCodigo, int lote, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            DataSet datos = null;
            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zonaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("loteDesde", SqlDbType.Int, lote, ParameterDirection.Input));
                parametros.Add(new dParameter("loteHasta", SqlDbType.Int, lote, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO facturaBO;
                        for (int i = 0; i < registros; i++)
                        {
                            facturaBO = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (facturaBO != null)
                                facturas.Add(facturaBO);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Actualizar lineas de factura/s (unidades,total,importe impuesto y la base), según el consumo de la cabecera.
        /// Se puede filtrar por Periodo,Contrato y Version
        /// </summary>
        /// <param name="factura">objeto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ActualizarLineas(cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                dValidator validador = new dValidator();
                int regAfectados = 0;
                string sqlCommand = "Facturas_ActualizarLineas";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("facturaCodigo", SqlDbType.SmallInt, factura.FacturaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, factura.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("version", SqlDbType.SmallInt, factura.Version, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out regAfectados);
                if (!resultado)
                {
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}, {6} {7}", Resource.periodo, factura.PeriodoCodigo, Resource.contrato, factura.ContratoCodigo, Resource.version, factura.Version, Resource.factura, factura.FacturaCodigo)));
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

        /// <summary>
        /// Actualizar lineas de todas las facturas, según el consumo de la cabecera. Son obligatorios pasarle 
        /// los siguientes campos, zonaCodigo, periodoCodigo, loteD, loteH.
        /// </summary>
        /// <param name="zonaCodigo">Código de la zona</param>
        /// <param name="periodoCodigo">Código del período</param>
        /// <param name="loteD">Lote desde</param>
        /// <param name="loteH">Lote hasta</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ActualizarConsumoLineas(string zonaCodigo, string periodoCodigo, int loteD, int loteH, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                dValidator validador = new dValidator();
                int regAfectados = 0;
                string sqlCommand = "Facturas_ActualizarLineas";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zonaCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("loteD", SqlDbType.Int, loteD, ParameterDirection.Input));
                parametros.Add(new dParameter("loteH", SqlDbType.Int, loteH, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out regAfectados);
                if (!resultado)
                {
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}, {6} {7}", Resource.zona, zonaCodigo, Resource.periodo, periodoCodigo, Resource.lote, loteD, Resource.lote, loteH)));
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

        public bool ObtenerLecturas(ref cBindableList<cFacturaBO> facturas, string periodo, string zona, int loteD, int loteH, int? ctrCodDesde, int? ctrCodHasta, string orden, bool soloPendientes, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            try
            {
                respuesta = new cRespuesta();
                string sqlCommand = "Facturas_SelectLecturas";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("soloPendientes", SqlDbType.Bit, soloPendientes, ParameterDirection.Input));


                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
                parametros.Add(new dParameter("loteDesde", SqlDbType.Int, loteD, ParameterDirection.Input));
                parametros.Add(new dParameter("loteHasta", SqlDbType.Int, loteH, ParameterDirection.Input));
                parametros.Add(new dParameter("contratoCodDesde", SqlDbType.Int, DBNullIfNull(ctrCodDesde), ParameterDirection.Input));
                parametros.Add(new dParameter("contratoCodHasta", SqlDbType.Int, DBNullIfNull(ctrCodHasta), ParameterDirection.Input));
                parametros.Add(new dParameter("orden", 10, SqlDbType.VarChar, orden, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        public bool Obtener(ref cBindableList<cFacturaBO> facturas, string periodo, string zona, bool? inspeccionables, int? ctrCodDesde, int? ctrCodHasta, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            try
            {
                respuesta = new cRespuesta();
                string sqlCommand = "Facturas_Select";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("soloInspeccionables", SqlDbType.Bit, inspeccionables, ParameterDirection.Input));


                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
                parametros.Add(new dParameter("contratoDesde", SqlDbType.Int, DBNullIfNull(ctrCodDesde), ParameterDirection.Input));
                parametros.Add(new dParameter("contratoHasta", SqlDbType.Int, DBNullIfNull(ctrCodHasta), ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        /// <summary>
        /// Comprueba si existen registros
        /// </summary>
        /// <param name="parametros"> parametros </param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve TRUE si existen , FALSE en caso contrario</returns>
        public bool Existen(cFacturaBO facturaBO, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();

            try
            {
                //Aplicar parámetros
                //facturaBO
                dParamsCollection dbParams = new dParamsCollection();
                dbParams.Add(new dParameter("facCod", SqlDbType.SmallInt, facturaBO.FacturaCodigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("facpercod", 6, SqlDbType.VarChar, facturaBO.PeriodoCodigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("facCtrCod", SqlDbType.Int, facturaBO.ContratoCodigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("facVersion", SqlDbType.SmallInt, facturaBO.Version, ParameterDirection.Input));
                dbParams.Add(new dParameter("exists", SqlDbType.Bit, ParameterDirection.Output));
                string sqlCommand = "Facturas_Exists";

                resultado = ExecSPWithParams(sqlCommand, ref dbParams);

                if (resultado)
                    resultado = Convert.ToBoolean(dbParams.Get("exists").Valor);
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

            return resultado;
        }

        /// <summary>
        /// Comprueba si existen registros
        /// </summary>
        /// <param name="periodo">Periodo</param>
        /// <param name="zona">Zona</param>
        /// <param name="tieneLecturaLector">Tiene lectura lector</param>
        /// <param name="respuesta">respuesta</param>
        /// <returns>Devuelve TRUE si existen , FALSE en caso contrario</returns>
        public bool Existen(string periodo, string zona, bool tieneLecturaLector, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();

            try
            {
                //Aplicar parámetros
                //facturaBO
                dParamsCollection dbParams = new dParamsCollection();
                dbParams.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                dbParams.Add(new dParameter("facZonCod", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
                dbParams.Add(new dParameter("tieneLecturaLector", SqlDbType.Bit, tieneLecturaLector, ParameterDirection.Input));
                dbParams.Add(new dParameter("exists", SqlDbType.Bit, ParameterDirection.Output));
                string sqlCommand = "Facturas_Exists";

                resultado = ExecSPWithParams(sqlCommand, ref dbParams);

                if (resultado)
                    resultado = Convert.ToBoolean(dbParams.Get("exists").Valor);
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

            return resultado;
        }

        /// <summary>
        /// Realización del proceso de apertura de un contrato
        /// </summary>
        /// <param name="facturaBO">Objeto factura.Campos requeridos: PeriodoCod,contratoCod,
        /// Dentro del Objeto contrato contratoVersion,clienteCod,zonaCod,LecturaAnterior,FechaLecturaAnterior,la fechaInicio y FechaAnulación.</param>
        /// <param name="usuario">Código de usuario</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <param name="fechaPeriodoDesde">Fecha inicio del periodo</param>
        /// <param name="fechaPeriodoHasta">Fecha fin del periodo</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool Apertura(cFacturaBO facturaBO, string usuario, DateTime fechaPeriodoDesde, DateTime fechaPeriodoHasta, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;

            try
            {
                string sqlCommand = "Facturas_InsertApertura";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("facPerCod", 6, SqlDbType.VarChar, facturaBO.PeriodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facCtrCod", SqlDbType.Int, facturaBO.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facCtrVersion", SqlDbType.SmallInt, facturaBO.Contrato.Version, ParameterDirection.Input));
                parametros.Add(new dParameter("facClicod", SqlDbType.Int, facturaBO.Contrato.TitularCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facZonCod", 4, SqlDbType.VarChar, facturaBO.Contrato.ZonCod, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAnt", SqlDbType.Int, facturaBO.LecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("facLecAntFec", SqlDbType.DateTime, facturaBO.FechaLecturaAnterior, ParameterDirection.Input));
                parametros.Add(new dParameter("user", 10, SqlDbType.VarChar, usuario, ParameterDirection.Input));

                parametros.Add(new dParameter("ctrFecIni", SqlDbType.DateTime, facturaBO.Contrato.FInicio, ParameterDirection.Input));
                parametros.Add(new dParameter("ctrFecAnu", SqlDbType.DateTime, facturaBO.Contrato.FAnulacion, ParameterDirection.Input));

                parametros.Add(new dParameter("fechaPeriodoDesde", SqlDbType.DateTime, fechaPeriodoDesde, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaPeriodoHasta", SqlDbType.DateTime, fechaPeriodoHasta, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (!resultado)
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Realización del proceso de apertura de un periodo/zona
        /// </summary>
        public cRespuesta Apertura(string zona, string periodo, DateTime fechaPeriodoDesde, DateTime fechaPeriodoHasta, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasInsertadas)
        {
            cRespuesta respuesta = new cRespuesta();
            facturasInsertadas = 0;

            dParamsCollection parametros = new dParamsCollection();
            parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
            parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
            parametros.Add(new dParameter("fechaPeriodoDesde", SqlDbType.DateTime, fechaPeriodoDesde, ParameterDirection.Input));
            parametros.Add(new dParameter("fechaPeriodoHasta", SqlDbType.DateTime, fechaPeriodoHasta, ParameterDirection.Input));
            parametros.Add(new dParameter("tskUser", 10, SqlDbType.VarChar, taskUser, ParameterDirection.Input));
            parametros.Add(new dParameter("tskType", SqlDbType.SmallInt, taskType, ParameterDirection.Input));
            parametros.Add(new dParameter("tskNumber", SqlDbType.Int, taskNumber, ParameterDirection.Input));
            parametros.Add(new dParameter("facturasInsertadas", SqlDbType.Int, ParameterDirection.Output));

            if (ExecSPWithParams("Tasks_Facturas_Apertura", ref parametros))
                facturasInsertadas = Convert.ToInt32(parametros.Get("facturasInsertadas").Valor);
            else
                respuesta.Resultado = ResultadoProceso.Error;

            return respuesta;
        }

        /// <summary>
        /// Realiza una ampliación de apertura
        /// </summary>
        public cRespuesta AmpliacionDeApertura(string zona, string periodo, int? contratoCodigo, bool anadirContratosNuevos, bool anadirServiciosNuevos, bool reinsertarServiciosExistentes, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasAfectadas)
        {
            cRespuesta respuesta = new cRespuesta();
            facturasAfectadas = 0;

            dParamsCollection parametros = new dParamsCollection();
            parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
            parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
            parametros.Add(new dParameter("contratoCodigo", SqlDbType.Int, contratoCodigo, ParameterDirection.Input));
            parametros.Add(new dParameter("anadirContratosNuevos", SqlDbType.Bit, anadirContratosNuevos, ParameterDirection.Input));
            parametros.Add(new dParameter("anadirServiciosNuevos", SqlDbType.Bit, anadirServiciosNuevos, ParameterDirection.Input));
            parametros.Add(new dParameter("reinsertarServiciosExistentes", SqlDbType.Bit, reinsertarServiciosExistentes, ParameterDirection.Input));
            parametros.Add(new dParameter("tskUser", 10, SqlDbType.VarChar, taskUser, ParameterDirection.Input));
            parametros.Add(new dParameter("tskType", SqlDbType.SmallInt, taskType, ParameterDirection.Input));
            parametros.Add(new dParameter("tskNumber", SqlDbType.Int, taskNumber, ParameterDirection.Input));
            parametros.Add(new dParameter("facturasAfectadas", SqlDbType.Int, ParameterDirection.Output));

            if (!ExecSPWithParams("Tasks_Facturas_AmpliacionApertura", ref parametros))
                respuesta.Resultado = ResultadoProceso.Error;
            else
                facturasAfectadas = Convert.ToInt32(parametros.Get("facturasAfectadas").Valor);

            return respuesta;
        }

        /// <summary>
        /// Elimina una apertura de facturación (facturas, registros de perzonalote y perzona)
        /// </summary>
        /// <param name="zona">zona</param>
        /// <param name="periodo">periodo</param>
        /// <param name="facturasEliminadas">Nº de facturas que han sido borradas</param>
        /// <returns>respuesta</returns>
        public cRespuesta EliminarApertura(string zona, string periodo, out int facturasEliminadas)
        {
            cRespuesta respuesta = new cRespuesta();
            facturasEliminadas = 0;

            try
            {
                string sqlCommand = "Facturas_EliminarApertura";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
                parametros.Add(new dParameter("facturasEliminadas", SqlDbType.Int, ParameterDirection.Output));

                if (ExecSPWithParams(sqlCommand, ref parametros))
                    facturasEliminadas = (int)parametros.Get("facturasEliminadas").Valor;
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return respuesta;
        }

        /// <summary>
        /// Realiza el cierre de una zona/periodo
        /// </summary>
        public cRespuesta Cierre(string zona, string periodo, DateTime fecha, short serie, short sociedad, string usuario, bool actualizarVersionContrato, bool actualizarTipoImpuesto, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasProcesadas, out int facturasTotales)
        {
            cRespuesta respuesta = new cRespuesta();
            facturasProcesadas = facturasTotales = 0;

            dParamsCollection parametros = new dParamsCollection();
            parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
            parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
            parametros.Add(new dParameter("fecha", SqlDbType.DateTime, fecha, ParameterDirection.Input));
            parametros.Add(new dParameter("serie", SqlDbType.SmallInt, serie, ParameterDirection.Input));
            parametros.Add(new dParameter("sociedad", SqlDbType.SmallInt, sociedad, ParameterDirection.Input));
            parametros.Add(new dParameter("usuario", 10, SqlDbType.VarChar, usuario, ParameterDirection.Input));
            parametros.Add(new dParameter("actualizarVersionContrato", SqlDbType.Bit, actualizarVersionContrato, ParameterDirection.Input));
            parametros.Add(new dParameter("actualizarTipoImpuesto", SqlDbType.Bit, actualizarTipoImpuesto, ParameterDirection.Input));

            parametros.Add(new dParameter("tskUser", 10, SqlDbType.VarChar, taskUser, ParameterDirection.Input));
            parametros.Add(new dParameter("tskType", SqlDbType.SmallInt, taskType, ParameterDirection.Input));
            parametros.Add(new dParameter("tskNumber", SqlDbType.Int, taskNumber, ParameterDirection.Input));

            parametros.Add(new dParameter("facturasProcesadas", SqlDbType.Int, ParameterDirection.Output));
            parametros.Add(new dParameter("facturasTotales", SqlDbType.Int, ParameterDirection.Output));

            if (ExecSPWithParams("Tasks_Facturas_Cierre", ref parametros))
            {
                facturasProcesadas = Convert.ToInt32(parametros.Get("facturasProcesadas").Valor);
                facturasTotales = Convert.ToInt32(parametros.Get("facturasTotales").Valor);
            }
            else
                respuesta.Resultado = ResultadoProceso.Error;

            return respuesta;
        }

        /// <summary>
        /// Cierre de una factura
        /// </summary>
        /// <param name="facturacionCierreBO">Contiene los datos para realizar el cierre</param>
        /// <param name="facturasProcesadas">Facturas que han sido cerradas</param>
        /// <param name="facturasTotales">Facturas totales de la selección</param>
        /// <param name="respuesta">Resultado de la operación</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public bool Cierre(cFacturacionCierreBO facturacionCierreBO, out int facturasProcesadas, out int facturasTotales, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            bool resultado = false;
            facturasTotales = 0;
            facturasProcesadas = 0;

            try
            {
                string sqlCommand = "Tasks_Facturas_Cierre";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, facturacionCierreBO.Zona, ParameterDirection.Input));
                parametros.Add(new dParameter("contrato", SqlDbType.Int, facturacionCierreBO.Contrato, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, facturacionCierreBO.Periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("fecha", SqlDbType.DateTime, facturacionCierreBO.Fecha, ParameterDirection.Input));
                parametros.Add(new dParameter("sociedad", SqlDbType.SmallInt, facturacionCierreBO.Sociedad, ParameterDirection.Input));
                parametros.Add(new dParameter("serie", SqlDbType.SmallInt, facturacionCierreBO.Serie, ParameterDirection.Input));
                parametros.Add(new dParameter("usuario", 10, SqlDbType.VarChar, facturacionCierreBO.Usuario, ParameterDirection.Input));
                parametros.Add(new dParameter("facturasProcesadas", SqlDbType.Int, ParameterDirection.Output));
                parametros.Add(new dParameter("facturasTotales", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros);
                if (resultado)
                {
                    facturasProcesadas = GetDbInt(parametros.Get("facturasProcesadas").Valor);
                    facturasTotales = GetDbInt(parametros.Get("facturasTotales").Valor);
                }
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Actualiza facturas a la última versión del contrato
        /// </summary>
        public cRespuesta ActualizarALaUltimaVersionDelContrato(string zona, string periodo, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasAfectadas)
        {
            facturasAfectadas = 0;
            cRespuesta respuesta = new cRespuesta();
            dParamsCollection parametros = new dParamsCollection();

            parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
            parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
            parametros.Add(new dParameter("facturasAfectadas", SqlDbType.Int, ParameterDirection.Output));

            parametros.Add(new dParameter("tskUser", 10, SqlDbType.VarChar, taskUser, ParameterDirection.Input));
            parametros.Add(new dParameter("tskType", SqlDbType.SmallInt, taskType, ParameterDirection.Input));
            parametros.Add(new dParameter("tskNumber", SqlDbType.Int, taskNumber, ParameterDirection.Input));

            if (ExecSPWithParams("Tasks_Facturas_ActualizarUltimaVersionDelContrato", ref parametros))
                facturasAfectadas = Convert.ToInt32(parametros.Get("facturasAfectadas").Valor);
            else
                respuesta.Resultado = ResultadoProceso.Error;

            return respuesta;
        }

        /// <summary>
        /// Obtiene por contrato, serie y número
        /// </summary>
        /// <param name="contrato">Código del contrato</param>
        /// <param name="serie">Código de la serie</param>
        /// <param name="numero">Número de la factura a obtener</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public cFacturaBO ObtenerPorContratoSerieYNumero(int contrato, short serie, string numero, out cRespuesta respuesta)
        {
            cFacturaBO factura = null;
            DataSet datos = null;
            respuesta = new cRespuesta();

            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, contrato, ParameterDirection.Input));
                parametros.Add(new dParameter("serie", SqlDbType.SmallInt, serie, ParameterDirection.Input));
                parametros.Add(new dParameter("numero", 20, SqlDbType.VarChar, numero, ParameterDirection.Input));

                if (ExecSPWithParams(sqlCommand, ref parametros, out datos))
                {
                    if (datos.Tables[0].Rows.Count > 0)
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            finally
            {
                if (datos != null)
                    datos.Dispose();
            }

            return factura;
        }

        /// <summary>
        /// Obtiene por serie y número
        /// </summary>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="serie">Código de la serie</param>
        /// <param name="numero">Número de la factura a obtener</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public cFacturaBO ObtenerPorPeriodoSerieYNumero(string periodoCodigo, short serie, string numero, out cRespuesta respuesta)
        {
            cFacturaBO factura = null;
            DataSet datos = null;
            respuesta = new cRespuesta();

            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("serie", SqlDbType.SmallInt, serie, ParameterDirection.Input));
                parametros.Add(new dParameter("numero", 20, SqlDbType.VarChar, numero, ParameterDirection.Input));

                if (ExecSPWithParams(sqlCommand, ref parametros, out datos))
                {
                    if (datos.Tables[0].Rows.Count > 0)
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            finally
            {
                if (datos != null)
                    datos.Dispose();
            }

            return factura;
        }

        /// <summary>
        /// Obtiene por sociedad, serie y número
        /// </summary>
        /// <param name="sociedad">Código de la sociedad</param>
        /// <param name="serie">Código de la serie</param>
        /// <param name="numero">Número de la factura a obtener</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public cFacturaBO ObtenerPorSociedadSerieYNumero(short sociedad, short serie, string numero, out cRespuesta respuesta)
        {
            cFacturaBO factura = null;
            DataSet datos = null;
            respuesta = new cRespuesta();

            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("sociedad", SqlDbType.SmallInt, sociedad, ParameterDirection.Input));
                parametros.Add(new dParameter("serie", SqlDbType.SmallInt, serie, ParameterDirection.Input));
                parametros.Add(new dParameter("numero", 20, SqlDbType.VarChar, numero, ParameterDirection.Input));

                if (ExecSPWithParams(sqlCommand, ref parametros, out datos))
                {
                    if (datos.Tables[0].Rows.Count > 0)
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            finally
            {
                if (datos != null)
                    datos.Dispose();
            }

            return factura;
        }

        /// <summary>
        /// Obtiene código de la factura a partir del periodo y contrato pasado por parámetro
        /// </summary>
        ///<param name="periodoCodigo">Código del periodo</param>
        /// <param name="contratoCodgigo">Código del contrato</param>
        /// <param name="facturaCodigo">Parámetro de salida con el código de la factura</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public cRespuesta ObtenerCodigo(string periodoCodigo, int? contratoCodgigo, out short? facturaCodigo)
        {
            cRespuesta respuesta = new cRespuesta();
            facturaCodigo = 0;
            try
            {
                //Aplicar parámetros
                dParamsCollection dbParams = new dParamsCollection();
                dbParams.Add(new dParameter("facpercod", 6, SqlDbType.VarChar, periodoCodigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("facCtrCod", SqlDbType.Int, contratoCodgigo, ParameterDirection.Input));
                dbParams.Add(new dParameter("facCod", SqlDbType.SmallInt, ParameterDirection.Output));

                string sqlCommand = "Facturas_ObtenerCodigo";
                if (!ExecSPWithParams(sqlCommand, ref dbParams))
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtener);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
                else
                    facturaCodigo = GetDbNullableShort(dbParams.Get("facCod").Valor);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return respuesta;
        }

        /// <summary>
        /// Obtiene facturas por contrato y orden de trabajo
        /// </summary>
        /// <param name="ot">Objeto orden de trabajo, obligatorio rellenar el código del contrato, la sociedad, serie y número</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Lista de facturas</returns>
        public cBindableList<cFacturaBO> ObtenerPorContratoYOrdenTrabajo(cOrdenTrabajoBO ot, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();

            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, ot.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("facSerScdCod", SqlDbType.SmallInt, ot.Serscd, ParameterDirection.Input));
                parametros.Add(new dParameter("facOTSerCod", SqlDbType.SmallInt, ot.Sercod, ParameterDirection.Input));
                parametros.Add(new dParameter("facOTNum", SqlDbType.Int, ot.Numero, ParameterDirection.Input));

                resultado = ExecSPWithParams(storedProcedure, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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

            return facturas;
        }

        /// <summary>
        /// Obtiene un registro de la tabla Facturas que sea del último periodo facturado
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerUltimoPeriodoCerrado(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                string sqlCommand = "Facturas_Select";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contrato", SqlDbType.Int, factura.ContratoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("soloPeriodicas", SqlDbType.Bit, 1, ParameterDirection.Input));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    if (datos.Tables[0].Rows.Count > 0)
                    {
                        factura = RellenarEntidad(datos.Tables[0].Rows[0], out respuesta);
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;
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

        /// <summary>
        /// Obtiene las facturas en las cuales no está reflejada una bonificación para un contrato, versión
        /// </summary>
        /// <param name="facCtrCod">Código del contrato</param>
        /// <param name="facCtrVersion">Versión del contrato</param>
        /// <param name="respuesta">Objeto respuesta con el resultado de la operación</param>
        /// <returns>Lista de facturas</returns>
        public cBindableList<cFacturaBO> ObtenerSinBonificar(int? facCtrCod, short? facCtrVersion, out cRespuesta respuesta)
        {
            bool resultado = false;
            DataSet datos = null;
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();

            try
            {
                respuesta = new cRespuesta();
                string storedProcedure = "Facturas_SelectSinBonificar";

                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contratoCodigo", SqlDbType.Int, facCtrCod, ParameterDirection.Input));
                parametros.Add(new dParameter("contratoVersion", SqlDbType.SmallInt, facCtrVersion, ParameterDirection.Input));

                resultado = ExecSPWithParams(storedProcedure, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cFacturaBO factura;
                        for (int i = 0; i < registros; i++)
                        {
                            factura = RellenarEntidad(datos.Tables[0].Rows[i], out respuesta);
                            if (factura != null)
                                facturas.Add(factura);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
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
            return facturas;
        }

        /// <summary>
        /// Simula una factura a partir del contrato y el consumo (contrato, consumo)
        /// </summary>
        /// <param name="contrato">Código del contrato</param>
        /// <param name="consumo">Consumo a simular</param>
        /// <param name="numeroHabitantes">Número de habitantes por suministro</param>
        /// <param name="importeTotal">Importe total calculado</param>
        /// <param name="cnsHabDia">Consumo por habitante y día en litros</param>
        /// <returns>Respuesta con el resultado de la operación</returns>
        public cRespuesta SimularConsumo(int contrato, int consumo, int? numeroHabitantes, out decimal importeTotal, out int? cnsHabDia)
        {
            cRespuesta respuesta = new cRespuesta();
            importeTotal = 0;
            cnsHabDia = null;

            try
            {
                string sqlCommand = "Facturas_SimularConsumo";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contratoCodigo", SqlDbType.Int, contrato, ParameterDirection.Input));
                parametros.Add(new dParameter("consumo", SqlDbType.Int, consumo, ParameterDirection.Input));
                parametros.Add(new dParameter("numeroHabitantes", SqlDbType.Int, numeroHabitantes, ParameterDirection.Input));
                parametros.Add(new dParameter("importeTotal", SqlDbType.Money, ParameterDirection.Output));
                parametros.Add(new dParameter("cnsPorHabDia", SqlDbType.Int, ParameterDirection.Output));

                if (ExecSPWithParams(sqlCommand, ref parametros))
                {
                    importeTotal = GetDbDecimal(parametros.Get("importeTotal").Valor);
                    cnsHabDia = GetDbNullableInt(parametros.Get("cnsPorHabDia").Valor);
                }
                else
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta;
        }

        /// <summary>
        /// Simula una factura a partir del contrato y el consumo (contrato, consumo)
        /// </summary>
        /// <param name="contrato">Código del contrato</param>
        /// <param name="consumo">Consumo a simular</param>
        /// <param name="numeroHabitantes">Número de habitantes por suministro</param>
        /// <param name="importeTotal">Importe total calculado</param>
        /// <param name="cnsHabDia">Consumo por habitante y día en litros</param>
        /// <returns>Respuesta con el resultado de la operación</returns>
        public cRespuesta SimularConsumoDetallado(int contrato, int consumo, int? numeroHabitantes, out cBindableList<cSimuladorDetalladoBO> serviciosSimulados)
        {
            bool resultado = false;
            cRespuesta respuesta = new cRespuesta();
            DataSet datos = null;
            serviciosSimulados = new cBindableList<cSimuladorDetalladoBO>();
            try
            {
                string sqlCommand = "Facturas_SimularConsumo_detallado";
                dParamsCollection parametros = new dParamsCollection();
                parametros.Add(new dParameter("contratoCodigo", SqlDbType.Int, contrato, ParameterDirection.Input));
                parametros.Add(new dParameter("consumo", SqlDbType.Int, consumo, ParameterDirection.Input));
                parametros.Add(new dParameter("numeroHabitantes", SqlDbType.Int, numeroHabitantes, ParameterDirection.Input));
                //parametros.Add(new dParameter("importeTotal", SqlDbType.Money, ParameterDirection.Output));
                //parametros.Add(new dParameter("cnsPorHabDia", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out datos);

                if (resultado)
                {
                    int registros = datos.Tables[0].Rows.Count;
                    if (registros > 0)
                    {
                        cSimuladorDetalladoBO simulador;
                        for (int i = 0; i < registros; i++)
                        {
                            simulador = RellenarEntidadSimulador(datos.Tables[0].Rows[i], out respuesta);
                            if (simulador != null)
                                serviciosSimulados.Add(simulador);
                        }
                        respuesta.Resultado = ResultadoProceso.OK;
                    }
                    else
                        respuesta.Resultado = ResultadoProceso.SinRegistros;

                }
                else
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoObtenerVarios);
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta;
        }

        /// <summary>
        /// Comprueba si existe cambio de tarifa a mitad de periodo
        /// </summary>
        /// <param name="periodo">Periodo</param>
        /// <param name="respuesta">respuesta</param>
        /// <returns>Devuelve TRUE si existen , FALSE en caso contrario</returns>
        public bool ExisteCambioTarifa(string periodo, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();

            try
            {
                //Aplicar parámetros
                //facturaBO
                dParamsCollection dbParams = new dParamsCollection();
                dbParams.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                dbParams.Add(new dParameter("exists", SqlDbType.Bit, ParameterDirection.Output));
                string sqlCommand = "Facturas_ExisteCambioTarifa";

                resultado = ExecSPWithParams(sqlCommand, ref dbParams);

                if (resultado)
                    resultado = Convert.ToBoolean(dbParams.Get("exists").Valor);
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
            return resultado;
        }

        /// <summary>
        /// Obtener si los diferidos de un periodo-zona deben aplicarse sólo a una factura concreta (true)
        /// </summary>
        /// <param name="zona"></param>
        /// <param name="difPeriodoAplicacion"></param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si deben aplicarse sólo a una factura concreta, False en caso contrario</returns>
        public bool ObtenerAplicarDiferidosSoloEnUnaFactura(string zona, string difPeriodoAplicacion, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();

            try
            {
                //Aplicar parámetros
                //facturaBO
                dParamsCollection dbParams = new dParamsCollection();
                dbParams.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
                dbParams.Add(new dParameter("difPeriodoAplicacion", 6, SqlDbType.VarChar, difPeriodoAplicacion, ParameterDirection.Input));
                dbParams.Add(new dParameter("soloEnUnaFactura", SqlDbType.Bit, ParameterDirection.Output));
                string sqlCommand = "Facturas_AplicarDiferidosSoloEnUnaFactura";

                resultado = ExecSPWithParams(sqlCommand, ref dbParams);

                if (resultado)
                    resultado = Convert.ToBoolean(dbParams.Get("soloEnUnaFactura").Valor);
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
            return resultado;
        }

        /// <summary>
        /// Marca como liquidado una línea en factura
        /// </summary>
        /// <param name="seleccion">selección de pendientes de cobro</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool LiquidarServiciosEnFacturas(SeleccionPtesCobro seleccion, string usuarioCodigo, out cRespuesta respuesta, out int registrosProcesados)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            registrosProcesados = 0;

            if (seleccion == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            try
            {
                string sqlCommand = "Liquidaciones_Update_FechaLiquidacionImpuesto";

                dParamsCollection parametros = new dParamsCollection();

                parametros.Add(new dParameter("fechaFacturaD", SqlDbType.DateTime, seleccion.Desde.FechaD, ParameterDirection.Input));
                parametros.Add(new dParameter("fechaFacturaH", SqlDbType.DateTime, seleccion.Hasta.FechaH, ParameterDirection.Input));
                parametros.Add(new dParameter("periodoD", 6, SqlDbType.VarChar, seleccion.Desde.PeriodoD, ParameterDirection.Input));
                parametros.Add(new dParameter("periodoH", 6, SqlDbType.VarChar, seleccion.Hasta.PeriodoH, ParameterDirection.Input));
                parametros.Add(new dParameter("tarifaD", SqlDbType.SmallInt, seleccion.Desde.TarifaD, ParameterDirection.Input));
                parametros.Add(new dParameter("tarifaH", SqlDbType.SmallInt, seleccion.Hasta.TarifaH, ParameterDirection.Input));
                parametros.Add(new dParameter("usoCod", SqlDbType.Int, seleccion.UsoCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("srvCod", SqlDbType.SmallInt, seleccion.ServicioCodigo, ParameterDirection.Input));
                parametros.Add(new dParameter("fclFecLiqImpuesto", SqlDbType.DateTime, AcuamaDateTime.Now, ParameterDirection.Input));
                parametros.Add(new dParameter("fclUsrLiqImpuesto", 10, SqlDbType.VarChar, usuarioCodigo, ParameterDirection.Input));

                parametros.Add(new dParameter("regAfectados", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out registrosProcesados);

                registrosProcesados = int.Parse(parametros.GetValue("regAfectados").ToString());

                if (!resultado)
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                    resultado = false;
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Aplica sanción del 100% de m3 facturados por zona a las facturas afectadas
        /// </summary>
        /// <param name="zona">zona</param>
        /// <param name="periodo">periodo</param>
        /// <param name="incidencias">incidencias de lectura separadas por ;</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool AplicarSancion100porZona(string zona, string periodo, string incidencias, string usuarioCodigo, out cRespuesta respuesta, out int registrosProcesados)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            registrosProcesados = 0;

            try
            {
                string sqlCommand = "Facturas_AplicarSancion100porZona";

                dParamsCollection parametros = new dParamsCollection();

                parametros.Add(new dParameter("zona", 4, SqlDbType.VarChar, zona, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("incidencias", 50, SqlDbType.VarChar, incidencias, ParameterDirection.Input));

                parametros.Add(new dParameter("regAfectados", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out registrosProcesados);

                registrosProcesados = int.Parse(parametros.GetValue("regAfectados").ToString());

                if (!resultado)
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                    resultado = false;
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Aplica sanción del 100% de m3 facturados por contrato
        /// </summary>
        /// <param name="contrato">contrato</param>
        /// <param name="periodo">periodo</param>
        /// <param name="aplicar">booleano que indica si aplicar o deshacer sanción</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool AplicarSancion100porContrato(int contrato, string periodo, bool aplicar, string usuarioCodigo, out cRespuesta respuesta, out int registrosProcesados)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            registrosProcesados = 0;

            try
            {
                string sqlCommand = "Facturas_AplicarSancion100porContrato";

                dParamsCollection parametros = new dParamsCollection();

                parametros.Add(new dParameter("contrato", SqlDbType.Int, contrato, ParameterDirection.Input));
                parametros.Add(new dParameter("periodo", 6, SqlDbType.VarChar, periodo, ParameterDirection.Input));
                parametros.Add(new dParameter("aplicar", SqlDbType.Bit, aplicar, ParameterDirection.Input));

                parametros.Add(new dParameter("regAfectados", SqlDbType.Int, ParameterDirection.Output));

                resultado = ExecSPWithParams(sqlCommand, ref parametros, out registrosProcesados);

                registrosProcesados = int.Parse(parametros.GetValue("regAfectados").ToString());

                if (!resultado)
                {
                    dValidator validador = new dValidator();
                    validador.AddCustomMessage(Resource.errorNoActualizado.Replace("@item", string.Format("{0} {1}, {2} {3}, {4} {5}", Resource.periodo)));
                    cExcepciones.ControlarER(new Exception(validador.Validate(true)), TipoExcepcion.Informacion, out respuesta);
                    resultado = false;
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
