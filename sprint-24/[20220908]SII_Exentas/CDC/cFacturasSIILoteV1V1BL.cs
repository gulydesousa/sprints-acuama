using BL.ProcesarLotesFacturaV2;
using BL.Sistema;
using BO.Comun;
using BO.Facturacion;
using BO.Resources;
using BO.SII.v1.v1;
using BO.Sistema;
using DL.Facturacion;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Transactions;
using System.Xml;
using System.Xml.Serialization;


namespace BL.Facturacion
{
    public class cFacturasSIILoteV1V1BL
    {
        public static string[] errores_reenvio = new[] { 
                ////Errores que provocan el rechazo del envío completo
                //"4104", // Error en la cabecera. El valor del campo NIF del bloque Titular no está identificado
                //"4105", // Error en la cabecera. El valor del campo NIFRepresentante del bloque Titular no está identificado
                "4109", // El NIF no está identificado. NIF: XXXX
                "4111", // El NIF tiene un formato erróneo.
                //"4122", // Error en la cabecera. El NIF del titular tiene un formato erróneo.
                //"4123", // Error en la cabecera. El NIFRepresentante tiene un formato erróneo.

                //Errores que provocan el rechazo de la factura (o de la petición completa si el error se produce en la cabecera)
                "1100", // Valor o tipo incorrecto del campo: XXXXX (sólo para campo NIF)
                "1104", // Valor del campo ID incorrecto
                "1116", // El NIF no está identificado. NIF:XXXXX
                "1117", // El NIF no está identificado. NIF:XXXXX. NOMBRE_RAZON:YYYYY
                "1153", // El NIF tiene un formato erróneo
                "1168", // El valor del CodigoPais solo puede ser 'ES' cuando el IDType sea '07'
                "1169", // El campo ID no contiene un NIF con formato correcto.

                //Errores que producen la aceptación y registro de la factura en el sistema (posteriormente deben ser corregidos)
                "2011" // El NIF de la contraparte no está censado                
            };

        public static string error_NIFNoCensado = "2011";
        public static string claveID_NoCensado = "07";

