using BL.Almacen;
using BL.Catastro;
using BL.Cobros;
using BL.Comun;
using BL.Sistema;
using BL.Tasks;
using BO.Almacen;
using BO.Catastro;
using BO.Cobros;
using BO.Comun;
using BO.Facturacion;
using BO.Resources;
using BO.Sistema;
using BO.Tasks;
using DL.Facturacion;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Transactions;

namespace BL.Facturacion
{
    public static class cFacturasBL
    {
        /// <summary>
        /// Indica si la validación que se realiza se hace sobre la lectura o la inspección
        /// </summary>
        public enum TipoValidacion { Lectura, Inspeccion }

        /// <summary>
        /// Respuesta de la validación
        /// </summary>
        public enum TipoRespuestaValidacion { OK, Negativo, Cero, Alto, Bajo, Error }
        public class RespuestaValidacion
        {
            public RespuestaValidacion()
            {
                resultado = TipoRespuestaValidacion.OK;
                mensaje = String.Empty;
            }

            private TipoRespuestaValidacion resultado;
            public TipoRespuestaValidacion Resultado
            {
                get { return resultado; }
                set { resultado = value; }
            }

            private string mensaje;
            public string Mensaje
            {
                get { return mensaje; }
                set { mensaje = value; }
            }
        }

        /// <summary>
        /// Inserta un nuevo registro
        /// </summary>
        /// <param name="factura">Objeto a insertar</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool Insertar(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;

            try
            {
                string errorStr = Validar(factura);
                if (errorStr == String.Empty)
                {
                    //Si el periodo no es de contado (periodos 0*) se comprueba si existe la factura y se inserta
                    //if (factura.PeriodoCodigo != "000001")
                    if (!factura.PeriodoCodigo.StartsWith("0"))
                    {
                        if (Existe(factura.PeriodoCodigo, factura.ContratoCodigo.Value, out respuesta))
                            cExcepciones.ControlarER(new Exception(Resource.errorInsertarExiste.Replace("@campo", Resource.factura).Replace("@item", Resource.periodo + ": " + factura.PeriodoCodigo + ", " + Resource.contrato + ": " + factura.ContratoCodigo)), TipoExcepcion.Informacion, out respuesta);
                        else
                        {
                            //Las facturas que no son de contado, siempre se insetar con código 1
                            factura.FacturaCodigo = 1;
                            resultado = new cFacturasDL().Insertar(ref factura, out respuesta);
                        }
                    }
                    else //Si el periodo es el del contado no es necesario comprobar si existe la factura, se le suma 1 al código de factura obtenido y se insertar con el nuevo código de factura
                    {
                        //Si el envío a sap de la factura es 0 o null obtener el valor del campo serEnvSAP de la serie de la factura a insertar para establecerlo en 
                        //el campo facEnvSAP de la factura de contado
                        ObtenerSerie(ref factura, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK && factura.Serie != null)
                        {
                            if (!factura.EnvioSAP.HasValue || (factura.EnvioSAP.HasValue && !factura.EnvioSAP.Value))
                                factura.EnvioSAP = factura.Serie.EnvioSAP;

                            short? facturaCodigo = 0;
                            if (ObtenerCodigo(factura.PeriodoCodigo, factura.ContratoCodigo, out facturaCodigo).Resultado == ResultadoProceso.OK)
                                factura.FacturaCodigo = facturaCodigo;
                            else
                                factura.FacturaCodigo = 1;

                            resultado = new cFacturasDL().Insertar(ref factura, out respuesta);
                        }
                    }
                }
                else
                {
                    resultado = false;
                    cExcepciones.ControlarER(new Exception(errorStr), TipoExcepcion.Informacion, out respuesta);
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
        /// Actualiza una factura y sus líneas
        /// </summary>
        /// <param name="factura">Objeto a actualizar</param>
        /// <param name="ActualizarEnvSeres">Actualiza el estado del envio</param>
        /// <param name="log">Log con información del proceso</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ActualizarEnvSeres(String sfacSerCod, String sfacnumero, out cRespuesta respuesta)
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

                //Actualizamos la factura y sus líneas
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    //ACTUALIZAR FACTURA


                    cFacturasDL facturasDL = new cFacturasDL();
                    resultado = facturasDL.ActualizarEnvSeres(sfacSerCod, sfacnumero, out respuesta);
                    //REPARTIR CONSUMO


                    //CONFIRMAR TRANSACCIÓN
                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
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
        /// Actualiza una factura y sus líneas
        /// </summary>
        /// <param name="factura">Objeto a actualizar</param>
        /// <param name="actualizarLineas">True = Actualiza las líneas (vuelve a hacer el reparto del consumo), False = NO</param>
        /// <param name="log">Log con información del proceso</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool Actualizar(cFacturaBO factura, bool actualizarLineas, out string log, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            log = String.Empty;


            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                string errorStrLectura = ValidarLectura(factura);

                if (String.IsNullOrEmpty(errorStrLectura))
                {
                    cFacturasDL facturasDL = new cFacturasDL();
                    cPerzonaBO perzona = new cPerzonaBO();
                    //Actualizamos la factura y sus líneas
                    using (TransactionScope scope = cAplicacion.NewTransactionScope())
                    {
                        //ACTUALIZAR FACTURA
                        resultado = facturasDL.Actualizar(factura, out respuesta);
                        //REPARTIR CONSUMO
                        if (actualizarLineas && respuesta.Resultado == ResultadoProceso.OK)
                            resultado = ActualizarLineas(factura, out respuesta);
                        //Obtiene el mensaje que indica si el importe de efectos pendientes a remesar es mayor al importe pendiente
                        if (respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrEmpty(factura.PeriodoCodigo) && factura.ContratoCodigo.HasValue && factura.FacturaCodigo.HasValue && factura.SociedadCodigo.HasValue)
                            ImporteEfectoPendienteMayorAImportePendiente(factura.PeriodoCodigo, factura.ContratoCodigo.Value, factura.FacturaCodigo.Value, factura.SociedadCodigo.Value, out log, out respuesta);

                        //CONFIRMAR TRANSACCIÓN
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            scope.Complete();
                    }
                }
                else
                {
                    resultado = false;
                    cExcepciones.ControlarER(new Exception(errorStrLectura), TipoExcepcion.Informacion, out respuesta);
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
        /// Actualiza factura y sus líneas con los datos de la inspección
        /// </summary>
        /// <param name="factura">Objeto a actualizar</param>
        /// <param name="actualizarLineas">True = Actualiza las líneas (vuelve a hacer el reparto del consumo), False = NO</param>
        /// <param name="log">Log con información del proceso</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ActualizarInspecciones(cFacturaBO factura, bool actualizarLineas, int? consumoFacturaOriginal, out string log, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            log = String.Empty;

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                string errorStrLectura = ValidarLectura(factura);
                if (String.IsNullOrEmpty(errorStrLectura))
                {
                    cPerzonaBO perzona = new cPerzonaBO();
                    //Actualizamos la factura y sus líneas
                    using (TransactionScope scope = cAplicacion.NewTransactionScope())
                    {
                        //No se ha tocado el consumo factura, únicamente se ha tocado la lectura, fecha o incidencia
                        if (consumoFacturaOriginal.HasValue)
                        {
                            if (factura.ConsumoFactura == consumoFacturaOriginal || factura.ConsumoFactura == factura.ConsumoFinal)
                                factura.ConsumoFactura = consumoFacturaOriginal;
                            else
                                factura.ConsumoFinal = null;
                        }
                        //Actualizamos la factura y sus líneas
                        resultado = Actualizar(factura, true, out log, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            //Actualizar en la tabla Perzona el campo de fecha de inspección inicial y final
                            if (factura.FechaLecturaInspector.HasValue)
                            {
                                perzona.CodigoZona = factura.ZonaCodigo;
                                perzona.CodigoPeriodo = factura.PeriodoCodigo;
                                new cPerzonaBL().Obtener(ref perzona, out respuesta);
                                if (respuesta.Resultado == ResultadoProceso.OK)
                                {
                                    //Si no tienen valor se asigna la fecha de inspección, si tiene valor y según sea de inicio o de fin se asigna o sigue con la que tiene
                                    perzona.InsiniReal = perzona.InsiniReal.HasValue ? (factura.FechaLecturaInspector < perzona.InsiniReal ? factura.FechaLecturaInspector : perzona.InsiniReal) : factura.FechaLecturaInspector;
                                    perzona.InsfinReal = perzona.InsfinReal.HasValue ? (factura.FechaLecturaInspector > perzona.InsfinReal ? factura.FechaLecturaInspector : perzona.InsfinReal) : factura.FechaLecturaInspector;
                                    new cPerzonaBL().Actualizar(perzona, out respuesta);
                                }
                            }
                        }
                        //CONFIRMAR TRANSACCIÓN
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            scope.Complete();
                    }
                }
                else
                {
                    resultado = false;
                    cExcepciones.ControlarER(new Exception(errorStrLectura), TipoExcepcion.Informacion, out respuesta);
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
        public static bool MarcarRemesada(short codigo, int contrato, string periodo, short version, int? numRemesa, DateTime? fechaRemesa, out cRespuesta respuesta)
        {
            return new cFacturasDL().MarcarRemesada(codigo, contrato, periodo, version, numRemesa, fechaRemesa, out respuesta);
        }

        public static cRespuesta ObtenerRectificada(ref cFacturaBO factura)
        {
            if (factura == null || factura.Version == 1 || !factura.Version.HasValue || !factura.ContratoCodigo.HasValue || String.IsNullOrEmpty(factura.PeriodoCodigo) || !factura.FacturaCodigo.HasValue)
                return new cRespuesta(ResultadoProceso.SinRegistros);
            cRespuesta respuesta;
            cFacturaBO facturaRectificada = new cFacturaBO();
            facturaRectificada.FacturaCodigo = factura.FacturaCodigo;
            facturaRectificada.ContratoCodigo = factura.ContratoCodigo;
            facturaRectificada.PeriodoCodigo = factura.PeriodoCodigo;
            facturaRectificada.Version = (short?)(factura.Version - 1);
            Obtener(ref facturaRectificada, out respuesta);
            if (respuesta.Resultado == ResultadoProceso.OK)
                factura.FacturaRectificada = facturaRectificada;
            return respuesta;
        }

        /// <summary>
        /// Cierre de factura rectificativa de Canal, y de las que se hayan generado si es el caso
        /// </summary>
        /// <param name="factura">Factura rectificativa que se quiere cerrar</param>
        /// <param name="log"></param>
        /// <param name="respuesta"></param>
        /// <returns></returns>
        public static bool CierreAgrupandoDiferidos(cFacturaBO factura, out string log, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            log = String.Empty;

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            resultado = new cFacturasDL().CierreAgrupandoDiferidos(factura, out log, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
                resultado = true;

            return resultado;
        }

        public static bool AplicacionDiferidosEnRectificativa(cFacturaBO factura, out int diferidosAplicados, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            diferidosAplicados = 0;

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            resultado = new cFacturasDL().AplicacionDiferidosEnRectificativa(factura, out diferidosAplicados, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
                resultado = true;

            return resultado;
        }

        /// <summary>
        /// Obtiene un registro
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool Obtener(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                resultado = new cFacturasDL().Obtener(ref factura, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Genera las líneas del desglose de la factura indicada
        /// </summary>
        /// <param name="codigo">Código de la factura</param>
        /// <param name="periodoCodigo">Código del periodo de la factura</param>
        /// <param name="contratoCodigo">Código del contrato del periodo</param>
        /// <param name="version">Versión de la factura</param>
        /// <returns>Objeto respuesta</returns>
        public static cRespuesta GenerarDesgloseDeLineasFactura(short codigo, string periodoCodigo, int contratoCodigo, short version)
        {
            return new cFacturasDL().GenerarDesgloseDeLineasFactura(codigo, periodoCodigo, contratoCodigo, version);
        }

        /// <summary>
        /// Realiza el desglose de líneas de facturas
        /// </summary>
        public static cRespuesta GenerarDesgloseDeLineasFacturas(string zona, string periodo, bool generarRectifSiPerZonaCerrado, short? sociedadRectificativa, short? serieRectificativa, string usuarioCodigo, string taskUser, ETaskType? taskType, int? taskNumber, out int lineasDesglosadas, out int lineasGeneradas)
        {
            return new cFacturasDL().GenerarDesgloseDeLineasFacturas(zona, periodo, generarRectifSiPerZonaCerrado, sociedadRectificativa, serieRectificativa, usuarioCodigo, taskUser, taskType, taskNumber, out lineasDesglosadas, out lineasGeneradas);
        }

        /// <summary>
        /// Realiza el campo del impuesto de las facturas según la fecha pasada por parámetro (null = ahora)
        /// </summary>
        public static cRespuesta CambioImpuesto(string zona, string periodo, DateTime? fecha, bool incluirFacturasCerradas, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasInsertadas)
        {
            return new cFacturasDL().CambioImpuesto(zona, periodo, fecha, incluirFacturasCerradas, taskUser, taskType, taskNumber, out facturasInsertadas);
        }

        /// <summary>
        /// Realiza el proceso de asignación de consumos
        /// </summary>
        public static cRespuesta AsignarConsumos(string zonaD, string zonaH, DateTime fechaLecturaFactura, int orden1, int? orden2, int? orden3, int? orden4, int? cnsValorDefinido, int? rutaAgrupada, int? loteD, int? loteH, string ruta1, string ruta2, string ruta3, string ruta4, string ruta5, string ruta6, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasAfectadas)
        {
            return new cFacturasDL().AsignarConsumos(zonaD, zonaH, fechaLecturaFactura, orden1, orden2, orden3, orden4, cnsValorDefinido, rutaAgrupada, loteD, loteH, ruta1, ruta2, ruta3, ruta4, ruta5, ruta6, taskUser, taskType, taskNumber, out facturasAfectadas);
        }

        /// <summary>
        /// Obtiene las últimas versiones de las facturas
        /// </summary>
        /// <param name="contratoCodigo">(opcional) Código del contrato</param>
        /// <param name="versionContratoHasta">Máxima versión del contrato</param>
        /// <param name="numRegistros">(opcional) Max. número de registros a obtener</param>
        /// <param name="periodoCodigo">(opcional) Código del periodo</param>
        /// <returns>Lista de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerUltimasVersiones(short? facturaCodigo, string periodoCodigo, int? contratoCodigo, short? versionContratoHasta, int? numRegistros, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerUltimasVersiones(facturaCodigo, periodoCodigo, contratoCodigo, versionContratoHasta, numRegistros, out respuesta);
        }

        /// <summary>
        /// Obtiene facturas por cliente y contrato
        /// </summary>
        /// <param name="contratoCodigo">Código del contrato (opcional)</param>
        /// <param name="docIdenCliente">Documento de Identidad del cliente (opcional)</param>
        /// <param name="ultimaVersion">True = Obtiene últimas versiones de la factura, Flase todas (opcional)</param>
        /// <param name="versionContratoHasta">Máxima versión del contrato (opcional)</param>
        /// <param name="fechaOnline">Si se establece este parámetro, sólo se obtendrán las facturas que deban ser visibles en la oficina online para esta fecha (opcional)</param>
        /// <returns>Lista de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerPorContratoYCliente(int? contratoCodigo, short? versionContratoHasta, string docIdenCliente, bool? ultimaVersion, DateTime? fechaOnline, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerPorContratoYCliente(contratoCodigo, versionContratoHasta, docIdenCliente, ultimaVersion, fechaOnline, out respuesta);
        }

        /// <summary>
        /// Obtiene facturas por cliente y contrato
        /// </summary>
        /// <param name="contratoCodigo">Código del contrato (opcional)</param>
        /// <param name="docIdenCliente">Documento de Identidad del cliente (opcional)</param>
        /// <param name="ultimaVersion">True = Obtiene últimas versiones de la factura, Flase todas (opcional)</param>
        /// <param name="versionContratoHasta">Máxima versión del contrato (opcional)</param>
        /// <returns>Lista de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerPorContratoYCliente(int? contratoCodigo, short? versionContratoHasta, string docIdenCliente, bool? ultimaVersion, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerPorContratoYCliente(contratoCodigo, versionContratoHasta, docIdenCliente, ultimaVersion, null, out respuesta);
        }

        /// <summary>
        /// Método para obtener una factura
        /// </summary>
        /// <param name="factura"> Objeto factura, dicho objeto requiere que se rellene el periodoCodigo, el contratoCodigo y la versión</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>Devuelve una lista con la factura obtenida</returns>
        public static cBindableList<cFacturaBO> ObtenerLista(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> blFactura = new cBindableList<cFacturaBO>();
            if (Obtener(ref factura, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                blFactura.Add(factura);
            return blFactura;
        }

        /// <summary>
        /// Obtiene todos las lineas de una Factura
        /// </summary>
        ///<param name="facturaBO">Objeto que contiene los campos que identifican el objeto (Periodo,Contrato y periodo)</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve el listado de líneas de facturas</returns>
        public static cBindableList<cLineaFacturaBO> ObtenerLineas(ref cFacturaBO facturaBO, out cRespuesta respuesta)
        {
            return ObtenerLineas(ref facturaBO, null, out respuesta);
        }

        /// <summary>
        /// Obtiene todos las lineas de una Factura
        /// </summary>
        ///<param name="facturaBO">Objeto que contiene los campos que identifican el objeto (Periodo,Contrato y periodo)</param>
        ///<param name="servicioCodigo">Código del servico</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve el listado de líneas de facturas</returns>
        public static cBindableList<cLineaFacturaBO> ObtenerLineas(ref cFacturaBO facturaBO, short? servicioCodigo, out cRespuesta respuesta)
        {
            if (facturaBO == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return null;
            }
            cBindableList<cLineaFacturaBO> lineasFactBO = new cBindableList<cLineaFacturaBO>();
            try
            {
                cLineasFacturaBL lineasFacBL = new cLineasFacturaBL();
                cLineaFacturaBO lineaBO = new cLineaFacturaBO();
                lineaBO.FacturaCodigo = facturaBO.FacturaCodigo.Value;
                lineaBO.Periodo = facturaBO.PeriodoCodigo;
                lineaBO.Contrato = facturaBO.ContratoCodigo.Value;
                lineaBO.Version = facturaBO.Version.Value;
                lineaBO.CodigoServicio = servicioCodigo ?? 0;
                lineasFacBL.ObtenerLineas(ref lineasFactBO, lineaBO, out respuesta);

                facturaBO.LineasFactura = respuesta.Resultado == ResultadoProceso.OK ? lineasFactBO : new cBindableList<cLineaFacturaBO>();

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return lineasFactBO;
        }

        /// <summary>
        /// Obtiene las líneas agrupadas por impuesto de una factura
        /// </summary>
        /// <param name="factura">factura</param>
        /// <param name="respuesta">respuesta</param>
        /// <returns>Respuesta</returns>
        public static cRespuesta ObtenerLineasAgrupadasPorImpuesto(ref cFacturaBO factura)
        {
            cRespuesta respuesta;

            //Obtengo las líneas de la factura
            ObtenerLineas(ref factura, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                //Agrupar por Impuesto
                SortedList<decimal, decimal> gruposImpuesto = new SortedList<decimal, decimal>(); //key = tipo impuesto, value = importe
                foreach (cLineaFacturaBO linea in factura.LineasFactura)
                    gruposImpuesto[linea.PtjImpuesto] = +linea.CBase;

                //Crear líneas
                factura.LineasAgrupadasPorImpuesto = new cBindableList<cLineaImportesBO>();
                foreach (decimal impuesto in gruposImpuesto.Keys)
                    factura.LineasAgrupadasPorImpuesto.Add(new cLineaImportesBO(impuesto.ToString() + " %", 1, gruposImpuesto[impuesto], impuesto));
            }

            return respuesta;
        }

        /// <summary>
        /// Obtiene las líneas detalladas (una línea para la cuota y una por cada escalado)
        /// </summary>
        /// <param name="factura">factura</param>
        /// <returns>respuesta</returns>
        public static cRespuesta ObtenerLineasDetalladas(ref cFacturaBO factura)
        {
            cRespuesta respuesta;

            //Obtengo las líneas de la factura
            ObtenerLineas(ref factura, out respuesta);
            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
            cLineasFacturaBL lineasFacturaBL = new cLineasFacturaBL();

            //Añadir líneas detalladas
            factura.LineasDetalladas = new cBindableList<cLineaImportesBO>();
            for (int i = 0; i < factura.LineasFactura.Count && respuesta.Resultado == ResultadoProceso.OK; i++)
            {
                //Obtener servicio
                cLineaFacturaBO refLinea = factura.LineasFactura[i];
                lineasFacturaBL.ObtenerServicio(ref refLinea, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    //Si la línea no tiene nada en los escalados no hay nada que detallar
                    if (refLinea.ArrayUnidades[0] == 0)
                        factura.LineasDetalladas.Add(new cLineaImportesBO(refLinea.Servicio.Descripcion, refLinea.Unidades, refLinea.Precio, refLinea.PtjImpuesto));
                    else //Si el servicio es medido, hay que sacar cuota y escalados
                    {
                        //LA DESCRIPCIÓN DEL SERVICIO SALE EN CASTELLANO SIEMPRE

                        //Añadimos la cuota
                        factura.LineasDetalladas.Add(new cLineaImportesBO("Cuota de " + refLinea.Servicio.Descripcion.ToLower(), refLinea.Unidades, refLinea.Precio, refLinea.PtjImpuesto));

                        //Añadimos los escalados
                        int e = 0;
                        while (refLinea.ArrayUnidades[e] > 0 && e < refLinea.ArrayUnidades.Length)
                        {
                            factura.LineasDetalladas.Add(new cLineaImportesBO("Consumo de " + refLinea.Servicio.Descripcion.ToLower() + " hasta " + refLinea.ArrayEscalas[e], refLinea.ArrayUnidades[e], refLinea.ArrayPrecios[e], refLinea.PtjImpuesto));
                            e++;
                        }
                    }
                }
            }

            return respuesta;
        }

        /// <summary>
        /// Obtiene un registro de la tabla Facturas con ultima versión
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ObtenerUltimaVersion(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                resultado = facturasDL.ObtenerUltimaVersion(ref factura, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
        /// <summary>
        /// Obtiene un registro de la tabla Facturas con ultima versión
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ObtenerUltimaVersionSOA(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                resultado = facturasDL.ObtenerUltimaVersionSOA(ref factura, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
        /// <summary>
        /// Obtiene un registro de la tabla Facturas que sea del último periodo facturado
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ObtenerUltimoPeriodoCerrado(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                resultado = facturasDL.ObtenerUltimoPeriodoCerrado(ref factura, out respuesta);
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
        /// <param name="factura">factura cuyas líneas se desean borrar</param>
        /// <param name="respuesta">Objeto cRespuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool BorrarLineas(cFacturaBO factura, out cRespuesta respuesta)
        {
            if (factura != null)
                return new cFacturasDL().BorrarLineas(factura, out respuesta);
            else
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
        }

        /// <summary>
        /// Borra una factura y sus líneas
        /// </summary>
        /// <param name="factura">objeto a borrar</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool Borrar(cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                resultado = facturasDL.Borrar(factura, out respuesta);

            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene todos los registros
        /// </summary>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>Lista enlazable que contiene las facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerTodos(out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                if (!facturasDL.ObtenerTodos(ref facturas, out respuesta))
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene los registro de una zona y periodo donde el consumo comunitario es mayor al consumo final
        /// </summary>
        /// <param name="periodoCodigo">código del periodo</param>
        /// <param name="zonaCodigo">código de la zona</param>
        /// <param name="soloCnsComunitarioMayorAlFinal">True si solo quieres obtener las facturas donde el consumo comunitario es mayor al final</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>Lista enlazable que contiene las facturas</returns>
        public static cBindableList<cFacturaBO> Obtener(string periodoCodigo, string zonaCodigo, bool soloCnsComunitarioMayorAlFinal, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasSeleccionBO seleccion = new cFacturasSeleccionBO();
                seleccion.Zona = zonaCodigo;
                seleccion.Periodo = periodoCodigo;
                seleccion.SoloCnsComunitarioMayorAlFinal = soloCnsComunitarioMayorAlFinal;
                facturas = new cFacturasDL().Obtener(seleccion, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene el contrato de la factura
        /// </summary>
        /// <param name="factura">Objeto Factura que contiene el codigo del contrato </param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool ObtenerContrato(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;

            }
            bool resultado = false;

            try
            {
                cContratoBO contratoBO = new cContratoBO();
                contratoBO.Codigo = factura.ContratoCodigo.Value;
                contratoBO.Version = factura.ContratoVersion.Value;

                resultado = cContratoBL.Obtener(ref contratoBO, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    factura.Contrato = contratoBO;

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        internal static cBindableList<cLineaFacturaBO> ObtenerLineasConDeuda(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            return ObtenerLineasConDeuda(ref factura, null, out respuesta);
        }


        /// <summary>
        /// Obtiene todos las lineas de una Factura
        /// </summary>
        ///<param name="facturaBO">Objeto que contiene los campos que identifican el objeto (Periodo,Contrato y periodo)</param>
        ///<param name="servicioCodigo">Código del servico</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve el listado de líneas de facturas</returns>
        public static cBindableList<cLineaFacturaBO> ObtenerLineasConDeuda(ref cFacturaBO facturaBO, short? servicioCodigo, out cRespuesta respuesta)
        {
            if (facturaBO == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return null;
            }
            cBindableList<cLineaFacturaBO> lineasFactBO = new cBindableList<cLineaFacturaBO>();
            try
            {
                cLineasFacturaBL lineasFacBL = new cLineasFacturaBL();
                cLineaFacturaBO lineaBO = new cLineaFacturaBO();
                lineaBO.FacturaCodigo = facturaBO.FacturaCodigo.Value;
                lineaBO.Periodo = facturaBO.PeriodoCodigo;
                lineaBO.Contrato = facturaBO.ContratoCodigo.Value;
                lineaBO.Version = facturaBO.Version.Value;
                lineaBO.CodigoServicio = servicioCodigo ?? 0;
                lineasFacBL.ObtenerLineasConDeuda(ref lineasFactBO, lineaBO, out respuesta);

                facturaBO.LineasFactura = respuesta.Resultado == ResultadoProceso.OK ? lineasFactBO : new cBindableList<cLineaFacturaBO>();

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return lineasFactBO;
        }






        /// <summary>
        /// Obtiene la ultima version del contrato para asignarlo a la factura
        /// </summary>
        /// <param name="factura">Objeto Factura que contiene el codigo del contrato</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool ObtenerContratoUltimaVersion(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;

            }
            bool resultado = false;

            try
            {
                cContratoBO contratoBO = new cContratoBO();
                contratoBO.Codigo = factura.ContratoCodigo.Value;

                resultado = cContratoBL.ObtenerUltimaVersion(ref contratoBO, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    factura.Contrato = contratoBO;

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene el periodo de la factura
        /// </summary>
        /// <param name="factura">Objeto Factura que contiene el codigo del periodo</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool ObtenerPeriodo(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;

            }
            bool resultado = false;

            try
            {
                cPeriodoBL periodoBL = new cPeriodoBL();
                cPeriodoBO periodoBO = new cPeriodoBO();
                periodoBO.Codigo = factura.PeriodoCodigo;

                resultado = periodoBL.Obtener(ref periodoBO, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    factura.Periodo = periodoBO;

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene la zona de la factura
        /// </summary>
        /// <param name="factura">Objeto Factura que contiene el codigo de la zona</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool ObtenerZona(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;

            }
            bool resultado = false;

            try
            {
                cZonaBL zonaBL = new cZonaBL();
                cZonaBO zonaBO = new cZonaBO();
                zonaBO.Codigo = factura.ZonaCodigo;

                resultado = zonaBL.Obtener(ref zonaBO, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    factura.Zona = zonaBO;

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene el lector o inspector de la factura
        /// </summary>
        /// <param name="factura">Objeto Factura que contiene el codigo del empleado</param>
        /// <param name="lector">Si lector es "true" se obtiene el empleado lector , en caso contrario se obtiene el empleado inspector</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool ObtenerEmpleado(ref cFacturaBO factura, bool lector, out cRespuesta respuesta)
        {
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            bool resultado = false;

            try
            {
                cEmpleadoBO empleadoBO = new cEmpleadoBO();

                if (lector && factura.LectorCodigoEmpleado.HasValue && factura.LectorCodigoContratista.HasValue)
                {
                    empleadoBO.Codigo = factura.LectorCodigoEmpleado.Value;
                    empleadoBO.Contratistacod = factura.LectorCodigoContratista.Value;
                }
                else if (factura.InspectorCodigoEmpleado.HasValue && factura.InspectorCodigoContratista.HasValue)
                {
                    empleadoBO.Codigo = factura.InspectorCodigoEmpleado.Value;
                    empleadoBO.Contratistacod = factura.InspectorCodigoContratista.Value;
                }

                if (empleadoBO.Codigo == 0 || empleadoBO.Contratistacod == 0)
                {
                    respuesta = new cRespuesta();
                    respuesta.Resultado = ResultadoProceso.SinRegistros;
                    resultado = true;
                }
                else
                {
                    resultado = cEmpleadoBL.Obtener(ref empleadoBO, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        if (lector)
                            factura.Lector = empleadoBO;
                        else
                            factura.Inspector = empleadoBO;
                    }
                }
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene el empleado lector asignado en la tabla perzonalote
        /// </summary>
        /// <param name="factura">Objeto Factura que contiene el codigo del empleado</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool ObtenerEmpleadoPerzonaLote(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;

            }
            bool resultado = false;

            try
            {
                cPerzonaloteBL perzonaloteBL = new cPerzonaloteBL();
                cPerzonaloteBO perzonaloteBO = new cPerzonaloteBO();

                perzonaloteBO.CodigoZona = factura.ZonaCodigo;
                perzonaloteBO.CodigoPeriodo = factura.PeriodoCodigo;
                perzonaloteBO.Codigo = factura.Lote.Value;
                resultado = perzonaloteBL.Obtener(ref perzonaloteBO, out respuesta);
                if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                {
                    resultado = perzonaloteBL.ObtenerEmpleado(ref perzonaloteBO, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK)
                        factura.Lector = perzonaloteBO.EmpleadoBO;
                }


            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene el cliente de la factura
        /// </summary>
        /// <param name="factura">Objeto Factura que contiene el codigo del cliente </param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool ObtenerCliente(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;

            }
            bool resultado = false;

            try
            {
                cClienteBO clienteBO = new cClienteBO();
                clienteBO.Codigo = factura.ClienteCodigo.Value;

                resultado = cClienteBL.Obtener(ref clienteBO, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    factura.Cliente = clienteBO;

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Construye el filtro para realizar búsquedas de registros
        /// </summary>
        /// <param name="camposBusqueda">Lista ordenada con los textos de los campos a filtrar</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve un string con el filtro a aplicar</returns>
        public static string ConstruirFiltroSQL(SortedList camposBusqueda, out cRespuesta respuesta)
        {
            string resultado = String.Empty;
            try
            {
                camposBusqueda["lote"] = cAplicacion.BuildRange(Convert.ToString(camposBusqueda["loteDesde"]), Convert.ToString(camposBusqueda["loteHasta"]), cConfiguration.kSeparadorBuscarRango);
                camposBusqueda["fechaFac"] = cAplicacion.BuildRange(Convert.ToString(camposBusqueda["fechaFacD"]), Convert.ToString(camposBusqueda["fechaFacH"]), cConfiguration.kSeparadorBuscarRango);
                camposBusqueda["fechaFacReg"] = cAplicacion.BuildRange(Convert.ToString(camposBusqueda["fechaFacRegD"]), Convert.ToString(camposBusqueda["fechaFacRegH"]), cConfiguration.kSeparadorBuscarRango);
                camposBusqueda["fctTotal"] = cAplicacion.BuildRange(Convert.ToString(camposBusqueda["fctTotalD"]), Convert.ToString(camposBusqueda["fctTotalH"]), cConfiguration.kSeparadorBuscarRango);

                resultado = new cFacturasDL().ConstruirFiltroSQL(camposBusqueda, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene los registros de según el filtro 
        /// </summary>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve una lista enlazable de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerPorFiltro(string filtro, out cRespuesta respuesta, int? estadoDeuda = null)
        {
            int auxTotalRowCount;
            return ObtenerPorFiltro(filtro, null, null, null, out auxTotalRowCount, out respuesta, estadoDeuda);
        }

        /// <summary>
        /// Obtiene los registros de según el filtro 
        /// </summary>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="pageSize">Número de registros que caben en una página</param>
        /// <param name="pageIndex">Índice de la página a obtener</param>
        /// <param name="totalRowCount">Número de filas que corresponde con el filtro</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve una lista enlazable de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerPorFiltro(string filtro, int? pageSize, int? pageIndex, bool? soloFacturase, out int totalRowCount, out cRespuesta respuesta, int? estadoDeuda)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            new cFacturasDL().ObtenerPorFiltro(ref facturas, filtro, pageSize, pageIndex, soloFacturase, out totalRowCount, out respuesta, estadoDeuda);

            return facturas;
        }

        /// <summary>
        /// Obtiene los registros inspeccionables según el filtro
        /// </summary>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve una lista enlazable de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerInspeccionablesPorFiltro(string filtro, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.ObtenerInspeccionablesPorFiltro(ref facturas, filtro, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene los registros pendientes de lectura según el filtro
        /// </summary>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve una lista enlazable de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerPendientesDeLeerPorFiltro(string filtro, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.ObtenerPendientesDeLeerPorFiltro(ref facturas, filtro, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene todos los registros pendientes de lectura
        /// </summary>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve una lista enlazable de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerPendientesDeLeer(out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.ObtenerPendientesDeLeer(ref facturas, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta.Resultado == ResultadoProceso.OK ? facturas : new cBindableList<cFacturaBO>();
        }

        /// <summary>
        /// Obtiene todos los registros inspeccionables de lectura
        /// </summary>
        /// <param name="filtro">Filtro SQL</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve una lista enlazable de facturas inspeccionables</returns>
        public static cBindableList<cFacturaBO> ObtenerInspeccionables(out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturaDL = new cFacturasDL();
                if (!facturaDL.ObtenerInspeccionables(ref facturas, out respuesta))
                    respuesta.Resultado = ResultadoProceso.Error;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return facturas;
        }

        /// <summary>
        /// Realización del proceso de calculo del consumo real
        /// </summary>
        /// <param name="facturaBO">Objeto con el cual se realizará el proceso de calculo de consumo real
        ///                         Necesario: Código del contrato, Lectura anterior, Fecha lectura anterior y Fecha lectura actual</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <param name="consumoReal">Nº de consumo real de la factura</param>
        /// <param name="lecturaAnterior">Lectura anterior real</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool CalculoConsumoReal(cFacturaBO facturaBO, out int? consumoReal, out int? lecturaAnterior, out cRespuesta respuesta)
        {
            return new cFacturasDL().CalculoConsumoReal(facturaBO, out consumoReal, out lecturaAnterior, out respuesta);
        }

        /// <summary>
        /// Valida los datos de lectura de la Factura.
        /// </summary>
        /// <param name="factura">Objeto factura a validar</param>
        /// <returns>string que contiene el mensaje</returns>
        public static string ValidarLectura(cFacturaBO factura)
        {
            cValidator validator = new cValidator();
            if (factura.FechaLecturaAnterior != null && factura.FechaLecturaLector != null)
                validator.AddFechaAnterior(((DateTime)factura.FechaLecturaAnterior).ToShortDateString(), ((DateTime)factura.FechaLecturaLector).ToShortDateString(), Resource.fecha_lectura_anterior, Resource.fecha_lectura_actual);

            return validator.Validate(true);
        }

        /// <summary>
        /// Obtiene el primer registro de factura sin lectura
        /// </summary>
        /// <param name="factura">Objeto que contiene los datos clave, y del cual se desea obtener el resto</param>
        /// <param name="lector">Booleano que indica que tipo de lectura no debe tener la factura</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ObtenerPrimeraSinLectura(ref cFacturaBO factura, bool lector, out cRespuesta respuesta)
        {
            //lector = true, lectura lector debe de estar vacio
            //lector = false, lectura inspector debe de estar vacio
            bool resultado = false;
            respuesta = new cRespuesta();
            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                resultado = facturasDL.ObtenerPrimeraSinLectura(ref factura, lector, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Comprueba que la incidencia introducida es correcta respecto al consumo y
        /// calcula el consumo
        /// </summary>
        /// <param name="factura">Objeto cFacturaBO, con las siguientes propiedades asiganadas: codigo incidencia, lecturaAnterior, lecturaActual, codigo contrato, codigo periodo</param>
        /// <param name="tipo">Enumerado para el tipo de inicidencia</param>
        /// <param name="respVal">Respuesta de la validación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ValidarIncidenciaConsumo(ref cFacturaBO factura, TipoValidacion tipo, out RespuestaValidacion respVal)
        {
            cIncilecBO incidenciaBO = new cIncilecBO();
            cIncilecBL incidenciaBL = new cIncilecBL();
            cFacturasDL facturaDL = new cFacturasDL();

            int? consumo = null;
            int? bajo = null, alto = null;
            int consumoAceptable = 0;

            int? consumoReal, lecturaAnterior;

            bool resultado = true;
            respVal = new RespuestaValidacion();
            cRespuesta respuesta = new cRespuesta();

            if (factura == null)
            {
                respVal.Resultado = TipoRespuestaValidacion.Error;
                return false;
            }

            try
            {
                // Segun el tipo usamos datos de Lectura o Inspeccion
                switch (tipo)
                {
                    case TipoValidacion.Lectura:
                        incidenciaBO.Codigo = factura.LectorIncidenciaLectura ?? String.Empty;
                        break;
                    case TipoValidacion.Inspeccion:
                        incidenciaBO.Codigo = factura.InspectorIncidenciaLectura ?? String.Empty;
                        break;
                }
                if (incidenciaBO.Codigo == String.Empty)
                {
                    incidenciaBO.MCalculo = "D";
                    incidenciaBO.CAlto = false;
                    incidenciaBO.CBajo = false;
                    incidenciaBO.CCero = true;
                    incidenciaBO.CNega = false;
                }
                else
                    incidenciaBL.Obtener(ref incidenciaBO, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    switch (incidenciaBO.MCalculo)
                    {
                        case "A":
                            // Arrastre de Lecturas
                            // En alguna facturacion anterior, se facturó una lectura superior a la real, y hasta que se supere el consumo
                            // facturado en dicho periodo, se facturan 0 m3, y se almacena la lectura del lector.

                            //Obtenemos los posibles consumos intermedios por cambios de contador en consumoReal
                            resultado = CalculoConsumoReal(factura, out consumoReal, out lecturaAnterior, out respuesta);

                            if (resultado)
                            {
                                factura.LecturaFactura = lecturaAnterior;
                                factura.ConsumoFactura = 0;

                                switch (tipo)
                                {
                                    case TipoValidacion.Lectura:
                                        factura.FechaLecturaFactura = factura.FechaLecturaLector;
                                        break;
                                    case TipoValidacion.Inspeccion:
                                        factura.FechaLecturaFactura = factura.FechaLecturaInspector;
                                        break;
                                }
                            }
                            else
                            {
                                respVal.Mensaje = Resource.laIncidenciaSeleccionadaNoEsValida;
                                respVal.Resultado = TipoRespuestaValidacion.Error;
                            }

                            break;

                        case "D":
                            // Diferencia de lecturas
                            // Es necesario llamar a un procedimiento que nos obtenga los posibles consumos intermedios por cambios de contador
                            // Por defecto el consumo es la diferencia de lecturas de la factura.
                            if (factura.LecturaLector.HasValue)
                            {
                                //Obtenemos los posibles consumos intermedios por cambios de contador en consumoReal
                                resultado = CalculoConsumoReal(factura, out consumoReal, out lecturaAnterior, out respuesta);

                                if (resultado)
                                {
                                    switch (tipo)
                                    {
                                        case TipoValidacion.Lectura:
                                            //calculamos el consumo de la factura
                                            factura.ConsumoFactura = (factura.LecturaLector - lecturaAnterior) + consumoReal;
                                            factura.LecturaFactura = factura.LecturaLector;
                                            break;
                                        case TipoValidacion.Inspeccion:
                                            //calculamos el consumo de la factura
                                            factura.ConsumoFactura = (factura.LecturaInspector - lecturaAnterior) + consumoReal;
                                            factura.LecturaFactura = factura.LecturaInspector;
                                            break;
                                    }
                                    //Obtenemos de la tabla parametros el valor del consumoAceptable 
                                    if (cParametroBL.GetInteger("CONSUMOACEPTABLE", out consumoAceptable).Resultado == ResultadoProceso.OK)
                                    {
                                        //calculamos el consumo Promedio
                                        resultado = CalculoConsumoPromedio(factura.ContratoCodigo.Value, factura.PeriodoCodigo, out consumo, out respuesta);
                                        if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                                        {
                                            if (consumo <= consumoAceptable)
                                            {
                                                if (factura.ConsumoFactura > consumoAceptable)
                                                {
                                                    resultado = CalculoConsumoAltoBajo(consumo.Value, out alto, out bajo, out respuesta);
                                                    if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                                                    {
                                                        if (factura.ConsumoFactura > alto) factura.Inspeccion = 5;
                                                        if (factura.ConsumoFactura < bajo) factura.Inspeccion = 4;
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                //Obtenemos los limites de consumo alto y bajo del consumo Promedio
                                                if (consumo.HasValue && resultado)
                                                {
                                                    resultado = CalculoConsumoAltoBajo(consumo.Value, out alto, out bajo, out respuesta);
                                                    if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                                                    {
                                                        if (factura.ConsumoFactura > alto) factura.Inspeccion = 5;
                                                        if (factura.ConsumoFactura < bajo) factura.Inspeccion = 4;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            else
                            {
                                respVal.Mensaje = Resource.laIncidenciaSeleccionadaNoEsValida;
                                respVal.Resultado = TipoRespuestaValidacion.Error;
                            }
                            break;

                        case "E":
                            // PROMEDIO:
                            // Estimación de Consumo
                            // Obtenemos el consumo Promedio
                            // si no tenemos consumo medio facturamos (valor de tarifa como facturación estandar)

                            //Obtenemos los posibles consumos intermedios por cambios de contador en consumoReal
                            resultado = CalculoConsumoReal(factura, out consumoReal, out lecturaAnterior, out respuesta);

                            if (resultado)
                            {
                                resultado = CalculoConsumoPromedio(factura.ContratoCodigo.Value, factura.PeriodoCodigo, out consumo, out respuesta);
                                if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                                {
                                    factura.ConsumoFactura = consumo;
                                    factura.LecturaFactura = (lecturaAnterior + consumo) >= consumoReal ? lecturaAnterior + consumo - consumoReal : 0;
                                }
                            }
                            else
                            {
                                respVal.Mensaje = Resource.laIncidenciaSeleccionadaNoEsValida;
                                respVal.Resultado = TipoRespuestaValidacion.Error;
                            }

                            break;

                        case "EP":
                            // PERIODO:                            
                            // Estimación de Consumo
                            // Obtenemos el consumo del mismo periodo pero del año anterior
                            // Si no tenemos dicho consumo facturamos consumo medio de los 3 periodos anteriores
                            // Si no exiten 3 periodos anteriores se calcula el consumo de la ruta calibre
                            //TODO:Esto se ha quitado temporalmente-->si no tenemos consumo medio facturamos (valor de tarifa como facturación estandar)

                            //Obtenemos los posibles consumos intermedios por cambios de contador en consumoReal
                            resultado = CalculoConsumoReal(factura, out consumoReal, out lecturaAnterior, out respuesta);
                            if (resultado)
                            {
                                string strExplotacion = null;

                                if (cParametroBL.GetString("EXPLOTACION", out strExplotacion).Resultado == ResultadoProceso.OK)
                                {
                                    if (!String.IsNullOrWhiteSpace(strExplotacion) && strExplotacion == "AVG")
                                    //Para AVG ha de cumplir el artículo 78
                                    //comprobar la lógica de los periodos consultados o calcular capacidad nominal del contador por 15h
                                    {
                                        resultado = CalculoConsumoEstimadoPeriodo_AVG(factura.ContratoCodigo.Value, factura.PeriodoCodigo, out consumo, out respuesta);
                                        if (resultado && respuesta.Resultado == ResultadoProceso.OK && consumo.HasValue)
                                            factura.ConsumoFactura = consumo;
                                    }
                                    else
                                    {
                                        resultado = CalculoConsumoMismoPeriodoEjercAnterior(factura.ContratoCodigo.Value, factura.PeriodoCodigo, out consumo, out respuesta);
                                        if (resultado && respuesta.Resultado == ResultadoProceso.OK && consumo.HasValue)
                                            factura.ConsumoFactura = consumo;
                                        else
                                        {
                                            resultado = CalculoConsumoPromedio(factura.ContratoCodigo.Value, factura.PeriodoCodigo, out consumo, out respuesta);
                                            if (resultado && respuesta.Resultado == ResultadoProceso.OK && consumo.HasValue)
                                                factura.ConsumoFactura = consumo;
                                            else
                                            {

                                                //Si la explotación es Guadalajara-->Método de cálculo ruta calibre
                                                if (!String.IsNullOrWhiteSpace(strExplotacion) && strExplotacion == "Guadalajara")
                                                {
                                                    cContratoBO contrato = new cContratoBO();
                                                    ObtenerContratoUltimaVersion(ref factura, out respuesta);
                                                    if (respuesta.Resultado == ResultadoProceso.OK && factura.Contrato != null)
                                                    {
                                                        contrato = factura.Contrato;
                                                        cContratoBL.ObtenerUltimoContadorInstalado(ref contrato, out respuesta);
                                                    }
                                                    if (respuesta.Resultado == ResultadoProceso.OK && contrato.UltimoContadorInstalado != null)
                                                    {
                                                        //TODO:Preguntar por qué ruta se debe agrupar, iniciamente la obtenemos del parámetro con clave RUTACORTELOTE cuyo valor es 3
                                                        int rutaAgrupada = 0;
                                                        if (cParametroBL.GetInteger("RUTACORTELOTE", out rutaAgrupada).Resultado == ResultadoProceso.OK)
                                                            CalculoConsumoPromedioPorDiametroYRuta(factura.ZonaCodigo, factura.ZonaCodigo, contrato.UltimoContadorInstalado.Diametro, rutaAgrupada, factura.PeriodoCodigo, contrato.Codigo, out consumo, out respuesta);
                                                        if (respuesta.Resultado == ResultadoProceso.OK && consumo.HasValue)
                                                            factura.ConsumoFactura = consumo;
                                                        else //TODO:Este caso normalmente era 0 porque hacia el promedio de la tarifa, ver como debe quedar
                                                            consumo = 0;
                                                    }
                                                }
                                                else //TODO:Este caso normalmente era 0 porque hacia el promedio de la tarifa, ver como debe quedar
                                                    consumo = 0;
                                            }
                                        }
                                    }

                                    factura.LecturaFactura = (lecturaAnterior + consumo) >= consumoReal ? lecturaAnterior + consumo - consumoReal : 0;
                                }
                            }
                            else
                            {
                                respVal.Mensaje = Resource.laIncidenciaSeleccionadaNoEsValida;
                                respVal.Resultado = TipoRespuestaValidacion.Error;
                            }
                            break;
                        case "VC":
                            //vuelta de contador.
                            //si la lectura anterior es mayor que 5 digitos obtenemos lo consumido hasta la vuelta.
                            if (factura.LecturaLector.HasValue)
                            {
                                int cnsAntesVC = 0;
                                string strLecAnt = factura.LecturaAnterior.ToString();
                                string finContador = String.Empty;
                                for (int a = 0; a < strLecAnt.Length; a++)
                                    finContador = finContador + "9";
                                if (factura.LecturaAnterior < Convert.ToInt32(finContador))
                                    cnsAntesVC = Convert.ToInt32(finContador) - factura.LecturaAnterior.Value;

                                factura.ConsumoFactura = factura.LecturaLector.Value + cnsAntesVC;
                                factura.LecturaFactura = factura.LecturaLector;

                                //Obtenemos de la tabla parametros el valor del consumoAceptable 
                                if (cParametroBL.GetInteger("CONSUMOACEPTABLE", out consumoAceptable).Resultado == ResultadoProceso.OK)
                                {
                                    //calculamos el consumo Promedio
                                    resultado = CalculoConsumoPromedio(factura.ContratoCodigo.Value, factura.PeriodoCodigo, out consumo, out respuesta);
                                    if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                                    {
                                        if (consumo <= consumoAceptable)
                                        {
                                            if (factura.ConsumoFactura > consumoAceptable)
                                            {
                                                resultado = CalculoConsumoAltoBajo(consumo.Value, out alto, out bajo, out respuesta);
                                                if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                                                {
                                                    if (factura.ConsumoFactura > alto) factura.Inspeccion = 5;
                                                    if (factura.ConsumoFactura < bajo) factura.Inspeccion = 4;
                                                }
                                            }
                                        }
                                        else
                                        {
                                            //Obtenemos los limites de consumo alto y bajo del consumo Promedio
                                            if (consumo.HasValue && resultado)
                                            {
                                                resultado = CalculoConsumoAltoBajo(consumo.Value, out alto, out bajo, out respuesta);
                                                if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                                                {
                                                    if (factura.ConsumoFactura > alto) factura.Inspeccion = 5;
                                                    if (factura.ConsumoFactura < bajo) factura.Inspeccion = 4;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            else
                            {
                                respVal.Mensaje = Resource.laIncidenciaSeleccionadaNoEsValida;
                                respVal.Resultado = TipoRespuestaValidacion.Error;
                            }
                            break;
                    }

                    //Si ya había una inspección para la factura pero la incidencia indica que hay que inspeccionar
                    //le ponemos 1 a la inspección de la factura
                    if (resultado && incidenciaBO.Inspeccion)
                        factura.Inspeccion = 1;

                    //Comprobar si la incidencia y el consumo son válidos (comparando el consumo con el alto y el bajo)
                    //Sólo en caso de que el medio de cálculo sea 'D' (diferencial) ó 'EP' (estimado con periodo) 
                    if (resultado && (incidenciaBO.MCalculo == "D" || incidenciaBO.MCalculo == "EP"))
                    {
                        if (factura.ConsumoFactura < 0)
                        {
                            factura.ConsumoFactura = 0;
                            //Ya estaria asignada la lectura de factura según el método de calculo de la observación
                            //factura.LecturaFactura = factura.LecturaLector;

                            if (incidenciaBO.CNega == false)
                            {
                                //Incidencia no valida para CONSUMO NEGATIVO'
                                respVal.Resultado = TipoRespuestaValidacion.Negativo;
                                respVal.Mensaje = Resource.consumoEsNegativo;
                            }
                            else
                                factura.Inspeccion = 1;
                        }
                        else if (factura.ConsumoFactura == 0)
                        {
                            if (incidenciaBO.CCero == false)
                            {
                                //Incidencia no valida para CONSUMO CERO'
                                respVal.Resultado = TipoRespuestaValidacion.Cero;
                                respVal.Mensaje = Resource.consumoEsCero;
                            }
                        }
                        else if (alto != -1 && factura.ConsumoFactura > alto)
                        {
                            if (incidenciaBO.CAlto == false)
                            {
                                //Incidencia no valida para CONSUMO ALTO'
                                respVal.Resultado = TipoRespuestaValidacion.Alto;
                                respVal.Mensaje = Resource.consumoEsAlto;
                            }
                        }
                        else if (bajo != null && factura.ConsumoFactura < bajo)
                        {
                            if (incidenciaBO.CBajo == false)
                            {
                                //'Incidencia no valida para CONSUMO BAJO'
                                respVal.Resultado = TipoRespuestaValidacion.Bajo;
                                respVal.Mensaje = Resource.consumoBajo; ;
                            }
                        }
                    }

                    cValidator validador = new cValidator();
                    if (factura.ConsumoFactura != null)
                        validador.AddMaxValue(factura.ConsumoFactura.Value, 999999, Resource.consumo);
                    string error = validador.Validate(true);
                    if (error != String.Empty)
                    {
                        cExcepciones.ControlarER(new Exception(error), TipoExcepcion.Informacion);
                        respVal.Mensaje = error;
                        respVal.Resultado = TipoRespuestaValidacion.Error;
                        resultado = false;
                    }
                }
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            finally
            {
                if (respuesta.Resultado == ResultadoProceso.Error)
                {
                    respVal.Resultado = TipoRespuestaValidacion.Error;
                    respVal.Mensaje = respuesta.Ex.Message;
                }
            }

            return resultado;
        }

        /// <summary>
        /// Comprueba si existen lineas en la tabla LineasFactura según un periodo,un Contrato y una Version de la factura
        /// </summary>
        /// <param name="facturaBO">Objeto Factura a obtener</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si si existen lineas y False en caso contrario</returns>
        public static bool ExistenLineas(cFacturaBO facturaBO, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();

            if (facturaBO == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;

            }
            bool resultado = false;

            try
            {
                cLineasFacturaBL lineasFacturaBL = new cLineasFacturaBL();
                cLineaFacturaBO LineaFacturaBO = new cLineaFacturaBO();
                LineaFacturaBO.Periodo = facturaBO.PeriodoCodigo;
                LineaFacturaBO.Contrato = facturaBO.ContratoCodigo.Value;
                LineaFacturaBO.Version = facturaBO.Version.Value;

                resultado = lineasFacturaBL.Existen(ref LineaFacturaBO, out respuesta);

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
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
        /// <param name="tarvalBo">Objeto de Tarval, Almacena los parametros de salidaCabecera</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ObtenerValoresTarifa(short servicio, short tarifa, DateTime? fecPeriodoD, DateTime? fecPeriodoH, DateTime? fecInicio, DateTime? fecFin, ref cTarvalBO tarvalBo, out cRespuesta respuesta)
        {
            bool resultado;
            respuesta = new cRespuesta();

            try
            {
                resultado = new cFacturasDL().ObtenerValoresTarifa(servicio, tarifa, fecPeriodoD, fecPeriodoH, fecInicio, fecFin, ref tarvalBo, out respuesta);
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
        /// </summary>
        /// <param name="factura">Factura que contiene la zona (factura.ZonCod), el periodo (factura.PerCod)</param>
        /// <param name="lector">Si lector != null, obtendremos las facuras cuyos lotes estén asignados a ese lector</param>
        /// <param name="loteDesde">Lote desde el cual se quieren obtener facturas</param>
        /// <param name="loteHasta">Lote hasta el cual se quieren obtener facturas</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>BindableList de Facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerParaDescargaTPL(cFacturaBO factura, cEmpleadoBO lector, int loteDesde, int loteHasta, bool? incluirCtrSinSerMedAct, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();

            if (factura == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return null;
            }

            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            cBindableList<cFacturaBO> resultado = null;

            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                if (facturasDL.ObtenerParaDescargaTPL(ref facturas, factura, lector, loteDesde, loteHasta, incluirCtrSinSerMedAct, out respuesta))
                {
                    /*Necesitaremos los objetos: 
                     * factura.Zona
                     * factura.Lector DE PERZONALOTE
                     * factura.Contrato
                     * factura.Contrato.Emplazamiento
                     * factura.Contrato.Inmueble
                     * factura.Contrato.Cliente 
                     */

                    //Obtenemos los objetos necesarios para cada factura
                    cPerzonaloteBL perzonaloteBL = new cPerzonaloteBL();
                    cPerzonaloteBO perzonalote = new cPerzonaloteBO();
                    cContratoBO contrato;
                    cFacturaBO facturaIterador;
                    int i;
                    for (i = 0; i < facturas.Count; i++)
                    {
                        facturaIterador = facturas[i];

                        //Zona
                        if (!ObtenerZona(ref facturaIterador, out respuesta))
                            break;

                        //Contrato
                        if (!ObtenerContrato(ref facturaIterador, out respuesta))
                            break;

                        //Lector DE PERZONALOTE
                        if (!ObtenerEmpleado(ref facturaIterador, true, out respuesta))
                            break;

                        //Inmueble
                        contrato = facturaIterador.Contrato;
                        if (!cContratoBL.ObtenerInmueble(ref contrato, out respuesta))
                            break;
                        facturaIterador.Contrato.InmuebleBO = contrato.InmuebleBO;

                        //Emplazamiento
                        if (!cContratoBL.ObtenerEmplazamiento(ref contrato, out respuesta))
                            break;
                        facturaIterador.Contrato.EmplazamientoBO = contrato.EmplazamientoBO;

                        //Cliente
                        if (!cContratoBL.ObtenerCliente(ref contrato, out respuesta))
                            break;
                        facturaIterador.Contrato.ClienteBO = contrato.ClienteBO;
                    }

                    if (i == facturas.Count)
                        resultado = facturas;
                }
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            if (resultado == null)
                respuesta.Resultado = ResultadoProceso.Error;

            return resultado;
        }

        /// <summary>
        /// Obtiene el Importe Facturado de una Factura, almacenandolo en la factura
        /// </summary>
        /// <param name="factura">Factrua</param>
        /// <param name="fecha"></param>
        /// <returns>Objeto Respuesta con el resultado de la operación</returns>
        public static cRespuesta ObtenerImporteFacturado(ref cFacturaBO factura, Nullable<DateTime> fecha, int precision = 2)
        {
            cRespuesta respuesta;
            factura.TotalFacturado = ObtenerImporteFacturado(factura.FacturaCodigo.Value, factura.ContratoCodigo.Value, factura.PeriodoCodigo, factura.Version.Value, null, null, false, out respuesta, precision);

            return respuesta;
        }

        /// <summary>
        /// Obtiene el Importe Cobrado de una Factura, almacenandolo en la factura
        /// </summary>
        /// <param name="factura">Factrua</param>
        /// <param name="fecha"></param>
        /// <returns>Objeto Respuesta con el resultado de la operación</returns>
        public static cRespuesta ObtenerImporteCobrado(ref cFacturaBO factura, Nullable<DateTime> fecha, int precision = 2)
        {
            cRespuesta respuesta;
            factura.TotalCobrado = cCobrosBL.ObtenerImporteCobrado(factura.ContratoCodigo.Value, factura.PeriodoCodigo, factura.FacturaCodigo.Value, fecha, out respuesta, precision);

            return respuesta;
        }

        /// <summary>
        /// Obtiene el Importe Facturado de un contrato 
        /// </summary>
        /// <param name="facturaCodigo">Código de la factrua</param>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="prefacturas">True: Solo prefacturas; False: Ninguna prefactura; NULL: Todas </param>
        /// <param name="periodosSaldo">True: Obtiene el importe facturado solo desde el periodo de inicio del saldo</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>El importe facturado obtenido </returns>
        public static decimal ObtenerImporteFacturado(int contratoCod, bool? prefacturas, bool periodosSaldo, out cRespuesta respuesta, int precision = 2)
        {
            return ObtenerImporteFacturado(null, contratoCod, null, null, null, prefacturas, periodosSaldo, out respuesta, precision);
        }

        /// <summary>
        /// Obtiene el Importe Facturado de un contrato en un periodo y una fecha determinada (de la ultima factura)
        /// Si no se indica la version se obtendrá el importe Facturado de la ultima versión de la factura.
        /// </summary>
        /// <param name="facturaCodigo">Código de la factrua</param>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="periodoCod">Código del Periodo</param>
        /// <param name="version">Código de la Versión (si el valor es null se obtendrá el importe Facturado de la ultima versión)</param>
        /// <param name="fecha">Fecha </param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>El importe facturado obtenido </returns>
        public static decimal ObtenerImporteFacturado(short? facturaCodigo, int contratoCod, string periodoCod, short? version, Nullable<DateTime> fecha, out cRespuesta respuesta, int precision = 2)
        {
            return ObtenerImporteFacturado(facturaCodigo, contratoCod, periodoCod, version, fecha, null, false, out respuesta, precision);
        }
        /// <summary>
        /// Obtiene el Importe Facturado de un contrato en un periodo y una fecha determinada (de la ultima factura)
        /// Si no se indica la version se obtendrá el importe Facturado de la ultima versión de la factura.
        /// </summary>
        /// <param name="facturaCodigo">Código de la factrua</param>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="periodoCod">Código del Periodo</param>
        /// <param name="version">Código de la Versión (si el valor es null se obtendrá el importe Facturado de la ultima versión)</param>
        /// <param name="fecha">Fecha </param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>El importe facturado obtenido </returns>
        public static decimal ObtenerImporteFacturadoSOA(string codExplo ,short? facturaCodigo, int contratoCod, string periodoCod, short? version, Nullable<DateTime> fecha, out cRespuesta respuesta)
        {
            return ObtenerImporteFacturadoSOA(codExplo,facturaCodigo, contratoCod, periodoCod, version, fecha, null, false, out respuesta);
        }
        /// <summary>
        /// Obtiene el Importe Facturado de un contrato en un periodo y una fecha determinada (de la ultima factura)
        /// Si no se indica la version se obtendrá el importe Facturado de la ultima versión de la factura.
        /// </summary>
        /// <param name="facturaCodigo">Código de la factrua</param>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="periodoCod">Código del Periodo</param>
        /// <param name="version">Código de la Versión (si el valor es null se obtendrá el importe Facturado de la ultima versión)</param>
        /// <param name="fecha">Fecha </param>
        /// <param name="prefacturas">True: Solo prefacturas; False: Ninguna prefactura; NULL: Todas </param>
        /// <param name="periodosSaldo">True: Obtiene el importe facturado solo desde el periodo de inicio del saldo</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>El importe facturado obtenido </returns>
        public static decimal ObtenerImporteFacturadoSOA(string codExplo, short? facturaCodigo, int contratoCod, string periodoCod, short? version, Nullable<DateTime> fecha, bool? prefacturas, bool periodosSaldo, out cRespuesta respuesta, int precision = 2)
        {
            decimal resultado = 0;
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                resultado = facturasDL.ObtenerImporteFacturadoSOA(codExplo, facturaCodigo, contratoCod, periodoCod, version, fecha, prefacturas, periodosSaldo, out respuesta, precision);
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
        /// <param name="facturaCodigo">Código de la factrua</param>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="periodoCod">Código del Periodo</param>
        /// <param name="version">Código de la Versión (si el valor es null se obtendrá el importe Facturado de la ultima versión)</param>
        /// <param name="fecha">Fecha </param>
        /// <param name="prefacturas">True: Solo prefacturas; False: Ninguna prefactura; NULL: Todas </param>
        /// <param name="periodosSaldo">True: Obtiene el importe facturado solo desde el periodo de inicio del saldo</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>El importe facturado obtenido </returns>
        public static decimal ObtenerImporteFacturado(short? facturaCodigo, int contratoCod, string periodoCod, short? version, Nullable<DateTime> fecha, bool? prefacturas, bool periodosSaldo, out cRespuesta respuesta, int precision = 2)
        {
            decimal resultado = 0;
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                resultado = facturasDL.ObtenerImporteFacturado(facturaCodigo, contratoCod, periodoCod, version, fecha, prefacturas, periodosSaldo, out respuesta, precision);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
        /// <summary>
        /// Obtiene el importe pendiente de cobrar (Si el importe cobrado es mayor al facturado será negativo el importe pendiente)
        /// </summary>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="efectosPendientes">True indica que debe tener en cuenta los efectos pendientes de remesar y no rechazados, False que no.</param>
        /// <param name="entregasACuenta">True indica que solo tiene en cuenta los cobros por entregas a cuenta</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Importe pendiente</returns>
        public static decimal ObtenerImportePendiente(short facturaCodigo, int contratoCodigo, string periodoCodigo, short sociedadCodigo, bool efectosPendientes, bool entregasACuenta, out cRespuesta respuesta)
        {
            short puntoPagoCodigo = 99;
            short medioPagoCodigo = 99;

            respuesta = cParametroBL.GetShort("PUNTO_PAGO_ENTREGAS_A_CTA", out puntoPagoCodigo);

            if (respuesta.Resultado == ResultadoProceso.OK)
                respuesta = cParametroBL.GetShort("MEDIO_PAGO_ENTREGAS_A_CTA", out medioPagoCodigo);

            if (respuesta.Resultado == ResultadoProceso.OK)
                return ObtenerImporteFacturado(facturaCodigo, contratoCodigo, periodoCodigo, null, null, out respuesta) - cCobrosBL.ObtenerImporteCobrado(contratoCodigo, periodoCodigo, facturaCodigo, null, entregasACuenta == true ? (short?)medioPagoCodigo : null, entregasACuenta == true ? (short?)puntoPagoCodigo : null, false, null, null, null, out respuesta) - (efectosPendientes ? cEfectosPendientesBL.ObtenerImportePendienteARemesar(contratoCodigo, periodoCodigo, facturaCodigo, sociedadCodigo, false, out respuesta) : 0);

            return 0;
        }
        /// Obtiene el importe pendiente de cobrar (Si el importe cobrado es mayor al facturado será negativo el importe pendiente)
        /// </summary>
        ///<param name="codExplo">Código explotación</param>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="efectosPendientes">True indica que debe tener en cuenta los efectos pendientes de remesar y no rechazados, False que no.</param>
        /// <param name="entregasACuenta">True indica que solo tiene en cuenta los cobros por entregas a cuenta</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Importe pendiente</returns>
        public static decimal ObtenerImportePendienteSOA(string CodExplo, short facturaCodigo, int contratoCodigo, string periodoCodigo, short sociedadCodigo, bool efectosPendientes, bool entregasACuenta, out cRespuesta respuesta)
        {
            short puntoPagoCodigo = 99;
            short medioPagoCodigo = 99;
            decimal impFacturado = 0;
            decimal impCobrado = 0;
            decimal impEfectosPendiente = 0;
            decimal impPendiente = 0;

            respuesta = cParametroBL.GetShortSOA("PUNTO_PAGO_ENTREGAS_A_CTA", CodExplo, out puntoPagoCodigo);

            if (respuesta.Resultado == ResultadoProceso.OK)
                respuesta = cParametroBL.GetShortSOA("MEDIO_PAGO_ENTREGAS_A_CTA", CodExplo, out medioPagoCodigo);
            
            if (respuesta.Resultado == ResultadoProceso.OK)
                impFacturado = ObtenerImporteFacturadoSOA(CodExplo, facturaCodigo, contratoCodigo, periodoCodigo, null, null, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
                impCobrado = cCobrosBL.ObtenerImporteCobradoSOA(CodExplo, contratoCodigo, periodoCodigo, facturaCodigo, null, entregasACuenta == true ? (short?)medioPagoCodigo : null, entregasACuenta == true ? (short?)puntoPagoCodigo : null, false, null, null, null, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK && efectosPendientes)
                impEfectosPendiente = cEfectosPendientesBL.ObtenerImportePendienteARemesarSOA(CodExplo, contratoCodigo, periodoCodigo, facturaCodigo, sociedadCodigo, false, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                impPendiente = impFacturado - impCobrado - impEfectosPendiente;
                //return ObtenerImporteFacturadoSOA(CodExplo, facturaCodigo, contratoCodigo, periodoCodigo, null, null, out respuesta) 
                //        -  cCobrosBL.ObtenerImporteCobradoSOA(CodExplo, contratoCodigo, periodoCodigo, facturaCodigo, null, entregasACuenta == true ? (short?)medioPagoCodigo : null, entregasACuenta == true ? (short?)puntoPagoCodigo : null, false, null, null, null, out respuesta) 
                //        - (efectosPendientes ? cEfectosPendientesBL.ObtenerImportePendienteARemesarSOA(CodExplo, contratoCodigo, periodoCodigo, facturaCodigo, sociedadCodigo, false, out respuesta) : 0);
            }
            
            return impPendiente;
        }


        /// <summary>
        /// Obtiene el importe pendiente de cobrar (Si el importe cobrado es mayor al facturado será negativo el importe pendiente)
        /// </summary>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="efectosPendientes">True indica que debe tener en cuenta los efectos pendientes de remesar y no rechazados, False que no.</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Importe pendiente</returns>
        public static decimal ObtenerImportePendienteSOA(string codExplo,short facturaCodigo, int contratoCodigo, string periodoCodigo, short sociedadCodigo, bool efectosPendientes, out cRespuesta respuesta)
        {
            return ObtenerImportePendienteSOA(codExplo,facturaCodigo, contratoCodigo, periodoCodigo, sociedadCodigo, efectosPendientes, false, out respuesta);
        }

        /// <summary>
        /// Obtiene el importe pendiente de cobrar (Si el importe cobrado es mayor al facturado será negativo el importe pendiente)
        /// </summary>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="efectosPendientes">True indica que debe tener en cuenta los efectos pendientes de remesar y no rechazados, False que no.</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Importe pendiente</returns>
        public static decimal ObtenerImportePendiente(short facturaCodigo, int contratoCodigo, string periodoCodigo, short sociedadCodigo, bool efectosPendientes, out cRespuesta respuesta)
        {
            return ObtenerImportePendiente(facturaCodigo, contratoCodigo, periodoCodigo, sociedadCodigo, efectosPendientes, false, out respuesta);
        }



        /// <summary>
        /// Obtiene el Importe Facturado de un contrato en un periodo y una fecha determinada (de la ultima factura)
        /// Si no se indica la version se obtendrá el importe Facturado de la ultima versión de la factura.
        /// </summary>
        /// <param name="factura">Objeto factura</param>
        /// <param name="fecha">Fecha </param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si todo ha ido bien, false en caso de haber errores</returns>
        public static bool ObtenerTotalFacturado(ref cFacturaBO factura, DateTime? fecha, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                decimal importe = facturasDL.ObtenerImporteFacturado(factura.FacturaCodigo, factura.ContratoCodigo.Value, factura.PeriodoCodigo, factura.Version, fecha, null, false, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    factura.TotalFacturado = importe;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta.Resultado == ResultadoProceso.OK;
        }

        public static bool ObtenerTotalFacturado(ref cFacturaBO factura, DateTime? fecha, out cRespuesta respuesta, int precision)
        {
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                decimal importe = facturasDL.ObtenerImporteFacturado(factura.FacturaCodigo, factura.ContratoCodigo.Value, factura.PeriodoCodigo, factura.Version, fecha, null, false, out respuesta, precision);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    factura.TotalFacturado = importe;
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta.Resultado == ResultadoProceso.OK;
        }

        /// <summary>
        /// Obtiene las facturas de un contrato cuya versión del contrato sea menor o igual que la del contrato pasado como parámetro
        /// </summary>
        /// <param name="contratoBO">Objeto contrato, es necesario rellenar el codigo del contrato y la versión</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPorContrato(cContratoBO contratoBO, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.ObtenerPorContrato(ref facturas, contratoBO, null, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas de un código de contrato y versión pasados como parámetro
        /// </summary>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="version">Versión del contrato</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPorContrato(int contratoCodigo, short version, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cContratoBO contrato = new cContratoBO();
                contrato.Codigo = contratoCodigo;
                contrato.Version = version;
                new cFacturasDL().ObtenerPorContrato(ref facturas, contrato, null, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas de un código de contrato y versión pasados como parámetro
        /// </summary>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="version">Versión del contrato</param>
        /// <param name="ordenDesc">Determina si se desea que se ordene de forma descendente</param>
        /// <param name="soloVersionCtr">Si vale true seleccionará solo las facturas que tienen la versión del contrato, 
        /// si vale false seleccionará las factuaras hasta la versión del contrato y si vale null todas las facturas</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPorContrato(int contratoCodigo, short version, bool? ordenDesc, bool? soloVersionCtr, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cContratoBO contrato = new cContratoBO();
                contrato.Codigo = contratoCodigo;
                contrato.Version = version;

                new cFacturasDL().ObtenerPorContrato(ref facturas, contrato, ordenDesc, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas de un periodo y una zona (todas las versiones de factura)
        /// </summary>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="zonaCodigo">Código de la zona</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPorPeriodoYZona(string periodoCodigo, string zonaCodigo, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.ObtenerPorPeriodoYZona(ref facturas, periodoCodigo, zonaCodigo, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas de un periodo, una zona y un lote(todas las versiones de factura)
        /// </summary>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="zonaCodigo">Código de la zona</param>
        /// <param name="lote">Número del lote</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPorPeriodoZonaYLote(string periodoCodigo, string zonaCodigo, int lote, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                new cFacturasDL().ObtenerPorPeriodoZonaYLote(ref facturas, periodoCodigo, zonaCodigo, lote, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas pendientes de cobro de un contrato en concreto
        /// Rellena los campos del BO TotalCobrado y TotalFacturado
        /// </summary>
        /// <param name="contratoCod">codigo del Contrato</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPendientesDeCobro(int contratoCod, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.ObtenerPendientesDeCobro(ref facturas, contratoCod, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas pendientes de cobro de un cliente
        /// </summary>
        /// <param name="clienteCodigo">Código del cliente</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPendientesDeCobroPorCliente(int clienteCodigo, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                new cFacturasDL().ObtenerPendientesDeCobroPorCliente(ref facturas, clienteCodigo, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas pendientes de cobro de un contrato en concreto
        /// Obtiene las facturas mediante el filtro indicado
        /// </summary>
        /// <param name="contratoCod">codigo del Contrato</param>
        /// <param name="periodoCodigo">codigo del Periodo</param>
        /// <param name="facturaCodigo">codigo de la factura</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> Obtener(int contratoCod, string periodoCodigo, short facturaCodigo, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();

            cFacturaBO factura = new cFacturaBO();
            factura.ContratoCodigo = contratoCod;
            factura.PeriodoCodigo = periodoCodigo;
            factura.FacturaCodigo = facturaCodigo;

            new cFacturasDL().ObtenerUltimaVersion(ref factura, out respuesta);
            if (respuesta.Resultado == ResultadoProceso.OK)
                facturas.Add(factura);

            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas con el importe cobrado mayor al facturado
        /// Rellena los campos del BO TotalCobrado y TotalFacturado
        /// </summary>
        /// <param name="contratoCod">codigo del Contrato</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerSobreCobradas(int contratoCod, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            new cFacturasDL().ObtenerSobreCobradas(ref facturas, contratoCod, out respuesta);

            return facturas;
        }

        public static cBindableList<cFacturaBO> ObtenerPorTipoDeuda(int contratoCod, cFacturasDL.TipoDeuda tipoDeuda,  out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();

            if (contratoCod > 0)
            {
                new cFacturasDL().ObtenerPorTipoDeuda(ref facturas, contratoCod, tipoDeuda, out respuesta);
            }

            return facturas;
        }

        /// <summary>
        /// Obtiene las facturas pendientes de cobro
        /// Rellena los campos del BO TotalCobrado y TotalFacturado
        /// </summary>
        /// <param name="ptesCobro">Objeto que contiene los parámetros para la selección</param>
        /// <param name="mayoresAlPeriodoInicioExplotacion">Se obtendrán las facturas de los peridos mayores al inicio de actividad si es 'true', y todas en caso contrario</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPendientesDeCobro(SeleccionPtesCobro ptesCobro, bool mayoresAlPeriodoInicioExplotacion, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                //Si el campo mayoresAlPeriodoInicioExplotacion está a "true", 
                //sólo se obtendrán las facturas pendientes de cobro de los periodos mayores al inicio de actividad
                if (mayoresAlPeriodoInicioExplotacion)
                    ptesCobro.Desde.PeriodoD = String.IsNullOrEmpty(ptesCobro.Desde.PeriodoD) ? cParametroBL.ObtenerValor("PERIODO_INICIO", out respuesta) : ptesCobro.Desde.PeriodoD;
                if (respuesta.Resultado == ResultadoProceso.OK)
                    new cFacturasDL().ObtenerPendientesDeCobro(ref facturas, ptesCobro, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene una lista enlazable
        /// </summary>
        /// <param name="seleccion">Selección realizada</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>Lista enlazable (si no se encuentran datos devuelve una lista vacía)</returns>
        public static cBindableList<cFacturaBO> Obtener(cFacturasSeleccionBO seleccion, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = null;
            new cFacturasDL().Obtener(ref facturas, seleccion, out respuesta);
            return facturas != null ? facturas : new cBindableList<cFacturaBO>();
        }
        /// <summary>
        /// Obtiene una lista enlazable
        /// </summary>
        /// <param name="seleccion">Selección realizada</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>Lista enlazable (si no se encuentran datos devuelve una lista vacía)</returns>
        public static cBindableList<cFacturaBO> ObtenerSOA(cFacturasSeleccionBO seleccion, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = null;
            new cFacturasDL().ObtenerSOA(ref facturas, seleccion, out respuesta);
            return facturas != null ? facturas : new cBindableList<cFacturaBO>();
        }
        /// <summary>
        /// Inserta expedientes de corte a partir de una lista de facturas
        /// </summary>
        /// <param name="facturas">Lista de facturas pendientes de cobrar</param>
        /// <param name="numExpedientes">Número de expedientes de corte insertados</param>
        /// <returns>Respuesta</returns>
        public static cRespuesta InsertarExpedientesCorte(cBindableList<cFacturaBO> facturas, short? tipo, out int numExpedientes, out string log)
        {
            cRespuesta respuesta = new cRespuesta();
            numExpedientes = 0;
            log = String.Empty;

            if (facturas != null)
            {
                //Crear los expedientes de corte
                cBindableList<cExpedienteCorteBO> expedientesCorte = GenerarExpedientesCorte(facturas);

                //Insertar los expedientes de corte
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    for (int i = 0; i < expedientesCorte.Count && respuesta.Resultado != ResultadoProceso.Error; i++)
                    {
                        cExpedienteCorteBO refExpCorte = expedientesCorte[i];
                        refExpCorte.TipoExpedienteCorteCodigo = tipo;
                        //Si el expediente de corte no está cerrado 
                        if (!cExpedientesCorteBL.Existe(refExpCorte.ContratoCodigo.Value, false, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                        {
                            respuesta = cExpedientesCorteBL.Insertar(ref refExpCorte, out log);
                            if (respuesta.Resultado == ResultadoProceso.OK)
                                numExpedientes++;
                        }
                    }
                    if (respuesta.Resultado != ResultadoProceso.Error)
                        scope.Complete();
                    else
                        numExpedientes = 0;
                }
            }

            return respuesta;
        }

        /// <summary>
        /// Genera expedientes de corte a partir de una lista de facturas
        /// </summary>
        /// <param name="facturas">Lista con las facturas pendientes de cobro para generar sus expedientes de corte</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cExpedienteCorteBO> GenerarExpedientesCorte(cBindableList<cFacturaBO> facturas)
        {
            //Agrupar por contrato
            SortedList slExpedientesCorte = new SortedList(); //Código -> Código de contrato. Valor -> Exp.Corte del contrato
            foreach (cFacturaBO factura in facturas)
            {
                cExpedienteCorteBO expedienteCorte = (cExpedienteCorteBO)slExpedientesCorte[factura.ContratoCodigo.ToString()];
                expedienteCorte = expedienteCorte ?? new cExpedienteCorteBO();
                expedienteCorte.ContratoCodigo = factura.ContratoCodigo;
                expedienteCorte.NumeroFacturas = (expedienteCorte.NumeroFacturas ?? 0) + 1;
                expedienteCorte.ImporteDeuda = (expedienteCorte.ImporteDeuda ?? 0) + factura.TotalFacturado - factura.TotalCobrado;
                expedienteCorte.FechaRegistro = AcuamaDateTime.Now;

                //Almacenamos separados por ; los periodos de las facturas de un mismo contrato incluidos en la generación del expediente de corte
                expedienteCorte.PeriodosDeuda = (!String.IsNullOrWhiteSpace(expedienteCorte.PeriodosDeuda) ? (expedienteCorte.PeriodosDeuda + ";") : String.Empty) + factura.PeriodoCodigo;
                slExpedientesCorte[factura.ContratoCodigo.ToString()] = expedienteCorte;
            }

            //Convertir SortedList a BindableList
            cBindableList<cExpedienteCorteBO> expedientesCorte = new cBindableList<cExpedienteCorteBO>();
            foreach (DictionaryEntry key in slExpedientesCorte)
                expedientesCorte.Add((cExpedienteCorteBO)key.Value);

            return expedientesCorte;
        }

        /// <summary>
        /// Obtenemos una lista de cobros.
        /// </summary>
        /// <param name="contratoCod">Código del contrato</param>
        /// <param name="periodoCod">Código del periodo</param>
        /// <param name="periodoCod">Código de la factura</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>lista de cobros de la factura</returns>
        public static cBindableList<cCobroBO> ObtenerCobros(int contratoCod, short? facturaCod, string periodoCod, out cRespuesta respuesta)
        {
            cBindableList<cCobroBO> cobrosLista = null;
            if (periodoCod != null)
                cCobrosBL.ObtenerPorFactura(contratoCod, facturaCod, periodoCod, out cobrosLista, out respuesta);
            else
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
            }
            return cobrosLista;
        }

        /// <summary>
        /// Actualizar lineas de factura/s (unidades,total,importe impuesto y la base), según el consumo de la cabecera.
        /// Se puede filtrar por Periodo,Contrato y Version
        /// </summary>
        /// <param name="factura">Objeto Factura.</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ActualizarLineas(cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            cLineasFacturaDL lineasFacturaDL = new cLineasFacturaDL();
            cBindableList<cCobroLinBO> cobroLineas = null;
            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    #region "Precisión del redondeo (facE: 2, default:4)"
                    //Cuando se crea una nueva versión, el metodo InsertarLineas las recalcula con precisión que corresponde.
                    //Pero si sólo se actualiza, tenemos que forzar la actualización de todas las lineas a la precisión correcta.
                    bool esFacE = EsFacE(factura);
                    int  precisionBase = basePrecision(factura);

                    cBindableList<cLineaFacturaBO> facLineas = ObtenerLineas(ref factura, out respuesta);
                    foreach (cLineaFacturaBO fl in facLineas)
                    {
                        new cLineasFacturaBL().Actualizar(fl, esFacE, precisionBase, out respuesta);
                    }

                    #endregion


                    resultado = new cFacturasDL().ActualizarLineas(factura, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrEmpty(factura.Numero))
                    {
                        cobroLineas = cCobrosLinBL.ObtenerPorFactura(factura.FacturaCodigo.Value, factura.PeriodoCodigo, factura.ContratoCodigo.Value, factura.Version.Value, out respuesta);
                        respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
                        for (int j = 0; j < cobroLineas.Count && respuesta.Resultado == ResultadoProceso.OK; j++)
                        {
                            cBindableList<cLineaFacturaBO> facLin = new cLineasFacturaBL().ObtenerTodos(factura, out respuesta);
                            if (respuesta.Resultado == ResultadoProceso.OK && facLin.Count > 0)
                                cCobrosLinBL.GenerarDesgloses(cobroLineas[j].SociedadCodigo, cobroLineas[j].PPagoCodigo, cobroLineas[j].Numero, cobroLineas[j].Linea, true, true, out respuesta);
                        }
                    }
                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
                    else
                        cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta.Resultado == ResultadoProceso.OK;
        }

        /// <summary>
        /// Simula una factura a partir del contrato y el consumo, son obligatorios los parámetros contrato y consumo
        /// Devuelve el importe total de la factura y el consumo por habitante y día en el caso de que se le pase también el número de habitantes por suministro
        /// </summary>
        /// <param name="contrato">Código del contrato</param>
        /// <param name="consumo">Consumo a simular</param>
        /// <param name="numeroHabitantes">Número de habitantes por suministro</param>
        /// <param name="importeTotal">Importe total calculado</param>
        /// <param name="cnsHabDia">Consumo por habitante y día en litros</param>
        /// <returns>Respuesta con el resultado de la operación</returns>
        public static cRespuesta SimularConsumo(int contrato, int consumo, int? numeroHabitantes, out decimal importeTotal, out int? cnsHabDia)
        {
            cRespuesta respuesta = null;
            importeTotal = 0;
            cnsHabDia = 0;
            try
            {
                respuesta = new cFacturasDL().SimularConsumo(contrato, consumo, numeroHabitantes, out importeTotal, out cnsHabDia);
            }
            catch (Exception ex)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta;
        }

        /// Simula una factura a partir del contrato y el consumo, son obligatorios los parámetros contrato y consumo
        /// Devuelve el importe total de la factura y el consumo por habitante y día en el caso de que se le pase también el número de habitantes por suministro
        /// </summary>
        /// <param name="contrato">Código del contrato</param>
        /// <param name="consumo">Consumo a simular</param>
        /// <param name="numeroHabitantes">Número de habitantes por suministro</param>
        /// <param name="importeTotal">Importe total calculado</param>
        /// <param name="cnsHabDia">Consumo por habitante y día en litros</param>
        /// <returns>Respuesta con el resultado de la operación</returns>
        public static cRespuesta SimularConsumoDetallado(int contrato, int consumo, int? numeroHabitantes, out cBindableList<cSimuladorDetalladoBO> serviciosSimulado)
        {
            cRespuesta respuesta = null;
            serviciosSimulado = new cBindableList<cSimuladorDetalladoBO>();
            try
            {
                respuesta = new cFacturasDL().SimularConsumoDetallado(contrato, consumo, numeroHabitantes, out serviciosSimulado);
            }
            catch (Exception ex)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta;
        }


        /// <summary>
        /// Aplicar los consumos comunitarios (siempre que la zona este aperturada)
        /// </summary>
        /// <param name="periodoPeriodo">código del periodo</param>
        /// <param name="zonaCodigo">código de la zona</param>
        /// <param name="usarActualizarFacCtrVersion">True si lo que deseas es uasar y actualizar la última versión del contrato en la factura , False si no</param>
        /// <returns>Resultado de la operación</returns>
        public static cRespuesta AplicarConsumosComunitarios(string periodoCodigo, string zonaCodigo, bool usarYActualizarFacCtrVersion, int? ctrRaiz)
        {
            cRespuesta respuesta = new cFacturasDL().AplicarConsumosComunitarios(periodoCodigo, zonaCodigo, usarYActualizarFacCtrVersion, ctrRaiz);
            return respuesta;
        }

        /// <summary>
        /// Actualizar lineas de todas las facturas. Son obligatorios los campos zonaCodigo, periodoCodigo, loteD, loteH.
        /// </summary>
        /// <param name="zonaCodigo">Código de la zona</param>
        /// <param name="periodoCodigo">Código del período</param>
        /// <param name="loteD">Lote desde</param>
        /// <param name="loteH">Lote hasta</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ActualizarConsumoLineas(string zonaCodigo, string periodoCodigo, int loteD, int loteH, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                resultado = new cFacturasDL().ActualizarConsumoLineas(zonaCodigo, periodoCodigo, loteD, loteH, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Rellena el objeto Serie de la factura
        /// </summary>
        /// <param name="factura">factura</param>
        /// <param name="respuesta">respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ObtenerSerie(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;

            if (factura != null && factura.SerieCodigo.HasValue && factura.SociedadCodigo.HasValue)
            {
                cSerieBO serie = new cSerieBO();
                serie.Codigo = factura.SerieCodigo.Value;
                serie.CodSociedad = factura.SociedadCodigo.Value;
                resultado = cSerieBL.Obtener(ref serie, out respuesta);
                if (resultado)
                    factura.Serie = serie;
            }
            else
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
            }

            return resultado;
        }

        /// <summary>
        /// Rellena el objeto Sociedad de la factura
        /// </summary>
        /// <param name="factura">factura</param>
        /// <param name="respuesta">respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ObtenerSociedad(ref cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultado = false;

            if (factura != null)
            {
                cSociedadBO sociedad = new cSociedadBO();
                sociedad.Codigo = factura.SociedadCodigo.Value;
                resultado = cSociedadBL.Obtener(ref sociedad, out respuesta);
                if (resultado)
                    factura.Sociedad = sociedad;
            }
            else
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
            }

            return resultado;
        }




        /// <summary>
        /// Inserta las líneas de una factura
        /// </summary>
        /// <param name="factura">cFacturaBO</param>
        /// <param name="respuesta">respuesta</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool InsertarLineas(cFacturaBO factura, out cRespuesta respuesta)
        {
            bool resultadoInsertar = true;
            respuesta = new cRespuesta();
            ArrayList lineasInsertadas = new ArrayList();
            cLineasFacturaBL linFacBL = new cLineasFacturaBL();
            cLineaFacturaBO linea;
            
            try
            {
                #region "Precisión del redondeo (facE: 2, default:4)"
                bool esFacE = EsFacE(factura);
                #endregion

                for (int i = 0; factura.LineasFactura != null && i < factura.LineasFactura.Count && resultadoInsertar; i++)
                {
                    linea = factura.LineasFactura[i];
                    //asignamos la clave de la cabecera a la linea 
                    linea.Periodo = factura.PeriodoCodigo;
                    linea.Contrato = factura.ContratoCodigo.Value;
                    linea.Version = factura.Version.Value;

                    resultadoInsertar = linFacBL.Insertar(ref linea, esFacE, basePrecision(factura), out respuesta);
                    if (resultadoInsertar)
                        lineasInsertadas.Add(linea);
                }

                cRespuesta respuestaBorrar;
                bool resultadoBorrar = true;
                if (!resultadoInsertar) //Si no se han insertado todas las líneas, borro las que se haya insertado
                    foreach (cLineaFacturaBO lineaInsertada in lineasInsertadas)
                        resultadoBorrar = resultadoBorrar && linFacBL.Borrar(lineaInsertada, out respuestaBorrar);

                //Asignar mensaje de error
                if (!resultadoInsertar) //No se ha podido insertar todas las líneas
                    if (resultadoBorrar) //Se han borrado las líneas insertadas tras el fallo de insertar una línea
                        cExcepciones.ControlarER(new Exception(Resource.errorLineasNoInsertadas), TipoExcepcion.Informacion, out respuesta);
                    else //Ha fallado la inserción de alguna línea y no se ha podido borrar todas las líneas insertadas
                        cExcepciones.ControlarER(new Exception(Resource.errorSoloSeHanInsertadoAlgunasLineas), TipoExcepcion.Informacion, out respuesta);
            }
            catch (Exception ex)
            {
                resultadoInsertar = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultadoInsertar;
        }

        /// <summary>
        /// Inserta una nueva versión de la factura.
        /// </summary>
        /// <param name="factura">Objeto a actualizar. Tras la ejecución este objeto contiene la factura rectificativa</param>
        /// <param name="usuarioRegistro">Código del usuario de registro</param>
        /// <param name="log">Log con información del proceso</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool Duplicar(ref cFacturaBO factura, string usuarioRegistro, out string log, out cRespuesta respuesta)
        {
            bool resultado = false;
            log = String.Empty;
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    string errorStrLectura = ValidarLectura(factura);

                    if (errorStrLectura == String.Empty)
                    {
                        cFacturaBO facturaRectif = factura.Copiar(); //facturaRecif = Factura Rectificativa
                        //Obtener la serie relacionada
                        resultado = ObtenerSerie(ref factura, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            //Sino tiene (es decir es = 0) dejaremos la serie que tenga
                            if (factura.Serie.SerieCodRel > 0)
                            {
                                facturaRectif.SerieCodigo = factura.Serie.SerieCodRel;
                                //facturaRectif.Numero = factura.Serie.NumeroFactura + 1;
                                string explotacionCodigo = null;
                                if (cParametroBL.GetString("EXPLOTACION_CODIGO", out explotacionCodigo).Resultado == ResultadoProceso.OK)

                                    facturaRectif.Numero = string.Format("{0}{1}{2}", AcuamaDateTime.Today.Year.ToString().Substring(2, 2), (Convert.ToInt32(explotacionCodigo) * 100).ToString(), (factura.Serie.NumeroFactura + 1).ToString());
                            }
                            //Insertamos la cabecera de la facturaRectif con la fecha de hoy y el usuario del sistema
                            facturaRectif.Fecha = AcuamaDateTime.Today;
                            facturaRectif.FechaRegistro = AcuamaDateTime.Now;
                            facturaRectif.UsuarioRegistro = usuarioRegistro;
                            facturaRectif.TipoRect = "R4";//por defecto Factura Rectificativa (Resto), ya que es una campo obligatorio en la rectificativa
                            facturaRectif.FechaContabilizacion = facturaRectif.FechaContabilizacionAnulada = null;
                            facturaRectif.UsuarioContabilizacion = facturaRectif.UsuarioContabilizacionAnulada = null;

                            if (facturaRectif.EnvioSAP.HasValue && !facturaRectif.EnvioSAP.Value)
                            {
                                ObtenerSerie(ref facturaRectif, out respuesta);
                                if (respuesta.Resultado == ResultadoProceso.OK && facturaRectif.Serie != null)
                                    facturaRectif.EnvioSAP = facturaRectif.Serie.EnvioSAP;
                            }
                            string errorStr = Validar(facturaRectif);

                            ObtenerContrato(ref factura, out respuesta);

                            cSERESBO estado = new cSERESBO();
                            if (respuesta.Resultado == ResultadoProceso.OK)
                            {
                                // TODO: ***** SE COMENTA TEMPORALMENTE PARA QUE PUEDAN RECTIFICAR EN SVB 23/03/2018 *************
                                //       ***** LES DA ERROR PORQUE cSERESBL.ObtenerUltimaPorFactura NO ENCUENTRA EL REGISTRO *****

                                //estado = cSERESBL.ObtenerUltimaPorFactura(factura.Numero, String.IsNullOrEmpty(factura.Contrato.PagadorDocIden) ? factura.Contrato.TitularDocIden : factura.Contrato.PagadorDocIden, out respuesta);

                                //if ((respuesta.Resultado == ResultadoProceso.SinRegistros && factura.EnvSERES == "R") || (respuesta.Resultado == ResultadoProceso.OK && estado != null && (estado.EstadoCodigo == "DEPO" || estado.EstadoCodigo == "TRAM" || estado.EstadoCodigo == "RGTDA")))
                                //    errorStr += Resource.facturaNoSePuedeRectificarEstadoPendiente + Environment.NewLine;
                                //respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
                                /////////////////

                                //Obtener la última versión del contrato para las comprobaciones de facturaE y actualización del campo facEnvSERES de la rectificativa
                                cContratoBO ctr = new cContratoBO();
                                ctr.Codigo = facturaRectif.ContratoCodigo.Value;
                                cContratoBL.ObtenerUltimaVersion(ref ctr, out respuesta);
                                if (respuesta.Resultado == ResultadoProceso.OK)
                                {
                                    decimal? totalFacturado = ObtenerImporteFacturado(facturaRectif.FacturaCodigo.Value, facturaRectif.ContratoCodigo.Value, facturaRectif.PeriodoCodigo, facturaRectif.Version.Value, null, null, false, out respuesta);
                                    if (respuesta.Resultado == ResultadoProceso.OK)
                                    {
                                        // Si la anterior era rectificativa esta tambien o si cumple las condiciones para facture
                                        if (!String.IsNullOrEmpty(facturaRectif.EnvSERES) || ((ctr.FacturaeActiva.HasValue && ctr.FacturaeActiva.Value) && (totalFacturado >= ctr.FacturaeMinimo)))
                                            facturaRectif.EnvSERES = "P";
                                    }
                                }

                                if (respuesta.Resultado == ResultadoProceso.OK && errorStr == String.Empty)
                                    resultado = new cFacturasDL().Insertar(ref facturaRectif, out respuesta);
                                else
                                {
                                    resultado = false;
                                    cExcepciones.ControlarER(new Exception(errorStr), TipoExcepcion.Informacion, out respuesta);
                                }
                            }
                        }
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            //Obtenemos las lineas de la factura pasada por parámetro
                            ObtenerLineas(ref factura, out respuesta);
                            //Si el resultado es sin registros se le asigna ok, porque pueden haber facturas sin líneas de las cuales queramos generar rectificativa.
                            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
                            if (respuesta.Resultado == ResultadoProceso.OK)
                            {
                                facturaRectif.LineasFactura = factura.LineasFactura;
                                resultado = InsertarLineas(facturaRectif, out respuesta);
                            }
                            if (respuesta.Resultado == ResultadoProceso.OK)
                            {
                                Obtener(ref factura, out respuesta);

                                if (respuesta.Resultado == ResultadoProceso.OK)
                                {
                                    //Actualizamos de la version anterior los campos Reftificacion
                                    factura.SerieRectificativa = facturaRectif.SerieCodigo;
                                    factura.NumeroRectificativa = facturaRectif.Numero;
                                    factura.FechaFactRectificativa = facturaRectif.Fecha;
                                    resultado = Actualizar(factura, false, out log, out respuesta);
                                }
                                else
                                    resultado = false;
                            }
                        }

                        //Al "Actualizar líneas" se generan los desgloses sólo si ya tenía desgloses.
                        //Al no tener, porque la acabo de crear, hay que comprobar si la rectificada tiene, y generarlos en la rectificativa en caso de que sí los tenga.
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            if (factura.FacturaCodigo.HasValue && !String.IsNullOrEmpty(factura.PeriodoCodigo) && factura.ContratoCodigo.HasValue && factura.Version.HasValue)
                                respuesta = GenerarDesgloseDeLineasEnRectificativa(factura.FacturaCodigo.Value, factura.PeriodoCodigo, factura.ContratoCodigo.Value, factura.Version.Value);
                        }

                        //Actualizar líneas
                        if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                        {
                            ActualizarLineas(facturaRectif, out respuesta);
                            if (respuesta.Resultado == ResultadoProceso.OK)
                                factura = facturaRectif;
                        }

                        //---------------------------------------------------------------------------------------
                        //Generación del cobro rectificativo a partir de la factura duplicada,
                        //si existe al menos 1 cobro con importe distinto de 0. Y además tenemos al menos una línea de factura
                        //---------------------------------------------------------------------------------------
                        if (respuesta.Resultado == ResultadoProceso.OK && factura.LineasFactura.Count > 0)
                            respuesta = cCobrosBL.GenerarRectificativo(factura, usuarioRegistro);


                        if (respuesta.Resultado == ResultadoProceso.OK)
                            scope.Complete();
                    }
                    else
                        cExcepciones.ControlarER(new Exception(errorStrLectura), TipoExcepcion.Informacion, out respuesta);
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
        /// Indica si el importe de efectos pendientes a remesar es mayor al importe pendiente de cobrar de la factura
        /// (SOLO es una indicación, NO quiere decir que si es True no deba continuar)
        /// </summary>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <param name="sociedadCodigo">Código de la sociedad</param>
        /// <param name="log">Log con información del proceso</param>                                
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si es mayor el importe de efectos pendientes a remesar que el importe pendiente de cobrar de la factura, False lo contrario</returns>
        public static bool ImporteEfectoPendienteMayorAImportePendiente(string periodoCodigo, int contratoCodigo, short facturaCodigo, short sociedadCodigo, out string log, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            log = String.Empty;

            if (!String.IsNullOrEmpty(periodoCodigo))
            {
                decimal importeEfectosPendientes = cEfectosPendientesBL.ObtenerImportePendienteARemesar(contratoCodigo, periodoCodigo, facturaCodigo, sociedadCodigo, false, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK && importeEfectosPendientes > 0)
                {
                    decimal importePendiente = ObtenerImportePendiente(facturaCodigo, contratoCodigo, periodoCodigo, sociedadCodigo, false, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK && importeEfectosPendientes > importePendiente)
                    {
                        log = Resource.factura + ' ' + string.Format("{0} {1}, {2} {3}", Resource.periodo, periodoCodigo, Resource.contrato, contratoCodigo) + ": " + Resource.val_LessOrEqual.Replace("@field1", Resource.importeEfePdteRemesar).Replace("@field2", Resource.importePdteCobrar);
                        return true;
                    }
                }
            }
            else
                respuesta.Resultado = ResultadoProceso.Error;

            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;

            return false;
        }

        /// <summary>
        /// Inserta una nueva versión de la factura para una prefactura que pertenece a una zona y periodod cerrada. Estableciendo
        /// sociedad, serie pasados por parámetro, fecha factura la del día actual y obteniendo el numerador de factura más 1 a partir de la serie
        /// </summary>
        /// <param name="preFactura">Objeto a actualizar. Tras la ejecución este objeto contiene la factura con la sociedad, serie que ha establecido
        /// el usuario, el número a partir del numerador de la serie que le llega por parámetro y la fecha de factura del día actual.</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool DuplicarPrefactura(ref cFacturaBO preFactura, string usuarioRegistro, out cRespuesta respuesta)
        {
            bool resultado = false;
            if (preFactura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    string errorStrLectura = ValidarLectura(preFactura);
                    if (errorStrLectura == String.Empty)
                    {
                        cFacturaBO facturaRectif = preFactura.Copiar();

                        ObtenerSerie(ref preFactura, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            //facturaRectif.Numero = preFactura.Serie.NumeroFactura + 1;
                            string explotacionCodigo = null;
                            if (cParametroBL.GetString("EXPLOTACION_CODIGO", out explotacionCodigo).Resultado == ResultadoProceso.OK)
                                facturaRectif.Numero = string.Format("{0}{1}{2}", AcuamaDateTime.Today.Year.ToString().Substring(1, 2), explotacionCodigo, (preFactura.Serie.NumeroFactura + 1).ToString());
                            facturaRectif.Fecha = AcuamaDateTime.Today;
                            facturaRectif.UsuarioRegistro = usuarioRegistro;
                            facturaRectif.TipoRect = "R4";//por defecto Factura Rectificativa (Resto), ya que es una campo obligatorio en la rectificativa
                            facturaRectif.FechaContabilizacion = facturaRectif.FechaContabilizacionAnulada = null;
                            facturaRectif.UsuarioContabilizacion = facturaRectif.UsuarioContabilizacionAnulada = null;
                        }
                        string errorStr = Validar(preFactura);
                        if (errorStr == String.Empty)
                            resultado = new cFacturasDL().Insertar(ref facturaRectif, out respuesta);
                        else
                        {
                            resultado = false;
                            cExcepciones.ControlarER(new Exception(errorStr), TipoExcepcion.Informacion, out respuesta);
                        }

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            //Obtenemos las lineas de la factura pasada por parámetro
                            ObtenerLineas(ref preFactura, out respuesta);
                            //Si el resultado es sin registros se le asigna ok, porque pueden haber facturas sin líneas de las cuales queramos generar rectificativa.
                            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
                            if (respuesta.Resultado == ResultadoProceso.OK)
                            {
                                facturaRectif.LineasFactura = preFactura.LineasFactura;
                                resultado = InsertarLineas(facturaRectif, out respuesta);
                            }
                        }

                        //Generamos el desglose de las líneas si en la factura rectificada las tenía.
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            if (preFactura.FacturaCodigo.HasValue && !String.IsNullOrEmpty(preFactura.PeriodoCodigo) && preFactura.ContratoCodigo.HasValue && preFactura.Version.HasValue)
                                respuesta = GenerarDesgloseDeLineasEnRectificativa(preFactura.FacturaCodigo.Value, preFactura.PeriodoCodigo, preFactura.ContratoCodigo.Value, preFactura.Version.Value);
                        }
                        if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                        {
                            Obtener(ref preFactura, out respuesta);
                            if (respuesta.Resultado == ResultadoProceso.OK)
                            {
                                //Actualizamos de la version anterior los campos Reftificacion
                                preFactura.SerieRectificativa = facturaRectif.SerieCodigo;
                                preFactura.NumeroRectificativa = facturaRectif.Numero;
                                preFactura.FechaFactRectificativa = facturaRectif.Fecha;
                                string log;
                                resultado = Actualizar(preFactura, false, out log, out respuesta);
                            }
                            else
                                resultado = false;
                        }
                        if (resultado && respuesta.Resultado == ResultadoProceso.OK)
                        {
                            ActualizarLineas(facturaRectif, out respuesta);
                            if (respuesta.Resultado == ResultadoProceso.OK)
                                preFactura = facturaRectif;
                        }
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            scope.Complete();
                    }
                    else
                        cExcepciones.ControlarER(new Exception(errorStrLectura), TipoExcepcion.Informacion, out respuesta);
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
        /// A partir de una factura donde su contrato se le ha realizado un cambio de titular, se realiza el cambio en la factura del contrato viejo al nuevo, de las siguientes formas:
        /// - Factura: Se anula la factura y a la factura nula se le realiza una rectificativa con el contrato nuevo. Fra. Actual -> Fra. Anula Actual -> Fra. Nuevo contrato
        /// - Prefactura: Se insertar la factura con el contrato nuevo y se borra la del contrato antiguo
        /// - Prefactura cerrada: Se rectifica la factura creando una nueva al contrato nuevo. (Es necesario pasarle la sociedad y serie de la nueva factura). Fra. Actual -> Fra. Nuevo contrato
        /// </summary>
        /// <param name="factura">Objeto factura a actualizar el contrato</param>
        /// <param name="sociedadCodigo">Código de la sociedad</param>
        /// <param name="serieCodigo">Código de la serie</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Objeto factura nueva</returns>
        public static cFacturaBO ActualizarContrato(cFacturaBO factura, short? sociedadCodigo, short? serieCodigo, string usuarioRegistro, out string log, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            cContratoBO contratoUltimaVersion = new cContratoBO();
            log = String.Empty;
            short? serieFacturaNueva = null;

            cFacturaBO facturaNueva = factura.Copiar();

            bool zonaPeriodoAbierto = (new cPerzonaBL().ZonaYPeriodoAbierto(factura.ZonaCodigo, factura.PeriodoCodigo, out respuesta));
            bool esPreFactura = factura.SerieCodigo == null && factura.SociedadCodigo == null && zonaPeriodoAbierto;
            bool esPreFacturaCerrada = String.IsNullOrWhiteSpace(factura.Numero) && !factura.SerieCodigo.HasValue && !factura.SociedadCodigo.HasValue && !esPreFactura;

            //Si es una prefactura cerrada debe indicarse la sociedad y la serie de la nueva factura
            if (esPreFacturaCerrada && (!sociedadCodigo.HasValue || !serieCodigo.HasValue))
                cExcepciones.ControlarER(new Exception(Resource.val_required.Replace("@Field", Resource.sociedad + "/" + Resource.serie)), TipoExcepcion.Error, out respuesta);

            if (respuesta.Resultado != ResultadoProceso.OK)
                return null;

            //Obtenemos última versión del contrato para ver si tiene un cambio de titular
            if (factura.ContratoCodigo.HasValue)
            {
                contratoUltimaVersion.Codigo = factura.ContratoCodigo.Value;
                cContratoBL.ObtenerUltimaVersion(ref contratoUltimaVersion, out respuesta);
            }
            else
                cExcepciones.ControlarER(new Exception(Resource.errorProducidoError), TipoExcepcion.Error, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                //Comprobar que tiene un cambio de titular el contrato de la factura
                if (!contratoUltimaVersion.CodigoNuevo.HasValue)
                    cExcepciones.ControlarER(new Exception(Resource.contratoNoTieneCambioTitular.Replace("@item", factura.ContratoCodigo.ToString())), TipoExcepcion.Error, out respuesta);

                //No se realiza nada si para el contratoNuevo/periodo ya existe factura (para facturas de periodos 0* si está permitido)
                //if (contratoUltimaVersion.CodigoNuevo.HasValue && factura.PeriodoCodigo != "000001" && cFacturasBL.Existe(factura.PeriodoCodigo, contratoUltimaVersion.CodigoNuevo.Value, out respuesta))
                if (contratoUltimaVersion.CodigoNuevo.HasValue && !factura.PeriodoCodigo.StartsWith("0") && cFacturasBL.Existe(factura.PeriodoCodigo, contratoUltimaVersion.CodigoNuevo.Value, out respuesta))
                    cExcepciones.ControlarER(new Exception(Resource.errorInsertarExiste.Replace("@campo", Resource.factura).Replace("@item", Resource.periodo + ": " + factura.PeriodoCodigo + ", " + Resource.contrato + ": " + contratoUltimaVersion.CodigoNuevo.Value)), TipoExcepcion.Error, out respuesta);

                if (respuesta.Resultado != ResultadoProceso.OK)
                    return null;

                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    //Anular la factura del contrato antiguo, si no tiene sociedad/serie/número no se anula
                    if (!esPreFacturaCerrada && !esPreFactura)
                    {
                        cFacturasBL.Anular(factura, usuarioRegistro, out log, out respuesta);
                        cSerieBO serie = new cSerieBO();
                        //Obtenemos la serie para la factura del contrato nuevo, obtenemos primero la serie de la factura actual y después de su serie relacionada obtenemos la serie relacionada.
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            ObtenerSerie(ref factura, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            if (factura.Serie.SerieCodRel > 0)
                            {
                                serie.Codigo = factura.Serie.SerieCodRel;
                                serie.CodSociedad = factura.Serie.CodSociedad;
                                cSerieBL.Obtener(ref serie, out respuesta);
                            }
                            else
                                cExcepciones.ControlarER(new Exception(Resource.debeExistirSerieRelacionada), TipoExcepcion.Error, out respuesta);

                            if (respuesta.Resultado == ResultadoProceso.OK)
                                if (factura.Serie.SerieCodRel > 0)
                                    serieFacturaNueva = serie.SerieCodRel;
                                else
                                    cExcepciones.ControlarER(new Exception(Resource.debeExistirSerieRelacionada), TipoExcepcion.Error, out respuesta);
                        }

                        if (respuesta.Resultado != ResultadoProceso.OK)
                        {
                            cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Error, out respuesta);
                            return null;
                        }
                    }

                    //Crear la factura con el contrato nuevo
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        cContratoBO contratoNuevoUltimaVersion = new cContratoBO();
                        contratoNuevoUltimaVersion.Codigo = contratoUltimaVersion.CodigoNuevo.Value;
                        cContratoBL.ObtenerUltimaVersion(ref contratoNuevoUltimaVersion, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            facturaNueva.ContratoCodigo = contratoNuevoUltimaVersion.Codigo;
                            facturaNueva.ContratoVersion = contratoNuevoUltimaVersion.Version;
                            facturaNueva.ZonaCodigo = contratoNuevoUltimaVersion.ZonCod;
                            facturaNueva.ClienteCodigo = contratoNuevoUltimaVersion.TitularCodigo;
                            facturaNueva.SerieCodigo = esPreFactura ? null : (esPreFacturaCerrada ? serieCodigo : serieFacturaNueva);
                            facturaNueva.SociedadCodigo = esPreFactura ? null : (esPreFacturaCerrada ? sociedadCodigo : facturaNueva.SociedadCodigo);

                            facturaNueva.FechaRegistro = AcuamaDateTime.Now;
                            facturaNueva.UsuarioRegistro = usuarioRegistro;

                            facturaNueva.Fecha = esPreFactura ? null : (DateTime?)AcuamaDateTime.Today;

                            facturaNueva.FechaContabilizacion = facturaNueva.FechaContabilizacionAnulada = null;
                            facturaNueva.UsuarioContabilizacion = facturaNueva.UsuarioContabilizacionAnulada = null;

                            //Se debe obtener el valor del envío SAP de la serie que se va a establecer en la nueva factura para su inserción en FacSII
                            if (!esPreFactura)
                            {
                                if (facturaNueva.EnvioSAP.HasValue && !facturaNueva.EnvioSAP.Value)
                                {
                                    ObtenerSerie(ref facturaNueva, out respuesta);
                                    if (respuesta.Resultado == ResultadoProceso.OK && facturaNueva.Serie != null)
                                        facturaNueva.EnvioSAP = facturaNueva.Serie.EnvioSAP;
                                }
                            }

                            //Si tenía desglose se inserta en esta nueva factura también
                            if (cFacturasBL.InsertarConLineas(facturaNueva, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                                if (cFacturasBL.TieneDesglose(factura.FacturaCodigo.Value, factura.PeriodoCodigo, factura.ContratoCodigo.Value, (short)(factura.Version.Value), out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                                    respuesta = cFacturasBL.GenerarDesgloseDeLineasFactura(facturaNueva.FacturaCodigo.Value, facturaNueva.PeriodoCodigo, facturaNueva.ContratoCodigo.Value, 1);

                            //Si es una prefactura, se debe borrar la prefactura del contrato antiguo
                            if (esPreFactura)
                                Borrar(factura, out respuesta);
                        }
                    }

                    //Actualizar la factura nula (importe 0) indicándole que la factura que rectifica es la factura del nuevo contrato
                    if (respuesta.Resultado == ResultadoProceso.OK && !esPreFactura)
                    {
                        cFacturaBO facturaNula = new cFacturaBO();
                        facturaNula.ContratoCodigo = factura.ContratoCodigo;
                        facturaNula.PeriodoCodigo = factura.PeriodoCodigo;
                        facturaNula.FacturaCodigo = factura.FacturaCodigo;

                        cFacturasBL.ObtenerUltimaVersion(ref facturaNula, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            facturaNula.SerieRectificativa = facturaNueva.SerieCodigo;
                            facturaNula.NumeroRectificativa = facturaNueva.Numero;
                            facturaNula.FechaFactRectificativa = facturaNueva.Fecha;

                            Actualizar(facturaNula, false, out log, out respuesta);
                        }
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
                }
            }

            return facturaNueva;
        }

        /// <summary>
        /// Anula la factura pasada por parametro.
        /// El objeto debe estar relleno.
        /// </summary>
        /// <param name="factura">cFacturaBO</param>
        /// <param name="log">Log con información del proceso</param>
        /// <param name="respuesta">respuesta</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool Anular(cFacturaBO factura, string usuarioRegistro, out string log, out cRespuesta respuesta)
        {
            bool resultado = false;
            log = String.Empty;
            if (factura == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    cFacturaBO facturaRectif = factura.Copiar(); //facturaRecif = Factura Rectificativa
                    resultado = ObtenerSerie(ref factura, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        if (factura.Serie.SerieCodRel > 0)
                        {
                            facturaRectif.SerieCodigo = factura.Serie.SerieCodRel;
                            //facturaRectif.Numero = factura.Serie.NumeroFactura + 1;
                            string explotacionCodigo = null;
                            if (cParametroBL.GetString("EXPLOTACION_CODIGO", out explotacionCodigo).Resultado == ResultadoProceso.OK)
                                facturaRectif.Numero = string.Format("{0}{1}{2}", AcuamaDateTime.Today.Year.ToString().Substring(1, 2), explotacionCodigo, (factura.Serie.NumeroFactura + 1).ToString());
                        }
                        else
                        {
                            resultado = false;
                            cExcepciones.ControlarER(new Exception(Resource.debeExistirSerieRelacionada), TipoExcepcion.Informacion, out respuesta);
                        }
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        facturaRectif.Fecha = AcuamaDateTime.Today;
                        facturaRectif.UsuarioRegistro = usuarioRegistro;
                        facturaRectif.TipoRect = "R4"; //por defecto Factura Rectificativa (Resto), ya que es un valor obligatorio en la rectificativa
                        facturaRectif.FechaContabilizacion = facturaRectif.FechaContabilizacionAnulada = null;
                        facturaRectif.UsuarioContabilizacion = facturaRectif.UsuarioContabilizacionAnulada = null;

                        if (facturaRectif.EnvioSAP.HasValue && !facturaRectif.EnvioSAP.Value)
                        {
                            ObtenerSerie(ref facturaRectif, out respuesta);
                            if (respuesta.Resultado == ResultadoProceso.OK && facturaRectif.Serie != null)
                                facturaRectif.EnvioSAP = facturaRectif.Serie.EnvioSAP;
                        }
                        string errorStr = Validar(facturaRectif);
                        if (errorStr == string.Empty)
                            resultado = new cFacturasDL().Insertar(ref facturaRectif, out respuesta);
                        else
                        {
                            resultado = false;
                            cExcepciones.ControlarER(new Exception(errorStr), TipoExcepcion.Informacion, out respuesta);
                        }
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        //obtenemos las líneas de la factura pasada por parametro y modificamos las unidades a cero
                        ObtenerLineas(ref factura, out respuesta);
                        facturaRectif.LineasFactura = factura.LineasFactura;

                        if (respuesta.Resultado == ResultadoProceso.OK)
                            for (int i = 0; i < facturaRectif.LineasFactura.Count; i++)
                            {
                                facturaRectif.LineasFactura[i].Periodo = facturaRectif.PeriodoCodigo;
                                facturaRectif.LineasFactura[i].Contrato = facturaRectif.ContratoCodigo.Value;
                                facturaRectif.LineasFactura[i].Version = facturaRectif.Version.Value;
                                facturaRectif.LineasFactura[i].Unidades = (decimal)0;
                                facturaRectif.LineasFactura[i].CBase = (decimal)0;
                                facturaRectif.LineasFactura[i].ImpImpuesto = (decimal)0;
                                facturaRectif.LineasFactura[i].Total = (decimal)0;
                                for (int j = 0; j < facturaRectif.LineasFactura[i].ArrayPrecios.Length; j++)
                                    facturaRectif.LineasFactura[i].ArrayPrecios[j] = (decimal)0;
                            }

                        //insertamos en la nueva factura las líneas
                        resultado = InsertarLineas(facturaRectif, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            //actualizamos de la versión anterior los campos Reftificación
                            factura.SerieRectificativa = facturaRectif.SerieCodigo;
                            factura.NumeroRectificativa = facturaRectif.Numero;
                            factura.FechaFactRectificativa = facturaRectif.Fecha;
                            resultado = Actualizar(factura, false, out log, out respuesta);
                        }
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        respuesta = cCobrosBL.GenerarRectificativo(facturaRectif, usuarioRegistro);

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
                    else
                        cExcepciones.ControlarER(new Exception(Resource.errorFacturaNoAnulada), TipoExcepcion.Informacion, out respuesta);
                }
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return respuesta.Resultado == ResultadoProceso.OK;
        }

        /// <summary>
        /// Generamos el desglose de las líneas si en la factura rectificada las tenía.
        /// </summary>
        /// <param name="codigo">Código de la factura</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="contratoCodigo">Cóigo del contrato</param>
        /// <param name="versionRectificada">Versión de la factura que se va a rectificar</param>
        /// <returns>Objeto respuesta</returns>
        public static cRespuesta GenerarDesgloseDeLineasEnRectificativa(short codigo, string periodoCodigo, int contratoCodigo, short versionRectificada)
        {
            cRespuesta respuesta;
            if (TieneDesglose(codigo, periodoCodigo, contratoCodigo, versionRectificada, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                respuesta = GenerarDesgloseDeLineasFactura(codigo, periodoCodigo, contratoCodigo, (short)(versionRectificada + 1));
            return respuesta;
        }

        /// <summary>
        /// Generamos el desglose de las líneas si en la factura rectificada las tenía.
        /// </summary>
        /// <param name="codigo">Código de la factura</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="contratoCodigo">Cóigo del contrato</param>
        /// <param name="version">Versión de la factura</param>
        /// <returns>True si tiene desglose, False si no lo tiene</returns>
        public static bool TieneDesglose(short codigo, string periodoCodigo, int contratoCodigo, short version, out cRespuesta respuesta)
        {
            return cFaclinDesgloseBL.Existe(codigo, periodoCodigo, contratoCodigo, version, out respuesta);
        }

        /// <summary>
        /// Inserta una factura y sus líneas
        /// </summary>
        /// <param name="factura">Objeto cFacturaBO</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool InsertarConLineas(cFacturaBO factura, out cRespuesta respuesta)
        {
            cLineasFacturaBL linFacBL = new cLineasFacturaBL();

            try
            {
                if (factura == null)
                {
                    respuesta = new cRespuesta();
                    respuesta.Resultado = ResultadoProceso.Error;
                    return false;
                }
                else
                {
                    using (TransactionScope scope = cAplicacion.NewTransactionScope())
                    {
                        #region "Precisión del redondeo (facE: 2, default:4)"
                        bool esFacE = EsFacE(factura);
                        #endregion

                        //Inserta la cabecera
                        Insertar(ref factura, out respuesta);

                        //Inserta las líneas
                        if (factura.LineasFactura != null && factura.LineasFactura.Count > 0)
                        {
                            for (int i = 0; respuesta.Resultado == ResultadoProceso.OK && i < factura.LineasFactura.Count; i++)
                            {
                                cLineaFacturaBO refLinea = factura.LineasFactura[i];

                                //asignamos la clave de la cabecera a la linea 
                                //por si estos campos están asociados a otra cabecera
                                refLinea.Periodo = factura.PeriodoCodigo;
                                refLinea.Contrato = factura.ContratoCodigo.Value;
                                refLinea.Version = factura.Version.Value;
                                refLinea.FacturaCodigo = factura.FacturaCodigo.Value;

                                linFacBL.Insertar(ref refLinea, esFacE, basePrecision(factura), out respuesta);
                            }

                            //Actualizamos las líneas en función de la cabecera por si las líneas tenían asociada otra cabecera
                            if (respuesta.Resultado == ResultadoProceso.OK)
                                ActualizarLineas(factura, out respuesta);
                        }

                        if (respuesta.Resultado == ResultadoProceso.OK)
                            scope.Complete();
                        else
                            cExcepciones.ControlarER(new Exception(Resource.errorLineasNoInsertadas), TipoExcepcion.Informacion, out respuesta);
                    }
                }

            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return respuesta.Resultado == ResultadoProceso.OK;
        }

        public static cBindableList<cFacturaBO> ObtenerLecturas(string periodo, string zona, int loteD, int loteH, int? ctrCodDesde, int? ctrCodHasta, string orden, bool soloPendientes, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.ObtenerLecturas(ref facturas, periodo, zona, loteD, loteH, ctrCodDesde, ctrCodHasta, orden, soloPendientes, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        public static cBindableList<cFacturaBO> Obtener(string periodo, string zona, bool? inspeccionables, int? ctrCodDesde, int? ctrCodHasta, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                cFacturasDL facturasDL = new cFacturasDL();
                facturasDL.Obtener(ref facturas, periodo, zona, inspeccionables, ctrCodDesde, ctrCodHasta, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene el consumo de la tarifa del primer servicio medido del contrato
        /// </summary>
        /// <param name="contratoCodigo">Código de contrato</param>
        /// <param name="version">Versión del contrato</param>
        /// <param name="consumo">Consumo de la tarifa del primer servicio medido</param>
        /// <returns>Respuesta</returns>
        public static cRespuesta ObtenerConsumoPromedioTarifa(int contratoCodigo, short version, out int? consumo)
        {
            cRespuesta respuesta = new cRespuesta();

            consumo = null;

            cContratoBO contrato = new cContratoBO();
            contrato.Codigo = contratoCodigo;
            contrato.Version = version;

            if (cContratoBL.ExistenServiciosMedidosPorContratos(contrato.Codigo, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
            {
                cBindableList<cContratoservicioBO> serviciosPorContrato = new cContratoservicioBL().ObtenerPorContrato(contrato.Codigo, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    bool primeroObtenido = false;
                    cServicioBO servicio = null;
                    //Obtenemos el primer servicio medido
                    for (int i = 0; i < serviciosPorContrato.Count && primeroObtenido != true; i++)
                    {
                        servicio = new cServicioBL().Obtener(serviciosPorContrato[i].Servicio, out respuesta);

                        if (servicio != null && respuesta.Resultado == ResultadoProceso.OK)
                        {
                            if (servicio.Tipo == "M" && serviciosPorContrato[i].FechaBaja == null) //Ver si es medido y no este dado de baja
                            {
                                cTarifaBO tarifaBO = new cTarifaBO();
                                tarifaBO.Codigo = serviciosPorContrato[i].Tarifa;

                                cTarifaBL.Obtener(ref tarifaBO, out respuesta);
                                if (respuesta.Resultado == ResultadoProceso.OK)
                                {
                                    primeroObtenido = true;
                                    consumo = tarifaBO.ConsumoPromedio;
                                }
                            }
                        }
                    }
                }
            }

            return respuesta;
        }

        /// <summary>
        /// Obtiene el consumo del mismo periodo del ejercicio anterior.
        /// </summary>
        /// <param name="contratoCodigo">Código de contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="calcularPromedioDeTarifa">Indica si debe calcularle el consumo a partir de la tarifa si el cálculo de consumo en el mismo periodo del ejercicio anterior es null</param>
        /// <param name="consumoPeriodo">Consumo del mismo periodo del ejercicio anterior</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool CalculoConsumoMismoPeriodoEjercAnterior(int contratoCodigo, string periodoCodigo, bool calcularPromedioDeTarifa, out int? consumoPeriodo, out cRespuesta respuesta)
        {
            return new cFacturasDL().CalculoConsumoMismoPeriodoEjercAnterior(contratoCodigo, periodoCodigo, calcularPromedioDeTarifa, out consumoPeriodo, out respuesta);
        }

        /// <summary>
        /// Obtiene el consumo del mismo periodo del ejercicio anterior.
        /// </summary>
        /// <param name="contratoCodigo">Código de contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="consumoPeriodo">Consumo del mismo periodo del ejercicio anterior</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool CalculoConsumoMismoPeriodoEjercAnterior(int contratoCodigo, string periodoCodigo, out int? consumoPeriodo, out cRespuesta respuesta)
        {
            return CalculoConsumoMismoPeriodoEjercAnterior(contratoCodigo, periodoCodigo, true, out consumoPeriodo, out respuesta);
        }

        /// <summary>
        /// Obtiene el consumo promedio.
        /// </summary>
        /// <param name="contratoCodigo">Código de contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="calcularPromedioDeTarifa">ndica si debe calcularle el consumo a partir de la tarifa si el cálculo de consumo en el mismo periodo del ejercicio anterior es null</param>
        /// <param name="consumoPromedio">Consumo promedio</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool CalculoConsumoPromedio(int contratoCodigo, string periodoCodigo, bool calcularPromedioDeTarifa, out int? consumoPromedio, out cRespuesta respuesta)
        {
            return new cFacturasDL().CalculoConsumoPromedio(contratoCodigo, periodoCodigo, calcularPromedioDeTarifa, out consumoPromedio, out respuesta);
        }

        /// <summary>
        /// Obtiene el consumo promedio.
        /// </summary>
        /// <param name="contratoCodigo">Código de contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="consumoPromedio">Consumo promedio</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool CalculoConsumoPromedio(int contratoCodigo, string periodoCodigo, out int? consumoPromedio, out cRespuesta respuesta)
        {
            return CalculoConsumoPromedio(contratoCodigo, periodoCodigo, true, out consumoPromedio, out respuesta);
        }

        /// <summary>
        /// Obtiene los limites alto y bajo para un consumo determinado.
        /// </summary>
        /// <param name="consumo">Consumo</param>
        /// <param name="alto">valor alto</param>
        /// <param name="bajo">valor bajo</param>
        /// <returns></returns>
        public static bool CalculoConsumoAltoBajo(int consumo, out int? alto, out int? bajo, out cRespuesta respuesta)
        {
            return new cFacturasDL().CalculoConsumoAltoBajo(consumo, out alto, out bajo, out respuesta);
        }

        /// <summary>
        /// Obtiene el consumo promedio por diámetro, ruta y contrato.
        /// </summary>
        /// <param name="zonaD">Zona desde</param>
        /// <param name="zonaH">Zona hasta</param>
        /// <param name="diametro">Diámetro del contador</param>
        /// <param name="rutaAgrupada">Ruta por la cual se agrupará</param>
        /// <param name="periodo">Periodo de la factura</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="consumoPromedio">Consumo promedio</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool CalculoConsumoPromedioPorDiametroYRuta(string zonaD, string zonaH, short diametro, int rutaAgrupada, string periodo, int? contratoCodigo, out int? consumoPromedio, out cRespuesta respuesta)
        {
            return new cFacturasDL().CalculoConsumoPromedioPorDiametroYRuta(zonaD, zonaH, diametro, rutaAgrupada, periodo, contratoCodigo, out consumoPromedio, out respuesta);
        }

        /// <summary>
        /// Obtiene el consumo promedio por diámetro y ruta.
        /// </summary>
        /// <param name="zonaD">Zona desde</param>
        /// <param name="zonaH">Zona hasta</param>
        /// <param name="diametro">Diámetro del contador</param>
        /// <param name="rutaAgrupada">Ruta por la cual se agrupará</param>
        /// <param name="periodo">Periodo de la factura</param>
        /// <param name="consumoPromedio">Consumo promedio</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool CalculoConsumoPromedioPorDiametroYRuta(string zonaD, string zonaH, short diametro, int rutaAgrupada, string periodo, out int? consumoPromedio, out cRespuesta respuesta)
        {
            return new cFacturasDL().CalculoConsumoPromedioPorDiametroYRuta(zonaD, zonaH, diametro, rutaAgrupada, periodo, null, out consumoPromedio, out respuesta);
        }

        /// <summary>
        /// Obtiene el consumo para método de cálculo estimación periodo para AVG.
        /// </summary>
        /// <param name="contratoCodigo">Código de contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="consumoPeriodo">Consumo del mismo periodo del ejercicio anterior</param>
        /// <returns>True si no hay errores, false en caso contrario</returns>
        public static bool CalculoConsumoEstimadoPeriodo_AVG(int contratoCodigo, string periodoCodigo, out int? consumoPeriodo, out cRespuesta respuesta)
        {
            return new cFacturasDL().CalculoConsumoEstimadoPeriodo_AVG(contratoCodigo, periodoCodigo, out consumoPeriodo, out respuesta);
        }

        /// <summary>
        /// Comprueba que existe una determinada factura
        /// </summary>
        /// <param name="periodo">Código periodo</param>
        /// <param name="contrato">Código contrato</param>
        /// <param name="version">Versión</param>
        /// <param name="respuesta">Objeto cRespuesta</param>
        /// <returns>True si el asiento existe, False en caso contrario </returns>
        public static bool Existe(string periodo, int contrato, short? version, out cRespuesta respuesta)
        {
            cFacturaBO facturaBO = new cFacturaBO();
            facturaBO.PeriodoCodigo = periodo;
            facturaBO.ContratoCodigo = contrato;
            facturaBO.Version = version;
            return new cFacturasDL().Existen(facturaBO, out respuesta);
        }

        /// <summary>
        /// Comprueba que existe una determinada factura
        /// </summary>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <param name="periodo">Código periodo</param>
        /// <param name="contrato">Código contrato</param>
        /// <param name="version">Versión</param>
        /// <param name="respuesta">Objeto cRespuesta</param>
        /// <returns>True si el asiento existe, False en caso contrario </returns>
        public static bool Existe(short? facturaCodigo, string periodo, int contrato, short? version, out cRespuesta respuesta)
        {
            cFacturaBO facturaBO = new cFacturaBO();
            facturaBO.FacturaCodigo = facturaCodigo;
            facturaBO.PeriodoCodigo = periodo;
            facturaBO.ContratoCodigo = contrato;
            facturaBO.Version = version;
            return new cFacturasDL().Existen(facturaBO, out respuesta);
        }

        /// <summary>
        /// Comprueba que existe una determinada factura
        /// </summary>
        /// <param name="periodo">Código periodo</param>
        /// <param name="contrato">Código contrato</param>
        /// <param name="respuesta">Objeto cRespuesta</param>
        /// <returns>True si el asiento existe, False en caso contrario </returns>
        public static bool Existe(string periodo, int contrato, out cRespuesta respuesta)
        {
            return Existe(periodo, contrato, null, out respuesta);
        }

        /// <summary>
        /// Obtiene por contrato, serie y número
        /// </summary>
        /// <param name="contrato">contrato</param>
        /// <param name="serie">serie</param>
        /// <param name="numero">número</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>Objeto facturas</returns>
        public static cFacturaBO ObtenerPorContratoSerieYNumero(int contrato, short serie, string numero, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerPorContratoSerieYNumero(contrato, serie, numero, out respuesta);
        }

        /// <summary>
        /// Obtiene por periodo, serie y número
        /// </summary>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="serie">Serie</param>
        /// <param name="numero">Número</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>Objeto facturas</returns>
        public static cFacturaBO ObtenerPorPeriodoSerieYNumero(string periodoCodigo, short serie, string numero, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerPorPeriodoSerieYNumero(periodoCodigo, serie, numero, out respuesta);
        }

        /// <summary>
        /// Obtiene por sociedad, serie y número
        /// </summary>
        /// <param name="sociedad">sociedad</param>
        /// <param name="serie">serie</param>
        /// <param name="numero">número</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>Objeto facturas</returns>
        public static cFacturaBO ObtenerPorSociedadSerieYNumero(short sociedad, short serie, string numero, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerPorSociedadSerieYNumero(sociedad, serie, numero, out respuesta);
        }
        /// <summary>
        /// Método para actualizar la versión del contrato a partir de una factura
        /// la factura que se pasa para actualizar, al finalizar el método es la factura rectificativa
        /// </summary>
        /// <param name="facturaParaActualizar">Objeto factura</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public static bool ActualizarVersionContrato(ref cFacturaBO facturaParaActualizar, string usuarioRegistro, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            string log = String.Empty;
            if (facturaParaActualizar == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    string errorStr = ValidarLectura(facturaParaActualizar);
                    if (errorStr == String.Empty)
                    {
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            ObtenerContratoUltimaVersion(ref facturaParaActualizar, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            facturaParaActualizar.ContratoVersion = facturaParaActualizar.Contrato.Version;
                            facturaParaActualizar.ClienteCodigo = facturaParaActualizar.Contrato.TitularCodigo;
                        }

                        if (respuesta.Resultado == ResultadoProceso.OK && facturaParaActualizar.SociedadCodigo.HasValue && facturaParaActualizar.SerieCodigo.HasValue && !String.IsNullOrWhiteSpace(facturaParaActualizar.Numero) && facturaParaActualizar.FechaRegistro.HasValue && facturaParaActualizar.FechaRegistro.Value.ToShortDateString() != AcuamaDateTime.Today.ToShortDateString())
                            Duplicar(ref facturaParaActualizar, usuarioRegistro, out log, out respuesta);
                        else
                            if (respuesta.Resultado == ResultadoProceso.OK)
                            resultado = Actualizar(facturaParaActualizar, false, out log, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                            scope.Complete();
                    }
                    else
                        cExcepciones.ControlarER(new Exception(errorStr), TipoExcepcion.Informacion, out respuesta);
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
        /// Obtiene código de la factura a partir del periodo y contrato pasado por parámetro
        /// </summary>
        ///<param name="periodoCodigo">Código del periodo</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="facturaCodigo">Parámetro de salidaCabecera con el código de la factura</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta ObtenerCodigo(string periodoCodigo, int? contratoCodigo, out short? facturaCodigo)
        {
            return new cFacturasDL().ObtenerCodigo(periodoCodigo, contratoCodigo, out facturaCodigo);
        }

        /// <summary>
        /// Obtiene facturas por contrato y orden de trabajo
        /// </summary>
        /// <param name="ot">Objeto orden de trabajo, obligatorio rellenar el código del contrato, la sociedad, serie y número</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Lista de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerPorContratoYOrdenTrabajo(cOrdenTrabajoBO ot, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerPorContratoYOrdenTrabajo(ot, out respuesta);
        }

        /// <summary>
        /// Valida los datos de un objeto de negocio del tipo de esta clase
        /// </summary>
        /// <param name="factura">objeto de negocio</param>
        /// <returns>String que contiene el error (vacío si no hay errores)</returns>
        public static string Validar(cFacturaBO factura)
        {
            cValidator validator = new cValidator();

            validator.AddRequiredField(factura.PeriodoCodigo, Resource.periodo);
            validator.AddRequiredField(factura.ContratoCodigo, Resource.contrato);
            validator.AddRequiredField(factura.ZonaCodigo, Resource.zona);

            // Si no tiene sociedad, por ejemplo cuando sea una preFactura, no se validará
            if (factura.SociedadCodigo.HasValue)
            {
                // Si tiene sociedad, debe tener serie
                validator.AddRequiredField(factura.SerieCodigo, Resource.serie);

                //Obtener sociedad
                cSociedadBO sociedad = new cSociedadBO();
                sociedad.Codigo = factura.SociedadCodigo.Value;
                cRespuesta respuesta;
                cSociedadBL.Obtener(ref sociedad, out respuesta);

                //Comprobar respuesta
                if (respuesta.Resultado != ResultadoProceso.OK)
                    validator.AddCustomMessage(respuesta.Ex.Message);

                //La fecha de factura ha de ser siempre mayor a la fecha de cierre contable, si no esta vacia existe la fecha de cierre contable
                if (respuesta.Resultado == ResultadoProceso.OK && sociedad.FechaCierreContable.HasValue)
                {
                    if (factura.Fecha.HasValue)
                        validator.AddFechaAnteriorEstricta(sociedad.FechaCierreContable.Value.ToString(), factura.Fecha.Value.ToString(), Resource.fechaCierreContable, Resource.fecha_factura);
                    if (factura.FechaContabilizacion.HasValue && sociedad.FechaCierreContable.Value > factura.FechaContabilizacion.Value)
                        validator.AddCustomMessage(Resource.val_fechaAnterior.Replace("@field2", Resource.fechaContabilizacionAbv2).Replace("@field1", Resource.fechaContable));
                }
            }

            // Si el periodo no es periódico entonces es obligatorio meter una sociedad
            if (!String.IsNullOrEmpty(factura.PeriodoCodigo) && factura.PeriodoCodigo.StartsWith("0"))
                validator.AddRequiredField(factura.SociedadCodigo, Resource.sociedad);

            // Si la factura tiene fecha de anulación contable también tiene que tener fecha contable
            if (factura.FechaContabilizacionAnulada.HasValue)
                validator.AddRequiredField(factura.FechaContabilizacion, Resource.fechaContabilizacion);

            return validator.Validate(true);
        }

        /// <summary>
        /// Método para obtener las facturas pendientes de cobro a partir de unos parámetros introducidos por el usuario, 
        /// y actualizar los campos de liquidación de las líneas de esas facturas
        /// </summary>
        /// <param name="servicioCodigo">Código del servicio, este servicio es liquidable</param>
        /// <param name="fechaD">Fecha desde para la selección de las facturas pendientes</param>
        /// <param name="fechaH">Fecha hasta para la selección de las facturas pendientes</param>
        /// <param name="periodoD">Código del periodo desde</param>
        /// <param name="periodoH">Código del periodo hasta</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta LiquidarPendientesDeCobro(short? servicioCodigo, DateTime? fechaD, DateTime? fechaH, string periodoD, string periodoH, string usuarioCodigo, short? tarifaD, short? tarifaH, int? usoCodigo, out string log, out int registrosProcesados)
        {
            return LiquidarPendientesDeCobro(servicioCodigo, fechaD, fechaH, periodoD, periodoH, usuarioCodigo, tarifaD, tarifaH, usoCodigo, out registrosProcesados, out log, null, null, null);
        }



        /// <summary>
        /// Método para obtener las facturas pendientes de cobro a partir de unos parámetros introducidos por el usuario, 
        /// y actualizar los campos de liquidación de las líneas de esas facturas
        /// </summary>
        /// <param name="servicioCodigo">Código del servicio, este servicio es liquidable</param>
        /// <param name="fechaD">Fecha desde para la selección de las facturas pendientes</param>
        /// <param name="fechaH">Fecha hasta para la selección de las facturas pendientes</param>
        /// <param name="periodoD">Código del periodo desde</param>
        /// <param name="periodoH">Código del periodo hasta</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <param name="taskUser">Usuario que ejecuta la tarea</param>
        /// <param name="taskType">Tipo de tarea</param>
        /// <param name="taskNumber">Número de tarea</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta LiquidarPendientesDeCobro(short? servicioCodigo, DateTime? fechaD, DateTime? fechaH, string periodoD, string periodoH, string usuarioCodigo, short? tarifaD, short? tarifaH, int? usoCodigo, out int registrosProcesados, out string log, string taskUser, ETaskType? taskType, int? taskNumber)
        {
            cRespuesta respuesta = new cRespuesta();
            registrosProcesados = 0;
            log = String.Empty;

            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    //Obtener las facturas pendientes de cobro, filtrando por los parámetros introducidos por el usuario
                    SeleccionPtesCobro seleccion = new SeleccionPtesCobro();
                    seleccion.Desde = new SeleccionPtesCobro.DesdeHasta();
                    seleccion.Desde.PeriodoD = periodoD;
                    seleccion.Hasta.PeriodoH = periodoH;
                    seleccion.Desde.FechaD = fechaD;
                    seleccion.Hasta.FechaH = fechaH;
                    seleccion.ServicioCodigo = servicioCodigo;
                    seleccion.Desde.TarifaD = tarifaD;
                    seleccion.Hasta.TarifaH = tarifaH;
                    seleccion.UsoCodigo = usoCodigo;

                    cBindableList<cFacturaBO> facturas = ObtenerPendientesDeCobro(seleccion, true, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.SinRegistros)
                        respuesta.Resultado = ResultadoProceso.OK;

                    //Establecer número de pasos de la tarea
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, facturas.Count);

                    //********************************
                    //Para posponer la actualización de los totales;
                    cFacTotalesTrab_Insert(facturas);
                    //********************************

                    foreach (cFacturaBO factura in facturas)
                    {
                        #region "Precisión del redondeo (facE: 2, default:4)"
                        bool esFacE = EsFacE(factura);
                        int precisionBase = basePrecision(factura);
                        #endregion

                        //Si alguna iteración devuelve otra respuesta que no sea OK, forzamos la salidaCabecera del bucle y devolvermos la respuesta
                        if (respuesta.Resultado != ResultadoProceso.OK)
                            break;

                        cFacturaBO cabeceraFactura = factura;

                        cBindableList<cLineaFacturaBO> lineasFactura = ObtenerLineas(ref cabeceraFactura, servicioCodigo, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            registrosProcesados++;
                        respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            foreach (cLineaFacturaBO lineas in lineasFactura)
                            {
                                if (respuesta.Resultado != ResultadoProceso.OK)
                                    break;

                                //Actualizar sus líneas para cada una de estas facturas, rellenar la fecha de liquidación y el usuario
                                //Datos de liquidación
                                lineas.UsuarioCodigo = usuarioCodigo;
                                lineas.FechaLiquidacion = AcuamaDateTime.Now;
                                new cLineasFacturaBL().Actualizar(lineas, esFacE, precisionBase, out respuesta);
                                //----------------------------------------------------------------------------------------------------
                                //Generación del cobro rectificativo a partir de la factura liquidada,
                                //si existe al menos 1 cobro con importe distinto de 0. Y además tenemos al menos una línea de factura
                                if (respuesta.Resultado == ResultadoProceso.OK)
                                {
                                    respuesta = cCobrosBL.GenerarRectificativoPorLiquidacion(lineas.Contrato, lineas.Periodo, usuarioCodigo);
                                    respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
                                }

                                if (respuesta.Resultado == ResultadoProceso.OK)
                                {
                                    string permiteRepartoManual = cParametroBL.ObtenerValor("REPARTO_COBROS_MANUAL", out respuesta);

                                    if (respuesta.Resultado == ResultadoProceso.OK)
                                        if ((Convert.ToBoolean(permiteRepartoManual)))
                                            log = Resource.infoRevisarRepartoManual;
                                }
                            }
                        }
                        //Si estamos ejecutando en modo tarea...
                        if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        {
                            //Comprobar si se desea cancelar
                            if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                                return new cRespuesta();
                            //Incrementar el número de pasos
                            cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                        }
                    }
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        //********************************
                        //Para ejecutar la actualización de los totales;
                        cFacTotalesTrab_Delete();
                        //********************************
                        scope.Complete();
                    }
                }
            }
            catch (Exception ex)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
                registrosProcesados = 0;
            }

            return respuesta;
        }

        /// <summary>
        /// Método para actualizar los campos de liquidación de las líneas de esas facturas
        /// </summary>
        /// <param name="servicioCodigo">Código del servicio, este servicio es liquidable</param>
        /// <param name="fechaD">Fecha desde para la selección de las facturas pendientes</param>
        /// <param name="fechaH">Fecha hasta para la selección de las facturas pendientes</param>
        /// <param name="periodoD">Código del periodo desde</param>
        /// <param name="periodoH">Código del periodo hasta</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta LiquidarServicio(short? servicioCodigo, DateTime? fechaD, DateTime? fechaH, string periodoD, string periodoH, string usuarioCodigo, short? tarifaD, short? tarifaH, int? usoCodigo, out string log, out int registrosProcesados)
        {
            return LiquidarServicio(servicioCodigo, fechaD, fechaH, periodoD, periodoH, usuarioCodigo, tarifaD, tarifaH, usoCodigo, out registrosProcesados, out log, null, null, null);
        }

        /// <summary>
        /// Método para actualizar los campos de liquidación de las líneas de esas facturas
        /// </summary>
        /// <param name="servicioCodigo">Código del servicio, este servicio es liquidable</param>
        /// <param name="fechaD">Fecha desde para la selección de las facturas pendientes</param>
        /// <param name="fechaH">Fecha hasta para la selección de las facturas pendientes</param>
        /// <param name="periodoD">Código del periodo desde</param>
        /// <param name="periodoH">Código del periodo hasta</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <param name="taskUser">Usuario que ejecuta la tarea</param>
        /// <param name="taskType">Tipo de tarea</param>
        /// <param name="taskNumber">Número de tarea</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta LiquidarServicio(short? servicioCodigo, DateTime? fechaD, DateTime? fechaH, string periodoD, string periodoH, string usuarioCodigo, short? tarifaD, short? tarifaH, int? usoCodigo, out int registrosProcesados, out string log, string taskUser, ETaskType? taskType, int? taskNumber)
        {
            cRespuesta respuesta = new cRespuesta();
            registrosProcesados = 0;
            log = String.Empty;

            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    //Obtener las facturas pendientes de cobro, filtrando por los parámetros introducidos por el usuario
                    SeleccionPtesCobro seleccion = new SeleccionPtesCobro();
                    seleccion.Desde = new SeleccionPtesCobro.DesdeHasta();
                    seleccion.Desde.PeriodoD = periodoD;
                    seleccion.Hasta.PeriodoH = periodoH;
                    seleccion.Desde.FechaD = fechaD;
                    seleccion.Hasta.FechaH = fechaH;
                    seleccion.ServicioCodigo = servicioCodigo;
                    seleccion.Desde.TarifaD = tarifaD;
                    seleccion.Hasta.TarifaH = tarifaH;
                    seleccion.UsoCodigo = usoCodigo;

                    bool Correcto = LiquidarServiciosEnFacturas(seleccion, usuarioCodigo, out respuesta, out registrosProcesados);

                    if (respuesta.Resultado == ResultadoProceso.SinRegistros)
                        respuesta.Resultado = ResultadoProceso.OK;

                    //Establecer número de pasos de la tarea
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, 1);

                    //Si estamos ejecutando en modo tarea...
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    {
                        //Comprobar si se desea cancelar
                        if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            return new cRespuesta();
                        //Incrementar el número de pasos
                        cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
                }
            }
            catch (Exception ex)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
                registrosProcesados = 0;
            }

            return respuesta;
        }

        public static bool Existe(string periodo, string zona, bool tieneLecturaLector, out cRespuesta respuesta)
        {
            return new cFacturasDL().Existen(periodo, zona, tieneLecturaLector, out respuesta);
        }

        /// <summary>
        /// Realiza la apertura de una zona/periodo
        /// </summary>
        public static cRespuesta Apertura(string zona, string periodo, DateTime fechaPeriodoDesde, DateTime fechaPeriodoHasta, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasInsertadas)
        {
            return new cFacturasDL().Apertura(zona, periodo, fechaPeriodoDesde, fechaPeriodoHasta, taskUser, taskType, taskNumber, out facturasInsertadas);
        }

        /// <summary>
        /// Realiza una ampliación de apertura
        /// </summary>
        public static cRespuesta AmpliacionDeApertura(string zona, string periodo, bool anadirContratosNuevos, bool anadirServiciosNuevos, bool reinsertarServiciosExistentes, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasAfectadas)
        {
            return new cFacturasDL().AmpliacionDeApertura(zona, periodo, null, anadirContratosNuevos, anadirServiciosNuevos, reinsertarServiciosExistentes, taskUser, taskType, taskNumber, out facturasAfectadas);
        }

        /// <summary>
        /// Realiza una ampliación de apertura
        /// </summary>
        public static cRespuesta AmpliacionDeApertura(string zona, string periodo, int? contratoCodigo, bool anadirContratosNuevos, bool anadirServiciosNuevos, bool reinsertarServiciosExistentes, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasAfectadas)
        {
            return new cFacturasDL().AmpliacionDeApertura(zona, periodo, contratoCodigo, anadirContratosNuevos, anadirServiciosNuevos, reinsertarServiciosExistentes, taskUser, taskType, taskNumber, out facturasAfectadas);
        }

        /// <summary>
        /// Elimina la apertura de una zona/periodo
        /// </summary>
        public static cRespuesta EliminarApertura(string zona, string periodo, out int facturasEliminadas)
        {
            return new cFacturasDL().EliminarApertura(zona, periodo, out facturasEliminadas);
        }

        /// <summary>
        /// Realiza el cierre masivo de varias zona/periodo
        /// </summary>
        public static cRespuesta CierreMasivo(cBindableList<cPerzonaBO> perzonas, DateTime fecha, short serieCodigo, short sociedadCodigo, string usuarioCodigo, bool actualizarVersionContrato, bool actualizarTipoImpuesto, string taskUser, ETaskType? taskType, int? taskNumber, out string log, out int facturasProcesadas, out int facturasTotales)
        {
            cRespuesta respuesta = new cRespuesta();
            facturasProcesadas = 0;
            facturasTotales = 0;
            int facturasProcesadasPerzona = 0;
            int facturasTotalesPerzona = 0;
            log = String.Empty;

            using (TransactionScope scope = cAplicacion.NewTransactionScope())
            {
                //Establecer número de pasos de la tarea
                if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, perzonas.Count);

                //Cerrar perzonas
                foreach (cPerzonaBO perzona in perzonas)
                {
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        respuesta = Cierre(perzona.CodigoZona, perzona.CodigoPeriodo, fecha, serieCodigo, sociedadCodigo, usuarioCodigo, actualizarVersionContrato, actualizarTipoImpuesto, null, null, null, out facturasProcesadasPerzona, out facturasTotalesPerzona);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            facturasProcesadas += facturasProcesadasPerzona;
                            facturasTotales += facturasTotalesPerzona;
                            log += Resource.perzonaCerradaCorrectamente.Replace("@zona", perzona.CodigoZona).Replace("@periodo", perzona.CodigoPeriodo) + Environment.NewLine;
                        }
                        else
                            log += Resource.errorCierrePerzona.Replace("@zona", perzona.CodigoZona).Replace("@periodo", perzona.CodigoPeriodo) + Environment.NewLine;
                    }
                }

                //Si estamos ejecutando en modo tarea...
                if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                {
                    //Comprobar si se desea cancelar
                    if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                        return new cRespuesta();
                    //Incrementar el número de pasos
                    cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                }

                if (respuesta.Resultado == ResultadoProceso.OK)
                    scope.Complete();
            }



            return respuesta;
        }

        /// <summary>
        /// Realiza el cierre de una zona/periodo
        /// </summary>
        //public static cRespuesta Cierre(string zona, string periodo, DateTime fecha, short serie, short sociedad, string usuario, bool actualizarVersionContrato, bool actualizarTipoImpuesto, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasProcesadas, out int facturasTotales)
        //{
        //    return new cFacturasDL().Cierre(zona, periodo, fecha, serie, sociedad, usuario, actualizarVersionContrato, actualizarTipoImpuesto, taskUser, taskType, taskNumber, out facturasProcesadas, out facturasTotales);
        //}

        public static cRespuesta Cierre(string zona, string periodo, DateTime fecha, short serie, short sociedad, string usuario, bool actualizarVersionContrato, bool actualizarTipoImpuesto, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasProcesadas, out int facturasTotales)
        {
            cRespuesta respuesta = new cRespuesta();
            bool otAbiertas = false;
            facturasProcesadas = 0;
            facturasTotales = 0;

            cFacturasSeleccionBO seleccion = new cFacturasSeleccionBO();
            seleccion.Zona = zona;
            seleccion.Periodo = periodo;

            //Primeramente vemos si existen diferidos aplicados a este periodo, sino hay diferidos se cierra como siempre
            //difPendApli= cDiferidosBL.HayPendientesDeAplicar(zona,  periodo, out respuesta);
            //if (respuesta.Resultado != ResultadoProceso.Error)
            //{
            if (cParametroBL.ObtenerValor("EXPLOTACION_CODIGO").Equals("008"))
            {
                // Obtener las facturas para los sus diferidos
                cBindableList<cFacturaBO> facturas = Obtener(seleccion, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK && facturas.Count > 0)
                {
                    foreach (cFacturaBO factura in facturas)
                    {
                        // Si hay alguna OT abierta no se hará el cierre de facturación
                        if (otAbiertas)
                            break;

                        cDiferidosSeleccionBO seleccionDif = new cDiferidosSeleccionBO();
                        seleccionDif.PeriodoCodigo = factura.PeriodoCodigo;
                        seleccionDif.ContratoCodigo = factura.ContratoCodigo;

                        // Obtener los diferidos de cada factura para ver sus OT
                        cBindableList<cDiferidoBO> diferidos = cDiferidosBL.Obtener(seleccionDif, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            foreach (cDiferidoBO diferido in diferidos)
                            {
                                if (otAbiertas)
                                    break;

                                cDiferidoBO diferidoOT = diferido;
                                respuesta = cDiferidosBL.ObtenerOrdenTrabajo(ref diferidoOT);

                                // Si una OT está abierta se tira para abajo todo el cierre de facturación
                                if (respuesta.Resultado == ResultadoProceso.OK)
                                    if (!diferidoOT.OrdenTrabajo.Fcierre.HasValue)
                                        otAbiertas = true;
                            }
                        }
                    }

                    if (otAbiertas)
                    {
                        respuesta.Ex = new Exception("No se puede cerrar la facturación. Alguna OT con diferidos aplicados en esta facturación está abierta" + Environment.NewLine);
                        respuesta.Resultado = ResultadoProceso.Error;
                    }
                    else
                    {
                        respuesta = new cFacturasDL().Cierre(zona, periodo, fecha, serie, sociedad, usuario, actualizarVersionContrato, actualizarTipoImpuesto, taskUser, taskType, taskNumber, out facturasProcesadas, out facturasTotales);
                    }
                }
            }
            else
                respuesta = new cFacturasDL().Cierre(zona, periodo, fecha, serie, sociedad, usuario, actualizarVersionContrato, actualizarTipoImpuesto, taskUser, taskType, taskNumber, out facturasProcesadas, out facturasTotales);
            // }

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
        public static bool Cierre(cFacturacionCierreBO facturacionCierreBO, out int facturasProcesadas, out int facturasTotales, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            facturasProcesadas = 0;
            facturasTotales = 0;
            cFacturasDL facturasDL = new cFacturasDL();

            try
            {
                //Al no tener una factura que validar se crea una con los datos necesarios a validar
                cFacturaBO factura = new cFacturaBO();
                factura.SociedadCodigo = facturacionCierreBO.Sociedad;
                factura.Fecha = facturacionCierreBO.Fecha;
                factura.PeriodoCodigo = facturacionCierreBO.Periodo;
                factura.ContratoCodigo = facturacionCierreBO.Contrato;
                factura.SerieCodigo = facturacionCierreBO.Serie;
                factura.ZonaCodigo = facturacionCierreBO.Zona;

                string errorStr = Validar(factura);

                if (errorStr == String.Empty)
                    resultado = facturasDL.Cierre(facturacionCierreBO, out facturasProcesadas, out facturasTotales, out respuesta);
                else
                    cExcepciones.ControlarER(new Exception(errorStr), TipoExcepcion.Informacion, out respuesta);
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
        public static cRespuesta ActualizarALaUltimaVersionDelContrato(string zona, string periodo, string taskUser, ETaskType? taskType, int? taskNumber, out int facturasAfectadas)
        {
            return new cFacturasDL().ActualizarALaUltimaVersionDelContrato(zona, periodo, taskUser, taskType, taskNumber, out facturasAfectadas);
        }

        /// <summary>
        /// Obtiene las facturas de un código de contrato y versión pasados como parámetro
        /// </summary>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="ordenDesc">Determina si se desea que se ordene de forma descendente</param>
        /// <param name="versionContratoDesde">Versión del contrato desde</param>
        /// <param name="versionContratoHasta">Versión del contrato hasta</param>
        /// <param name="numeroPeriodos">Número de periodos facturados</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Lista enlazable</returns>
        public static cBindableList<cFacturaBO> ObtenerPorContrato(int contratoCodigo, bool? ordenDesc, short? versionContratoDesde, short? versionContratoHasta, int? numeroPeriodos, out cRespuesta respuesta)
        {
            cBindableList<cFacturaBO> facturas = new cBindableList<cFacturaBO>();
            respuesta = new cRespuesta();
            try
            {
                new cFacturasDL().ObtenerPorContrato(ref facturas, contratoCodigo, ordenDesc, versionContratoDesde, versionContratoHasta, numeroPeriodos, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturas;
        }

        /// <summary>
        /// Obtiene un string donde se ha generado el código de barras con formato 507
        /// </summary>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="facturaCodigo">Código de factura</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Texto con el formato 507 para el código de barras</returns>
        public static string CodificarCodigoBarrasConFormato507(string periodoCodigo, int contratoCodigo, short facturaCodigo, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            cFacturaBO factura = new cFacturaBO();

            int diasVtoPorDefecto = 0;
            respuesta = cParametroBL.GetInteger("DIAS_VTO_C57_POR_DEFECTO", out diasVtoPorDefecto);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                factura.PeriodoCodigo = periodoCodigo;
                factura.ContratoCodigo = contratoCodigo;
                factura.FacturaCodigo = facturaCodigo;

                ObtenerUltimaVersion(ref factura, out respuesta);
            }

            //Comprobamos que ha obtenido bien la factura y que no es prefactura
            if (respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrWhiteSpace(factura.Numero) && factura.SerieCodigo.HasValue && factura.SociedadCodigo.HasValue && factura.Fecha.HasValue)
            {
                //Obtener el importe pendiente sin tener en cuenta el importe que pueda haber en efectos pendientes a remesar sin cobrar
                decimal importePendienteFactura = ObtenerImportePendiente(factura.FacturaCodigo.Value, factura.ContratoCodigo.Value, factura.PeriodoCodigo, factura.SociedadCodigo.Value, true, true, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    cPeriodoBO periodo = new cPeriodoBO();
                    periodo.Codigo = factura.PeriodoCodigo;
                    new cPeriodoBL().Obtener(ref periodo, out respuesta);

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {

                        cSociedadBO sociedad = new cSociedadBO();

                        //Independientemente de la sociedad que venga en la factura, tengo que obtener la sociedad de la remesa
                        string sociedadRemesa = cParametroBL.ObtenerValor("SOCIEDAD_REMESA");

                        if (!String.IsNullOrEmpty(sociedadRemesa))
                        {
                            sociedad.Codigo = short.Parse(sociedadRemesa);
                        }
                        else
                        {
                            sociedad.Codigo = factura.SociedadCodigo.Value;
                        }

                        cSociedadBL.Obtener(ref sociedad, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK && sociedad.SufijoC57.HasValue && sociedad.FechaInicioC57.HasValue && factura.Fecha >= sociedad.FechaInicioC57.Value)
                        {
                            //Vamos indicándole las diferentes partes que componen la cadena de carácteres que componen el formato 507
                            string idenAplicacion = "90"; //Por defecto
                            string tipo = "507"; //Indica el código del formato
                            string emisora = String.IsNullOrEmpty(sociedad.Nif) ? String.Empty : Regex.Replace(sociedad.Nif, "([^0-9])", "").PadLeft(8, '0'); //8 carácteres en total, solo los números
                            string sufijo = sociedad.SufijoC57.Value.ToString().PadLeft(3, '0');//3

                            string referencia;
                            if (factura.Numero.Length >= 7)
                                referencia = sociedad.Codigo.ToString() + factura.SerieCodigo.ToString().PadLeft(2, '0') + factura.Numero.Substring(0, 2).PadLeft(2, '0') + factura.Numero.Substring(5).PadLeft(6, '0'); //sociedad/serie/año/numero de factura, 11 carácteres en total
                            else
                                referencia = sociedad.Codigo.ToString() + factura.SerieCodigo.ToString().PadLeft(2, '0') + factura.Numero.PadLeft(8, '0'); //sociedad/serie/numero de factura, 11 carácteres en total

                            //Dependiendo del sufijo ver si se debe poner el identificador a ceros o con la fecha actual más los días de vencimiento. (Se pone la fecha si el sufijo es mayor o igual a 500)
                            string identificador = Convert.ToInt32(sufijo) >= 500 ? (periodo.FechaFinPagoVoluntario.HasValue && periodo.FechaFinPagoVoluntario > AcuamaDateTime.Today ? periodo.FechaFinPagoVoluntario.Value : AcuamaDateTime.Today.AddDays(sociedad.DiasVencimientoC57.HasValue && sociedad.DiasVencimientoC57.Value > 0 ? sociedad.DiasVencimientoC57.Value : diasVtoPorDefecto)).ToString("dd/MM/yy").Replace("/", String.Empty) : "000000"; //6 carácteres en total, Fecha del vencimiento
                            string importe = importePendienteFactura.ToString("N2").Replace(",", String.Empty).Replace(".", String.Empty).PadLeft(10, '0'); //10 carácteres en total
                            string paridad = "0"; // Bit de paridad

                            //Calcular el dígito de control
                            decimal digitoControl = ((Convert.ToDecimal(Convert.ToInt64(emisora) + Convert.ToInt32(sufijo) + Convert.ToInt64(referencia) + Convert.ToInt64(identificador) + Convert.ToInt64(importe)) % 97)) / 97;
                            string digitoRef = (digitoControl > 0 ? (100 - (Math.Truncate(digitoControl * 100))).ToString() : "0").PadLeft(2, '0');

                            //Validamos que todos los campos que forman el código de barras con formato 507 son correctos, en total son 46 carácteres
                            if (idenAplicacion.Length == 2 && tipo.Length == 3 && emisora.Length == 8 && sufijo.Length == 3 && referencia.Length == 11 && identificador.Length == 6 && importe.Length == 10 && paridad.Length == 1 && digitoRef.Length == 2)
                                return string.Format("{0}{1}{2}{3}{4}{5}{6}{7}{8}", idenAplicacion, tipo, emisora, sufijo, referencia, digitoRef, identificador, importe, paridad);
                            else
                                return String.Empty;
                        }
                    }
                }
            }
            return String.Empty;
        }

        /// <summary>
        /// Decodifica un código de barras
        /// </summary>
        /// <param name="codigoBarras">Cadena de carácteres con el código de barras codificado en formato 507</param>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="codigoBarrasDecodificado">Objeto cCodigoBarrasFormato507BO con los valores decodificados</param>
        /// <returns>Respuesta con el resultado de la operación</returns>
        public static cRespuesta DecodificarCodigoBarrasFormato507(string codigoBarras, string usuarioCodigo, out cCodigoBarrasFormato507BO codigoBarrasDecodificado)
        {
            codigoBarrasDecodificado = new cCodigoBarrasFormato507BO();
            cRespuesta respuesta = new cRespuesta();

            if (String.IsNullOrEmpty(codigoBarras) || codigoBarras.Length != 46)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                cExcepciones.ControlarER(new Exception(Resource.errorFormato507CodigoDeBarrasIncorrecto), TipoExcepcion.Error, out respuesta);
                return respuesta;
            }

            //Obtener el punto de pago y el medio de pago de la tabla agente de cobros a partir del usuario
            cBindableList<cAgenteCobroBO> agentesCobro = cAgentesCobrosBL.ObtenerPorUsuario(usuarioCodigo, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.SinRegistros)
            {
                cExcepciones.ControlarER(new Exception(Resource.agentesCobroNoExistenPorUsuario.Replace("@item", usuarioCodigo)), TipoExcepcion.Error, out respuesta);
                return respuesta;
            }

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                codigoBarrasDecodificado.PuntoPagoCodigo = agentesCobro[0].PuntoPagoCodigo;
                codigoBarrasDecodificado.MedioPagoCodigo = agentesCobro[0].MedioPagoCodigo;

                codigoBarrasDecodificado.CodigoBarras = codigoBarras;
                codigoBarrasDecodificado.Emisora = codigoBarras.Substring(5, 8);
                codigoBarrasDecodificado.Referencia = codigoBarras.Substring(16, 11);
                codigoBarrasDecodificado.Importe = Convert.ToDecimal(codigoBarras.Substring(33, 10));
                codigoBarrasDecodificado.SociedadCodigo = Convert.ToInt16(codigoBarras.Substring(16, 1));

                codigoBarrasDecodificado.FechaRegistro = AcuamaDateTime.Today;
                codigoBarrasDecodificado.FechaCobro = AcuamaDateTime.Today;
                codigoBarrasDecodificado.UsuarioCodigo = usuarioCodigo;
            }

            cFacturaBO factura = new cFacturaBO();
            short sociedad = 0, serie = 0;
            string numero = String.Empty;

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                //Obtener la factura a partir de la sociedad/serie/número
                sociedad = codigoBarrasDecodificado.SociedadCodigo.HasValue ? codigoBarrasDecodificado.SociedadCodigo.Value : (short)0;
                serie = Convert.ToInt16(codigoBarrasDecodificado.Referencia.Substring(1, 2));
                numero = codigoBarrasDecodificado.Referencia.Substring(3, 8);
                //numero = Convert.ToInt32(codigoBarrasDecodificado.Referencia.Substring(3, 8));
                factura = ObtenerPorSociedadSerieYNumero(sociedad, serie, numero, out respuesta);
            }

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                //Obtener el importe facturado
                codigoBarrasDecodificado.ImporteFacturado = cFacturasBL.ObtenerImporteFacturado(factura.FacturaCodigo.Value, factura.ContratoCodigo.Value, factura.PeriodoCodigo, factura.Version.Value, null, out respuesta);
                codigoBarrasDecodificado.ImporteCobrado = cCobrosBL.ObtenerImporteCobrado(factura.ContratoCodigo.Value, factura.PeriodoCodigo, factura.FacturaCodigo.Value, null, out respuesta);
                codigoBarrasDecodificado.ImportePendiente = (codigoBarrasDecodificado.ImporteFacturado.HasValue ? codigoBarrasDecodificado.ImporteFacturado : 0) - (codigoBarrasDecodificado.ImporteCobrado.HasValue ? codigoBarrasDecodificado.ImporteCobrado : 0);
                //Sobreescribir la referencia descartando los ceros sobrantes
                codigoBarrasDecodificado.Referencia = sociedad.ToString() + serie.ToString() + numero;

            }

            cContratoBO contrato = new cContratoBO();

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                contrato.Codigo = factura.ContratoCodigo.Value;
                contrato.Version = factura.ContratoVersion.Value;
                cContratoBL.Obtener(ref contrato, out respuesta);
            }

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                codigoBarrasDecodificado.DireccionSuministro = contrato.TitularDireccion;
                codigoBarrasDecodificado.NombreTitular = contrato.TitularNombre;
                codigoBarrasDecodificado.ContratoCodigo = factura.ContratoCodigo;
                codigoBarrasDecodificado.SerieCodigo = factura.SerieCodigo;
                codigoBarrasDecodificado.NumeroFactura = factura.Numero;
                codigoBarrasDecodificado.PeriodoCodigo = factura.PeriodoCodigo;
            }

            return respuesta;
        }

        /// <summary>
        /// Obtiene las facturas en las cuales no está reflejada una bonificación para un contrato, versión
        /// </summary>
        /// <param name="facCtrCod">Código del contrato</param>
        /// <param name="facCtrVersion">Versión del contrato</param>
        /// <param name="respuesta">Objeto respuesta con el resultado de la operación</param>
        /// <returns>Lista de facturas</returns>
        public static cBindableList<cFacturaBO> ObtenerSinBonificar(int? facCtrCod, short? facCtrVersion, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerSinBonificar(facCtrCod, facCtrVersion, out respuesta);
        }

        /// <summary>
        /// Codifica el periodo usando el código de factura
        /// </summary>
        /// <param name="periodo">Código del periodo</param>
        /// <param name="codigo">Entero con el código de la factura</param>
        /// <returns>String con el periodo codificado</returns>
        public static String CodificarPeriodoYCodigo(string periodo, short codigo)
        {
            if (periodo.Length == 6 && periodo.Substring(0, 5) == "00000")
                periodo = periodo.Replace(periodo.Substring(0, 5), "#") + codigo.ToString().PadLeft(4, '0');

            return periodo;
        }

        /// <summary>
        /// Decodifica el periodo y código de factura codificado
        /// </summary>
        /// <param name="str">String con la codificación del periodo y el código de factura</param>
        /// <param name="periodo">Código del periodo</param>
        /// <param name="codigo">Código de factura</param>
        /// <returns>Devuelve true si se ha decodificado correctamente, false en caso contrario</returns>
        public static bool DecodificarPeriodoYCodigo(string str, out string periodo, out short codigo)
        {
            periodo = str ?? String.Empty;
            codigo = 1;
            if (str.StartsWith("#") && str.Length == 6)
            {
                str = str.Replace(str.Substring(0, 1), "00000");
                periodo = str.Substring(0, 6);

                if (!short.TryParse(str.Substring(6, str.Length - 6), out codigo))
                    return false;

                return true;
            }
            return false;
        }

        /// <summary>
        /// Comprueba que existe un cambio de tarifa a mitad de periodo
        /// </summary>
        /// <param name="periodo">Código periodo</param>
        /// <param name="respuesta">Objeto cRespuesta</param>
        /// <returns>True si el cambio existe, False en caso contrario </returns>
        public static bool ExisteCambioTarifa(string periodo, out cRespuesta respuesta)
        {
            return new cFacturasDL().ExisteCambioTarifa(periodo, out respuesta);
        }

        /// <summary>
        /// Obtener si los diferidos de un periodo-zona deben aplicarse sólo a una factura concreta (true)
        /// </summary>
        /// <param name="zona"></param>
        /// <param name="difPeriodoAplicacion"></param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si deben aplicarse sólo a una factura concreta, False en caso contrario</returns>
        public static bool ObtenerAplicarDiferidosSoloEnUnaFactura(string zona, string difPeriodoAplicacion, out cRespuesta respuesta)
        {
            return new cFacturasDL().ObtenerAplicarDiferidosSoloEnUnaFactura(zona, difPeriodoAplicacion, out respuesta);
        }

        /// <summary>
        /// Obtiene las últimas versiones de las facturas
        /// </summary>
        /// <param name="seleccion">Selecciones del usuario</param>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si la operación fue correcta o si no había órdenes que abrir</returns>
        public static bool LiquidarServiciosEnFacturas(SeleccionPtesCobro seleccion, string usuarioCodigo, out cRespuesta respuesta, out int registrosProcesados)
        {
            return new cFacturasDL().LiquidarServiciosEnFacturas(seleccion, usuarioCodigo, out respuesta, out registrosProcesados);
        }

        /// <summary>
        /// Abre las OTs que tienen diferidos aplicados en una factura
        /// </summary>
        /// <param name="factura">Factura de la que queremos abrir las órdenes de trabajo de los diferidos que incluye</param>
        /// <param name="resetTodosCamposCierre">Si se quieren resetear todos los campos del cierre (true) o sólo la fecha de cierre (false)</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>True si la operación fue correcta o si no había órdenes que abrir</returns>
        public static bool AbrirOTs(cFacturaBO factura, bool resetTodosCamposCierre, out cRespuesta respuesta)
        {
            cBindableList<cOrdenTrabajoBO> ordenes = new cBindableList<cOrdenTrabajoBO>();
            respuesta = new cRespuesta();

            try
            {
                // La serie de las OT no se corresponde con la de la factura sino con el tipo de OT
                // Recogemos todas sin tener en cuenta la serie
                factura.Serie = null;
                factura.SerieCodigo = null;

                ordenes = cOrdenTrabajoBL.ObtenerPorFactura(factura, out respuesta);
                if (ordenes.Count > 0)
                {
                    foreach (cOrdenTrabajoBO orden in ordenes)
                    {
                        if (orden.Fcierre != null)
                        {
                            using (TransactionScope scope = cAplicacion.NewTransactionScope())
                            {
                                // Vamos dejando abiertas las OT que tienen diferidos aplicados en esa factura
                                respuesta = cOrdenTrabajoBL.Abrir(orden, resetTodosCamposCierre);
                                if (respuesta.Resultado != ResultadoProceso.OK && respuesta.Resultado != ResultadoProceso.SinRegistros)
                                    return false;

                                // Desaplicamos los diferidos que están aplicados en la factura
                                respuesta = cOrdenTrabajoBL.DesaplicarDiferidos(orden, factura);
                                if (respuesta.Resultado == ResultadoProceso.OK || respuesta.Resultado == ResultadoProceso.SinRegistros)
                                    scope.Complete();
                                else
                                    return false;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return true;
        }

        #region "Precisión del redondeo (facE: 2, default:4)"
        /// <summary>
        /// Comprueba si la factura corresponde a un contrato de Factura Electronica
        /// </summary>
        /// <param name="factura">Factura de la que queremos comprobar el contrato</param>
        /// <returns>True si es un contrato de factura electronica.</returns>

        public static bool EsFacE(cFacturaBO factura)
        {
            bool result = false;
            cRespuesta respuesta = new cRespuesta();

            try
            {
                //Obtenemos el contrato asociado a la factura
                cContratoBO contrato = new cContratoBO
                {
                    Codigo = factura.ContratoCodigo ?? 0,
                    Version = factura.ContratoVersion ?? 0
                };
                cContratoBL.Obtener(ref contrato, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK)
                    result = contrato.FacturaeActiva ?? false;                
            }
            catch (Exception)
            {
                
            }
            return result;
        }
        #endregion

        /// <summary>
        /// Aplica sanción del 100% de m3 facturados por zona a las facturas afectadas
        /// </summary>
        /// <param name="zona">zona</param>
        /// <param name="periodo">periodo</param>
        /// <param name="incidencias">incidencias de lectura separadas por ;</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta AplicarSancion100porZona(string zona, string periodo, string incidencias, string usuarioCodigo, out string log, out int registrosProcesados)
        {
            return AplicarSancion100porZona(zona, periodo, incidencias, usuarioCodigo, out log, out registrosProcesados, null, null, null);
        }

        /// <summary>
        /// Aplica sanción del 100% de m3 facturados por zona a las facturas afectadas
        /// </summary>
        /// <param name="zona">zona</param>
        /// <param name="periodo">periodo</param>
        /// <param name="incidencias">incidencias de lectura separadas por ;</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <param name="taskUser">Usuario que ejecuta la tarea</param>
        /// <param name="taskType">Tipo de tarea</param>
        /// <param name="taskNumber">Número de tarea</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta AplicarSancion100porZona(string zona, string periodo, string incidencias, string usuarioCodigo, out string log, out int registrosProcesados, string taskUser, ETaskType? taskType, int? taskNumber)
        {
            cRespuesta respuesta = new cRespuesta();
            registrosProcesados = 0;
            log = String.Empty;

            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    bool Correcto = new cFacturasDL().AplicarSancion100porZona(zona, periodo, incidencias, usuarioCodigo, out respuesta, out registrosProcesados);

                    if (respuesta.Resultado == ResultadoProceso.SinRegistros)
                        respuesta.Resultado = ResultadoProceso.OK;

                    //Establecer número de pasos de la tarea
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, 1);

                    //Si estamos ejecutando en modo tarea...
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    {
                        //Comprobar si se desea cancelar
                        if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            return new cRespuesta();
                        //Incrementar el número de pasos
                        cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
                }
            }
            catch (Exception ex)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
                registrosProcesados = 0;
            }

            return respuesta;
        }

        /// <summary>
        /// Aplica sanción del 100% de m3 facturados por zona a las facturas afectadas
        /// </summary>
        /// <param name="zona">zona</param>
        /// <param name="periodo">periodo</param>
        /// <param name="incidencias">incidencias de lectura separadas por ;</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta AplicarSancion100porContrato(int contrato, string periodo, bool aplicar, string usuarioCodigo, out string log, out int registrosProcesados)
        {
            return AplicarSancion100porContrato(contrato, periodo, aplicar, usuarioCodigo, out log, out registrosProcesados, null, null, null);
        }

        /// <summary>
        /// Aplica sanción del 100% de m3 facturados por zona a las facturas afectadas
        /// </summary>
        /// <param name="zona">zona</param>
        /// <param name="periodo">periodo</param>
        /// <param name="incidencias">incidencias de lectura separadas por ;</param>
        /// <param name="usuarioCodigo">Código del usuario que ha iniciado sesión</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <param name="taskUser">Usuario que ejecuta la tarea</param>
        /// <param name="taskType">Tipo de tarea</param>
        /// <param name="taskNumber">Número de tarea</param>
        /// <returns>Objeto respuesta con el resultado de la operación</returns>
        public static cRespuesta AplicarSancion100porContrato(int contrato, string periodo, bool aplicar, string usuarioCodigo, out string log, out int registrosProcesados, string taskUser, ETaskType? taskType, int? taskNumber)
        {
            cRespuesta respuesta = new cRespuesta();
            registrosProcesados = 0;
            log = String.Empty;

            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    bool Correcto = new cFacturasDL().AplicarSancion100porContrato(contrato, periodo, aplicar, usuarioCodigo, out respuesta, out registrosProcesados);

                    if (respuesta.Resultado == ResultadoProceso.SinRegistros)
                        respuesta.Resultado = ResultadoProceso.OK;

                    //Establecer número de pasos de la tarea
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, 1);

                    //Si estamos ejecutando en modo tarea...
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    {
                        //Comprobar si se desea cancelar
                        if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            return new cRespuesta();
                        //Incrementar el número de pasos
                        cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
                }
            }
            catch (Exception ex)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
                registrosProcesados = 0;
            }

            return respuesta;
        }

        public static int basePrecision(cFacturaBO factura)
        {
            int result = 4;

            try
            {
                DateTime fecha;
                cParametroBL.GetDateTime("LINEAS_2DECIMALES", out fecha);

                if (factura.FechaRegistro != null && fecha != null)
                    result = factura.FechaRegistro >= fecha ? 2 : 4;
            }
            catch
            {

            }
            return result;

        }


        #region facTotalesTrab: Para posponer la actualización de los totales
        private static void cFacTotalesTrab_Insert(cBindableList<cFacturaBO> facturas)
        {
            try
            {
                cFacTotalesTrabBL facTotalesTrab = new cFacTotalesTrabBL();
                facTotalesTrab.Insertar(facturas);
            }
            catch { }
        }

        private static void cFacTotalesTrab_Delete()
        {
            cRespuesta respuesta = new cRespuesta();
            try
            {
                cFacTotalesTrabBL facTotalesTrab = new cFacTotalesTrabBL();
                facTotalesTrab.Borrar(out respuesta);
            }
            catch { }
        }
        #endregion

    }
}