        /// <summary>
        /// Obtiene una lista enlazable
        /// </summary>
        /// <param name="filtro">filtro que condicionará la búsqueda</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>Lista enlazable (si no se encuentran datos devuelve una lista vacía)</returns>
        public static cBindableList<cFacturasSIILoteBO> ObtenerTodos(string filtro, out cRespuesta respuesta)
        {
            cBindableList<cFacturasSIILoteBO> facturasSIILoteLista = null;
            respuesta = new cRespuesta();

            cFacturasSIILoteDL facturasSIILoteDL = new cFacturasSIILoteDL();
            cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros();
            parametros.BusinessObject = new cFacturasSIILoteBO();

            try
            {
                facturasSIILoteLista = facturasSIILoteDL.Obtener(filtro, parametros, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return facturasSIILoteLista != null ? facturasSIILoteLista : new cBindableList<cFacturasSIILoteBO>();
        }

        /// <summary>
        /// Obtiene un registro de facturasSIILote a partir de nuestro id (facturasSIILote.fcSiiLtID)
        /// </summary>
        /// <param name="id">Guid nuestro</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns></returns>
        public static cFacturasSIILoteBO Obtener(string id, out cRespuesta respuesta)
        {
            cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros();
            parametros.BusinessObject = new cFacturasSIILoteBO();
            parametros.BusinessObject.Id = id;

            cBindableList<cFacturasSIILoteBO> facturasSIILote = new cFacturasSIILoteDL().Obtener(null, parametros, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
                if (facturasSIILote.Count == 1)
                    return facturasSIILote[0];
                else
                    cExcepciones.ControlarER(new Exception(Resource.errorObtenidosVariosRegistros), TipoExcepcion.Informacion, out respuesta);

            return null;
        }

        /// <summary>
        /// Obtiene un registro de facturasSIILote a partir de su id (facturasSIILote.fcSiiLtIdIntercambioRet)
        /// </summary>
        /// <param name="idIntercambioRet">Id del lote en el SII</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns></returns>
        public static cFacturasSIILoteBO ObtenerPorIdIntercambioRet(string idIntercambioRet, out cRespuesta respuesta)
        {
            cFacturasSIILoteBO facturaSIILote = new cFacturasSIILoteBO { IdIntercambioRet = idIntercambioRet };
            cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros
            {
                BusinessObject = facturaSIILote,
                PorIdIntercambioRet = true
            };

            cBindableList<cFacturasSIILoteBO> facturasSIILote = new cFacturasSIILoteDL().Obtener(null, parametros, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
                if (facturasSIILote.Count == 1)
                    return facturasSIILote[0];
                else
                    cExcepciones.ControlarER(new Exception(Resource.errorObtenidosVariosRegistros), TipoExcepcion.Informacion, out respuesta);

            return null;
        }

        /// <summary>
        /// Actualiza un registro en la tabla facSIILote
        /// </summary>
        /// <param name="facturaSIILote">Objeto cFacturasSIILoteBO</param>
        /// <param name="PorIdIntercambioRet">False si queremos que actualice por Id, True si queremos que actualice por IdIntercambioRet</param>
        /// <returns></returns>
        public static cRespuesta Actualizar(cFacturasSIILoteBO facturaSIILote)
        {
            cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros
            {
                BusinessObject = facturaSIILote,
                PorIdIntercambioRet = false
            };
            return new cFacturasSIILoteDL().Actualizar(parametros);
        }

        /// <summary>
        /// Actualiza un registro en la tabla facSIILote
        /// </summary>
        /// <param name="facturaSIILote">Objeto cFacturasSIILoteBO</param>
        /// <param name="PorIdIntercambioRet">False si queremos que actualice por Id, True si queremos que actualice por IdIntercambioRet</param>
        /// <returns></returns>
        public static cRespuesta Actualizar(cFacturasSIILoteBO facturaSIILote, bool porIdIntercambioRet)
        {
            cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros
            {
                BusinessObject = facturaSIILote,
                PorIdIntercambioRet = porIdIntercambioRet
            };
            return new cFacturasSIILoteDL().Actualizar(parametros);
        }

        public static cRespuesta Insertar(cFacturasSIILoteBO facturaSIILote)
        {
            cRespuesta respuesta = new cRespuesta();

            // Comprobar si existe
            if (!String.IsNullOrEmpty(facturaSIILote.Id) && Existe(facturaSIILote.Id, out respuesta))
                cExcepciones.ControlarER(new Exception(Resource.errorInsertarExiste.Replace("@item", Resource.identificadorAbv2 + ": " + facturaSIILote.Id)), TipoExcepcion.Informacion, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros();
                parametros.BusinessObject = facturaSIILote;

                respuesta = new cFacturasSIILoteDL().Insertar(parametros);
            }

            return respuesta;
        }

        public static bool Existe(string id, out cRespuesta respuesta)
        {
            cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros();
            parametros.BusinessObject = new cFacturasSIILoteBO();
            parametros.BusinessObject.Id = id;

            return new cFacturasSIILoteDL().Existen(parametros, out respuesta);
        }

        public static cRespuesta Borrar(string id)
        {
            cRespuesta respuesta;

            using (TransactionScope scope = cAplicacion.NewTransactionScope())
            {
                cFacturasSIILoteDL.Parametros parametros = new cFacturasSIILoteDL.Parametros();
                parametros.BusinessObject = new cFacturasSIILoteBO();
                parametros.BusinessObject.Id = id;

                respuesta = new cFacturasSIILoteDL().Borrar(parametros);

                if (respuesta.Resultado == ResultadoProceso.OK)
                    scope.Complete();
            }

            return respuesta;
        }

        /// <summary>
        /// Obtiene los lotes de las facturas SII de alta, modificació y anulación
        /// </summary>
        /// <param name="diaPosterior">True: Solo facturas anteriores a hoy</param>
        /// <param name="log">Log del proceso de lotes</param>
        /// <param name="loteXMLAltas">Lote de altas</param>
        /// <param name="loteXMLModificaciones">Lote de modificaciones</param>
        /// <param name="loteXMLAnulaciones">Lote de anulaciones</param>
        /// <returns></returns>
        public static cRespuesta ProcesarLotes(bool? diaPosterior, out string logLotes, out ArrayList loteXMLAltas, out ArrayList loteXMLModificaciones, out ArrayList loteXMLAnulaciones)
        {
            cRespuesta respuesta = new cRespuesta();
            cFacturasSIILoteBO lote = new cFacturasSIILoteBO();
            string logLote = String.Empty;
            cSociedadBO sociedad = new cSociedadBO();
            cBindableList<cFacturaSIIBO> facturasSII = null;
            XmlDocument loteXMLAlta, loteXMLAnulacion, loteXMLModificacion = null;
            int numeroLotes = 0;
            int maxFacSIILote = 0;
            int inicioLote;
            loteXMLAltas = new ArrayList();
            loteXMLAnulaciones = new ArrayList();
            loteXMLModificaciones = new ArrayList();
            logLotes = String.Empty;

//            using (TransactionScope scope = cAplicacion.NewTransactionScope())
  //          {
           
            string strSociedadRemesa = cParametroBL.ObtenerValor("SOCIEDAD_REMESA", out respuesta);
            string strSociedadPorDefecto = cParametroBL.ObtenerValor("SOCIEDAD_POR_DEFECTO", out respuesta);
            string strSociedadSII = String.IsNullOrEmpty(strSociedadRemesa) ? strSociedadPorDefecto: strSociedadRemesa;
            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                sociedad.Codigo = String.IsNullOrEmpty(strSociedadSII) ? (short)0 : Convert.ToInt16(strSociedadSII);
                cSociedadBL.Obtener(ref sociedad, out respuesta);
            }

            string explotacionCodigo = null;
            if (respuesta.Resultado == ResultadoProceso.OK)
                explotacionCodigo = cParametroBL.ObtenerValor("EXPLOTACION_CODIGO", out respuesta);

            string versionSII = null;
            if (respuesta.Resultado == ResultadoProceso.OK)
                versionSII = cParametroBL.ObtenerValor("VERSION_SII", out respuesta);

            // Número máximo de facturas SII por lote
            string maxFacSIILoteString = null;
            if (respuesta.Resultado == ResultadoProceso.OK)
                maxFacSIILoteString = cParametroBL.ObtenerValor("FacLoteSII", out respuesta);

            //Con esto borramos los casos que se hayan hecho rectificativas y no se haya modificado nada en sus importes
            /* if (respuesta.Resultado == ResultadoProceso.OK)
                 respuesta = cFacturasSIIBL.BorrarDuplicadas();
             respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
             */
            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                maxFacSIILote = String.IsNullOrEmpty(maxFacSIILoteString) ? 0 : Convert.ToInt32(maxFacSIILoteString);

                lote.IdTenant = "SACYR";

                lote.IdAgrupacion = sociedad.CodigoSAP;
                lote.Sociedad = sociedad.CodigoSAP;
                lote.Origen = explotacionCodigo;
                lote.TitularNIF = sociedad.Nif;
                lote.TitularNombreRazon = sociedad.Nombre;
                lote.VersionSII = versionSII;

                facturasSII = cFacturasSIIBL.ObtenerFacturasAltas(diaPosterior, "A0", out respuesta);
            }

            if (respuesta.Resultado == ResultadoProceso.OK && facturasSII.Count > 0)
            {
                numeroLotes = Convert.ToInt32(Math.Ceiling((decimal)facturasSII.Count / maxFacSIILote));
                inicioLote = 0;

                // Número de lotes a generar
                for (int i = 0; i < numeroLotes && respuesta.Resultado == ResultadoProceso.OK; i++)
                {
                    lote.FacturasSII = new cBindableList<cFacturaSIIBO>();

                    // Añadir las facturas SII al lote a procesar
                    for (int j = inicioLote; j < maxFacSIILote * (i + 1) && j < facturasSII.Count(); j++)
                        lote.FacturasSII.Add(facturasSII[j]);

                    loteXMLAlta = new XmlDocument();
                    respuesta = ProcesarLotesEmisionFacturasAlta(lote, out loteXMLAlta, out logLote);
                    logLotes += logLote;

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        loteXMLAltas.Add(loteXMLAlta);

                    inicioLote += maxFacSIILote;
                }
            }

            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;

            if (respuesta.Resultado == ResultadoProceso.OK)
                facturasSII = cFacturasSIIBL.ObtenerFacturasAltas(diaPosterior, "A1", out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK && facturasSII.Count > 0)
            {
                numeroLotes = Convert.ToInt32(Math.Ceiling((decimal)facturasSII.Count / maxFacSIILote));
                inicioLote = 0;

                // Número de lotes a generar
                for (int i = 0; i < numeroLotes && respuesta.Resultado == ResultadoProceso.OK; i++)
                {
                    lote.FacturasSII = new cBindableList<cFacturaSIIBO>();

                    // Añadir las facturas SII al lote a procesar
                    for (int j = inicioLote; j < maxFacSIILote * (i + 1) && j < facturasSII.Count(); j++)
                        lote.FacturasSII.Add(facturasSII[j]);

                    loteXMLAlta = new XmlDocument();
                    respuesta = ProcesarLotesEmisionFacturasAlta(lote, out loteXMLAlta, out logLote);
                    logLotes += logLote;

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        loteXMLAltas.Add(loteXMLAlta);

                    inicioLote += maxFacSIILote;
                }
            }

            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;

            if (respuesta.Resultado == ResultadoProceso.OK)
                facturasSII = cFacturasSIIBL.ObtenerFacturasModificadas(diaPosterior, "A0", out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK && facturasSII.Count > 0)
            {
                numeroLotes = Convert.ToInt32(Math.Ceiling((decimal)facturasSII.Count / maxFacSIILote));
                inicioLote = 0;

                // Número de lotes a generar
                for (int i = 0; i < numeroLotes && respuesta.Resultado == ResultadoProceso.OK; i++)
                {
                    lote.FacturasSII = new cBindableList<cFacturaSIIBO>();

                    // Añadir las facturas SII al lote a procesar
                    for (int j = inicioLote; j < maxFacSIILote * (i + 1) && j < facturasSII.Count(); j++)
                        lote.FacturasSII.Add(facturasSII[j]);

                    loteXMLModificacion = new XmlDocument();
                    respuesta = ProcesarLotesEmisionFacturasModificadas(lote, out loteXMLModificacion, out logLote);
                    logLotes += logLote;

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        loteXMLModificaciones.Add(loteXMLModificacion);

                    inicioLote += maxFacSIILote;
                }
            }

            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;

            if (respuesta.Resultado == ResultadoProceso.OK)
                facturasSII = cFacturasSIIBL.ObtenerFacturasModificadas(diaPosterior, "A1", out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK && facturasSII.Count > 0)
            {
                numeroLotes = Convert.ToInt32(Math.Ceiling((decimal)facturasSII.Count / maxFacSIILote));
                inicioLote = 0;

                // Número de lotes a generar
                for (int i = 0; i < numeroLotes && respuesta.Resultado == ResultadoProceso.OK; i++)
                {
                    lote.FacturasSII = new cBindableList<cFacturaSIIBO>();

                    // Añadir las facturas SII al lote a procesar
                    for (int j = inicioLote; j < maxFacSIILote * (i + 1) && j < facturasSII.Count(); j++)
                        lote.FacturasSII.Add(facturasSII[j]);

                    loteXMLModificacion = new XmlDocument();
                    respuesta = ProcesarLotesEmisionFacturasModificadas(lote, out loteXMLModificacion, out logLote);
                    logLotes += logLote;

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        loteXMLModificaciones.Add(loteXMLModificacion);

                    inicioLote += maxFacSIILote;
                }
            }

            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;

            if (respuesta.Resultado == ResultadoProceso.OK)
                facturasSII = cFacturasSIIBL.ObtenerFacturasAnuladas(diaPosterior, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK && facturasSII.Count > 0)
            {
                numeroLotes = Convert.ToInt32(Math.Ceiling((decimal)facturasSII.Count / maxFacSIILote));
                inicioLote = 0;

                // Número de lotes a generar
                for (int i = 0; i < numeroLotes && respuesta.Resultado == ResultadoProceso.OK; i++)
                {
                    lote.FacturasSII = new cBindableList<cFacturaSIIBO>();

                    // Añadir las facturas SII al lote a procesar
                    for (int j = inicioLote; j < maxFacSIILote * (i + 1) && j < facturasSII.Count(); j++)
                        lote.FacturasSII.Add(facturasSII[j]);

                    loteXMLAnulacion = new XmlDocument();
                    respuesta = ProcesarLotesAnulacionFacturas(lote, out loteXMLAnulacion, out logLote);
                    logLotes += logLote;

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        loteXMLAnulaciones.Add(loteXMLAnulacion);

                    inicioLote += maxFacSIILote;
                }
            }

            //if (respuesta.Resultado == ResultadoProceso.OK)
            //  scope.Complete();
            //}

            respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;
            return respuesta;
        }

        public static cRespuesta ProcesarLotesEmisionFacturasAlta(cFacturasSIILoteBO lote, out XmlDocument loteXML, out string log)
        {
            cRespuesta respuesta = new cRespuesta();
            cSociedadBO sociedadBO = new cSociedadBO();
            //IdOperacionesTrascendenciaTributariaType? claveRegimen = null;
            string claveRegimen = null;
            loteXML = null;
            log = null;
            //int contadorIVA;
            loteDTO loteDTO = new loteDTO();
            System.Net.ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

            using (TransactionScope scope = cAplicacion.NewTransactionScope())
            {
                string strSociedadRemesa = cParametroBL.ObtenerValor("SOCIEDAD_REMESA", out respuesta);
                string strSociedadPorDefecto = cParametroBL.ObtenerValor("SOCIEDAD_POR_DEFECTO", out respuesta);
                string strSociedadSII = String.IsNullOrEmpty(strSociedadRemesa) ? strSociedadPorDefecto : strSociedadRemesa;
                if (respuesta.Resultado != ResultadoProceso.OK)
                    cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Error, out respuesta);
                else
                {
                    sociedadBO.Codigo = String.IsNullOrEmpty(strSociedadSII) ? (short)0 : Convert.ToInt16(strSociedadSII);

                    cSociedadBL.Obtener(ref sociedadBO, out respuesta);
                    if (respuesta.Resultado != ResultadoProceso.OK)
                        cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Error, out respuesta);
                }

                if (respuesta.Resultado == ResultadoProceso.OK)
                    claveRegimen = ObtenerClaveRegimenEspecial(out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK && lote != null && lote.FacturasSII != null && lote.FacturasSII.Count > 0)
                {
                    SuministroLRFacturasEmitidas facturasEmitida = new SuministroLRFacturasEmitidas();

                    facturasEmitida.Cabecera = new BO.SII.v1.v1.CabeceraSii();
                    facturasEmitida.Cabecera.IDVersionSii = VersionSII(lote.VersionSII);
                    facturasEmitida.Cabecera.Titular = new BO.SII.v1.v1.PersonaFisicaJuridicaESType();
                    facturasEmitida.Cabecera.Titular.NIF = sociedadBO.Nif;
                    facturasEmitida.Cabecera.Titular.NombreRazon = sociedadBO.Nombre;
                    //facturasEmitida.Cabecera.Titular.NIFRepresentante = String.Empty;

                    // Todo lote tiene que tener el mismo tipo de comunicación
                    facturasEmitida.Cabecera.TipoComunicacion = lote.FacturasSII[0].CabeceraTipoComunic == "A0" ? BO.SII.v1.v1.ClaveTipoComunicacionType.A0 : BO.SII.v1.v1.ClaveTipoComunicacionType.A1; // Altas

                    facturasEmitida.RegistroLRFacturasEmitidas = new BO.SII.v1.v1.LRfacturasEmitidasType[lote.FacturasSII.Count];

                    decimal importeTotal = 0;
                    int numeroFacturas = 0;
                    foreach (cFacturaSIIBO facturaSII in lote.FacturasSII)
                    {
                        if (facturaSII.FacturaSIIDesglosesBO.Count == 0)
                            cExcepciones.ControlarER(new Exception("La factura @item no tiene desglose SII".Replace("@item", facturaSII.NumSerieFacturaEmisor)), TipoExcepcion.Error, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            BO.SII.v1.v1.LRfacturasEmitidasType factura = new BO.SII.v1.v1.LRfacturasEmitidasType();
                            importeTotal += facturaSII.ImporteTotal.HasValue ? facturaSII.ImporteTotal.Value : 0;
                            // Periodo impositivo
                            factura.PeriodoLiquidacion = new BO.SII.v1.v1.RegistroSiiPeriodoLiquidacion();
                            factura.PeriodoLiquidacion.Ejercicio = facturaSII.PeriodoImpositivoEjercicio;
                            switch (facturaSII.PeriodoImpositivoPeriodo)
                            {
                                case "01": case "1": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item01; break;
                                case "02": case "2": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item02; break;
                                case "03": case "3": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item03; break;
                                case "04": case "4": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item04; break;
                                case "05": case "5": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item05; break;
                                case "06": case "6": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item06; break;
                                case "07": case "7": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item07; break;
                                case "08": case "8": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item08; break;
                                case "09": case "9": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item09; break;
                                case "10": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item10; break;
                                case "11": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item11; break;
                                case "12": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item12; break;
                            }

                            // ID de factura
                            factura.IDFactura = new BO.SII.v1.v1.IDFacturaExpedidaType();
                            factura.IDFactura.IDEmisorFactura = new BO.SII.v1.v1.IDFacturaExpedidaTypeIDEmisorFactura();
                            factura.IDFactura.IDEmisorFactura.NIF = facturaSII.IdEmisorFacturaNif;
                            factura.IDFactura.NumSerieFacturaEmisor = facturaSII.NumSerieFacturaEmisor;
                            factura.IDFactura.FechaExpedicionFacturaEmisor = facturaSII.FechaExpFacturaEmisor.HasValue ? facturaSII.FechaExpFacturaEmisor.Value.ToString("dd-MM-yyyy") : String.Empty;
                            //factura.IDFactura.NumSerieFacturaEmisorResumenFin = String.Empty;

                            // Factura expedida
                            factura.FacturaExpedida = new BO.SII.v1.v1.FacturaExpedidaType();                        
                            if (facturaSII.TipoFactura == "F1")
                                factura.FacturaExpedida.TipoFactura = BO.SII.v1.v1.ClaveTipoFacturaType.F1;
                            if (facturaSII.TipoFactura == "F2")
                                factura.FacturaExpedida.TipoFactura = BO.SII.v1.v1.ClaveTipoFacturaType.F2;



                            // Valor fijo 01 (parámetro "claveregimen"), salvo para las del primer semestre, que es valor fijo 16 y lo cogemos del registro de facSII
                            //factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia = claveRegimen.HasValue ? claveRegimen.Value : IdOperacionesTrascendenciaTributariaType.Item01;
                            factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia = ClaveRegimenEspecial(!string.IsNullOrEmpty(facturaSII.ClaveRegimenEspecialOTrasc) ? facturaSII.ClaveRegimenEspecialOTrasc : claveRegimen);

                            factura.FacturaExpedida.ImporteTotal = facturaSII.ImporteTotal.HasValue ? facturaSII.ImporteTotal.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";

                            if (facturaSII.ImporteTotal > 100000)
                            {
                                factura.FacturaExpedida.Macrodato = new MacrodatoType();
                                factura.FacturaExpedida.Macrodato = MacrodatoType.S;
                            }
                            else
                            {
                                factura.FacturaExpedida.Macrodato = new MacrodatoType();
                                factura.FacturaExpedida.Macrodato = MacrodatoType.N;
                            }


                            factura.FacturaExpedida.DescripcionOperacion = facturaSII.DesOperacion;
                            //factura.FacturaExpedida.ImporteTransmisionSujetoAIVA = String.Empty;
                            //factura.FacturaExpedida.BaseImponibleACoste = String.Empty;
                            factura.FacturaExpedida.FechaOperacion = facturaSII.FechaOperacion.HasValue ? facturaSII.FechaOperacion.Value.ToString("dd-MM-yyyy") : String.Empty;

                            //# Revisar
                            factura.FacturaExpedida.EmitidaPorTercerosODestinatarioSpecified = false;
                            factura.FacturaExpedida.EmitidaPorTercerosODestinatario = String.IsNullOrEmpty(facturaSII.EmitidaPorTerceros) || facturaSII.EmitidaPorTerceros == "N" ? BO.SII.v1.v1.EmitidaPorTercerosType.N : BO.SII.v1.v1.EmitidaPorTercerosType.S;

                            factura.FacturaExpedida.TipoRectificativaSpecified = false;
                            //factura.FacturaExpedida.TipoRectificativa = ClaveTipoRectificativaType.S;

                            factura.FacturaExpedida.VariosDestinatariosSpecified = false;
                            //factura.FacturaExpedida.VariosDestinatarios = VariosDestinatariosType.N;

                            factura.FacturaExpedida.CuponSpecified = false;
                            //factura.FacturaExpedida.Cupon = CuponType.N;

                            // Datos del inmueble
                            /*
                            factura.FacturaExpedida.DatosInmueble = new DatosInmuebleType[1];
                            factura.FacturaExpedida.DatosInmueble[0] = new DatosInmuebleType();
                            factura.FacturaExpedida.DatosInmueble[0].ReferenciaCatastral = facturaSII.InmuebleRefCat;
                            //factura.FacturaExpedida.DatosInmueble[0].SituacionInmueble = SituacionInmuebleType.Item1;
                            */

                            // Facturas agrupadas
                            /*
                            factura.FacturaExpedida.FacturasAgrupadas = new IDFacturaARType[1];
                            factura.FacturaExpedida.FacturasAgrupadas[0].FechaExpedicionFacturaEmisor = String.Empty;
                            factura.FacturaExpedida.FacturasAgrupadas[0].NumSerieFacturaEmisor = String.Empty;
                            */

                            // Importe rectificacion
                            /*
                            factura.FacturaExpedida.ImporteRectificacion = new DesgloseRectificacionType();
                            factura.FacturaExpedida.ImporteRectificacion.BaseRectificada = facturaSII.RectificadaBase.HasValue ? facturaSII.RectificadaBase.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                            factura.FacturaExpedida.ImporteRectificacion.CuotaRecargoRectificado = String.Empty;
                            factura.FacturaExpedida.ImporteRectificacion.CuotaRectificada = facturaSII.RectificadaCuota.HasValue ? facturaSII.RectificadaCuota.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                            */

                            // Facturas rectificadas
                            /*
                            factura.FacturaExpedida.FacturasRectificadas = new IDFacturaARType[1];
                            factura.FacturaExpedida.FacturasRectificadas[0].FechaExpedcionFacturaEmisor = facturaSII.RectificadaFechaExpFacturaEmisor.HasValue ? facturaSII.RectificadaFechaExpFacturaEmisor.Value.ToString("dd-MM-yyyy") : String.Empty;
                            factura.FacturaExpedida.FacturasRectificadas[0].NumSerieFacturaEmisor = facturaSII.RectificadaNumSereFacturaEmisor;
                            */

                            // Contraparte
                            if (facturaSII.TipoFactura != "F2" && facturaSII.TipoFactura != "R5")
                            {

                                factura.FacturaExpedida.Contraparte = new BO.SII.v1.v1.PersonaFisicaJuridicaType();
                                factura.FacturaExpedida.Contraparte.NIFRepresentante = facturaSII.ContraparteNifRepres;
                                factura.FacturaExpedida.Contraparte.NombreRazon = facturaSII.ContraparteNombreRazon;
                                factura.FacturaExpedida.Contraparte.Item = facturaSII.ContraparteNif;
                                if (!String.IsNullOrEmpty(facturaSII.ContraparteIdOtro))
                                {
                                    if (String.IsNullOrEmpty(facturaSII.ContraparteIdTipo))
                                        cExcepciones.ControlarER(new Exception("Tipo de persona jurídica es incorrecta en la factura @item".Replace("@item", facturaSII.NumSerieFacturaEmisor)), TipoExcepcion.Error, out respuesta);

                                    if (respuesta.Resultado == ResultadoProceso.OK)
                                    {
                                        BO.SII.v1.v1.IDOtroType otro = new BO.SII.v1.v1.IDOtroType();
                                        otro.ID = facturaSII.ContraparteId;
                                        otro.IDType = TipoPersonaJuridica(facturaSII.ContraparteIdTipo).Value;
                                        otro.CodigoPaisSpecified = !String.IsNullOrEmpty(facturaSII.ContraparteIdOtro);
                                        if (!String.IsNullOrEmpty(facturaSII.ContraparteIdOtro))
                                        {
                                            CountryType2 pais;
                                            Enum.TryParse(facturaSII.ContraparteIdOtro, out pais);
                                            otro.CodigoPais = pais;
                                        }
                                        factura.FacturaExpedida.Contraparte.Item = otro;
                                    }
                                }
                            }

                            // Tipo de desglose
                            factura.FacturaExpedida.TipoDesglose = null;

                            #region SII_Exentas
                            List<objDesglose_v1v1> desglose_v1v1 =  obtenerDesglosexTipo_v1v1(facturaSII);
                            #endregion

                            if (String.IsNullOrEmpty(facturaSII.ContraparteIdOtro) && !(String.IsNullOrEmpty(facturaSII.ContraparteNif)) && facturaSII.ContraparteNif.Substring(0, 1) != "N")
                            {
                                // Desglose: Factura
                                BO.SII.v1.v1.TipoSinDesgloseType desgloseFactura = null;

                                if (factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01 && // Desglose: No sujeta
                                    // Exceptuamos las del 16-Primer semestre, que siempre son sujetas y no exentas
                                    factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item16 &&
                                    factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item15)  
                                {
                                    factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                    desgloseFactura = new BO.SII.v1.v1.TipoSinDesgloseType();
                                    desgloseFactura.NoSujeta = new BO.SII.v1.v1.NoSujetaType();
                                    desgloseFactura.NoSujeta.ImportePorArticulos7_14_Otros = facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                    desgloseFactura.NoSujeta.ImporteTAIReglasLocalizacion = facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                    factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                    factura.FacturaExpedida.TipoDesglose.Item = desgloseFactura;
                                }
                                else // Desglose: Sujeta
                                {
                                    factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                    desgloseFactura = new BO.SII.v1.v1.TipoSinDesgloseType();

                                    #region SII_Exentas
                                    objDesglose_v1v1 objDesglose = desglose_v1v1.Where(x => x.TipoDesglose == TipoDesglose.DesgloseFactura).FirstOrDefault();
                                    desgloseFactura.Sujeta = objDesglose.SujetasType;
                                    desgloseFactura.NoSujeta = objDesglose.NoSujetasType;

                                    /*
                                    desgloseFactura.Sujeta = new BO.SII.v1.v1.SujetaType();
                                    desgloseFactura.Sujeta.NoExenta = new BO.SII.v1.v1.SujetaTypeNoExenta();
                                    desgloseFactura.Sujeta.NoExenta.TipoNoExenta = TipoOperacionSujetaNoExenta(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta);
                                    //String.IsNullOrEmpty(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta) || facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta == "S1" ? TipoOperacionSujetaNoExentaType.S1 : TipoOperacionSujetaNoExentaType.S2;

                                    if (facturaSII.FacturaSIIDesglosesBO.Count() > 0)
                                    {
                                        var agrupadoPorImpuesto = facturaSII.FacturaSIIDesglosesBO.GroupBy(a => a.TipoImpositivo).ToList();

                                        desgloseFactura.Sujeta.NoExenta.DesgloseIVA = new BO.SII.v1.v1.DetalleIVAEmitidaType[facturaSII.FacturaSIIDesglosesBO.Count()];
                                        contadorIVA = 0;
                                        for (int a = 0; a < agrupadoPorImpuesto.Count; a++)
                                        {
                                            decimal? baseImponible = 0;
                                            decimal? cuotaRepercutida = 0;
                                            for (int j = 0; j < agrupadoPorImpuesto[a].ToList().Count; j++)
                                            {
                                                baseImponible += agrupadoPorImpuesto[a].ToList()[j].BaseImponible.HasValue ? agrupadoPorImpuesto[a].ToList()[j].BaseImponible.Value : 0;
                                                cuotaRepercutida += agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.HasValue ? agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.Value : 0;
                                            }

                                            desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA] = new BO.SII.v1.v1.DetalleIVAEmitidaType();
                                            desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].BaseImponible = baseImponible.HasValue ? baseImponible.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                            desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRepercutida = cuotaRepercutida.HasValue ? cuotaRepercutida.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                            desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoImpositivo = agrupadoPorImpuesto[a].Key.HasValue ? agrupadoPorImpuesto[a].Key.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                            //desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoRecargoEquivalencia = String.Empty;
                                            //desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRecargoEquivalencia = String.Empty;

                                            contadorIVA++;
                                        }
                                    }
                                    */
                                    #endregion

                                    factura.FacturaExpedida.TipoDesglose.Item = desgloseFactura;
                                }
                            }
                            else
                            {
                                // Desglose: Tipo de la operacion
                                BO.SII.v1.v1.TipoConDesgloseType desgloseTipoOperacion = null;

                                if (factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01 && // Desglose: No sujeta
                                    // Exceptuamos las del 16-Primer semestre, que siempre son sujetas y no exentas
                                    factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item16 &&
                                    factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item15)  
                                {
                                    factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                    desgloseTipoOperacion = new BO.SII.v1.v1.TipoConDesgloseType();
                                    desgloseTipoOperacion.Entrega = new BO.SII.v1.v1.TipoSinDesgloseType();
                                    desgloseTipoOperacion.Entrega.NoSujeta = new BO.SII.v1.v1.NoSujetaType();
                                    desgloseTipoOperacion.Entrega.NoSujeta.ImportePorArticulos7_14_Otros = facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                    desgloseTipoOperacion.Entrega.NoSujeta.ImporteTAIReglasLocalizacion = facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                    factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                    factura.FacturaExpedida.TipoDesglose.Item = desgloseTipoOperacion;
                                }
                                else // Desglose: Sujeta
                                {
                                    // Comprobar si existe entrega y/o prestación de servicios
                                    bool entrega = false;
                                    bool prestacionServicios = false;

                                    foreach (cFacturaSIIDesgloseBO facturaSIIDesglose in facturaSII.FacturaSIIDesglosesBO)
                                    {
                                        if (facturaSIIDesglose.Entrega.HasValue && facturaSIIDesglose.Entrega.Value && !entrega)
                                            entrega = true;
                                        if (facturaSIIDesglose.Entrega.HasValue && !facturaSIIDesglose.Entrega.Value && !prestacionServicios)
                                            prestacionServicios = true;
                                    }

                                    factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                    desgloseTipoOperacion = new BO.SII.v1.v1.TipoConDesgloseType();

                                    if (entrega)
                                    {
                                        desgloseTipoOperacion.Entrega = new BO.SII.v1.v1.TipoSinDesgloseType();

                                        #region SII_Exentas
                                        objDesglose_v1v1 objDesglose = desglose_v1v1.Where(x => x.TipoDesglose == TipoDesglose.OperacionEntrega).FirstOrDefault();
                                       
                                        desgloseTipoOperacion.Entrega.Sujeta = objDesglose.SujetasType;
                                        desgloseTipoOperacion.Entrega.NoSujeta = objDesglose.NoSujetasType;
                                        /*
                                        desgloseTipoOperacion.Entrega.Sujeta = new BO.SII.v1.v1.SujetaType();
                                        desgloseTipoOperacion.Entrega.Sujeta.NoExenta = new BO.SII.v1.v1.SujetaTypeNoExenta();
                                        desgloseTipoOperacion.Entrega.Sujeta.NoExenta.TipoNoExenta = TipoOperacionSujetaNoExenta(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta);
                                        // String.IsNullOrEmpty(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta) || facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta == "S1" ? TipoOperacionSujetaNoExentaType.S1 : TipoOperacionSujetaNoExentaType.S2;

                                        if (facturaSII.FacturaSIIDesglosesBO.Count() > 0)
                                        {
                                            var agrupadoPorImpuesto = facturaSII.FacturaSIIDesglosesBO.GroupBy(a => new { a.TipoImpositivo, a.Entrega }).ToList();

                                            desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA = new BO.SII.v1.v1.DetalleIVAEmitidaType[facturaSII.FacturaSIIDesglosesBO.Count()];
                                            contadorIVA = 0;
                                            for (int a = 0; a < agrupadoPorImpuesto.Count; a++)
                                            {
                                                decimal? baseImponible = 0;
                                                decimal? cuotaRepercutida = 0;

                                                for (int j = 0; j < agrupadoPorImpuesto[a].ToList().Count; j++)
                                                {
                                                    baseImponible += agrupadoPorImpuesto[a].ToList()[j].BaseImponible.HasValue ? agrupadoPorImpuesto[a].ToList()[j].BaseImponible.Value : 0;
                                                    cuotaRepercutida += agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.HasValue ? agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.Value : 0;
                                                }

                                                if (agrupadoPorImpuesto[a].Key.Entrega.HasValue && agrupadoPorImpuesto[a].Key.Entrega.Value)
                                                {
                                                    desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA] = new BO.SII.v1.v1.DetalleIVAEmitidaType();
                                                    desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].BaseImponible = baseImponible.HasValue ? baseImponible.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                    desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRepercutida = cuotaRepercutida.HasValue ? cuotaRepercutida.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                    desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoImpositivo = agrupadoPorImpuesto[a].Key.TipoImpositivo.HasValue ? agrupadoPorImpuesto[a].Key.TipoImpositivo.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                    //desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRecargoEquivalencia = String.Empty;
                                                    //desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoRecargoEquivalencia = String.Empty;

                                                    contadorIVA++;
                                                }
                                            }
                                        }
                                        */
                                        #endregion SII_Exentas
                                    }

                                    if (prestacionServicios)
                                    {
                                        if (factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01 && // Desglose: No sujeta
                                            // Exceptuamos las del 16-Primer semestre, que siempre son sujetas y no exentas
                                            factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item16 &&
                                    factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item15)  
                                        {
                                            desgloseTipoOperacion.PrestacionServicios = new BO.SII.v1.v1.TipoSinDesglosePrestacionType();
                                            desgloseTipoOperacion.PrestacionServicios.NoSujeta = new BO.SII.v1.v1.NoSujetaType();
                                            desgloseTipoOperacion.PrestacionServicios.NoSujeta.ImportePorArticulos7_14_Otros = facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                            desgloseTipoOperacion.PrestacionServicios.NoSujeta.ImporteTAIReglasLocalizacion = facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                        }
                                        else
                                        {
                                            desgloseTipoOperacion.PrestacionServicios = new BO.SII.v1.v1.TipoSinDesglosePrestacionType();

                                            #region SII_Exentas
                                            objDesglose_v1v1 objDesglose = desglose_v1v1.Where(x => x.TipoDesglose == TipoDesglose.OperacionPrestacionServicios).FirstOrDefault();

                                            desgloseTipoOperacion.PrestacionServicios.Sujeta = objDesglose.SujetaPrestacionType;
                                            desgloseTipoOperacion.PrestacionServicios.NoSujeta = objDesglose.NoSujetasType;
                                            /*
                                            desgloseTipoOperacion.PrestacionServicios.Sujeta = new BO.SII.v1.v1.SujetaPrestacionType();
                                            desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta = new BO.SII.v1.v1.SujetaPrestacionTypeNoExenta();
                                            desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.TipoNoExenta = TipoOperacionSujetaNoExenta(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta);
                                            // String.IsNullOrEmpty(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta) || facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta == "S1" ? TipoOperacionSujetaNoExentaType.S1 : TipoOperacionSujetaNoExentaType.S2;

                                            if (facturaSII.FacturaSIIDesglosesBO.Count() > 0)
                                            {
                                                var agrupadoPorImpuesto = facturaSII.FacturaSIIDesglosesBO.GroupBy(a => new { a.TipoImpositivo, a.Entrega }).ToList();

                                                desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA = new BO.SII.v1.v1.DetalleIVAEmitidaPrestacionType[facturaSII.FacturaSIIDesglosesBO.Count()];
                                                contadorIVA = 0;

                                                for (int a = 0; a < agrupadoPorImpuesto.Count; a++)
                                                {
                                                    decimal? baseImponible = 0;
                                                    decimal? cuotaRepercutida = 0;

                                                    for (int j = 0; j < agrupadoPorImpuesto[a].ToList().Count; j++)
                                                    {
                                                        baseImponible += agrupadoPorImpuesto[a].ToList()[j].BaseImponible.HasValue ? agrupadoPorImpuesto[a].ToList()[j].BaseImponible.Value : 0;
                                                        cuotaRepercutida += agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.HasValue ? agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.Value : 0;
                                                    }

                                                    if (agrupadoPorImpuesto[a].Key.Entrega.HasValue && !agrupadoPorImpuesto[a].Key.Entrega.Value)
                                                    {
                                                        desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA] = new BO.SII.v1.v1.DetalleIVAEmitidaPrestacionType();
                                                        desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].BaseImponible = baseImponible.HasValue ? baseImponible.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                        desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRepercutida = cuotaRepercutida.HasValue ? cuotaRepercutida.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                        desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoImpositivo = agrupadoPorImpuesto[a].Key.TipoImpositivo.HasValue ? agrupadoPorImpuesto[a].Key.TipoImpositivo.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";

                                                        contadorIVA++;
                                                    }
                                                }
                                            }
                                            */
                                            #endregion SII_Exentas

                                        }
                                    }
                                        
                                    factura.FacturaExpedida.TipoDesglose.Item = desgloseTipoOperacion;
                                }
                            }

                            facturasEmitida.RegistroLRFacturasEmitidas[numeroFacturas] = factura;
                            numeroFacturas++;
                            }
                        }

                        lote.Id = null;
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            respuesta = Insertar(lote);

                        // loteDTO loteDTO = new loteDTO();
                        // Actualizar las facturasSII rellenando el lote
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            XmlDocument facturasEmitidaXML = Serializar(facturasEmitida);
                            byte[] codificar = null;
                            if (lote.Origen != "012")
                            {
                                codificar = System.Text.ASCIIEncoding.ASCII.GetBytes(facturasEmitidaXML.InnerXml);
                            }
                            else
                            {
                                codificar = System.Text.ASCIIEncoding.ASCII.GetBytes(facturasEmitidaXML.InnerXml.Replace("es/aeat/ssii/fact/ws/", "es/aeat/ssii/igic/ws/").Replace("eIVA", "eIGIC").Replace("<IDVersionSii>1.1", "<IDVersionSii>1.0"));
                                loteDTO.agenciaTributaria = "CA";
                            }
                            lote.DocLoteB64 = System.Convert.ToBase64String(codificar);

                            loteDTO.docLoteB64 = lote.DocLoteB64;
                            loteDTO.guid = lote.Id;
                            loteDTO.etiqueta_externa = lote.Id;
                            loteDTO.id_agrupacion = lote.IdAgrupacion;
                            loteDTO.id_sociedad = lote.Sociedad;
                            loteDTO.id_tenant = lote.IdTenant;
                            loteDTO.importeTotal = (float)importeTotal;
                            loteDTO.numRegistros = lote.FacturasSII.Count();
                            loteDTO.origen = lote.Origen;
                            loteDTO.tipoComunicacion = lote.FacturasSII[0].CabeceraTipoComunic;
                            loteDTO.tipoOperacion = "SuministroLRFacturasEmitidas";
                            loteDTO.titularNIF = lote.TitularNIF;
                            loteDTO.titularNombreRazon = lote.TitularNombreRazon;
                            loteDTO.versionSII = lote.VersionSII;

                            foreach (cFacturaSIIBO facturaSII in lote.FacturasSII)
                            {
                                if (respuesta.Resultado != ResultadoProceso.OK)
                                    break;

                                facturaSII.LoteId = lote.Id;
                                respuesta = cFacturasSIIBL.Actualizar(facturaSII);
                            }
                        }

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            loteXML = Serializar(loteDTO);
                            loteXML.InnerXml = loteXML.InnerXml.Replace("loteDTO", "Lote");
                        }


                        if (respuesta.Resultado != ResultadoProceso.OK)
                            log = respuesta.Ex.Message + Environment.NewLine;
                        else
                            log = Resource.lote + " " + lote.Id + ": " + (String.IsNullOrEmpty(lote.EnvIdError) ? (String.IsNullOrEmpty(lote.EnvIdErrorMiddleware) ? "Procesado" : lote.EnvIdErrorMiddleware) : lote.EnvIdError) + Environment.NewLine;

                        if (respuesta.Resultado == ResultadoProceso.OK)
                            scope.Complete();
                    }
                }


                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    ProcesarLoteResponseReturn respuestaLote = new ProcesarLoteResponseReturn();

                    try
                    {
                        ProcesarLoteWSImplService procesar = new ProcesarLoteWSImplService();

                        string url = cConfiguration.GetWebConfigConfigurationValue("webserviceURL");
                        string userName = cConfiguration.GetWebConfigConfigurationValue("username");
                        string password = cConfiguration.GetWebConfigConfigurationValue("password");

                        if (!string.IsNullOrEmpty(url))
                            procesar.Url = url;
                        // Set the client-side credentials using the Credentials property.
                        if (!string.IsNullOrEmpty(userName) && !string.IsNullOrEmpty(password))
                        {
                            ICredentials credentials = new NetworkCredential(userName, password);
                            procesar.Credentials = credentials;
                        }
                        respuestaLote = procesar.ProcesarLote(loteDTO);

                    }
                    catch (Exception ex)
                    {
                        lote.Estado = "T";
                        lote.ErrorDescripcion = "Error Técnico";
                        lote.InfoLIne1 = ex.Message;
                        respuesta = Actualizar(lote);
                        //scope.Complete();
                        respuesta.Resultado = ResultadoProceso.Error;
                        throw ex;

                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        // Actualizar respuesta del lote
                        lote.Estado = respuestaLote.estado;
                        lote.IdError = respuestaLote.idError;
                        lote.ErrorDescripcion = respuestaLote.descripcion;
                        lote.IdIntercambioRet = respuestaLote.idIntercambioRet;
                        lote.InfoLIne1 = respuestaLote.infoLIne1;
                        lote.InfoLIne2 = respuestaLote.infoLIne2;
                        lote.InfoLIne3 = respuestaLote.infoLIne3;
                        lote.FechaUpdate = String.IsNullOrEmpty(respuestaLote.timeStamp) ? null : (DateTime?)Convert.ToDateTime(respuestaLote.timeStamp);
                        respuesta = Actualizar(lote);
                    }
                }

                return respuesta;
            }

        public static cRespuesta ProcesarLotesEmisionFacturasModificadas(cFacturasSIILoteBO lote, out XmlDocument loteXML, out string log)
        {
            cRespuesta respuesta = new cRespuesta();
            cSociedadBO sociedadBO = new cSociedadBO();
            loteXML = null;
            log = null;
            //IdOperacionesTrascendenciaTributariaType? claveRegimen = null;
            string claveRegimen = null;
            //int contadorIVA;
            loteDTO loteDTO = new loteDTO();
            System.Net.ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

            using (TransactionScope scope = cAplicacion.NewTransactionScope())
            {
                string strSociedadRemesa = cParametroBL.ObtenerValor("SOCIEDAD_REMESA", out respuesta);
                string strSociedadPorDefecto = cParametroBL.ObtenerValor("SOCIEDAD_POR_DEFECTO", out respuesta);
                string strSociedadSII = String.IsNullOrEmpty(strSociedadRemesa) ? strSociedadPorDefecto : strSociedadRemesa;
                if (respuesta.Resultado != ResultadoProceso.OK)
                    cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Error, out respuesta);
                else
                {
                    sociedadBO.Codigo = String.IsNullOrEmpty(strSociedadSII) ? (short)0 : Convert.ToInt16(strSociedadSII);

                    cSociedadBL.Obtener(ref sociedadBO, out respuesta);
                    if (respuesta.Resultado != ResultadoProceso.OK)
                        cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Error, out respuesta);
                }

                if (respuesta.Resultado == ResultadoProceso.OK)
                    claveRegimen = ObtenerClaveRegimenEspecial(out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK && lote != null && lote.FacturasSII != null && lote.FacturasSII.Count > 0)
                {
                    SuministroLRFacturasEmitidas facturasEmitida = new SuministroLRFacturasEmitidas();

                    facturasEmitida.Cabecera = new BO.SII.v1.v1.CabeceraSii();
                    facturasEmitida.Cabecera.IDVersionSii = VersionSII(lote.VersionSII);
                    facturasEmitida.Cabecera.Titular = new BO.SII.v1.v1.PersonaFisicaJuridicaESType();
                    facturasEmitida.Cabecera.Titular.NIF = sociedadBO.Nif;
                    facturasEmitida.Cabecera.Titular.NombreRazon = sociedadBO.Nombre;
                    //facturasEmitida.Cabecera.Titular.NIFRepresentante = String.Empty;
                    facturasEmitida.Cabecera.TipoComunicacion = lote.FacturasSII[0].CabeceraTipoComunic == "A0" ? BO.SII.v1.v1.ClaveTipoComunicacionType.A0 : BO.SII.v1.v1.ClaveTipoComunicacionType.A1; // Modificadas

                    facturasEmitida.RegistroLRFacturasEmitidas = new BO.SII.v1.v1.LRfacturasEmitidasType[lote.FacturasSII.Count];

                    decimal importeTotal = 0;
                    int numeroFacturas = 0;
                    foreach (cFacturaSIIBO facturaSII in lote.FacturasSII)
                    {
                        if (facturaSII.FacturaSIIDesglosesBO.Count == 0)
                            cExcepciones.ControlarER(new Exception("La factura @item no tiene desglose SII".Replace("@item", facturaSII.NumSerieFacturaEmisor)), TipoExcepcion.Error, out respuesta);

                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            BO.SII.v1.v1.LRfacturasEmitidasType factura = new BO.SII.v1.v1.LRfacturasEmitidasType();
                            importeTotal += facturaSII.ImporteTotal.HasValue ? facturaSII.ImporteTotal.Value : 0;
                            // Periodo impositivo
                            factura.PeriodoLiquidacion = new BO.SII.v1.v1.RegistroSiiPeriodoLiquidacion();
                            factura.PeriodoLiquidacion.Ejercicio = facturaSII.PeriodoImpositivoEjercicio;
                            switch (facturaSII.PeriodoImpositivoPeriodo)
                            {
                                case "01": case "1": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item01; break;
                                case "02": case "2": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item02; break;
                                case "03": case "3": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item03; break;
                                case "04": case "4": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item04; break;
                                case "05": case "5": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item05; break;
                                case "06": case "6": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item06; break;
                                case "07": case "7": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item07; break;
                                case "08": case "8": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item08; break;
                                case "09": case "9": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item09; break;
                                case "10": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item10; break;
                                case "11": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item11; break;
                                case "12": factura.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item12; break;
                            }

                            // ID de factura
                            factura.IDFactura = new BO.SII.v1.v1.IDFacturaExpedidaType();
                            factura.IDFactura.IDEmisorFactura = new BO.SII.v1.v1.IDFacturaExpedidaTypeIDEmisorFactura();
                            factura.IDFactura.IDEmisorFactura.NIF = facturaSII.IdEmisorFacturaNif;
                            factura.IDFactura.NumSerieFacturaEmisor = facturaSII.NumSerieFacturaEmisor;
                            factura.IDFactura.FechaExpedicionFacturaEmisor = facturaSII.FechaExpFacturaEmisor.HasValue ? facturaSII.FechaExpFacturaEmisor.Value.ToString("dd-MM-yyyy") : String.Empty;
                            //factura.IDFactura.NumSerieFacturaEmisorResumenFin = String.Empty;

                            BO.SII.v1.v1.ClaveTipoFacturaType? tipoFactura = ClaveTipoFactura(facturaSII.TipoFactura);

                            if (!tipoFactura.HasValue)
                                cExcepciones.ControlarER(new Exception("Tipo de factura incorrecta para la factura @item".Replace("@item", facturaSII.NumSerieFacturaEmisor)), TipoExcepcion.Error, out respuesta);

                            // Factura expedida
                            factura.FacturaExpedida = new BO.SII.v1.v1.FacturaExpedidaType();
                            factura.FacturaExpedida.TipoFactura = tipoFactura.Value;

                            // Valor fijo 01 (parámetro "claveregimen"), salvo para las del primer semestre, que es valor fijo 16 y lo cogemos del registro de facSII
                            //factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia = claveRegimen.HasValue ? claveRegimen.Value : IdOperacionesTrascendenciaTributariaType.Item01;
                            factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia = ClaveRegimenEspecial(!string.IsNullOrEmpty(facturaSII.ClaveRegimenEspecialOTrasc) ? facturaSII.ClaveRegimenEspecialOTrasc : claveRegimen);

                            factura.FacturaExpedida.ImporteTotal = facturaSII.ImporteTotal.HasValue ? facturaSII.ImporteTotal.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                            if (facturaSII.ImporteTotal > 100000)
                            {
                                factura.FacturaExpedida.Macrodato = new MacrodatoType();
                                factura.FacturaExpedida.Macrodato = MacrodatoType.S;
                            }
                            else
                            {
                                factura.FacturaExpedida.Macrodato = new MacrodatoType();
                                factura.FacturaExpedida.Macrodato = MacrodatoType.N;
                            }

                            factura.FacturaExpedida.DescripcionOperacion = facturaSII.DesOperacion;
                            //factura.FacturaExpedida.ImporteTransmisionSujetoAIVA = String.Empty;
                            //factura.FacturaExpedida.BaseImponibleACoste = String.Empty;
                            factura.FacturaExpedida.FechaOperacion = facturaSII.FechaOperacion.HasValue ? facturaSII.FechaOperacion.Value.ToString("dd-MM-yyyy") : String.Empty;

                            //# Revisar
                            factura.FacturaExpedida.EmitidaPorTercerosODestinatarioSpecified = false;
                            factura.FacturaExpedida.EmitidaPorTercerosODestinatario = String.IsNullOrEmpty(facturaSII.EmitidaPorTerceros) || facturaSII.EmitidaPorTerceros == "N" ? BO.SII.v1.v1.EmitidaPorTercerosType.N : BO.SII.v1.v1.EmitidaPorTercerosType.S;

                            factura.FacturaExpedida.TipoRectificativaSpecified = true;
                            factura.FacturaExpedida.TipoRectificativa = BO.SII.v1.v1.ClaveTipoRectificativaType.S;

                            factura.FacturaExpedida.VariosDestinatariosSpecified = false;
                            //factura.FacturaExpedida.VariosDestinatarios = VariosDestinatariosType.N;

                            factura.FacturaExpedida.CuponSpecified = false;
                            //factura.FacturaExpedida.Cupon = CuponType.N;

                            // Datos del inmueble
                            /*
                            factura.FacturaExpedida.DatosInmueble = new DatosInmuebleType[1];
                            factura.FacturaExpedida.DatosInmueble[0] = new DatosInmuebleType();
                            factura.FacturaExpedida.DatosInmueble[0].ReferenciaCatastral = facturaSII.InmuebleRefCat;
                            //factura.FacturaExpedida.DatosInmueble[0].SituacionInmueble = SituacionInmuebleType.Item1;
                            */

                                        // Facturas agrupadas
                                        /*
                                        factura.FacturaExpedida.FacturasAgrupadas = new IDFacturaARType[1];
                                        factura.FacturaExpedida.FacturasAgrupadas[0] = new IDFacturaARType();
                                        factura.FacturaExpedida.FacturasAgrupadas[0].FechaExpedicionFacturaEmisor = facturaSII.RectificadaFechaExpFacturaEmisor.HasValue ? facturaSII.RectificadaFechaExpFacturaEmisor.Value.ToString("dd-MM-yyyy") : String.Empty;
                                        factura.FacturaExpedida.FacturasAgrupadas[0].NumSerieFacturaEmisor = facturaSII.RectificadaNumSereFacturaEmisor;
                                        */

                                        // Importe rectificacion
                                        factura.FacturaExpedida.ImporteRectificacion = new BO.SII.v1.v1.DesgloseRectificacionType();
                        factura.FacturaExpedida.ImporteRectificacion.BaseRectificada = facturaSII.RectificadaBase.HasValue ? facturaSII.RectificadaBase.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                        //factura.FacturaExpedida.ImporteRectificacion.CuotaRecargoRectificado = String.Empty;
                        factura.FacturaExpedida.ImporteRectificacion.CuotaRectificada = facturaSII.RectificadaCuota.HasValue ? facturaSII.RectificadaCuota.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";

                        // Facturas rectificadas
                        factura.FacturaExpedida.FacturasRectificadas = new BO.SII.v1.v1.IDFacturaARType[1];
                        factura.FacturaExpedida.FacturasRectificadas[0] = new BO.SII.v1.v1.IDFacturaARType();
                        factura.FacturaExpedida.FacturasRectificadas[0].FechaExpedicionFacturaEmisor = facturaSII.RectificadaFechaExpFacturaEmisor.HasValue ? facturaSII.RectificadaFechaExpFacturaEmisor.Value.ToString("dd-MM-yyyy") : String.Empty;
                        factura.FacturaExpedida.FacturasRectificadas[0].NumSerieFacturaEmisor = facturaSII.RectificadaNumSereFacturaEmisor;

                        if (facturaSII.TipoFactura != "F2" && facturaSII.TipoFactura != "R5") //No es simplificada
                        {
                            factura.FacturaExpedida.Contraparte = new BO.SII.v1.v1.PersonaFisicaJuridicaType();
                        factura.FacturaExpedida.Contraparte.NIFRepresentante = facturaSII.ContraparteNifRepres;
                        factura.FacturaExpedida.Contraparte.NombreRazon = facturaSII.ContraparteNombreRazon;
                        factura.FacturaExpedida.Contraparte.Item = facturaSII.ContraparteNif;
                        if (!String.IsNullOrEmpty(facturaSII.ContraparteIdOtro))
                        {
                            if (String.IsNullOrEmpty(facturaSII.ContraparteIdTipo))
                                cExcepciones.ControlarER(new Exception("Tipo de persona jurídica es incorrecta para la factura @item".Replace("@item", facturaSII.NumSerieFacturaEmisor)), TipoExcepcion.Error, out respuesta);

                            if (respuesta.Resultado == ResultadoProceso.OK)
                            {
                                BO.SII.v1.v1.IDOtroType otro = new BO.SII.v1.v1.IDOtroType();
                                otro.ID = facturaSII.ContraparteId;
                                otro.IDType = TipoPersonaJuridica(facturaSII.ContraparteIdTipo).Value;
                                otro.CodigoPaisSpecified = !String.IsNullOrEmpty(facturaSII.ContraparteIdOtro);
                                if (!String.IsNullOrEmpty(facturaSII.ContraparteIdOtro))
                                {
                                    CountryType2 pais;
                                    Enum.TryParse(facturaSII.ContraparteIdOtro, out pais);
                                    otro.CodigoPais = pais;
                                }
                                factura.FacturaExpedida.Contraparte.Item = otro;
                            }
                        }
                        }
                        // Tipo de desglose
                        factura.FacturaExpedida.TipoDesglose = null;

                            #region SII_Exentas
                            List<objDesglose_v1v1> desglose_v1v1 = obtenerDesglosexTipo_v1v1(facturaSII);
                            #endregion

                            if (String.IsNullOrEmpty(facturaSII.ContraparteIdOtro) && !(String.IsNullOrEmpty(facturaSII.ContraparteNif)) && facturaSII.ContraparteNif.Substring(0, 1) != "N")
                        {
                            // Desglose: Factura
                            BO.SII.v1.v1.TipoSinDesgloseType desgloseFactura = null;

                            if (factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01 && // Desglose: No sujeta
                                // Exceptuamos las del 16-Primer semestre, que siempre son sujetas y no exentas
                                factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item16 &&
                                factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item15)
                            {
                                factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                desgloseFactura = new BO.SII.v1.v1.TipoSinDesgloseType();
                                desgloseFactura.NoSujeta = new BO.SII.v1.v1.NoSujetaType();
                                desgloseFactura.NoSujeta.ImportePorArticulos7_14_Otros = facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                desgloseFactura.NoSujeta.ImporteTAIReglasLocalizacion = facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                factura.FacturaExpedida.TipoDesglose.Item = desgloseFactura;
                            }
                            else // Desglose: Sujeta
                            {
                                factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                desgloseFactura = new BO.SII.v1.v1.TipoSinDesgloseType();

                                #region SII_Exentas
                                objDesglose_v1v1 objDesglose = desglose_v1v1.Where(x => x.TipoDesglose == TipoDesglose.DesgloseFactura).FirstOrDefault();
                                desgloseFactura.Sujeta = objDesglose.SujetasType;
                                desgloseFactura.NoSujeta = objDesglose.NoSujetasType;

                                /*
                                desgloseFactura.Sujeta = new BO.SII.v1.v1.SujetaType();
                                desgloseFactura.Sujeta.NoExenta = new BO.SII.v1.v1.SujetaTypeNoExenta();
                                desgloseFactura.Sujeta.NoExenta.TipoNoExenta = TipoOperacionSujetaNoExenta(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta);
                                // String.IsNullOrEmpty(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta) || facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta == "S1" ? TipoOperacionSujetaNoExentaType.S1 : TipoOperacionSujetaNoExentaType.S2;

                                if (facturaSII.FacturaSIIDesglosesBO.Count() > 0)
                                {
                                    var agrupadoPorImpuesto = facturaSII.FacturaSIIDesglosesBO.GroupBy(a => a.TipoImpositivo).ToList();

                                    desgloseFactura.Sujeta.NoExenta.DesgloseIVA = new BO.SII.v1.v1.DetalleIVAEmitidaType[facturaSII.FacturaSIIDesglosesBO.Count()];

                                    contadorIVA = 0;
                                    for (int a = 0; a < agrupadoPorImpuesto.Count; a++)
                                    {
                                        decimal? baseImponible = 0;
                                        decimal? cuotaRepercutida = 0;
                                        for (int j = 0; j < agrupadoPorImpuesto[a].ToList().Count; j++)
                                        {
                                            baseImponible += agrupadoPorImpuesto[a].ToList()[j].BaseImponible.HasValue ? agrupadoPorImpuesto[a].ToList()[j].BaseImponible.Value : 0;
                                            cuotaRepercutida += agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.HasValue ? agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.Value : 0;
                                        }

                                        desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA] = new BO.SII.v1.v1.DetalleIVAEmitidaType();
                                        desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].BaseImponible = baseImponible.HasValue ? baseImponible.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                        desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRepercutida = cuotaRepercutida.HasValue ? cuotaRepercutida.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                        desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoImpositivo = agrupadoPorImpuesto[a].Key.HasValue ? agrupadoPorImpuesto[a].Key.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                        //desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoRecargoEquivalencia = String.Empty;
                                        //desgloseFactura.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRecargoEquivalencia = String.Empty;

                                        contadorIVA++;
                                    }
                                }
                                */
                                #endregion
                                factura.FacturaExpedida.TipoDesglose.Item = desgloseFactura;
                            }
                        }
                        else
                        {
                            // Desglose: Tipo de la operacion
                            BO.SII.v1.v1.TipoConDesgloseType desgloseTipoOperacion = null;

                            if (factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01 && // Desglose: No sujeta
                                // Exceptuamos las del 16-Primer semestre, que siempre son sujetas y no exentas
                                factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item16 &&
                                factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item15)
                            {
                                factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                desgloseTipoOperacion = new BO.SII.v1.v1.TipoConDesgloseType();
                                desgloseTipoOperacion.Entrega = new BO.SII.v1.v1.TipoSinDesgloseType();
                                desgloseTipoOperacion.Entrega.NoSujeta = new BO.SII.v1.v1.NoSujetaType();
                                desgloseTipoOperacion.Entrega.NoSujeta.ImportePorArticulos7_14_Otros = facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                desgloseTipoOperacion.Entrega.NoSujeta.ImporteTAIReglasLocalizacion = facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                factura.FacturaExpedida.TipoDesglose.Item = desgloseTipoOperacion;
                            }
                            else // Desglose: Sujeta
                            {
                                // Comprobar si existe entrega y/o prestación de servicios
                                bool entrega = false;
                                bool prestacionServicios = false;

                                factura.FacturaExpedida.TipoDesglose = new BO.SII.v1.v1.FacturaExpedidaTypeTipoDesglose();
                                desgloseTipoOperacion = new BO.SII.v1.v1.TipoConDesgloseType();

                                foreach (cFacturaSIIDesgloseBO facturaSIIDesglose in facturaSII.FacturaSIIDesglosesBO)
                                {
                                    if (facturaSIIDesglose.Entrega.HasValue && facturaSIIDesglose.Entrega.Value && !entrega)
                                        entrega = true;
                                    if (facturaSIIDesglose.Entrega.HasValue && !facturaSIIDesglose.Entrega.Value && !prestacionServicios)
                                        prestacionServicios = true;
                                }

                                if (entrega)
                                {
                                    desgloseTipoOperacion.Entrega = new BO.SII.v1.v1.TipoSinDesgloseType();
                                   
                                    #region SII_Exentas
                                    objDesglose_v1v1 objDesglose = desglose_v1v1.Where(x => x.TipoDesglose == TipoDesglose.OperacionEntrega).FirstOrDefault();

                                    desgloseTipoOperacion.Entrega.Sujeta = objDesglose.SujetasType;
                                    desgloseTipoOperacion.Entrega.NoSujeta = objDesglose.NoSujetasType;
                                    /*
                                    desgloseTipoOperacion.Entrega.Sujeta = new BO.SII.v1.v1.SujetaType();
                                    desgloseTipoOperacion.Entrega.Sujeta.NoExenta = new BO.SII.v1.v1.SujetaTypeNoExenta();
                                    desgloseTipoOperacion.Entrega.Sujeta.NoExenta.TipoNoExenta = TipoOperacionSujetaNoExenta(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta);
                                    // String.IsNullOrEmpty(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta) || facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta == "S1" ? TipoOperacionSujetaNoExentaType.S1 : TipoOperacionSujetaNoExentaType.S2;

                                    if (facturaSII.FacturaSIIDesglosesBO.Count() > 0)
                                    {
                                        var agrupadoPorImpuesto = facturaSII.FacturaSIIDesglosesBO.GroupBy(a => new { a.TipoImpositivo, a.Entrega }).ToList();
                                        desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA = new BO.SII.v1.v1.DetalleIVAEmitidaType[facturaSII.FacturaSIIDesglosesBO.Count()];
                                        contadorIVA = 0;

                                        for (int a = 0; a < agrupadoPorImpuesto.Count; a++)
                                        {
                                            decimal? baseImponible = 0;
                                            decimal? cuotaRepercutida = 0;

                                            for (int j = 0; j < agrupadoPorImpuesto[a].ToList().Count; j++)
                                            {
                                                baseImponible += agrupadoPorImpuesto[a].ToList()[j].BaseImponible.HasValue ? agrupadoPorImpuesto[a].ToList()[j].BaseImponible.Value : 0;
                                                cuotaRepercutida += agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.HasValue ? agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.Value : 0;
                                            }

                                            if (agrupadoPorImpuesto[a].Key.Entrega.HasValue && !agrupadoPorImpuesto[a].Key.Entrega.Value)
                                            {
                                                desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA] = new BO.SII.v1.v1.DetalleIVAEmitidaType();
                                                desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].BaseImponible = baseImponible.HasValue ? baseImponible.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRepercutida = cuotaRepercutida.HasValue ? cuotaRepercutida.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                desgloseTipoOperacion.Entrega.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoImpositivo = agrupadoPorImpuesto[a].Key.TipoImpositivo.HasValue ? agrupadoPorImpuesto[a].Key.TipoImpositivo.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";

                                                contadorIVA++;
                                            }
                                        }
                                    }
                                    */
                                    #endregion SII_Exentas
                                }

                                if (prestacionServicios)
                                {
                                    if (factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01 && // Desglose: No sujeta
                                        // Exceptuamos las del 16-Primer semestre, que siempre son sujetas y no exentas
                                        factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item16 &&
                                factura.FacturaExpedida.ClaveRegimenEspecialOTrascendencia != BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item15)
                                    {
                                        desgloseTipoOperacion.PrestacionServicios = new BO.SII.v1.v1.TipoSinDesglosePrestacionType();
                                        desgloseTipoOperacion.PrestacionServicios.NoSujeta = new BO.SII.v1.v1.NoSujetaType();
                                        desgloseTipoOperacion.PrestacionServicios.NoSujeta.ImportePorArticulos7_14_Otros = facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpPorArt7_14_Otros.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                        desgloseTipoOperacion.PrestacionServicios.NoSujeta.ImporteTAIReglasLocalizacion = facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.HasValue ? facturaSII.FacturaSIIDesglosesBO[0].ImpTAIReglasLoc.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                    }
                                    else
                                    {
                                        desgloseTipoOperacion.PrestacionServicios = new BO.SII.v1.v1.TipoSinDesglosePrestacionType();

                                        #region SII_Exentas
                                        objDesglose_v1v1 objDesglose = desglose_v1v1.Where(x => x.TipoDesglose == TipoDesglose.OperacionPrestacionServicios).FirstOrDefault();

                                        desgloseTipoOperacion.PrestacionServicios.Sujeta = objDesglose.SujetaPrestacionType;
                                        desgloseTipoOperacion.PrestacionServicios.NoSujeta = objDesglose.NoSujetasType;

                                        /*
                                        desgloseTipoOperacion.PrestacionServicios.Sujeta = new BO.SII.v1.v1.SujetaPrestacionType();
                                        desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta = new BO.SII.v1.v1.SujetaPrestacionTypeNoExenta();
                                        desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.TipoNoExenta = TipoOperacionSujetaNoExenta(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta);
                                        // String.IsNullOrEmpty(facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta) || facturaSII.FacturaSIIDesglosesBO[0].TipoNoExenta == "S1" ? TipoOperacionSujetaNoExentaType.S1 : TipoOperacionSujetaNoExentaType.S2;

                                        if (facturaSII.FacturaSIIDesglosesBO.Count() > 0)
                                        {
                                            var agrupadoPorImpuesto = facturaSII.FacturaSIIDesglosesBO.GroupBy(a => new { a.TipoImpositivo, a.Entrega }).ToList();
                                            desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA = new BO.SII.v1.v1.DetalleIVAEmitidaPrestacionType[facturaSII.FacturaSIIDesglosesBO.Count()];
                                            contadorIVA = 0;

                                            for (int a = 0; a < agrupadoPorImpuesto.Count; a++)
                                            {
                                                decimal? baseImponible = 0;
                                                decimal? cuotaRepercutida = 0;

                                                for (int j = 0; j < agrupadoPorImpuesto[a].ToList().Count; j++)
                                                {
                                                    baseImponible += agrupadoPorImpuesto[a].ToList()[j].BaseImponible.HasValue ? agrupadoPorImpuesto[a].ToList()[j].BaseImponible.Value : 0;
                                                    cuotaRepercutida += agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.HasValue ? agrupadoPorImpuesto[a].ToList()[j].CuotaRepercutida.Value : 0;
                                                }

                                                if (agrupadoPorImpuesto[a].Key.Entrega.HasValue && !agrupadoPorImpuesto[a].Key.Entrega.Value)
                                                {
                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA] = new BO.SII.v1.v1.DetalleIVAEmitidaPrestacionType();
                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].BaseImponible = baseImponible.HasValue ? baseImponible.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRepercutida = cuotaRepercutida.HasValue ? cuotaRepercutida.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoImpositivo = agrupadoPorImpuesto[a].Key.TipoImpositivo.HasValue ? agrupadoPorImpuesto[a].Key.TipoImpositivo.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";

                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA] = new BO.SII.v1.v1.DetalleIVAEmitidaPrestacionType();
                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].BaseImponible = baseImponible.HasValue ? baseImponible.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].CuotaRepercutida = cuotaRepercutida.HasValue ? cuotaRepercutida.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";
                                                    desgloseTipoOperacion.PrestacionServicios.Sujeta.NoExenta.DesgloseIVA[contadorIVA].TipoImpositivo = agrupadoPorImpuesto[a].Key.TipoImpositivo.HasValue ? agrupadoPorImpuesto[a].Key.TipoImpositivo.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";

                                                    contadorIVA++;
                                                }
                                            }
                                        }
                                        */
                                        #endregion SII_Exentas
                                    }
                                }

                                factura.FacturaExpedida.TipoDesglose.Item = desgloseTipoOperacion;
                            }
                        }

                        facturasEmitida.RegistroLRFacturasEmitidas[numeroFacturas] = factura;
                        numeroFacturas++;
                    }
                }

                lote.Id = null;
                if (respuesta.Resultado == ResultadoProceso.OK)
                    respuesta = Insertar(lote);

                // Actualizar las facturasSII rellenando el lote
                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    XmlDocument facturasEmitidaXML = Serializar(facturasEmitida);
                    byte[] codificar = null;
                    if (lote.Origen != "012")
                    {
                        codificar = System.Text.ASCIIEncoding.ASCII.GetBytes(facturasEmitidaXML.InnerXml);
                    }
                    else
                    {
                        codificar = System.Text.ASCIIEncoding.ASCII.GetBytes(facturasEmitidaXML.InnerXml.Replace("es/aeat/ssii/fact/ws/", "es/aeat/ssii/igic/ws/").Replace("eIVA", "eIGIC").Replace("<IDVersionSii>1.1", "<IDVersionSii>1.0"));
                        loteDTO.agenciaTributaria = "CA";
                    }
                    lote.DocLoteB64 = System.Convert.ToBase64String(codificar);

                    loteDTO.docLoteB64 = lote.DocLoteB64;
                    loteDTO.guid = lote.Id;
                    loteDTO.etiqueta_externa = lote.Id;
                    loteDTO.id_agrupacion = lote.IdAgrupacion;
                    loteDTO.id_sociedad = lote.Sociedad;
                    loteDTO.id_tenant = lote.IdTenant;
                    loteDTO.importeTotal = (float)importeTotal;
                    loteDTO.numRegistros = lote.FacturasSII.Count();
                    loteDTO.origen = lote.Origen;
                    loteDTO.tipoComunicacion = lote.FacturasSII[0].CabeceraTipoComunic;
                    loteDTO.tipoOperacion = "SuministroLRFacturasEmitidas";
                    loteDTO.titularNIF = lote.TitularNIF;
                    loteDTO.titularNombreRazon = lote.TitularNombreRazon;
                    loteDTO.versionSII = lote.VersionSII;

                    foreach (cFacturaSIIBO facturaSII in lote.FacturasSII)
                    {
                        if (respuesta.Resultado != ResultadoProceso.OK)
                            break;

                        facturaSII.LoteId = lote.Id;
                        respuesta = cFacturasSIIBL.Actualizar(facturaSII);
                    }
                }

                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    loteXML = Serializar(loteDTO);
                    loteXML.InnerXml = loteXML.InnerXml.Replace("loteDTO", "Lote");
                }

                if (respuesta.Resultado != ResultadoProceso.OK)
                    log = respuesta.Ex.Message + Environment.NewLine;
                else
                    log = Resource.lote + " " + lote.Id + ": " + (String.IsNullOrEmpty(lote.EnvIdError) ? (String.IsNullOrEmpty(lote.EnvIdErrorMiddleware) ? "Procesado" : lote.EnvIdErrorMiddleware) : lote.EnvIdError) + Environment.NewLine;

                if (respuesta.Resultado == ResultadoProceso.OK)
                    scope.Complete();
            }

        }

        if (respuesta.Resultado == ResultadoProceso.OK)
        {
            ProcesarLoteResponseReturn respuestaLote = new ProcesarLoteResponseReturn();

            try
            {
                ProcesarLoteWSImplService procesar = new ProcesarLoteWSImplService();

                string url = cConfiguration.GetWebConfigConfigurationValue("webserviceURL");
                string userName = cConfiguration.GetWebConfigConfigurationValue("username");
                string password = cConfiguration.GetWebConfigConfigurationValue("password");

                if (!string.IsNullOrEmpty(url))
                    procesar.Url = url;
                // Set the client-side credentials using the Credentials property.
                if (!string.IsNullOrEmpty(userName) && !string.IsNullOrEmpty(password))
                {
                    ICredentials credentials = new NetworkCredential(userName, password);
                    procesar.Credentials = credentials;
                }
                respuestaLote = procesar.ProcesarLote(loteDTO);

            }
            catch (Exception ex)
            {
                lote.Estado = "T";
                lote.ErrorDescripcion = "Error Técnico";
                lote.InfoLIne1 = ex.Message;
                respuesta = Actualizar(lote);
                //scope.Complete();
                respuesta.Resultado = ResultadoProceso.Error;
                throw ex;

            }

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                // Actualizar respuesta del lote
                lote.Estado = respuestaLote.estado;
                lote.IdError = respuestaLote.idError;
                lote.ErrorDescripcion = respuestaLote.descripcion;
                lote.IdIntercambioRet = respuestaLote.idIntercambioRet;
                lote.InfoLIne1 = respuestaLote.infoLIne1;
                lote.InfoLIne2 = respuestaLote.infoLIne2;
                lote.InfoLIne3 = respuestaLote.infoLIne3;
                lote.FechaUpdate = String.IsNullOrEmpty(respuestaLote.timeStamp) ? null : (DateTime?)Convert.ToDateTime(respuestaLote.timeStamp);
                respuesta = Actualizar(lote);
            }
        }

        return respuesta;
    }

        public static cRespuesta ProcesarLotesAnulacionFacturas(cFacturasSIILoteBO lote, out XmlDocument loteXML, out string log)
        {
            cRespuesta respuesta = new cRespuesta();
            cSociedadBO sociedadBO = new cSociedadBO();
            log = null;
            loteXML = null;
            loteDTO loteDTO = new loteDTO();
            System.Net.ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };

            using (TransactionScope scope = cAplicacion.NewTransactionScope())
            {
                string strSociedadRemesa = cParametroBL.ObtenerValor("SOCIEDAD_REMESA", out respuesta);
                string strSociedadPorDefecto = cParametroBL.ObtenerValor("SOCIEDAD_POR_DEFECTO", out respuesta);
                string strSociedadSII = String.IsNullOrEmpty(strSociedadRemesa) ? strSociedadPorDefecto : strSociedadRemesa;
                if (respuesta.Resultado != ResultadoProceso.OK)
                    cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Error);
                else
                {
                    sociedadBO.Codigo = String.IsNullOrEmpty(strSociedadSII) ? (short)0 : Convert.ToInt16(strSociedadSII);

                    cSociedadBL.Obtener(ref sociedadBO, out respuesta);
                    if (respuesta.Resultado != ResultadoProceso.OK)
                        cExcepciones.ControlarER(respuesta.Ex, TipoExcepcion.Error);
                }

                if (respuesta.Resultado == ResultadoProceso.OK && lote != null && lote.FacturasSII != null && lote.FacturasSII.Count > 0)
                {
                    BO.SII.v1.v1.BajaLRFacturasEmitidas bajas = new BO.SII.v1.v1.BajaLRFacturasEmitidas();

                    bajas.Cabecera = new BO.SII.v1.v1.CabeceraSiiBaja();
                    bajas.Cabecera.IDVersionSii = VersionSII(lote.VersionSII);
                    bajas.Cabecera.Titular = new BO.SII.v1.v1.PersonaFisicaJuridicaESType();
                    bajas.Cabecera.Titular.NIF = sociedadBO.Nif;
                    bajas.Cabecera.Titular.NombreRazon = sociedadBO.Nombre;
                    //bajas.Cabecera.Titular.NIFRepresentante = String.Empty;

                    bajas.RegistroLRBajaExpedidas = new BO.SII.v1.v1.LRBajaExpedidasType[lote.FacturasSII.Count];

                    decimal importeTotal = 0;
                    int numeroFacturas = 0;
                    foreach (cFacturaSIIBO facturaSII in lote.FacturasSII)
                    {
                        BO.SII.v1.v1.LRBajaExpedidasType anulacion = new BO.SII.v1.v1.LRBajaExpedidasType();
                        importeTotal += facturaSII.ImporteTotal.HasValue ? facturaSII.ImporteTotal.Value : 0;

                        // Periodo impositivo
                        anulacion.PeriodoLiquidacion = new BO.SII.v1.v1.RegistroSiiPeriodoLiquidacion();
                        anulacion.PeriodoLiquidacion.Ejercicio = facturaSII.PeriodoImpositivoEjercicio;
                        switch (facturaSII.PeriodoImpositivoPeriodo)
                        {
                            case "01": case "1": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item01; break;
                            case "02": case "2": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item02; break;
                            case "03": case "3": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item03; break;
                            case "04": case "4": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item04; break;
                            case "05": case "5": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item05; break;
                            case "06": case "6": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item06; break;
                            case "07": case "7": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item07; break;
                            case "08": case "8": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item08; break;
                            case "09": case "9": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item09; break;
                            case "10": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item10; break;
                            case "11": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item11; break;
                            case "12": anulacion.PeriodoLiquidacion.Periodo = BO.SII.v1.v1.TipoPeriodoType.Item12; break;
                        }

                        // ID de factura
                        anulacion.IDFactura = new BO.SII.v1.v1.IDFacturaExpedidaBCType();
                        anulacion.IDFactura.IDEmisorFactura = new BO.SII.v1.v1.IDFacturaExpedidaBCTypeIDEmisorFactura();
                        anulacion.IDFactura.IDEmisorFactura.NIF = facturaSII.IdEmisorFacturaNif;
                        anulacion.IDFactura.NumSerieFacturaEmisor = facturaSII.NumSerieFacturaEmisor;
                        anulacion.IDFactura.FechaExpedicionFacturaEmisor = facturaSII.FechaExpFacturaEmisor.HasValue ? facturaSII.FechaExpFacturaEmisor.Value.ToString("dd-MM-yyyy") : String.Empty;

                        bajas.RegistroLRBajaExpedidas[numeroFacturas] = anulacion;
                        numeroFacturas++;
                    }

                    lote.Id = null;
                    if (respuesta.Resultado == ResultadoProceso.OK)
                        respuesta = Insertar(lote);

                    // Actualizar las facturasSII rellenando el lote
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        XmlDocument bajasXML = Serializar(bajas);

                        byte[] codificar = null;
                        if (lote.Origen != "012")
                        {
                            codificar = System.Text.ASCIIEncoding.ASCII.GetBytes(bajasXML.InnerXml);
                        }
                        else
                        {
                            codificar = System.Text.ASCIIEncoding.ASCII.GetBytes(bajasXML.InnerXml.Replace("es/aeat/ssii/fact/ws/", "es/aeat/ssii/igic/ws/").Replace("eIVA", "eIGIC").Replace("<IDVersionSii>1.1", "<IDVersionSii>1.0"));
                            loteDTO.agenciaTributaria = "CA";
                        }
                        lote.DocLoteB64 = System.Convert.ToBase64String(codificar);

                        loteDTO.docLoteB64 = lote.DocLoteB64;
                        loteDTO.guid = lote.Id;
                        loteDTO.etiqueta_externa = lote.Id;
                        loteDTO.id_agrupacion = lote.IdAgrupacion;
                        loteDTO.id_sociedad = lote.Sociedad;
                        loteDTO.id_tenant = lote.IdTenant;
                        loteDTO.importeTotal = (float)importeTotal;
                        loteDTO.numRegistros = lote.FacturasSII.Count();
                        loteDTO.origen = lote.Origen;
                        loteDTO.tipoOperacion = "AnulacionLRFacturasEmitidas";
                        loteDTO.titularNIF = lote.TitularNIF;
                        loteDTO.titularNombreRazon = lote.TitularNombreRazon;
                        loteDTO.versionSII = lote.VersionSII;

                        foreach (cFacturaSIIBO facturaSII in lote.FacturasSII)
                        {
                            if (respuesta.Resultado != ResultadoProceso.OK)
                                break;

                            facturaSII.LoteId = lote.Id;
                            respuesta = cFacturasSIIBL.Actualizar(facturaSII);
                        }
                    }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        loteXML = Serializar(loteDTO);
                        loteXML.InnerXml = loteXML.InnerXml.Replace("loteDTO", "Lote");
                    }

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        log = respuesta.Ex.Message + Environment.NewLine;
                    else
                        log = Resource.lote + " " + lote.Id + ": " + (String.IsNullOrEmpty(lote.EnvIdError) ? (String.IsNullOrEmpty(lote.EnvIdErrorMiddleware) ? "Procesado" : lote.EnvIdErrorMiddleware) : lote.EnvIdError) + Environment.NewLine;

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        scope.Complete();
                }
            }

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                ProcesarLoteResponseReturn respuestaLote = new ProcesarLoteResponseReturn();

                try
                {
                    ProcesarLoteWSImplService procesar = new ProcesarLoteWSImplService();

                    string url = cConfiguration.GetWebConfigConfigurationValue("webserviceURL");
                    string userName = cConfiguration.GetWebConfigConfigurationValue("username");
                    string password = cConfiguration.GetWebConfigConfigurationValue("password");

                    if (!string.IsNullOrEmpty(url))
                        procesar.Url = url;
                    // Set the client-side credentials using the Credentials property.
                    if (!string.IsNullOrEmpty(userName) && !string.IsNullOrEmpty(password))
                    {
                        ICredentials credentials = new NetworkCredential(userName, password);
                        procesar.Credentials = credentials;
                    }
                    respuestaLote = procesar.ProcesarLote(loteDTO);

                }
                catch (Exception ex)
                {
                    lote.Estado = "T";
                    lote.ErrorDescripcion = "Error Técnico";
                    lote.InfoLIne1 = ex.Message;
                    respuesta = Actualizar(lote);
                    //scope.Complete();
                    respuesta.Resultado = ResultadoProceso.Error;
                    throw ex;

                }

                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    // Actualizar respuesta del lote
                    lote.Estado = respuestaLote.estado;
                    lote.IdError = respuestaLote.idError;
                    lote.ErrorDescripcion = respuestaLote.descripcion;
                    lote.IdIntercambioRet = respuestaLote.idIntercambioRet;
                    lote.InfoLIne1 = respuestaLote.infoLIne1;
                    lote.InfoLIne2 = respuestaLote.infoLIne2;
                    lote.InfoLIne3 = respuestaLote.infoLIne3;
                    lote.FechaUpdate = String.IsNullOrEmpty(respuestaLote.timeStamp) ? null : (DateTime?)Convert.ToDateTime(respuestaLote.timeStamp);

                    respuesta = Actualizar(lote);
                }
            }

            return respuesta;
        }

        /// <summary>
        /// Carga el xml de la respuesta en un objeto
        /// </summary>
        /// <param name="ruta">Ruta del fichero xml de la respuesta </param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public static bool CargaRespuestaXML(string rutaFichero, out cRespuesta respuesta)
        {
            // Ej. rutaFichero:
            //      ~/Ficheros/Documentos/ESTADO_FAC_SII/<ORIGEN>-<ID_SOCIEDAD>-<ID_LOTE>-<TipoOperacion>Response.xml
            //      ~/Ficheros/Documentos/ESTADO_FAC_SII/Ej. 004-F597-3006516519651681621998261FE-SuministroLRFacturasEmitidasResponse.xml
            respuesta = new cRespuesta();
            bool hayAlgunLoteErroneo = false;

            // Declare an object variable of the type to be deserialized
            //RespuestaAEATType oRespuestaAEAT = new RespuestaAEATType();
            ProcesarLoteSincronoResponse oRespuestaAEAT = new ProcesarLoteSincronoResponse();

            if (rutaFichero == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }

            bool resultado = false;

            // A FileStream is needed to read the XML document
            FileStream fs = new FileStream(rutaFichero, FileMode.Open);

            try
            {
                // Create an instance of the XmlSerializer class. Specify the type of object to be deserialized.
                XmlSerializer serializer = new XmlSerializer(typeof(ProcesarLoteSincronoResponse));

                // If the XML document has been altered with unknown nodes or attributes, handle them with the UnknownNode 
                // and UnknownAttribute events
                serializer.UnknownNode += new XmlNodeEventHandler(serializer_UnknownNode);
                serializer.UnknownAttribute += new XmlAttributeEventHandler(serializer_UnknownAttribute);

                // Use the Deserialize method to restore the object's state with data from the XML document
                oRespuestaAEAT = (ProcesarLoteSincronoResponse)serializer.Deserialize(fs);

                fs.Close();
                fs.Dispose();

                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    // Actualizamos en el lote los datos de cabecera
                    cFacturasSIILoteBO oFacSIILoteBO = new cFacturasSIILoteBO();
                    oFacSIILoteBO = ObtenerPorIdIntercambioRet(oRespuestaAEAT.@return.guid, out respuesta);
                    if (oFacSIILoteBO != null)
                    {
                        oFacSIILoteBO.IdIntercambioRet = oRespuestaAEAT.@return.guid;
                        oFacSIILoteBO.EnvEstado = EstadoLoteString(oRespuestaAEAT.@return.estado_envio);
                        oFacSIILoteBO.EnvIdError = oRespuestaAEAT.@return.codigoError;
                        oFacSIILoteBO.EnvIdErrorMiddleware = oRespuestaAEAT.@return.codigoMiddleware;
                        oFacSIILoteBO.EnvErrorDescripcion = oRespuestaAEAT.@return.descripcionError;

                        // Actualizamos siempre el estado del lote con el estado de la respuesta
                        //if (oFacSIILoteBO.EnvEstado == "S" || oFacSIILoteBO.EnvEstado == "W")
                        //{
                        oFacSIILoteBO.Estado = oFacSIILoteBO.EnvEstado;
                        oFacSIILoteBO.IdError = oRespuestaAEAT.@return.codigoError;
                        oFacSIILoteBO.ErrorDescripcion = oRespuestaAEAT.@return.descripcionError;
                        //}

                        if (oFacSIILoteBO.Estado != "S")
                            hayAlgunLoteErroneo = true;

                        respuesta = Actualizar(oFacSIILoteBO, true);
                        resultado = (respuesta.Resultado == ResultadoProceso.OK);

                        if (resultado)
                        {
                            // Actualizamos cada factura SII

                            // Si el XML completo es erróneo NO VENDRÁ ningún nodo de facturas, así que sólo actualizaremos la cabecera en facSIILote

                            // TODO: ¿Buscar todas las facturas que se incluyen en el lote y actualizarlas a erróneas?
                            // cBindableList<cFacturaSIIBO> facturasLote = cFacturasSIIBL.ObtenerPorLoteId

                            // Si el XML es correcto o parcialmente correcto, vendrán también los nodos con las facturas, 
                            // y vamos actualizando cada una de ellas
                            ProcesarLoteSincronoResponseReturnRegistros[] items =
                                (oRespuestaAEAT.@return.registros != null ? oRespuestaAEAT.@return.registros : null);

                            if (items != null)
                            {
                                foreach (ProcesarLoteSincronoResponseReturnRegistros reg in items)
                                {
                                    // Obtenemos la última factura de ese NumSerie                            
                                    cFacturaSIIBO fac = cFacturasSIIBL.ObtenerUltimaPorNumSerie(reg.numSerie, out respuesta);

                                    // Lo que nos importa es saber que hemos recogido la factura                                    
                                    resultado = (fac != null);
                                    if (!resultado) break;

                                    // Nos da igual si esta factura no tiene líneas, pero en ese caso la respuesta nos vendría
                                    // con un error de "Sin registros", que obviamos porque no nos interesa, y reiniciamos
                                    // la variable respuesta
                                    respuesta = new cRespuesta();

                                    // Campos a actualizar
                                    fac.ErrorCodigo = reg.codigoError;
                                    fac.ErrorDesc = reg.descripcionError;
                                    fac.Estado = EstadoFacturaInt(reg.estado);

                                    // Campos clave por los que actualizar
                                    fac.LoteId = oFacSIILoteBO.Id;
                                    // Ej. numSerie: 600-3-17600531  (Origen-Serie-Número factura)
                                    fac.NumSerieFacturaEmisor = reg.numSerie;

                                    // Creo una factura sólo con los campos clave y los campos a actualizar
                                    cFacturaSIIBO facActualizar = new cFacturaSIIBO();

                                    facActualizar.LoteId = fac.LoteId;
                                    facActualizar.NumSerieFacturaEmisor = fac.NumSerieFacturaEmisor;
                                    facActualizar.Estado = fac.Estado;
                                    facActualizar.ErrorCodigo = fac.ErrorCodigo;
                                    facActualizar.ErrorDesc = fac.ErrorDesc;

                                    respuesta = cFacturasSIIBL.ActualizarPorNumSerie(facActualizar);
                                    resultado = (respuesta.Resultado == ResultadoProceso.OK);
                                    if (!resultado) break;

                                    // Quitamos el reenvío automático. Se dejará preparado el reenvío justo antes del proceso
                                    // de preparación y envío de un nuevo lote
                                    #region Reenvío

                                    //// Preparamos el reenvío de las facturas incorrectas o con error técnico
                                    //// Sólo si el estado de la factura es "incorrecta" o "error técnico", porque si la respuesta del envío
                                    ////      es correcta ya no hace falta seguir reenviándolo
                                    //if ((fac.Estado == 3 || fac.Estado == 4) && // EstadoFacturaInt(reg.estado)
                                    //    errores_reenvio.Contains(fac.ErrorCodigo))
                                    //{
                                    //    // Si alguna de las facturas está rechazada por NIF erróneo por segunda vez, hay que volver a enviarla 
                                    //    //  (nuevos reg en facSii y facSiiDesglose)
                                    //    cBindableList<cFacturaSIIBO> facturas = cFacturasSIIBL.ObtenerTodasPorNumSerie(reg.numSerie, null, out respuesta);

                                    //    // Sólo nos interesa que se haya recogido correctamente la lista de facturas
                                    //    resultado = (facturas != null);
                                    //    if (!resultado) break;

                                    //    // Nos da igual si alguna factura no tiene líneas, pero en ese caso la respuesta nos vendría
                                    //    // con un error de "Sin registros", que obviamos porque no nos interesa, y reiniciamos
                                    //    // la variable respuesta
                                    //    respuesta = new cRespuesta();

                                    //    var respuestasNIFNoCensado = facturas
                                    //                    .Where(x => x.ErrorCodigo != null && errores_reenvio.Contains(x.ErrorCodigo))
                                    //                    .Select(x => x.ErrorCodigo);

                                    //    // La preparamos para que vuelva a enviarse, insertando una copia de la factura en la que 
                                    //    // incrementamos el número de envío y borramos los campos necesarios para que vuelva a 
                                    //    // añadirse a un nuevo lote y a enviarse
                                    //    cFacturaSIIBO nuevaFac = new cFacturaSIIBO();
                                    //    nuevaFac = fac.Copiar();
                                    //    nuevaFac.NumeroEnvio = nuevaFac.NumeroEnvio + 1;

                                    //    // Dejamos el código de error para los casos en que necesitamos revisarlo para saber
                                    //    // si es necesario o no crear una nueva versión de la factura (corrección de NIF erróneos)
                                    //    //nuevaFac.ErrorCodigo = null;
                                    //    //nuevaFac.ErrorDesc = null;
                                    //    nuevaFac.Estado = null;
                                    //    nuevaFac.LoteId = null;

                                    //    ///////////////////////////////////////

                                    //    // Si se está rechazando por NIF no censado o errores de NIF, comprobamos si ya se ha rechazado al menos 
                                    //    //      dos veces por ese tipo de errores, mirando los errores de todos los envíos de una factura
                                    //    // "Al menos dos veces" porque si ya lo hemos reenviado por medio del nodo idOtro y nos ha dado algún
                                    //    //      error, tenemos que seguir intentando reenviarlo
                                    //    bool incluirNodoIdOtro = false;
                                    //    incluirNodoIdOtro = (respuestasNIFNoCensado != null && respuestasNIFNoCensado.Count() >= 2);

                                    //    if (incluirNodoIdOtro)
                                    //    {
                                    //        // Cuando se cree un nuevo lote para procesar de nuevo las facturas de NIF no censado,
                                    //        // el xml deberá contener un nodo IdOtro con los siguientes campos:

                                    //        //Código país: ES
                                    //        nuevaFac.ContraparteIdOtro = "ES";
                                    //        //Clave ID: 07. No censado
                                    //        nuevaFac.ContraparteIdTipo = claveID_NoCensado;
                                    //        //Número Id: NIF no censado del receptor de la factura
                                    //        nuevaFac.ContraparteId = nuevaFac.ContraparteNif;
                                    //        //nuevaFac.ContraparteNif = reg.NIF;
                                    //        //Apellidos y nombre: Nombre del no censado receptor de la factura
                                    //        // Ya lo tenemos en ContraparteNombreRazon después del fac.Copiar()

                                    //        ////////////////////////////////////////
                                    //    }

                                    //    // Sólo si tiene líneas de desglose (que debería tenerlas)
                                    //    if (nuevaFac.FacturaSIIDesglosesBO != null)
                                    //    {
                                    //        foreach (cFacturaSIIDesgloseBO desg in nuevaFac.FacturaSIIDesglosesBO)
                                    //            desg.NumeroEnvio = desg.NumeroEnvio + 1;
                                    //    }

                                    //    cFacturasSIIBL.InsertarConLineas(nuevaFac, out respuesta);
                                    //    resultado = (respuesta.Resultado == ResultadoProceso.OK);
                                    //}

                                    #endregion
                                }
                            }
                        }
                    }

                    //Si todo va bien, finalizamos la transacción
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        // En caso de que haya habido errores, enviamos también mensaje de sistema y correo de aviso
                        if (hayAlgunLoteErroneo)
                            respuesta = EnviarEmailAvisoErroresSII(AcuamaDateTime.Today.ToShortDateString());

                        scope.Complete();
                    }
                }
            }
            catch (Exception ex)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                resultado = false;
                fs.Close();
                fs.Dispose();
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Enviar correo avisando de que hubo errores de envío al SII
        /// </summary>
        /// <param name="fecha">Fecha en la que ha habido envío incorrecto de facturas</param>
        /// <returns>Objeto Respuesta con el resultado del envío de correos</returns>
        public static cRespuesta EnviarEmailAvisoErroresSII(string fecha)
        {
            cRespuesta respuesta = new cRespuesta();
            cBindableList<BO.Sistema.cUsuarioBO> usuarios;

            usuarios = BL.Sistema.cUsuarioBL.ObtenerReceptoresEmailErroresSII(out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK && usuarios != null && usuarios.Count > 0)
            {
                for (int i = 0; i < usuarios.Count; i++)
                {
                    cUsuarioBO usuarioDestino = usuarios[i];

                    // Enviamos el correo
                    if (usuarioDestino.Empleado != null && usuarioDestino.Empleado.Email != null && !String.IsNullOrEmpty(usuarioDestino.Empleado.Email))
                        respuesta = cPlantillasCorreosBL.EnviarAvisoErroresSII(usuarioDestino.Empleado.Email, usuarioDestino.Empleado.Nombre, fecha);

                    // Insertamos también en la tabla de mensajes, se haya enviado bien el email o no, y tenga o no tenga correo definido el empleado
                    cMensajeBO mensaje = new cMensajeBO();
                    mensaje.Asunto = Resource.ETaskType_RecuperaEstadoSII;
                    mensaje.Fecha = AcuamaDateTime.Now;
                    mensaje.Texto = Resource.erroresEnvioSII;
                    mensaje.UsrDestino = usuarioDestino.Codigo;

                    new cMensajeBL().Insertar(mensaje, false, out respuesta);
                }
            }

            return respuesta;
        }

        /// <summary>
        /// Devuelve el número de facturas de un lote que es posible preparar para reenvío por errores de NIF
        /// </summary>
        /// <param name="fcSiiLtID">Id de lote que vamos a consultar</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion con la BD</param>
        /// <returns>Devuelve el número de facturas de ese lote que se podrían preparar para reenvío</returns>
        public static int CuantasFacturasAReenviar(string fcSiiLtID, out cRespuesta respuesta)
        {
            int cuantasFacturas = 0;
            respuesta = new cRespuesta();

            cuantasFacturas = new cFacturasSIILoteDL().CuantasFacturasAReenviar(fcSiiLtID, out respuesta);

            return cuantasFacturas;
        }

        public static string GetCodigoErrorUltimoEnvio(short fcSiiFacCod, string fcSiiFacPerCod, int fcSiiFacCtrCod, short fcSiiFacVersion, out cRespuesta respuesta)
        {
            string codigoError = new cFacturasSIIDL().GetCodigoErrorUltimoEnvio(fcSiiFacCod, fcSiiFacPerCod, fcSiiFacCtrCod, fcSiiFacVersion, out respuesta);

            return respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrWhiteSpace(codigoError) ? codigoError : null;
        }

        private static void serializer_UnknownNode(object sender, XmlNodeEventArgs e)
        {
            Console.WriteLine("Unknown Node:" + e.Name + "\t" + e.Text);
        }

        private static void serializer_UnknownAttribute(object sender, XmlAttributeEventArgs e)
        {
            System.Xml.XmlAttribute attr = e.Attr;
            //Console.WriteLine("Unknown attribute " +
            //attr.Name + "='" + attr.Value + "'");
        }

        /// <summary>
        /// Convierte el estado del lote de la cadena que nos llega en el XML al char que se guarda en BD
        /// </summary>
        /// <param name="estadoEnTexto"></param>
        /// <returns></returns>
        private static string EstadoLoteString(string estadoEnTexto)
        {
            string estado = null;
            estadoEnTexto = estadoEnTexto.ToUpper();
            estado = (estadoEnTexto.Equals("CORRECTO") ? "S" :
                     ((estadoEnTexto.Equals("PARCIALMENTE CORRECTO") ||
                           estadoEnTexto.Equals("PARCIALMENTECORRECTO") ||
                           estadoEnTexto.Equals("ACEPTADOCONERRORES")) ? "W" :
                     (estadoEnTexto.Equals("INCORRECTO") ? "E" :
                     (estadoEnTexto.Equals("ERROR TECNICO") ? "T" : estado))));

            return estado;
        }

        /// <summary>
        /// Convierte el estado de la factura de la cadena que nos llega en el XML al int que se guarda en BD
        /// </summary>
        /// <param name="estadoEnTexto"></param>
        /// <returns></returns>
        private static int? EstadoFacturaInt(string estadoEnTexto)
        {
            // Es el estado en el SII del lote  1 Aceptación completa, 2  Aceptación parcial, 3 Rechazo completo, 4 Error técnico
            int? estado = null;
            estadoEnTexto = estadoEnTexto.ToUpper();
            estado = (estadoEnTexto.Equals("CORRECTO") ? 1 :
                     ((estadoEnTexto.Equals("PARCIALMENTE CORRECTO") ||
                           estadoEnTexto.Equals("PARCIALMENTECORRECTO") ||
                           estadoEnTexto.Equals("ACEPTADOCONERRORES")) ? 2 :
                     (estadoEnTexto.Equals("INCORRECTO") ? 3 :
                     (estadoEnTexto.Equals("ERROR TECNICO") ? 4 : estado))));

            return estado;
        }

        public static XmlDocument Serializar(BO.Facturacion.ProcesarLoteSincronoResponse datos)
        {
            XmlSerializerNamespaces namespaces = new XmlSerializerNamespaces();

            using (MemoryStream ms = new MemoryStream())
            {
                using (XmlTextWriter xmltw = new XmlTextWriter(ms, Encoding.UTF8))
                {
                    XmlSerializer xmlser = new XmlSerializer(typeof(BO.Facturacion.ProcesarLoteSincronoResponse));
                    xmlser.Serialize(xmltw, datos, namespaces);

                    ms.Seek(0, SeekOrigin.Begin);
                    XmlDocument xmld = new XmlDocument();
                    xmld.Load(ms);
                    return xmld;
                }
            }
        }

        public static XmlDocument Serializar(BajaLRFacturasEmitidas datos)
        {
            XmlSerializerNamespaces namespaces = new XmlSerializerNamespaces();

            using (MemoryStream ms = new MemoryStream())
            {
                using (XmlTextWriter xmltw = new XmlTextWriter(ms, Encoding.UTF8))
                {
                    XmlSerializer xmlser = new XmlSerializer(typeof(BajaLRFacturasEmitidas));
                    xmlser.Serialize(xmltw, datos, namespaces);

                    ms.Seek(0, SeekOrigin.Begin);
                    XmlDocument xmld = new XmlDocument();
                    xmld.Load(ms);
                    return xmld;
                }
            }
        }

        public static XmlDocument Serializar(SuministroLRFacturasEmitidas datos)
        {
            XmlSerializerNamespaces namespaces = new XmlSerializerNamespaces();

            using (MemoryStream ms = new MemoryStream())
            {
                using (XmlTextWriter xmltw = new XmlTextWriter(ms, Encoding.UTF8))
                {
                    XmlSerializer xmlser = new XmlSerializer(typeof(SuministroLRFacturasEmitidas));
                    xmlser.Serialize(xmltw, datos, namespaces);

                    ms.Seek(0, SeekOrigin.Begin);
                    XmlDocument xmld = new XmlDocument();
                    xmld.Load(ms);
                    return xmld;
                }
            }
        }

        public static XmlDocument Serializar(loteDTO datos)
        {
            XmlSerializerNamespaces namespaces = new XmlSerializerNamespaces();

            using (MemoryStream ms = new MemoryStream())
            {
                using (XmlTextWriter xmltw = new XmlTextWriter(ms, Encoding.UTF8))
                {
                    XmlSerializer xmlser = new XmlSerializer(typeof(loteDTO));
                    xmlser.Serialize(xmltw, datos, namespaces);

                    ms.Seek(0, SeekOrigin.Begin);
                    XmlDocument xmld = new XmlDocument();
                    xmld.Load(ms);
                    return xmld;
                }
            }
        }

        private static string ObtenerClaveRegimenEspecial(out cRespuesta respuesta)
        {
            respuesta = new cRespuesta(ResultadoProceso.OK);

            string clave = cParametroBL.ObtenerValor("ClaveRegimen", out respuesta);

            return (clave ?? "01");
        }

        private static BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType ClaveRegimenEspecial(string clave)
        {
            switch (clave)
            {
                case "01": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01;
                case "02": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item02;
                case "03": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item03;
                case "04": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item04;
                case "05": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item05;
                case "06": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item06;
                case "07": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item07;
                case "08": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item08;
                case "09": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item09;
                case "10": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item10;
                case "11": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item11;
                case "12": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item12;
                case "13": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item13;
                case "14": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item14;
                case "15": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item15;
                case "16": return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item16;
            }

            return BO.SII.v1.v1.IdOperacionesTrascendenciaTributariaType.Item01;
        }

        private static TipoOperacionSujetaNoExentaType TipoOperacionSujetaNoExenta(string tipo)
        {
            switch (tipo)
            {
                case "S1": return TipoOperacionSujetaNoExentaType.S1;
                case "S2": return TipoOperacionSujetaNoExentaType.S2;
                case "S3": return TipoOperacionSujetaNoExentaType.S3;
            }
            return TipoOperacionSujetaNoExentaType.S1;
        }

        private static BO.SII.v1.v1.ClaveTipoFacturaType? ClaveTipoFactura(string tipo)
        {
            switch (tipo)
            {
                case "F1": return BO.SII.v1.v1.ClaveTipoFacturaType.F1;
                case "R1": return BO.SII.v1.v1.ClaveTipoFacturaType.R1;
                case "R2": return BO.SII.v1.v1.ClaveTipoFacturaType.R2;
                case "R3": return BO.SII.v1.v1.ClaveTipoFacturaType.R3;
                case "R4": return BO.SII.v1.v1.ClaveTipoFacturaType.R4;
                case "R5": return BO.SII.v1.v1.ClaveTipoFacturaType.R5;
            }

            return null;
        }

        private static PersonaFisicaJuridicaIDTypeType? TipoPersonaJuridica(string tipo)
        {
            switch (tipo)
            {
                case "02": case "2": return PersonaFisicaJuridicaIDTypeType.Item02;
                case "03": case "3": return PersonaFisicaJuridicaIDTypeType.Item03;
                case "04": case "4": return PersonaFisicaJuridicaIDTypeType.Item04;
                case "05": case "5": return PersonaFisicaJuridicaIDTypeType.Item05;
                case "06": case "6": return PersonaFisicaJuridicaIDTypeType.Item06;
                case "07": case "7": return PersonaFisicaJuridicaIDTypeType.Item07;
            }

            return null;
        }

        private static BO.SII.v1.v1.VersionSiiType VersionSII(string version)
        {
            return BO.SII.v1.v1.VersionSiiType.Item11;
        }

        private static BO.SII.v1.v1.CausaExencionType CausaExencion(string causa)
        {
            switch (causa)
            {
                case "E1": return BO.SII.v1.v1.CausaExencionType.E1;
                case "E2": return BO.SII.v1.v1.CausaExencionType.E2;
                case "E3": return BO.SII.v1.v1.CausaExencionType.E3;
                case "E4": return BO.SII.v1.v1.CausaExencionType.E4;
                case "E5": return BO.SII.v1.v1.CausaExencionType.E5;
                case "E6": return BO.SII.v1.v1.CausaExencionType.E6;
            }

            return BO.SII.v1.v1.CausaExencionType.E1;
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
                camposBusqueda["fechaEnvioSAP"] = cAplicacion.BuildRange(Convert.ToString(camposBusqueda["fechaEnvioSAPD"]), Convert.ToString(camposBusqueda["fechaEnvioSAPH"]), cConfiguration.kSeparadorBuscarRango);
                camposBusqueda["fechaUpdate"] = cAplicacion.BuildRange(Convert.ToString(camposBusqueda["fechaUpdateD"]), Convert.ToString(camposBusqueda["fechaUpdateH"]), cConfiguration.kSeparadorBuscarRango);

                resultado = new cFacturasSIILoteDL().ConstruirFiltroSQL(camposBusqueda, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        //protected void RellenarObjeto()
        //{

        //    FacturaSII.PeriodoCodigo = String.IsNullOrEmpty(tbPeriodo.Text) ? null : tbPeriodo.Text;
        //    FacturaSII.ContratoCodigo = String.IsNullOrEmpty(tbContrato.Text) ? null : (int?) Convert.ToInt32(tbContrato.Text);
        //    FacturaSII.FacturaCodigo = String.IsNullOrEmpty(tbCodigo.Text) ? null : (short?) Convert.ToInt16(tbCodigo.Text);
        //    FacturaSII.FacturaVersion = String.IsNullOrEmpty(tbVersion.Text) ? null : (short?)Convert.ToInt16(tbVersion.Text);

        //}




       

        //==============================================================================
        //==============================================================================
        //==============================================================================
        #region SII_Exentas

        /// <summary>
        /// Selecciona los totales de las filas de facSIIDesgloseFactura agrupando por: Tipo Operacion(Entrega, Prestacion Servicios), No-Sujeta, Sujeta(Exenta, No-Exenta)
        /// </summary>
        private static List<siiFacturaDesgloses> obtenerTotalesFacturaxTipoOperacion(cFacturaSIIBO facturaSII)
        {
            //********************************************************
            //Recuperamos las lineas en facSIIDesgloseFactura
            //Agrupando por [DesgloseTipoOperacion], CausaExencion, TipoNoExenta
            //********************************************************
            // TipoNoExenta | Causa Exención | 
            //      Ø       |       Ø        | NO SUJETA
            //      Ø       |       1        | SUJETA EXENTA
            //      1       |       1        | SUJETA EXENTA      
            //      1       |       Ø        | SUJETA NO EXENTA
            //********************************************************

            List<siiFacturaDesgloses> lstDesglose = null;
            string exMessage = string.Empty;

            try
            {

                lstDesglose = facturaSII.FacturaSIIDesglosesBO
                .GroupBy(g => new
                {
                    TipoOperacion   = (g.Entrega ?? false) ? TipoDesglose.OperacionEntrega : TipoDesglose.OperacionPrestacionServicios,
                    CausaExencion   = !string.IsNullOrEmpty(g.CausaExencion) ? g.CausaExencion : string.Empty,
                    TipoImpositivo  = string.IsNullOrEmpty(g.CausaExencion) && string.IsNullOrEmpty(g.TipoNoExenta) ? 0.00m : g.TipoImpositivo,
                    //Sujetas no Exentas las totalizamos en un solo grupo
                    TipoSujetaNoExenta = string.IsNullOrEmpty(g.CausaExencion) && !string.IsNullOrEmpty(g.TipoNoExenta) ? "S_" : string.Empty
                })

                .Select(x => new siiFacturaDesgloses
                {
                    DesgloseTipoOperacion = x.Key.TipoOperacion,
                    CausaExencion = x.Key.CausaExencion,
                    //Se asigna el mínimo valor de tipo Sujeta NO Exenta
                    TipoNoExenta = string.IsNullOrEmpty(x.Key.CausaExencion) ? x.Min(s => s.TipoNoExenta) : string.Empty,
                    TipoImpositivo = x.Key.TipoImpositivo,
                    BaseImponible = x.Sum(s => s.BaseImponible),
                    CuotaRepercutida = x.Sum(s => s.CuotaRepercutida),
                    ImportePorArticulos7_14_Otros = x.Sum(s => s.ImpPorArt7_14_Otros),
                    ImporteTAIReglasLocal = x.Sum(s => s.ImpTAIReglasLoc)

                })
                .OrderBy(o => o.TipoNoExenta)
                .ToList<siiFacturaDesgloses>();
            }
            catch (Exception ex)
            {
                exMessage = ex.Message;
            }

            return lstDesglose;
        }


        /// <summary>
        /// Selecciona los totales de las filas de facSIIDesgloseFactura agrupando por: No-Sujeta, Sujeta(Exenta, No-Exenta)
        /// </summary>
        private static List<siiFacturaDesgloses> obtenerTotalesFactura(List<siiFacturaDesgloses> facturaSII)
        {
            //********************************************************
            //Recuperamos las lineas totalizando sin tener en cuenta el tipo de desglose
            //Agrupando por CausaExencion, TipoNoExenta
            //********************************************************
            // TipoNoExenta | Causa Exención | 
            //      Ø       |       Ø        | NO SUJETA
            //      Ø       |       1        | SUJETA EXENTA
            //      1       |       1        | SUJETA EXENTA      
            //      1       |       Ø        | SUJETA NO EXENTA
            //********************************************************
            List<siiFacturaDesgloses> lstDesglose = null;
            string exMessage = string.Empty;

            try
            {

                lstDesglose = facturaSII
                .GroupBy(g => new
                {
                    CausaExencion = !string.IsNullOrEmpty(g.CausaExencion) ? g.CausaExencion : string.Empty,
                    TipoImpositivo = string.IsNullOrEmpty(g.CausaExencion) && string.IsNullOrEmpty(g.TipoNoExenta) ? 0.00m : g.TipoImpositivo,
                    //Sujetas no Exentas las totalizamos en un solo grupo
                    TipoSujetaNoExenta = string.IsNullOrEmpty(g.CausaExencion) && !string.IsNullOrEmpty(g.TipoNoExenta) ? "S_" : string.Empty
                })

                .Select(x => new siiFacturaDesgloses
                {
                    DesgloseTipoOperacion = TipoDesglose.DesgloseFactura,
                    CausaExencion = x.Key.CausaExencion,
                    //Se asigna el mínimo valor de tipo Sujeta NO Exenta
                    TipoNoExenta = string.IsNullOrEmpty(x.Key.CausaExencion) ? x.Min(s => s.TipoNoExenta) : string.Empty,
                    TipoImpositivo = x.Key.TipoImpositivo,
                    BaseImponible = x.Sum(s => s.BaseImponible),
                    CuotaRepercutida = x.Sum(s => s.CuotaRepercutida),
                    ImportePorArticulos7_14_Otros = x.Sum(s => s.ImportePorArticulos7_14_Otros),
                    ImporteTAIReglasLocal = x.Sum(s => s.ImporteTAIReglasLocal)
                })
                .OrderBy(o => o.TipoNoExenta)
                .ToList<siiFacturaDesgloses>();
            }
            catch(Exception ex)
            {
                exMessage = ex.Message;
            }

            return lstDesglose;
        }



        //*************************************************************************************
        /// <summary>
        /// Conforma un objeto similar al "TIPODESGLOSE" que se va a enviar al SII 
        /// </summary>
        private static objDesglose obtenerObjDesglose(List<siiFacturaDesgloses> lstDesglose)
        {
            objDesglose result = new objDesglose();

            try
            {
                //Ha un unico nodo con los totales
                result.totalNoSujeta = obtenerNoSujetas(lstDesglose);
                result.totalSujetaNoExentas = obtenerSujetasNoExentas(lstDesglose);
                //
                result.lstSujetaExentas = obtenerSujetasExentas(lstDesglose);
            }
            catch
            {
                result = null;
            }

            return result;
        }


        private static BO.SII.v1.v1.NoSujetaType obtenerNoSujetas(List<siiFacturaDesgloses> lstDesglose)
        {
            BO.SII.v1.v1.NoSujetaType result = null;

            try
            {
                List<siiFacturaDesgloses> lstNoSujeta = lstDesglose.Where(x => !x.esSujeta).ToList();

                if (lstNoSujeta.Count == 1)
                {
                    result = lstNoSujeta[0].noSujetasTotal();
                }
            }
            catch
            {
                result = null;
            }

            return result;
        }

        private static List<BO.SII.v1.v1.DetalleExentaType> obtenerSujetasExentas(List<siiFacturaDesgloses> lstDesglose)
        {
            List<BO.SII.v1.v1.DetalleExentaType> result = new List<BO.SII.v1.v1.DetalleExentaType>();

            try
            {
                List<siiFacturaDesgloses> lstSujetasExentas = lstDesglose.Where(x => x.esSujeta && x.esExenta).ToList();

                foreach (siiFacturaDesgloses s in lstDesglose)
                {
                    BO.SII.v1.v1.DetalleExentaType exenta = s.detalleExenta();

                    if (exenta != null) result.Add(exenta);
                }
            }
            catch
            {
                result = null;
            }

            return result;

        }

        private static objSujetaNoExentas obtenerSujetasNoExentas(List<siiFacturaDesgloses> lstDesglose)
        {

            objSujetaNoExentas result = null;
            List<BO.SII.v1.v1.DetalleIVAEmitidaType> lstSujetasNoExenta_IVA = new List<BO.SII.v1.v1.DetalleIVAEmitidaType>();

            try
            {
                List<siiFacturaDesgloses> lstSujetasNoExentas = lstDesglose.Where(x => x.esSujeta && !x.esExenta).ToList();

                foreach(siiFacturaDesgloses itemIVA in lstSujetasNoExentas)
                {
                    BO.SII.v1.v1.DetalleIVAEmitidaType noExenta_IVA = itemIVA.detalleIVAEmitida();
                    
                    if (noExenta_IVA != null) lstSujetasNoExenta_IVA.Add(noExenta_IVA);
                }

                if (lstSujetasNoExenta_IVA.Count > 0)
                {
                    //Todos los desgloses se asocian a un único tipo de operacion sujeta-noexenta
                    //Es suficienta asignar el valor del primer elemento
                    result = new objSujetaNoExentas(lstSujetasNoExentas[0].tipoOperacionSujetaNoExenta);
                    result.lstSujetaNoExenta_DesgloseIVA = lstSujetasNoExenta_IVA;
                }
            }
            catch
            {
                result = null;
            }

            return result;

        }




        /// <summary>
        /// Conforma un objeto similar al "TIPODESGLOSE" que se va a enviar al SII agrupado por No-Sujeta, Sujeta(Exenta, No-Exenta)
        /// </summary>
        private static objDesglosexTipo obtenerDesglosexFactura(List<siiFacturaDesgloses> lstDesgloseInput)
        {
            objDesglosexTipo result = null;
            try
            {
                List<siiFacturaDesgloses> lstDesgloseFac = obtenerTotalesFactura(lstDesgloseInput);
                objDesglose desglose = obtenerObjDesglose(lstDesgloseFac);

                result = new objDesglosexTipo(TipoDesglose.DesgloseFactura, desglose);
            }
            catch { }

            return result;
        }


        /// <summary>
        /// Conforma un objeto similar al "TIPODESGLOSE" que se va a enviar al SII agrupado por TipoDeglose, No-Sujeta, Sujeta(Exenta, No-Exenta)
        /// </summary>
        private static List<objDesglosexTipo> obtenerDesglosexTipo(List<siiFacturaDesgloses> lstDesglosexTipo)
        {
            List<objDesglosexTipo> result = new List<objDesglosexTipo>();
            
            if (lstDesglosexTipo.Count == 0) return result;

            try
            {
                //Por factura
                objDesglosexTipo siiTipoDesgloseFac = obtenerDesglosexFactura(lstDesglosexTipo);
                result.Add(siiTipoDesgloseFac);

                //Por tipo desglose
                List<TipoDesglose> lstTipoDesglose = lstDesglosexTipo.Select(x => x.DesgloseTipoOperacion).Distinct().ToList();
                
                foreach (TipoDesglose tipo in lstTipoDesglose)
                {
                    List<siiFacturaDesgloses> lstDesglosesTipo = lstDesglosexTipo.Where(x => x.DesgloseTipoOperacion == tipo).ToList();

                    objDesglose objDesgloseTipo =  obtenerObjDesglose(lstDesglosesTipo);

                    objDesglosexTipo siiTipoDesglosexTipo = new objDesglosexTipo(tipo, objDesgloseTipo);
                    result.Add(siiTipoDesglosexTipo);
                }
            }
            catch
            {
                result = null;
            }

            return result;
        }






        //*************************************************************************************
        /// <summary>
        /// Conforma un objeto para rellenar "TIPODESGLOSE" del  SII agrupado por: Tipo Operacion(Entrega, Prestacion Servicios), No-Sujeta, Sujeta(Exenta, No-Exenta)
        /// </summary>
        private static List<objDesglose_v1v1> obtenerDesglosexTipo_v1v1(cFacturaSIIBO facturaSII)
        {
            List<objDesglose_v1v1> result = null;

            try
            {
                List<siiFacturaDesgloses> lstDesglosesxTipo = obtenerTotalesFacturaxTipoOperacion(facturaSII);

                List<objDesglosexTipo> siiDesglosesxTipo= obtenerDesglosexTipo(lstDesglosesxTipo);

                result = siiDesglosesxTipo.Select(x => new objDesglose_v1v1(x)).ToList();
            }
            catch
            {

            }
            return result;
        }




        //*************************************************************************************
        private class objDesglose_v1v1
        {
            public TipoDesglose TipoDesglose { get; set; }

            public BO.SII.v1.v1.NoSujetaType NoSujetasType { get; set; }
            public BO.SII.v1.v1.SujetaType SujetasType { get; set; }

            public BO.SII.v1.v1.SujetaPrestacionType SujetaPrestacionType { 
                get 
                {
                   
                    BO.SII.v1.v1.SujetaPrestacionType result = new BO.SII.v1.v1.SujetaPrestacionType();

                    if (TipoDesglose == TipoDesglose.OperacionPrestacionServicios)
                    {
                        result.NoExenta = new BO.SII.v1.v1.SujetaPrestacionTypeNoExenta();
                        result.NoExenta.TipoNoExenta = this.SujetasType.NoExenta.TipoNoExenta;
                        result.NoExenta.DesgloseIVA = this.SujetasType.NoExenta.DesgloseIVA
                                                      .Select(x => new BO.SII.v1.v1.DetalleIVAEmitidaPrestacionType
                                                      {
                                                          BaseImponible = x.BaseImponible,
                                                          CuotaRepercutida = x.CuotaRepercutida,
                                                          TipoImpositivo = x.TipoImpositivo
                                                      }).ToArray();

                        result.Exenta = this.SujetasType.Exenta;
                    }
                    return result;
                } 
            }

            /// <summary>
            /// TipoDesglose como se envia a SII segun se trate de un "DESGLOSE FACTURA" o "DESGLOSE POR TIPO DE OPERACION" 
            /// </summary>
            public objDesglose_v1v1(objDesglosexTipo desglosexTipo)
            {
                string msg;
                try
                {
                    objDesglose desglose = desglosexTipo.objDesglose;

                    int numExentas = 0;
                    int numIVA_NoExentas = 0;

                    if(desglose != null)
                    {
                        if (desglose.lstSujetaExentas != null) 
                            numExentas = desglose.lstSujetaExentas.Count();
                        if (desglose.totalSujetaNoExentas != null && desglose.totalSujetaNoExentas.lstSujetaNoExenta_DesgloseIVA != null)
                            numIVA_NoExentas = desglose.totalSujetaNoExentas.lstSujetaNoExenta_DesgloseIVA.Count;

                    }

                    if (desglose == null) return;

                    //Tipo Desglose
                    this.TipoDesglose = desglosexTipo.TipoDesgose;

                    //No-Sujetas
                    this.NoSujetasType = desglose.totalNoSujeta;

                    //Sujetas
                    if (numExentas + numIVA_NoExentas > 0)
                        this.SujetasType = new BO.SII.v1.v1.SujetaType();

                    //Sujetas: EXENTA
                    if (desglose.lstSujetaExentas.Count > 0)
                        this.SujetasType.Exenta = desglose.lstSujetaExentas.ToArray();

                    //Sujetas: NO-EXENTA
                    if (numIVA_NoExentas > 0)
                    {
                        this.SujetasType.NoExenta = new BO.SII.v1.v1.SujetaTypeNoExenta();
                        this.SujetasType.NoExenta.TipoNoExenta = (TipoOperacionSujetaNoExentaType)desglose.totalSujetaNoExentas.tipoNoExenta;
                        this.SujetasType.NoExenta.DesgloseIVA = desglose.totalSujetaNoExentas.lstSujetaNoExenta_DesgloseIVA.ToArray();
                    }
                }
                catch(Exception ex)
                {
                    msg = ex.Message;

                }
            }

        }

        private class objSujetaNoExentas
        {
            //Tipo No Exenta es único para todas las líneas
            public BO.SII.v1.v1.TipoOperacionSujetaNoExentaType? tipoNoExenta = null;
            //Importes por tipo impositivo
            public List<BO.SII.v1.v1.DetalleIVAEmitidaType> lstSujetaNoExenta_DesgloseIVA { get; set; }

            public objSujetaNoExentas(TipoOperacionSujetaNoExentaType? tipoNoExenta)
            {
                if (tipoNoExenta != null)
                {
                    this.tipoNoExenta = (TipoOperacionSujetaNoExentaType)tipoNoExenta;
                }
            }
        }

 



        //*************************************************************************************
        private enum TipoDesglose
        {
            DesgloseFactura = 0,
            OperacionEntrega = 1,
            OperacionPrestacionServicios = 2
        }

        private class objDesglose
        {
            //NO SUJETAS: Totalizan los importes en los dos grupos definidos (ImportePorArticulos7_14_Otros, ImporteTAIReglasLocal) 
            public BO.SII.v1.v1.NoSujetaType totalNoSujeta { get; set; }

            //SUJETAS EXENTAS: Importes por tipo de exencion
            public List<BO.SII.v1.v1.DetalleExentaType> lstSujetaExentas { get; set; }

            //SUJETAS NO-EXENTAS: Importes por tipo impositivo
            public objSujetaNoExentas totalSujetaNoExentas { get; set; }
        }

        private class objDesglosexTipo
        {
            public TipoDesglose TipoDesgose { get; set; }
            public objDesglose objDesglose { get; set; }

            public objDesglosexTipo(TipoDesglose tipoDesglose)
            {
                this.TipoDesgose = tipoDesglose;
            }

            public objDesglosexTipo(TipoDesglose tipoDesglose, objDesglose objDesglose)
            {
                this.TipoDesgose = tipoDesglose;
                this.objDesglose = objDesglose;
            }
        }



        //*************************************************************************************
        /// <summary>
        /// Datos que vienen de facSIIDesgloseFactura agrupando por: Tipo Operacion(Entrega, Prestacion Servicios), No-Sujeta, Sujeta(Exenta, No-Exenta)
        /// </summary>
        private class siiFacturaDesgloses
        {
            public TipoDesglose DesgloseTipoOperacion { get; set; }
            public string CausaExencion { get; set; }
            public string TipoNoExenta { get; set; }

            public decimal? TipoImpositivo { get; set; }
            public decimal? BaseImponible { get; set; }
            public decimal? CuotaRepercutida { get; set; }
            public decimal? ImportePorArticulos7_14_Otros { get; set; }
            public decimal? ImporteTAIReglasLocal { get; set; }

            public bool esSujeta
            {
                get
                {
                    return !string.IsNullOrEmpty(this.CausaExencion) || !string.IsNullOrEmpty(this.TipoNoExenta);
                }
            }

            public bool esExenta
            {
                get
                {
                    return !string.IsNullOrEmpty(this.CausaExencion);
                }
            }

            public string strBaseImponible {
                get
                {
                    return formatDecimal(this.BaseImponible);
                }

            }

            public string strCuotaRepercutida
            {
                get
                {
                    return formatDecimal(this.CuotaRepercutida);
                }

            }

            public string strTipoImpositivo
            {
                get
                {
                    return formatDecimal(this.TipoImpositivo);
                }

            }

            public string strImportePorArticulos7_14_Otros
            {
                get
                {
                    return formatDecimal(this.ImportePorArticulos7_14_Otros);
                }

            }

            public string strImporteTAIReglasLocal
            {
                get
                {
                    return formatDecimal(this.ImporteTAIReglasLocal);
                }

            }

            public CausaExencionType? causaExencionType
            {
                get
                {
                    CausaExencionType? result;

                    if (string.IsNullOrEmpty(this.CausaExencion))
                        result = null;
                    else
                        result = (CausaExencionType)Enum.Parse(typeof(CausaExencionType), this.CausaExencion);
                    
                    return result;
                }
            }

            public BO.SII.v1.v1.TipoOperacionSujetaNoExentaType? tipoOperacionSujetaNoExenta
            {
                get
                {
                    TipoOperacionSujetaNoExentaType? result;

                    if (string.IsNullOrEmpty(this.TipoNoExenta))
                        result = null;
                    else
                        result = (TipoOperacionSujetaNoExentaType)Enum.Parse(typeof(TipoOperacionSujetaNoExentaType), this.TipoNoExenta);
                    
                    return result;
                }
            }

            private string formatDecimal(decimal? valor)
            {
                string result;

                result = valor.HasValue ? valor.Value.ToString("N2").Replace(".", "").Replace(',', '.') : "0";

                return result;
            }

            public BO.SII.v1.v1.DetalleExentaType detalleExenta ()
            {
                BO.SII.v1.v1.DetalleExentaType result = null;
                try
                {
                    result =
                    new BO.SII.v1.v1.DetalleExentaType
                    {
                        BaseImponible = this.strBaseImponible,
                        CausaExencion = (CausaExencionType)this.causaExencionType,
                        CausaExencionSpecified = true
                    };
                }
                catch { }

                return result;
            }

            public BO.SII.v1.v1.DetalleIVAEmitidaType detalleIVAEmitida()
            {
                BO.SII.v1.v1.DetalleIVAEmitidaType result = null;
                try
                {
                    result =
                    new BO.SII.v1.v1.DetalleIVAEmitidaType
                    {
                        BaseImponible = this.strBaseImponible,
                        CuotaRepercutida = this.strCuotaRepercutida,
                        TipoImpositivo = this.strTipoImpositivo,
                        CuotaRecargoEquivalencia = null,
                        TipoRecargoEquivalencia = null
                    };
                }
                catch { }

                return result;
            }

            public BO.SII.v1.v1.NoSujetaType noSujetasTotal()
            {
                BO.SII.v1.v1.NoSujetaType result = null;
                try
                {
                    result =
                    new BO.SII.v1.v1.NoSujetaType
                    {
                        //Al momento de este desarrollo estas columnas solo se inicializaban a NULL en facSiiDesglose.
                        //Será necesario adaptar los triggers para que inicialicen el valor que corresponda
                        ImportePorArticulos7_14_Otros = this.strImportePorArticulos7_14_Otros,
                        ImporteTAIReglasLocalizacion = this.strImporteTAIReglasLocal
                    };
                }
                catch { }

                return result;
            }
        }

        #endregion SII_Exentas
       
    }
}