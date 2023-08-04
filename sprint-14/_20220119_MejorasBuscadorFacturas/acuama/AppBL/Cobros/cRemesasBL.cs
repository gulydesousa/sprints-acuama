using System;
using System.Text;
using BO.Cobros;
using BO.Comun;
using BO.Maestros;
using BO.Facturacion;
using BO.Sistema;
using BO.Resources;
using BO.Catastro;
using BO.Tasks;
using System.Transactions;
using BL.Catastro;
using BL.Comun;
using BL.Facturacion;
using BL.Maestros;
using BL.Sistema;
using BL.Tasks;
using DL.Cobros;
using System.Reflection;
using System.IO;
using System.Xml;
using System.Text.RegularExpressions;
using System.Diagnostics;
using DL.Sistema;

namespace BL.Cobros
{
    public class cRemesasBL
    {
        /// <summary>
        /// Genera una remesa a partir de los efectos a remesar seleccionados por el usuario
        /// Genera un String con el formato Q19 que puede ser volcado a un fichero
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="bancoCodigo">Código del banco</param>
        /// <param name="fechaCobro">Fecha de cobro</param>
        /// <param name="detallado">Fichero detallado SI/NO</param>
        /// <param name="numRemesa">Número de la remesa generada</param>
        /// <param name="log">Log</param>
        /// <param name="remesados">Número de registros remesados</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>contenido del fichero</returns>
        public String RemesarCCC(String usuarioCodigo, short bancoCodigo, DateTime fechaCobro, bool detallado, out int numRemesa, out String log, out int remesados, out cRespuesta respuesta)
        {
            return RemesarCCC(usuarioCodigo, bancoCodigo, fechaCobro, detallado, out numRemesa, out log, out remesados, out respuesta, null, null, null);
        }

        /// <summary>
        /// Método pensado para funcionar en forma de TAREA
        /// Genera una remesa a partir de los efectos a remesar seleccionados por el usuario
        /// Genera un String con el formato Q19 que puede ser volcado a un fichero
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="bancoCodigo">Código del banco</param>
        /// <param name="fechaCobro">Fecha de cobro</param>
        /// <param name="detallado">Fichero detallado SI/NO</param>
        /// <param name="numRemesa">Número de la remesa generada</param>
        /// <param name="log">Log</param>
        /// <param name="remesados">Número de registros remesados</param>
        /// <param name="respuesta">Respuesta</param>
        /// <param name="taskUser">Usuario que ejecuta la tarea</param>
        /// <param name="taskType">Tipo de tarea</param>
        /// <param name="taskNumber">Número de tarea</param>
        /// <returns>contenido del fichero</returns>
        public String RemesarCCC(String usuarioCodigo, short bancoCodigo, DateTime fechaCobro, bool detallado, out int numRemesa, out String log, out int remesados, out cRespuesta respuesta, string taskUser, ETaskType? taskType, int? taskNumber)
        {
            StringBuilder salida = new StringBuilder(String.Empty);
            log = String.Empty;
            numRemesa = 0;
            remesados = 0;

            using (TransactionScope scope = cAplicacion.NewTransactionScope())
            {
                //Actualizamos los importes antes de obtener por si a habido algún cambio.
                respuesta = ActualizarImportes();

                cBindableList<cRemesaTrabBO> efectos = new cBindableList<cRemesaTrabBO>();
                //Obtener los efectos a remesar (Mientras un usuario no haya acabado la transacción para remesar otro quedará a la espera (Ver el procedimiento almacenado))
                if (respuesta.Resultado == ResultadoProceso.OK)
                    efectos = ObtenerEfectosARemesarPorUsuario(usuarioCodigo, String.Empty, true, out respuesta);

                //Si el resultado es ERROR o SIN REGISTROS NO REALIZA LA REMESA
                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    //Establecer número de pasos de la tarea
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, efectos.Count);

                    String saltoDeLinea = Environment.NewLine;
                    cValidator validator = new cValidator();
                    int procesados = 0;
                    int contador = 0;
                    decimal totalRemesa = 0;
                    decimal pendienteFactura = 0;
                    //int xnumero = 0;

                    //Fecha (hoy)
                    DateTime fecha = AcuamaDateTime.Now;
                    string strFecha = cAplicacion.FixedLengthString(fecha.Day.ToString(), 2, '0', true, true);
                    strFecha += cAplicacion.FixedLengthString(fecha.Month.ToString(), 2, '0', true, true);
                    strFecha += cAplicacion.FixedLengthString(fecha.Year.ToString(), 2, '0', true, true);

                    //Fecha (de cobro)
                    string strFechaCobro = cAplicacion.FixedLengthString(fechaCobro.Day.ToString(), 2, '0', true, true);
                    strFechaCobro += cAplicacion.FixedLengthString(fechaCobro.Month.ToString(), 2, '0', true, true);
                    strFechaCobro += cAplicacion.FixedLengthString(fechaCobro.Year.ToString(), 2, '0', true, true);

                    //Obtener datos del banco
                    cBancoBO banco = new cBancoBO();
                    banco.Codigo = bancoCodigo;
                    cBancosBL bancosBL = new cBancosBL();
                    bancosBL.Obtener(ref banco, out respuesta);
                    numRemesa = (banco.NumRemesa ?? 0) + 1;

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return String.Empty;

                    //Guardamos el nuevo numerador de remesas en bancos
                    banco.NumRemesa = numRemesa;
                    bancosBL.Actualizar(banco, out respuesta);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return String.Empty;

                    //Obtener datos de la sociedad
                    bancosBL.ObtenerSociedad(ref banco, out respuesta);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return String.Empty;

                    //Cuenta bancaria
                    String entidad = String.Empty;
                    String oficina = String.Empty;
                    String digitoControl = String.Empty;
                    String cuenta = String.Empty;
                    if (banco.CtaBancaria != null)
                        if (banco.CtaBancaria.Length == 20)
                        {
                            entidad = banco.CtaBancaria.Substring(0, 4);
                            oficina = banco.CtaBancaria.Substring(4, 4);
                            digitoControl = banco.CtaBancaria.Substring(8, 2);
                            cuenta = banco.CtaBancaria.Substring(10, 10);
                        }

                    if (entidad == String.Empty) //ERROR
                        validator.AddCustomMessage(Resource.bancoCaja + " " + banco.Codigo + ": " + Resource.cuentaBancariaNoEsValida);

                    //Si todo está correcto comenzamos
                    log = validator.Validate(true);
                    if (log != String.Empty)
                    {
                        respuesta.Resultado = ResultadoProceso.Error;
                        return String.Empty; //Si no está correcto devolvemos cadena vacía como contenido del fichero
                    }

                    //Cabecera de presentador
                    salida.Append("51"); //Fijo (euros)
                    salida.Append("80"); //Fijo (cabecera)
                    salida.Append(cAplicacion.FixedLengthString(banco.DocIdenTituCta.Replace("-", String.Empty).Replace(" ", String.Empty), 9, '0', true, false)); //nif -> 9 dígitos
                    salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); //sufijo remesa -> 3 dígitos numéricos
                    salida.Append(strFecha); //Fecha
                    salida.Append(cAplicacion.Replicate(" ", 6)); //6 espacios en blanco
                    salida.Append(cAplicacion.FixedLengthString(banco.TitularCuenta, 40, ' ', false, true)); //Nombre --> 40 dígitos
                    salida.Append(cAplicacion.Replicate(" ", 20)); //20 espacios en blanco
                    salida.Append(entidad); //entidad -> 4 dígitos
                    salida.Append(oficina);//oficina -> 4 dígitos 
                    salida.Append(cAplicacion.Replicate(" ", 12)); //12 blancos
                    salida.Append(cAplicacion.Replicate(" ", 40));  //40 blancos
                    salida.Append(cAplicacion.Replicate(" ", 14)); //14 blancos
                    salida.Append(saltoDeLinea);

                    procesados++;

                    //Cabecera de ordenante
                    salida.Append("53"); //Fijo (euros)
                    salida.Append("80"); //Fijo (cabecera)
                    salida.Append(cAplicacion.FixedLengthString(banco.DocIdenTituCta.Replace("-", String.Empty).Replace(" ", String.Empty), 9, '0', true, false)); //nif -> 9 dígitos
                    salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); //sufijo remesa -> 3 dígitos numéricos
                    salida.Append(strFecha); //Fecha
                    salida.Append(strFechaCobro); //Fecha de cargo
                    salida.Append(cAplicacion.FixedLengthString(banco.TitularCuenta, 40, ' ', false, true)); //Nombre --> 40 dígitos
                    salida.Append(entidad); //entidad -> 4 dígitos
                    salida.Append(oficina);//oficina -> 4 dígitos 
                    salida.Append(digitoControl); //dígito control -> 2 dígitos
                    salida.Append(cuenta); //cuenta ->10 dígitos
                    salida.Append(cAplicacion.Replicate(" ", 8)); //8 blancos
                    salida.Append("01"); //procedim-> 2  (procedimiento de adeudo "01" primero y "02" segundo)
                    salida.Append(cAplicacion.Replicate(" ", 10)); //10 blancos
                    salida.Append(cAplicacion.Replicate(" ", 40));  //40 blancos
                    salida.Append(cAplicacion.Replicate(" ", 14)); //14 blancos
                    salida.Append(saltoDeLinea);

                    procesados++;

                    bool extra = false;
                    if (banco.DocIdenTituCta.Replace("-", String.Empty).Replace(" ", String.Empty) != banco.Sociedad.Nif.Replace("-", String.Empty).Replace(" ", String.Empty))
                        extra = true;

                    int i;
                    string explotacionCodigo = cParametroBL.ObtenerValor("EXPLOTACION_CODIGO");

                    //Recorro los efectos a cobrar
                    for (int contEfectos = 0; contEfectos < efectos.Count; contEfectos++)
                    {
                        cRemesaTrabBO efecto = efectos[contEfectos];

                        //Obtener el efecto pendiente a remesar si lo tiene para indicarles el usuario y fecha de remesa
                        cEfectoPendienteBO efectoPendiente = ObtenerEfectoPendienteARemesar(efecto.EfectoPdteCodigo.Value, efecto.ContratoCodigo, efecto.PeriodoCodigo, efecto.FacturaCodigo, efecto.SociedadCodigo, respuesta);

                        pendienteFactura = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;

                        //Remesamos los efectos
                        if (efecto.Pagado < efecto.FacturaTotal)
                        {
                            if (respuesta.Resultado != ResultadoProceso.OK)
                                return String.Empty;

                            //Descripciones
                            String[] lineas = new String[16];

                            i = 0;
                            if (extra) //Presentador <> Ordenante
                            {
                                lineas[i] = banco.Sociedad.Nombre + " " + banco.Sociedad.Nif;
                                i++;
                            }

                            //Inmueble
                            lineas[i] = cAplicacion.FixedLengthString(efecto.DatosParaRemesar.InmuebleDireccion + " (" + efecto.DatosParaRemesar.InmuebleMunicipio + ")", 40, ' ', false, false);
                            i++;

                            //Nº factura
                            lineas[i] = "Fra N:" + cAplicacion.FixedLengthString(efecto.DatosParaRemesar.FacturaSerie.HasValue ? efecto.DatosParaRemesar.FacturaSerie.ToString() : String.Empty, 2, '0', true, true) + "." + cAplicacion.FixedLengthString(!String.IsNullOrWhiteSpace(efecto.DatosParaRemesar.FacturaNumero) ? efecto.DatosParaRemesar.FacturaNumero : String.Empty, 6, '0', true, true) + " " + (efecto.DatosParaRemesar.FacturaFecha.HasValue ? efecto.DatosParaRemesar.FacturaFecha.Value.ToShortDateString() : cAplicacion.Replicate(" ", 10));
                            i++;

                            //Lectura anterior y actual
                            if (efecto.DatosParaRemesar.FacturaLecturaFecha.HasValue)
                            {
                                lineas[i] = "LECTURAS  Ante." + cAplicacion.Replicate(" ", 6) + "Actual" + cAplicacion.Replicate(" ", 5) + "Consumo";
                                i++;

                                StringBuilder str = new StringBuilder(String.Empty);
                                str.Append(cAplicacion.FixedLengthString(efecto.DatosParaRemesar.FacturaLecturaAnteriorFecha.HasValue ? efecto.DatosParaRemesar.FacturaLecturaAnteriorFecha.Value.ToShortDateString() : String.Empty, 5, ' ', false, false));
                                str.Append(cAplicacion.FixedLengthString(efecto.DatosParaRemesar.FacturaLecturaAnterior.HasValue ? efecto.DatosParaRemesar.FacturaLecturaAnterior.ToString() : String.Empty, 8, ' ', true, false));
                                str.Append(cAplicacion.Replicate(" ", 2));
                                str.Append(cAplicacion.FixedLengthString(efecto.DatosParaRemesar.FacturaLecturaFecha.Value.ToShortDateString(), 5, ' ', false, false));
                                str.Append(cAplicacion.FixedLengthString(efecto.DatosParaRemesar.FacturaLectura.HasValue ? efecto.DatosParaRemesar.FacturaLectura.Value.ToString() : String.Empty, 8, ' ', true, false));
                                str.Append(cAplicacion.FixedLengthString((efecto.DatosParaRemesar.FacturaConsumo.HasValue ? efecto.DatosParaRemesar.FacturaConsumo.ToString() : String.Empty) + " m3", 10, ' ', true, false));
                                lineas[i] = str.ToString();
                                i++;
                            }

                            //Total factura
                            if (efecto.Pagado == 0)
                                lineas[lineas.Length - 1] = "     TOTAL FACTURA : " + cAplicacion.FixedLengthString(efecto.FacturaTotal.ToString("N2"), 13, ' ', true, false);
                            else
                                lineas[lineas.Length - 1] = "A.CTA :" + cAplicacion.FixedLengthString(efecto.Pagado.ToString("N2"), 10, ' ', true, false) + " TOTAL :" + cAplicacion.FixedLengthString(efecto.FacturaTotal.ToString("N2"), 13, ' ', true, false);

                            //Fijamos el tamaño de las líneas a 40 caracteres
                            for (i = 0; i < lineas.Length; i++)
                                lineas[i] = cAplicacion.FixedLengthString(lineas[i], 40, ' ', false, false);

                            //Sólo remesamos si hay CCC y si es un efecto pendiente a remesar mientras no este remesado ya ni rechazado
                            if (efecto.DatosParaRemesar.ContratoCCC != null && efecto.DatosParaRemesar.ContratoCCC.Length == 20 && (efectoPendiente == null || (efectoPendiente != null && !efectoPendiente.FechaRemesada.HasValue && !efectoPendiente.FechaRechazado.HasValue)))
                            {
                                if (efectoPendiente != null)
                                {
                                    //Actualizar al efecto pendiente a remesar el usuario y fecha de remesa
                                    if (efectoPendiente.Codigo.HasValue && efectoPendiente.ContratoCodigo.HasValue && !String.IsNullOrEmpty(efectoPendiente.PeriodoCodigo) && efectoPendiente.FacturaCodigo.HasValue && efectoPendiente.SociedadCodigo.HasValue)
                                        respuesta = cEfectosPendientesBL.MarcarRemesado(usuarioCodigo, efectoPendiente.Codigo.Value, efectoPendiente.ContratoCodigo.Value, efectoPendiente.PeriodoCodigo, efectoPendiente.FacturaCodigo.Value, efectoPendiente.SociedadCodigo.Value, fecha);
                                }
                                else
                                    //Actualizamos el número y la fecha de la remesa en la tabla FACTURAS
                                    cFacturasBL.MarcarRemesada(efecto.FacturaCodigo, efecto.ContratoCodigo, efecto.PeriodoCodigo, efecto.DatosParaRemesar.FacturaVersion.Value, numRemesa, fecha, out respuesta);

                                if (respuesta.Resultado != ResultadoProceso.OK)
                                    return String.Empty;

                                //Generamos el cobro (cabecera y línea) por la remesa
                                cCobroBO cobro = new cCobroBO();
                                cobro.SociedadCodigo = banco.SociedadCodigo.Value;
                                cobro.PPagoCodigo = banco.PpagoCodigo.Value;
                                cobro.MpcCodigo = banco.MpcCodigo.Value;
                                string sCCC = String.IsNullOrEmpty(efecto.DatosParaRemesar.ContratoCCC) ? String.IsNullOrEmpty(efecto.DatosParaRemesar.ContratoIBAN) ? null : efecto.DatosParaRemesar.ContratoIBAN : efecto.DatosParaRemesar.ContratoCCC;
                                cobro.MpcDatos[0] = String.IsNullOrEmpty(sCCC) ? Resource.noHayDatos : efecto.DatosParaRemesar.ContratoCCC.Substring(0, 4);
                                cobro.MpcDatos[1] = String.IsNullOrEmpty(sCCC) ? Resource.noHayDatos : efecto.DatosParaRemesar.ContratoCCC.Substring(4, 4);
                                cobro.MpcDatos[2] = String.IsNullOrEmpty(sCCC) ? Resource.noHayDatos : efecto.DatosParaRemesar.ContratoCCC.Substring(8, 2);
                                cobro.MpcDatos[3] = String.IsNullOrEmpty(sCCC) ? Resource.noHayDatos : efecto.DatosParaRemesar.ContratoCCC.Substring(10);
                                cobro.MpcDatos[5] = efecto.DatosParaRemesar.ContratoIBAN;
                                cobro.Importe = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;
                                cobro.ContratoCodigo = efecto.ContratoCodigo;
                                cobro.FecReg = AcuamaDateTime.Now;
                                cobro.Fecha = fechaCobro;
                                cobro.DocIden = efecto.DatosParaRemesar.ContratoDocIden;
                                cobro.UsuarioCodigo = usuarioCodigo;
                                cobro.Nombre = efecto.DatosParaRemesar.ContratoNombre;
                                cobro.Concepto = cAplicacion.GetAppLangResource("remesa") + ": " + numRemesa + ". " + cAplicacion.GetAppLangResource("fecha") + ": " + fecha.ToShortDateString();
                                cobro.Origen = cCobroBO.EOrigenCobro.Remesa;
                                cCobrosBL.Insertar(ref cobro, out respuesta); //INSERTAR CABECERA COBRO

                                if (respuesta.Resultado != ResultadoProceso.OK)
                                    return String.Empty;

                                cCobroLinBO cobroLin = new cCobroLinBO();
                                cobroLin = new cCobroLinBO();
                                cobroLin.Numero = cobro.Numero;
                                cobroLin.SociedadCodigo = cobro.SociedadCodigo;
                                cobroLin.Importe = cobro.Importe;
                                cobroLin.PeriodoCodigo = efecto.PeriodoCodigo;
                                cobroLin.CodigoFactura = efecto.FacturaCodigo;
                                cobroLin.PPagoCodigo = cobro.PPagoCodigo;
                                cobroLin.VersionFactura = efecto.DatosParaRemesar.FacturaVersion.Value;
                                cCobrosLinBL.Insertar(ref cobroLin, out respuesta); //INSERTAR LÍNEA DE COBRO

                                if (respuesta.Resultado != ResultadoProceso.OK)
                                    return String.Empty;

                                pendienteFactura = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;
                                totalRemesa += pendienteFactura;
                                //referencia (código explotación + código contrato) -> 12
                                string codigoDeReferencia = cAplicacion.FixedLengthString(explotacionCodigo, 3, '0', true, false) + cAplicacion.FixedLengthString(efecto.ContratoCodigo.ToString(), 9, '0', true, false);

                                //xnumero = serie * (1000000000 / (10 elevado a (cifras de serie - 1)))
                                //xnumero = efecto.SerieCodigo * (1000000000 / (Math.Pow(10 , (efecto.SerieCodigo.ToString().Length - 1))));
                                //xnumero = xnumero + efecto.FacturaNumero;

                                //Registro individual obligatorio
                                salida.Append("56"); //fijo (euros)
                                salida.Append("80"); //fijo (cabecera)
                                /////////////////
                                salida.Append(cAplicacion.FixedLengthString(banco.DocIdenTituCta.Replace("-", String.Empty).Replace(" ", String.Empty), 9, '0', true, false)); //nif -> 9 dígitos
                                salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); //sufijo -> 3 dígitos (TODO: SUFIJO SOCIEDAD?)
                                salida.Append(codigoDeReferencia); //Código de referencia
                                salida.Append(cAplicacion.FixedLengthString(efecto.DatosParaRemesar.ContratoNombre, 40, ' ', false, false));
                                salida.Append(efecto.DatosParaRemesar.ContratoCCC.Substring(0, 4)); //Entidad
                                salida.Append(efecto.DatosParaRemesar.ContratoCCC.Substring(4, 4)); //Oficina
                                salida.Append(efecto.DatosParaRemesar.ContratoCCC.Substring(8, 2)); //Código control
                                salida.Append(efecto.DatosParaRemesar.ContratoCCC.Substring(10, 10)); //Cuenta
                                salida.Append(cAplicacion.FixedLengthString(pendienteFactura.ToString("N2").Replace(",", "").Replace(".", ""), 10, '0', true, false));
                                salida.Append(cAplicacion.FixedLengthString(cFacturasBL.CodificarPeriodoYCodigo(efecto.PeriodoCodigo, efecto.FacturaCodigo), 6, ' ', true, false));
                                salida.Append(cAplicacion.Replicate(" ", 10)); //1 en blancos
                                salida.Append(lineas[0]);
                                salida.Append(cAplicacion.Replicate(" ", 8)); //8 blancos
                                salida.Append(saltoDeLinea);

                                contador++;
                                procesados++;

                                // *********** DETALLADO *********** //
                                if (detallado)
                                {
                                    if (!String.IsNullOrWhiteSpace(lineas[8] + lineas[1] + lineas[9]))
                                    {
                                        //Registro individual opcional
                                        salida.Append("56"); //Fijo (euros)
                                        salida.Append("81"); //Fijo cabecera
                                        salida.Append(cAplicacion.FixedLengthString(banco.Sociedad.Nif, 9, ' ', true, false)); //nif -> 9
                                        salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); // sufijo -> 3 TODO:Sufijo sociedad?
                                        salida.Append(codigoDeReferencia); //Código de referencia
                                        salida.Append(lineas[8]);
                                        salida.Append(lineas[1]);
                                        salida.Append(lineas[9]);
                                        salida.Append(cAplicacion.Replicate(" ", 14)); // libre -> 14
                                        salida.Append(saltoDeLinea);

                                        procesados++;
                                    }


                                    if (!String.IsNullOrWhiteSpace(lineas[2] + lineas[10] + lineas[3]))
                                    {
                                        //Registro individual opcional
                                        salida.Append("56"); //Fijo (euros)
                                        salida.Append("82"); //Fijo cabecera
                                        salida.Append(cAplicacion.FixedLengthString(banco.Sociedad.Nif, 9, ' ', true, false)); //nif -> 9
                                        salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); // sufijo -> 3 TODO:Sufijo sociedad?
                                        salida.Append(codigoDeReferencia); //Código de referencia
                                        salida.Append(lineas[2]);
                                        salida.Append(lineas[10]);
                                        salida.Append(lineas[3]);
                                        salida.Append(cAplicacion.Replicate(" ", 14)); // libre -> 14
                                        salida.Append(saltoDeLinea);

                                        procesados++;
                                    }

                                    if (!String.IsNullOrWhiteSpace(lineas[11] + lineas[4] + lineas[2]))
                                    {
                                        //Registro individual opcional
                                        salida.Append("56"); //Fijo (euros)
                                        salida.Append("83"); //Fijo cabecera
                                        salida.Append(cAplicacion.FixedLengthString(banco.Sociedad.Nif, 9, ' ', true, false)); //nif -> 9
                                        salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); // sufijo -> 3 TODO:Sufijo sociedad?
                                        salida.Append(codigoDeReferencia); //Código de referencia
                                        salida.Append(lineas[11]);
                                        salida.Append(lineas[4]);
                                        salida.Append(lineas[12]);
                                        salida.Append(cAplicacion.Replicate(" ", 14)); // libre -> 14
                                        salida.Append(saltoDeLinea);

                                        procesados++;
                                    }

                                    if (!String.IsNullOrWhiteSpace(lineas[5] + lineas[13] + lineas[6]))
                                    {
                                        //Registro individual opcional
                                        salida.Append("56"); //Fijo (euros)
                                        salida.Append("84"); //Fijo cabecera
                                        salida.Append(cAplicacion.FixedLengthString(banco.Sociedad.Nif, 9, ' ', true, false)); //nif -> 9
                                        salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); // sufijo -> 3 TODO:Sufijo sociedad?
                                        salida.Append(codigoDeReferencia); //Código de referencia
                                        salida.Append(lineas[5]);
                                        salida.Append(lineas[13]);
                                        salida.Append(lineas[6]);
                                        salida.Append(cAplicacion.Replicate(" ", 14)); // libre -> 14
                                        salida.Append(saltoDeLinea);

                                        procesados++;
                                    }

                                    if (!String.IsNullOrWhiteSpace(lineas[14] + lineas[7] + lineas[15]))
                                    {
                                        //Registro individual opcional
                                        salida.Append("56"); //Fijo (euros)
                                        salida.Append("85"); //Fijo cabecera
                                        salida.Append(cAplicacion.FixedLengthString(banco.Sociedad.Nif, 9, ' ', true, false)); //nif -> 9
                                        salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); // sufijo -> 3 TODO:Sufijo sociedad?
                                        salida.Append(codigoDeReferencia); //Código de referencia
                                        salida.Append(lineas[14]);
                                        salida.Append(lineas[7]);
                                        salida.Append(lineas[15]);
                                        salida.Append(cAplicacion.Replicate(" ", 14)); // libre -> 14
                                        salida.Append(saltoDeLinea);

                                        procesados++;
                                    }
                                }
                            }
                            else
                            {
                                validator = new cValidator();

                                if (efecto.DatosParaRemesar.ContratoCCC == null || efecto.DatosParaRemesar.ContratoCCC.Length != 20)
                                    validator.AddCustomMessage(Resource.errorElContratoXNoTieneCodigoDeCuentaAsociada.Replace("@codigo", efecto.ContratoCodigo.ToString()).Replace("@version", efecto.DatosParaRemesar.ContratoVersion.ToString()));

                                if (efectoPendiente != null)
                                {
                                    if (efectoPendiente.FechaRemesada.HasValue)
                                        validator.AddCustomMessage(Resource.efectoPendienteRemesado.Replace("@codigo", efectoPendiente.Codigo.ToString()).Replace("@periodo", efectoPendiente.PeriodoCodigo).Replace("@contrato", efectoPendiente.ContratoCodigo.ToString()).Replace("@facCod", efectoPendiente.FacturaCodigo.ToString()));
                                    if (efectoPendiente.FechaRechazado.HasValue)
                                        validator.AddCustomMessage(Resource.efectoPendienteRechazado.Replace("@codigo", efectoPendiente.Codigo.ToString()).Replace("@periodo", efectoPendiente.PeriodoCodigo).Replace("@contrato", efectoPendiente.ContratoCodigo.ToString()).Replace("@facCod", efectoPendiente.FacturaCodigo.ToString()));
                                }

                                log += validator.Validate(true);
                            }
                        } //fin if (efecto.Pagado < efecto.FacturaTotal)

                        //Si estamos ejecutando en modo tarea...
                        if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        {
                            //Comprobar si se desea cancelar
                            if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                                return String.Empty;

                            //Incrementar el número de pasos
                            cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                        }

                    } //fin for (contEfectos=0;contEfectos<efectos.Count;contEfectos++++)


                    //Actualizamos los importes antes de obtener por si a habido algún cambio.
                    respuesta = ActualizarImportes();

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return String.Empty;

                    //Borra todos los registro de remesasTrab que ya esten cobrada y por lo tanto no deben ser remesados
                    BorrarCobrados(out respuesta);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return String.Empty;

                    //Si estamos ejecutando en modo tarea...
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    {
                        //Comprobar si se desea cancelar
                        if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            return String.Empty;
                    }

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return String.Empty;

                    //Totales presentador
                    salida.Append("58"); //Fijo (euros)
                    salida.Append("80"); //Fijo cabecera
                    salida.Append(cAplicacion.FixedLengthString(banco.DocIdenTituCta.Replace("-", String.Empty).Replace(" ", String.Empty), 9, ' ', true, false)); //nif -> 9
                    salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); // sufijo -> 3 TODO:Sufijo sociedad?
                    salida.Append(cAplicacion.Replicate(" ", 12)); //12 blancos
                    salida.Append(cAplicacion.Replicate(" ", 40)); //Nombre -> 40 blancos
                    salida.Append(cAplicacion.Replicate(" ", 20)); //20 blancos
                    salida.Append(cAplicacion.FixedLengthString(totalRemesa.ToString("N2").Replace(",", "").Replace(".", ""), 10, '0', true, false)); //importe -> 10 dígitos
                    salida.Append(cAplicacion.Replicate(" ", 6)); //6 blancos
                    salida.Append(cAplicacion.FixedLengthString(contador.ToString(), 10, '0', true, false)); //contador -> 10 dígitos
                    salida.Append(cAplicacion.FixedLengthString(procesados.ToString(), 10, '0', true, false)); //procesados -> 10 dígitos
                    salida.Append(cAplicacion.Replicate(" ", 20)); //20 blancos
                    salida.Append(cAplicacion.Replicate(" ", 18)); //18 blancos
                    salida.Append(saltoDeLinea);

                    procesados += 2; //Hay que contar el último y el que pintas

                    //cabecera del ordenante
                    salida.Append("59"); //Fijo (euros)
                    salida.Append("80"); //Fijo cabecera
                    salida.Append(cAplicacion.FixedLengthString(banco.DocIdenTituCta.Replace("-", String.Empty).Replace(" ", String.Empty), 9, ' ', true, false)); //nif -> 9
                    salida.Append(cAplicacion.FixedLengthString(banco.SufijoRemesa.ToString(), 3, '0', true, true)); // sufijo -> 3
                    salida.Append(cAplicacion.Replicate(" ", 12)); //12 blancos
                    salida.Append(cAplicacion.Replicate(" ", 40)); //Nombre -> 40 blancos
                    salida.Append("0001");
                    salida.Append(cAplicacion.Replicate(" ", 16)); //16 blancos
                    salida.Append(cAplicacion.FixedLengthString(totalRemesa.ToString("N2").Replace(",", "").Replace(".", ""), 10, '0', true, false)); //importe -> 10 dígitos
                    salida.Append(cAplicacion.Replicate(" ", 6)); //6 blancos
                    salida.Append(cAplicacion.FixedLengthString(contador.ToString(), 10, '0', true, false)); // -> 10 dígitos
                    salida.Append(cAplicacion.FixedLengthString(procesados.ToString(), 10, '0', true, false)); // -> 10 dígitos
                    salida.Append(cAplicacion.Replicate(" ", 20)); //20 blancos
                    salida.Append(cAplicacion.Replicate(" ", 18)); //18 blancos
                    salida.Append(saltoDeLinea);

                    remesados = contador;

                    //SI TODO SE HA PROCESADO CORRECTEMENTE BORRO LOS DATOS DE LA TABLA TEMPORAL
                    BorrarEfectosPorUsuario(usuarioCodigo, out respuesta);

                    if (respuesta.Resultado == ResultadoProceso.Error)
                        return String.Empty;

                    //Si estamos ejecutando en modo tarea...
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    {
                        //Comprobar si se desea cancelar
                        if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            return String.Empty;
                    }

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return String.Empty;

                    //Si la ejecución llega hasta aquí, es porque todo está correcto. Finalizamos la transacción (COMMIT).
                    scope.Complete();

                } //Fin if(Respuesta.Resultado == OK)
            } //Fin TransactionScope

            return salida.ToString();
        }

        /// <summary>
        /// Convertir string a una cadena válida ISO20022
        /// </summary>
        /// <param name="valor">Valor a convertir</param>
        /// <returns>Valor convertido</returns>
        public String ConvertirAISO20022(string valor)
        {
            //Reemplazar acentos

            Regex replace_a_Accents = new Regex("[á|à|ä|â]", RegexOptions.Compiled);
            Regex replace_e_Accents = new Regex("[é|è|ë|ê]", RegexOptions.Compiled);
            Regex replace_i_Accents = new Regex("[í|ì|ï|î]", RegexOptions.Compiled);
            Regex replace_o_Accents = new Regex("[ó|ò|ö|ô]", RegexOptions.Compiled);
            Regex replace_u_Accents = new Regex("[ú|ù|ü|û]", RegexOptions.Compiled);

            Regex replace_A_Accents = new Regex("[Á|À|Ä|Â]", RegexOptions.Compiled);
            Regex replace_E_Accents = new Regex("[É|È|Ë|Ê]", RegexOptions.Compiled);
            Regex replace_I_Accents = new Regex("[Í|Ì|Ï|Î]", RegexOptions.Compiled);
            Regex replace_O_Accents = new Regex("[Ó|Ò|Ö|Ô]", RegexOptions.Compiled);
            Regex replace_U_Accents = new Regex("[Ú|Ù|Ü|Û]", RegexOptions.Compiled);

            valor = replace_a_Accents.Replace(valor, "a");
            valor = replace_e_Accents.Replace(valor, "e");
            valor = replace_i_Accents.Replace(valor, "i");
            valor = replace_o_Accents.Replace(valor, "o");
            valor = replace_u_Accents.Replace(valor, "u");

            valor = replace_A_Accents.Replace(valor, "A");
            valor = replace_E_Accents.Replace(valor, "E");
            valor = replace_I_Accents.Replace(valor, "I");
            valor = replace_O_Accents.Replace(valor, "O");
            valor = replace_U_Accents.Replace(valor, "U");

            String resultado = String.Empty;

            bool existe = false;
            string valoresPermitidos = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/-?:().,‘+ ";

            for (int i = 0; i < valor.Length; i++)
            {
                existe = false;
                for (int j = 0; j < valoresPermitidos.Length && existe == false; j++) { if (valoresPermitidos[j] == valor[i]) existe = true; }
                if (!existe)
                {
                    switch (valor[i])
                    {
                        case 'Ñ': resultado += "N"; break;
                        case 'ñ': resultado += "n"; break;
                        case 'Ç': resultado += "C"; break;
                        case 'ç': resultado += "c"; break;
                        case '"': resultado += "&quot;"; break;
                        case '\'': resultado += "&apos;"; break;
                        case '<': resultado += "&lt;"; break;
                        case '>': resultado += "&gt;"; break;
                        case '&': resultado += "&amp;"; break;
                        default: resultado += " "; break;
                    }
                }
                else
                    resultado += valor[i];
            }

            return resultado;
        }

       
        public String RemesarIBAN_Task(String usuarioCodigo, short bancoCodigo, DateTime fechaCobro, bool detallado, out int numRemesa, out String log, out int remesados, out cRespuesta respuesta, string taskUser = null, ETaskType? taskType=null, int? taskNumber=null)
        {
            string metodoRemesa = string.Empty;
            string versionRemesa = obtenerVersionRemesa(out respuesta);
            string result = string.Empty;

            DateTime fInicio = DateTime.Now;
            string mensaje = "REMESA_VERSION: " + versionRemesa;

            switch (versionRemesa)
            {
                case "2.0":
                    metodoRemesa = RemesaLogging(LogRemesa.INICIO, "RemesarIBAN_V2", mensaje);
                    result = RemesarIBAN_V2(usuarioCodigo, bancoCodigo, fechaCobro, detallado, out numRemesa, out log, out remesados, out respuesta, taskUser, taskType, taskNumber);
                    break;
                default:
                    metodoRemesa = RemesaLogging(LogRemesa.INICIO, "RemesarIBAN", mensaje);
                    result = RemesarIBAN(usuarioCodigo, bancoCodigo, fechaCobro, detallado, out numRemesa, out log, out remesados, out respuesta, taskUser, taskType, taskNumber);
                    break;
            }

            DateTime fFin = DateTime.Now;
            string tEjecucion = Math.Round(fFin.Subtract(fInicio).TotalMilliseconds * 0.001, 2, MidpointRounding.AwayFromZero).ToString();
            mensaje = string.Format("{0} | Remesados: {1} | Ejecución: {2} seg.", mensaje, remesados, tEjecucion);

            RemesaLogging(LogRemesa.FIN, metodoRemesa, mensaje);
            return result;
        }

        /// <summary>
        /// Método pensado para funcionar en forma de TAREA
        /// Genera una remesa a partir de los efectos a remesar seleccionados por el usuario
        /// Genera un String con el formato C19.14 que puede ser volcado a un fichero
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="bancoCodigo">Código del banco</param>
        /// <param name="fechaCobro">Fecha de cobro</param>
        /// <param name="detallado">Fichero detallado SI/NO</param>
        /// <param name="numRemesa">Número de la remesa generada</param>
        /// <param name="log">Log</param>
        /// <param name="remesados">Número de registros remesados</param>
        /// <param name="respuesta">Respuesta</param>
        /// <param name="taskUser">Usuario que ejecuta la tarea</param>
        /// <param name="taskType">Tipo de tarea</param>
        /// <param name="taskNumber">Número de tarea</param>
        /// <returns>contenido del fichero</returns>
        public String RemesarIBAN(String usuarioCodigo, short bancoCodigo, DateTime fechaCobro, bool detallado, out int numRemesa, out String log, out int remesados, out cRespuesta respuesta, string taskUser, ETaskType? taskType, int? taskNumber)
        {
            StringBuilder salida = new StringBuilder(String.Empty);
            log = String.Empty;
            numRemesa = 0;
            remesados = 0;

            using (TransactionScope scope = cAplicacion.NewTransactionScope())
            {
                //Actualizamos los importes antes de obtener por si ha habido algún cambio.
                respuesta = ActualizarImportes();

                cBindableList<cRemesaTrabBO> efectos = new cBindableList<cRemesaTrabBO>();
                //Obtener los efectos a remesar (Mientras un usuario no haya acabado la transacción para remesar otro quedará a la espera (Ver el procedimiento almacenado))
                if (respuesta.Resultado == ResultadoProceso.OK)
                    efectos = ObtenerEfectosARemesarPorUsuario(usuarioCodigo, String.Empty, true, out respuesta);

                //Si el resultado es ERROR o SIN REGISTROS no realiza la remesa
                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    //Establecer número de pasos de la tarea
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, efectos.Count);

                    cValidator validator = new cValidator();
                    decimal pendienteFactura = 0;
                    decimal totalRemesa = 0;
                    DateTime fecha = AcuamaDateTime.Now;

                    //Obtener datos del banco
                    cBancoBO banco = new cBancoBO();
                    banco.Codigo = bancoCodigo;
                    new cBancosBL().Obtener(ref banco, out respuesta);
                    numRemesa = (banco.NumRemesa ?? 0) + 1;

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return null;

                    //Guardamos el nuevo numerador de remesas en bancos
                    banco.NumRemesa = numRemesa;
                    new cBancosBL().Actualizar(banco, out respuesta);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return null;

                    //Obtener datos de la sociedad
                    new cBancosBL().ObtenerSociedad(ref banco, out respuesta);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return null;

                    //Cuenta bancaria
                    String entidad = String.Empty;
                    String oficina = String.Empty;
                    if (banco.CtaBancaria != null)
                        if (banco.CtaBancaria.Length == 20)
                        {
                            entidad = banco.CtaBancaria.Substring(0, 4);
                            oficina = banco.CtaBancaria.Substring(4, 4);
                        }

                    if (entidad == String.Empty) // Error
                        validator.AddCustomMessage(Resource.bancoCaja + " " + banco.Codigo + ": " + Resource.cuentaBancariaNoEsValida);

                    string identificadorAcreedor = null;
                    string sufijo = null;
                    respuesta = cParametroBL.GetString("SUFIJO", out sufijo);

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        cMandatosBL.GenerarIdentificadorAcreedor(cAplicacion.FixedLengthString(sufijo, 3, '0', true, true), "ES", out identificadorAcreedor);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        validator.AddCustomMessage(Resource.errorIdentificadorAcreedor);

                    //Si todo está correcto comenzamos
                    log = validator.Validate(true);
                    if (log != String.Empty)
                    {
                        respuesta.Resultado = ResultadoProceso.Error;
                        return null; //Si no está correcto devolvemos cadena vacía como contenido del fichero
                    }

                    StringWriter sw = new StringWriter(new StringBuilder(String.Empty));
                    XmlTextWriter xmlWriter = new XmlTextWriter(sw);
                    xmlWriter.Formatting = Formatting.Indented;
                    xmlWriter.Indentation = 3;

                    xmlWriter.WriteProcessingInstruction("xml", "version=\"1.0\" encoding=\"utf-8\"");
                    xmlWriter.WriteStartElement("Document");
                    xmlWriter.WriteAttributeString("xmlns", "urn:iso:std:iso:20022:tech:xsd:pain.008.001.02");
                    xmlWriter.WriteAttributeString("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
                    xmlWriter.WriteStartElement("CstmrDrctDbtInitn");
                    xmlWriter.WriteStartElement("GrpHdr");
                    xmlWriter.WriteStartElement("MsgId"); xmlWriter.WriteString("Remesa:" + numRemesa.ToString() + " (Fecha:" + String.Format("{0:yyyy-MM-dd}", fecha) + ")"); xmlWriter.WriteEndElement(); //identificador del fichero
                    xmlWriter.WriteStartElement("CreDtTm"); xmlWriter.WriteString(String.Format("{0:s}", fecha)); xmlWriter.WriteEndElement(); // Fecha del fichero
                    xmlWriter.WriteStartElement("NbOfTxs"); xmlWriter.WriteEndElement(); // Número de operaciones
                    xmlWriter.WriteStartElement("CtrlSum"); xmlWriter.WriteEndElement(); // Suma de todos los importes
                    xmlWriter.WriteStartElement("InitgPty");
                    xmlWriter.WriteStartElement("Nm"); xmlWriter.WriteString(ConvertirAISO20022(banco.TitularCuenta)); xmlWriter.WriteEndElement(); // Nombre del acreedor
                    xmlWriter.WriteStartElement("Id");
                    xmlWriter.WriteStartElement("OrgId");
                    xmlWriter.WriteStartElement("Othr");
                    xmlWriter.WriteStartElement("Id"); xmlWriter.WriteString(identificadorAcreedor); xmlWriter.WriteEndElement(); // Identificador del acreedor
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("PmtInf");
                    xmlWriter.WriteStartElement("PmtInfId"); xmlWriter.WriteString("Remesa:" + numRemesa.ToString() + " (Fecha:" + String.Format("{0:yyyy-MM-dd}", fecha) + ")"); xmlWriter.WriteEndElement(); // El mismo identificador del fichero, ya que solo hay un acreedor y una fecha de cobro
                    xmlWriter.WriteStartElement("PmtMtd"); xmlWriter.WriteString("DD"); xmlWriter.WriteEndElement(); // Por defecto 'DD', solo de admite este DirectDebit

                    if (cParametroBL.ObtenerValor("EXPLOTACION") == "AVG")
                    {
                        xmlWriter.WriteStartElement("BtchBookg"); xmlWriter.WriteString("true"); xmlWriter.WriteEndElement();
                        xmlWriter.WriteStartElement("NbOfTxs"); xmlWriter.WriteEndElement(); // Número de operaciones
                        xmlWriter.WriteStartElement("CtrlSum"); xmlWriter.WriteEndElement(); // Suma de todos los importes
                    }
                    xmlWriter.WriteStartElement("PmtTpInf");
                    xmlWriter.WriteStartElement("SvcLvl");
                    xmlWriter.WriteStartElement("Cd"); xmlWriter.WriteString("SEPA"); xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("LclInstrm");
                    xmlWriter.WriteStartElement("Cd"); xmlWriter.WriteString("CORE"); xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("SeqTp"); xmlWriter.WriteString("RCUR"); xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("ReqdColltnDt"); xmlWriter.WriteString(String.Format("{0:yyyy-MM-dd}", fechaCobro)); xmlWriter.WriteEndElement(); // Fecha del cobro
                    xmlWriter.WriteStartElement("Cdtr");
                    xmlWriter.WriteStartElement("Nm"); xmlWriter.WriteString(ConvertirAISO20022(banco.TitularCuenta)); xmlWriter.WriteEndElement(); // Nombre del acreedor
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("CdtrAcct");
                    xmlWriter.WriteStartElement("Id");
                    xmlWriter.WriteStartElement("IBAN"); xmlWriter.WriteString(banco.Iban); xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("Ccy"); xmlWriter.WriteString("EUR"); xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("CdtrAgt");
                    xmlWriter.WriteStartElement("FinInstnId");
                    xmlWriter.WriteStartElement("BIC"); xmlWriter.WriteString(banco.Bic); xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteStartElement("CdtrSchmeId");
                    xmlWriter.WriteStartElement("Id");
                    xmlWriter.WriteStartElement("PrvtId");
                    xmlWriter.WriteStartElement("Othr");
                    xmlWriter.WriteStartElement("Id"); xmlWriter.WriteString(identificadorAcreedor); xmlWriter.WriteEndElement(); // Identificador del acreedor
                    xmlWriter.WriteStartElement("SchmeNm");
                    xmlWriter.WriteStartElement("Prtry"); xmlWriter.WriteString("SEPA"); xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();

                    //Recorro los efectos a cobrar
                    for (int contEfectos = 0; contEfectos < efectos.Count; contEfectos++)
                    {
                        cRemesaTrabBO efecto = efectos[contEfectos];

                        //Obtener el efecto pendiente a remesar si lo tiene para indicarles el usuario y fecha de remesa
                        cEfectoPendienteBO efectoPendiente = ObtenerEfectoPendienteARemesar(efecto.EfectoPdteCodigo.Value, efecto.ContratoCodigo, efecto.PeriodoCodigo, efecto.FacturaCodigo, efecto.SociedadCodigo, respuesta);

                        Debug.Print("efecto.EfectoPdteCodigo.Value" + efecto.EfectoPdteCodigo.Value + "efecto.ContratoCodigo" + efecto.ContratoCodigo.ToString());


                        pendienteFactura = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;

                        //Remesamos los efectos
                        if (efecto.Pagado < efecto.FacturaTotal)
                        {
                            if (respuesta.Resultado != ResultadoProceso.OK)
                                return null;

                            //Sólo remesamos si hay CCC o IBAN/BIC y si es un efecto pendiente a remesar mientras no este remesado ya ni rechazado
                            if (efecto.DatosParaRemesar.ContratoIBAN != null && efecto.DatosParaRemesar.ContratoBIC != null && (efecto.DatosParaRemesar.ContratoBIC.Length == 11 || efecto.DatosParaRemesar.ContratoBIC.Length == 8) && efecto.DatosParaRemesar.ContratoBIC.Length <= 34 && (efectoPendiente == null || (efectoPendiente != null && !efectoPendiente.FechaRemesada.HasValue && !efectoPendiente.FechaRechazado.HasValue)))
                            {
                                //Obtenemos el mandato para realizar comprobaciones y comprobar que es correcto y se puede remesar
                                string referenciaMandato = efectoPendiente != null ? efectoPendiente.ReferenciaMandato : efecto.DatosParaRemesar.ReferenciaMandato;
                                cMandatoBO mandato = cMandatosBL.Obtener(referenciaMandato, out respuesta);

                                if (respuesta.Resultado == ResultadoProceso.Error)
                                    return null;

                                //Si existe un efecto a remesar con un contrato-versión anulada y mandato también se debe remesar
                                /*
                                bool esContratoAnulado = false;
                                cContratoBO ctr = new cContratoBO();
                                ctr.Codigo = efecto.ContratoCodigo;
                                ctr.Version = efecto.DatosParaRemesar.ContratoVersion.Value;
                                cContratoBL.Obtener(ref ctr, out respuesta);
                                if (respuesta.Resultado == ResultadoProceso.OK && ctr != null)
                                    esContratoAnulado = ctr.FAnulacion.HasValue;
                                //Almacenamos el estado original del mandato actual en una variable auxiliar para después restaurarlo con su valor correcto
                                cMandatoBO.EEstado estadoAux = mandato.EstadoActual;
                                //Cambiamos temporalmente el estado acutal del mandato a "Activo" siempre que se cumplan todas las condiciones para ello
                                mandato.EstadoActual = (esContratoAnulado && mandato.Referencia == ctr.ReferenciaMandato && mandato.EstadoActual == cMandatoBO.EEstado.Anulado) ? cMandatoBO.EEstado.Activo : mandato.EstadoActual;
                                */
                                //Comprobamos que los datos del mandato sean correctos para remesar el adeudo
                                if (respuesta.Resultado == ResultadoProceso.SinRegistros || (respuesta.Resultado == ResultadoProceso.OK && (!mandato.FechaFirma.HasValue || (mandato.EstadoActual != cMandatoBO.EEstado.Activo && mandato.EstadoActual != cMandatoBO.EEstado.Registrado) || (mandato.FechaUltimoUso.HasValue && ((fecha.Date.Month - mandato.FechaUltimoUso.Value.Month) + (12 * (fecha.Date.Year - mandato.FechaUltimoUso.Value.Year))) > 36))))
                                {
                                    //mandato.EstadoActual = estadoAux;
                                    //Actualizar la fecha de última modificación del mandato para mandatos caducados
                                    if (respuesta.Resultado == ResultadoProceso.OK && mandato.FechaUltimoUso.HasValue && ((fecha.Date.Month - mandato.FechaUltimoUso.Value.Month) + (12 * (fecha.Date.Year - mandato.FechaUltimoUso.Value.Year))) > 36)
                                    {
                                        mandato.FechaUltimaMod = fecha;
                                        mandato.EstadoActual = cMandatoBO.EEstado.Obsoleto;
                                        respuesta = cMandatosBL.Actualizar(mandato);
                                    }

                                    if (respuesta.Resultado == ResultadoProceso.Error)
                                        return null;

                                    validator = new cValidator();
                                    validator.AddCustomMessage(Resource.ErrorMandatoNoValido.Replace("@contrato", efecto.ContratoCodigo.ToString()).Replace("@version", efecto.DatosParaRemesar.ContratoVersion.ToString()));
                                    log += validator.Validate(true);
                                    respuesta.Resultado = ResultadoProceso.OK;
                                }
                                else
                                {
                                    //mandato.EstadoActual = estadoAux;
                                    //Comprobar si se modifico el mandato tras el último uso de él
                                    bool mandatoModificado = mandato.FechaUltimoUso.HasValue && mandato.FechaUltimaMod.HasValue ? (mandato.FechaUltimaMod > mandato.FechaUltimoUso ? true : false) : false;
                                    //Actualizar la fecha de última modificación del mandato.
                                    mandato.FechaUltimoUso = fecha;

                                    if (cMandatosBL.Actualizar(mandato).Resultado != ResultadoProceso.OK)
                                        return null;

                                    if (efectoPendiente != null)
                                    {
                                        //Actualizar al efecto pendiente a remesar el usuario y fecha de remesa
                                        if (efectoPendiente.Codigo.HasValue && efectoPendiente.ContratoCodigo.HasValue && !String.IsNullOrEmpty(efectoPendiente.PeriodoCodigo) && efectoPendiente.FacturaCodigo.HasValue && efectoPendiente.SociedadCodigo.HasValue)
                                            respuesta = cEfectosPendientesBL.MarcarRemesado(usuarioCodigo, efectoPendiente.Codigo.Value, efectoPendiente.ContratoCodigo.Value, efectoPendiente.PeriodoCodigo, efectoPendiente.FacturaCodigo.Value, efectoPendiente.SociedadCodigo.Value, fecha);
                                    }
                                    else
                                        //Actualizamos el número y la fecha de la remesa en la tabla FACTURAS
                                        cFacturasBL.MarcarRemesada(efecto.FacturaCodigo, efecto.ContratoCodigo, efecto.PeriodoCodigo, efecto.DatosParaRemesar.FacturaVersion.Value, numRemesa, fecha, out respuesta);

                                    if (respuesta.Resultado != ResultadoProceso.OK)
                                        return null;

                                    //Generamos el cobro (cabecera y línea) por la remesa
                                    cCobroBO cobro = new cCobroBO();
                                    cobro.SociedadCodigo = banco.SociedadCodigo.Value;
                                    cobro.PPagoCodigo = banco.PpagoCodigo.Value;
                                    cobro.MpcCodigo = banco.MpcCodigo.Value;
                                    //TODO: En los datos de los cobros se le indica al CCC que "no hay datos", si no tiene CCC al ser obligatorio el campo. Posteriormente cuando se implante por completo el IBAN habrá que quitar
                                    // el CCC de los datos de los medios de pago del cobro
                                    cIBANBO Iban = new cIBANBO(efecto.DatosParaRemesar.ContratoIBAN);
                                    cobro.MpcDatos[0] = Iban.Entidad;         // cobMpcDato1
                                    cobro.MpcDatos[1] = Iban.Oficina;         // cobMpcDato2
                                    cobro.MpcDatos[2] = Iban.DigitosControl;  // cobMpcDato3
                                    cobro.MpcDatos[3] = Iban.NumeroCuenta;    // cobMpcDato4
                                    cobro.MpcDatos[5] = Iban.IBAN;            // cobMpcDato6
                                    cobro.Importe = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;
                                    cobro.ContratoCodigo = efecto.ContratoCodigo;
                                    cobro.FecReg = AcuamaDateTime.Now;
                                    cobro.Fecha = fechaCobro;
                                    cobro.DocIden = efecto.DatosParaRemesar.ContratoDocIden;
                                    cobro.UsuarioCodigo = usuarioCodigo;
                                    cobro.Nombre = efecto.DatosParaRemesar.ContratoNombre;
                                    cobro.Concepto = cAplicacion.GetAppLangResource("remesa") + ": " + numRemesa + ". " + cAplicacion.GetAppLangResource("fecha") + ": " + fecha.ToShortDateString();
                                    cobro.Origen = cCobroBO.EOrigenCobro.Remesa;
                                    cCobrosBL.Insertar(ref cobro, out respuesta); //INSERTAR CABECERA COBRO

                                    if (respuesta.Resultado != ResultadoProceso.OK)
                                        return null;

                                    cCobroLinBO cobroLin = new cCobroLinBO();
                                    cobroLin = new cCobroLinBO();
                                    cobroLin.Numero = cobro.Numero;
                                    cobroLin.SociedadCodigo = cobro.SociedadCodigo;
                                    cobroLin.Importe = cobro.Importe;
                                    cobroLin.PeriodoCodigo = efecto.PeriodoCodigo;
                                    cobroLin.CodigoFactura = efecto.FacturaCodigo;
                                    cobroLin.PPagoCodigo = cobro.PPagoCodigo;
                                    cobroLin.VersionFactura = efecto.DatosParaRemesar.FacturaVersion.Value;
                                    cCobrosLinBL.Insertar(ref cobroLin, out respuesta); //Insertar línea de cobro

                                    if (respuesta.Resultado != ResultadoProceso.OK)
                                        return null;

                                    pendienteFactura = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;
                                    totalRemesa += pendienteFactura;

                                    xmlWriter.WriteStartElement("DrctDbtTxInf");
                                    xmlWriter.WriteStartElement("PmtId");
                                    xmlWriter.WriteStartElement("EndToEndId"); xmlWriter.WriteString(cobro.Numero.ToString() + "-" + cobro.PPagoCodigo.ToString() + "-" + efecto.PeriodoCodigo + "-" + efecto.FacturaCodigo.ToString() + "-" + efecto.ContratoCodigo.ToString() + (efecto.EfectoPendiente != null ? efecto.EfectoPendiente.Codigo.ToString() : String.Empty)); xmlWriter.WriteEndElement(); //Dato que referencia al adeudo
                                    xmlWriter.WriteEndElement();
                                    xmlWriter.WriteStartElement("InstdAmt"); xmlWriter.WriteAttributeString("Ccy", "EUR"); xmlWriter.WriteString(pendienteFactura.ToString("N2").Replace(".", "").Replace(",", ".")); xmlWriter.WriteEndElement();
                                    xmlWriter.WriteStartElement("DrctDbtTx");
                                    xmlWriter.WriteStartElement("MndtRltdInf");
                                    xmlWriter.WriteStartElement("MndtId"); xmlWriter.WriteString(mandato.Referencia); xmlWriter.WriteEndElement();
                                    xmlWriter.WriteStartElement("DtOfSgntr"); xmlWriter.WriteString(String.Format("{0:yyyy-MM-dd}", mandato.FechaFirma)); xmlWriter.WriteEndElement();
                                    xmlWriter.WriteStartElement("AmdmntInd"); xmlWriter.WriteString(mandatoModificado.ToString().ToLower()); xmlWriter.WriteEndElement();
                                    xmlWriter.WriteEndElement();
                                    xmlWriter.WriteEndElement();
                                    xmlWriter.WriteStartElement("DbtrAgt");
                                    xmlWriter.WriteStartElement("FinInstnId");
                                    xmlWriter.WriteStartElement("BIC"); xmlWriter.WriteString(efecto.DatosParaRemesar.ContratoBIC); xmlWriter.WriteEndElement();
                                    xmlWriter.WriteEndElement();
                                    xmlWriter.WriteEndElement();
                                    xmlWriter.WriteStartElement("Dbtr");
                                    xmlWriter.WriteStartElement("Nm"); xmlWriter.WriteString(ConvertirAISO20022(efecto.DatosParaRemesar.ContratoNombre)); xmlWriter.WriteEndElement(); // Nombre del deudor
                                    xmlWriter.WriteEndElement();
                                    xmlWriter.WriteStartElement("DbtrAcct");
                                    xmlWriter.WriteStartElement("Id");
                                    xmlWriter.WriteStartElement("IBAN"); xmlWriter.WriteString(efecto.DatosParaRemesar.ContratoIBAN); xmlWriter.WriteEndElement();
                                    xmlWriter.WriteEndElement();
                                    xmlWriter.WriteEndElement();
                                    if (detallado)
                                    {
                                        //Datos de la serie, número y fecha de factura
                                        string datosPrimariosFactura = "FRA.NUM.:" + cAplicacion.FixedLengthString(efecto.DatosParaRemesar.FacturaSerie.HasValue ? efecto.DatosParaRemesar.FacturaSerie.ToString() : String.Empty, 2, '0', true, true) + "." + (!String.IsNullOrWhiteSpace(efecto.DatosParaRemesar.FacturaNumero) ? efecto.DatosParaRemesar.FacturaNumero : String.Empty) + " " + (efecto.DatosParaRemesar.FacturaFecha.HasValue ? efecto.DatosParaRemesar.FacturaFecha.Value.ToShortDateString() : String.Empty) + ", ";

                                        //Datos de lectura anterior y actual de la factura
                                        string datosLecturaFactura = String.Empty;
                                        if (efecto.DatosParaRemesar.FacturaLecturaFecha.HasValue)
                                        {
                                            datosLecturaFactura = "Lecturas:" +
                                            " Anterior: " + (efecto.DatosParaRemesar.FacturaLecturaAnteriorFecha.HasValue ? efecto.DatosParaRemesar.FacturaLecturaAnteriorFecha.Value.ToString("dd/MM") : String.Empty) + " " + (efecto.DatosParaRemesar.FacturaLecturaAnterior.HasValue ? efecto.DatosParaRemesar.FacturaLecturaAnterior.ToString() : String.Empty) + "," +
                                            " Actual: " + (efecto.DatosParaRemesar.FacturaLecturaFecha.Value.ToString("dd/MM")) + " " + (efecto.DatosParaRemesar.FacturaLectura.HasValue ? efecto.DatosParaRemesar.FacturaLectura.Value.ToString() : String.Empty) + "," +
                                            " Cns.: " + (efecto.DatosParaRemesar.FacturaConsumo.HasValue ? efecto.DatosParaRemesar.FacturaConsumo.ToString() : String.Empty) + "m3" +
                                            ", ";
                                        }

                                        //Datos de importes de la factura    
                                        string datosImportesFactura = String.Empty;
                                        if (efecto.Pagado == 0)
                                            datosImportesFactura = "TOTAL: " + efecto.FacturaTotal.ToString("N2");
                                        else
                                            datosImportesFactura = "A.CTA:" + efecto.Pagado.ToString("N2") + " TOTAL: " + efecto.FacturaTotal.ToString("N2");

                                        xmlWriter.WriteStartElement("RmtInf");
                                        xmlWriter.WriteStartElement("Ustrd"); xmlWriter.WriteString(datosPrimariosFactura + datosLecturaFactura + datosImportesFactura); xmlWriter.WriteEndElement(); // Datos de ampliación del adeudo
                                        xmlWriter.WriteEndElement();
                                    }
                                    xmlWriter.WriteEndElement();

                                    remesados = remesados + 1;
                                }
                            }
                            else
                            {
                                if (efecto.DatosParaRemesar.ContratoIBAN == null || efecto.DatosParaRemesar.ContratoBIC == null || (efecto.DatosParaRemesar.ContratoBIC.Length != 11 && efecto.DatosParaRemesar.ContratoBIC.Length != 8) || efecto.DatosParaRemesar.ContratoIBAN.Length > 34)
                                    validator.AddCustomMessage(Resource.errorElContratoXNoTieneCodigoDeCuentaAsociada.Replace("@codigo", efecto.ContratoCodigo.ToString()).Replace("@version", efecto.DatosParaRemesar.ContratoVersion.ToString()));

                                if (efectoPendiente != null)
                                {
                                    if (efectoPendiente.FechaRemesada.HasValue)
                                        validator.AddCustomMessage(Resource.efectoPendienteRemesado.Replace("@codigo", efectoPendiente.Codigo.ToString()).Replace("@periodo", efectoPendiente.PeriodoCodigo).Replace("@contrato", efectoPendiente.ContratoCodigo.ToString()).Replace("@facCod", efectoPendiente.FacturaCodigo.ToString()));
                                    if (efectoPendiente.FechaRechazado.HasValue)
                                        validator.AddCustomMessage(Resource.efectoPendienteRechazado.Replace("@codigo", efectoPendiente.Codigo.ToString()).Replace("@periodo", efectoPendiente.PeriodoCodigo).Replace("@contrato", efectoPendiente.ContratoCodigo.ToString()).Replace("@facCod", efectoPendiente.FacturaCodigo.ToString()));
                                }

                                log += validator.Validate(true);
                            }
                        } //fin if (efecto.Pagado < efecto.FacturaTotal)

                        //Si estamos ejecutando en modo tarea...
                        if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        {
                            //Comprobar si se desea cancelar
                            if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                                return null;

                            //Incrementar el número de pasos
                            cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                        }

                    } //fin for (contEfectos=0;contEfectos<efectos.Count;contEfectos++++)


                    //Actualizamos los importes antes de obtener por si ha habido algún cambio.
                    respuesta = ActualizarImportes();

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return null;

                    //Borra todos los registro de remesasTrab que ya esten cobrados y por lo tanto no deben ser remesados
                    BorrarCobrados(out respuesta);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return null;

                    //Si estamos ejecutando en modo tarea...
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    {
                        //Comprobar si se desea cancelar
                        if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            return null;
                    }

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return null;

                    //SI TODO SE HA PROCESADO CORRECTEMENTE BORRO LOS DATOS DE LA TABLA TEMPORAL
                    BorrarEfectosPorUsuario(usuarioCodigo, out respuesta);

                    if (respuesta.Resultado == ResultadoProceso.Error)
                        return null;

                    //Si estamos ejecutando en modo tarea...
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                    {
                        //Comprobar si se desea cancelar
                        if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            return null;
                    }

                    if (respuesta.Resultado != ResultadoProceso.OK)
                        return null;

                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.WriteEndElement();
                    xmlWriter.Close();
                    sw.Close();

                    salida.Append(sw.ToString());

                    //Actualizar datos posteriormente calculados
                    salida.Replace("<NbOfTxs />", "<NbOfTxs>" + remesados + "</NbOfTxs>");
                    salida.Replace("<CtrlSum />", "<CtrlSum>" + totalRemesa.ToString("N2").Replace(".", "").Replace(",", ".") + "</CtrlSum>");

                    // Ya realizado la conversión a ISO20022, debemos deshacer los cambios que hace la generación del XML porque ya se hacen los cambios oportunos al convertirlo
                    // Por ejemplo al convertir el & a &amp; el XML lo volverá a convertir quedando &ampamp; y eso no debe ser así.

                    salida.Replace("&amp;quot;", "&quot;");
                    salida.Replace("&amp;apos;", "&apos;");
                    salida.Replace("&amp;lt;", "&lt;");
                    salida.Replace("&amp;gt;", "&gt;");
                    salida.Replace("&amp;amp;", "&amp;");

                    //Si la ejecución llega hasta aquí, es porque todo está correcto. Finalizamos la transacción (COMMIT).
                    scope.Complete();

                } //Fin if(Respuesta.Resultado == OK)
            } //Fin TransactionScope

            return salida.ToString();
        }

        /// <summary>
        /// Obtiene el efecto pendiente a remesar desde la remesa
        /// </summary>
        /// <param name="codigo">Código del efecto pendiente a remesar</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <returns>Objeto efecto pendiente a remesar</returns>
        public cEfectoPendienteBO ObtenerEfectoPendienteARemesar(int codigo, int contratoCodigo, string periodoCodigo, short facturaCodigo, short sociedadCodigo, cRespuesta respuesta)
        {
            return cEfectosPendientesBL.Obtener(codigo, contratoCodigo, periodoCodigo, facturaCodigo, sociedadCodigo, out respuesta);
        }

        /// <summary>
        /// Obtiene un elemento
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="contratoCodigo">Código del contrato</param>
        /// <param name="periodoCodigo">Código del periodo</param>
        /// <param name="facturaCodigo">Código de la factura</param>
        /// <param name="efectoPdteCodigo">Código del efecto pendiente a remesar</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>Elemento obtenido</returns>
        public static cRemesaTrabBO Obtener(string usuarioCodigo, int contratoCodigo, string periodoCodigo, short facturaCodigo, int efectoPdteCodigo, out cRespuesta respuesta)
        {
            cRemesaTrabBO remesaTrab = null;

            //Parámetros
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;
            parametros.RemesaTrab.PeriodoCodigo = periodoCodigo;
            parametros.RemesaTrab.ContratoCodigo = contratoCodigo;
            parametros.RemesaTrab.FacturaCodigo = facturaCodigo;
            parametros.RemesaTrab.EfectoPdteCodigo = efectoPdteCodigo;
            
            //Obtener elemento de capa de datos
            cBindableList<cRemesaTrabBO> lista = new cBindableList<cRemesaTrabBO>();
            new cRemesasDL().ObtenerEfectosARemesar(ref lista, parametros, null, out respuesta);

            //Extracción del elemento de la lista obtenido
            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                remesaTrab = lista.Count == 1 ? lista[0] : null;
                if (lista.Count > 1)
                    cExcepciones.ControlarER(new Exception(Resource.errorObtenidosVariosRegistros), TipoExcepcion.Informacion, out respuesta);
            }

            return remesaTrab;
        }

        /// <summary>
        /// Obtiene un único objeto
        /// </summary>
        /// <param name="remesaTrab">Objeto que contiene los datos que identifican un único objeto</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerEfectoARemesar(ref cRemesaTrabBO remesaTrab, out cRespuesta respuesta)
        {
            bool resultado = false;
            cBindableList<cRemesaTrabBO> remesas = null;
            respuesta = new cRespuesta();
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();

            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.RemesaTrab.ContratoCodigo = remesaTrab.ContratoCodigo;
            parametros.RemesaTrab.PeriodoCodigo = remesaTrab.PeriodoCodigo;
            parametros.RemesaTrab.UsuarioCodigo = remesaTrab.UsuarioCodigo;
            parametros.RemesaTrab.FacturaCodigo = remesaTrab.FacturaCodigo;
            parametros.RemesaTrab.EfectoPdteCodigo = remesaTrab.EfectoPdteCodigo;

            try
            {
                resultado = new cRemesasDL().ObtenerEfectosARemesar(ref remesas, parametros, String.Empty, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    remesaTrab = remesas[0];
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }

        /// <summary>
        /// Obtiene una lista enlazable
        /// </summary>
        /// <param name="filtro">filtro que condicionará la búsqueda</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>Lista enlazable (si no se encuentran datos devuelve una lista vacía)</returns>
        public cBindableList<cRemesaTrabBO> ObtenerEfectosARemesar(String filtro, out cRespuesta respuesta)
        {
            cBindableList<cRemesaTrabBO> remesas = null;
            respuesta = new cRespuesta();
            cRemesasDL remesasDL = new cRemesasDL();

            try
            {
                remesasDL.ObtenerEfectosARemesar(ref remesas, null, filtro, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return remesas ?? new cBindableList<cRemesaTrabBO>();
        }

        
        /// <summary>
        /// Obtiene una lista enlazable según el usuario
        /// </summary>
        /// <param name="usuarioCodigo">código del usuario</param>
        /// <param name="filtro">filtro que condicionará la búsqueda</param>
        /// <param name="soloConflictos">True solo escoger efectos pendientes a remesar que entren en conflicto con facturas a remesar</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>Lista enlazable (si no se encuentran datos devuelve una lista vacía)</returns>
        public cBindableList<cRemesaTrabBO> ObtenerEfectosARemesarPorUsuario(String usuarioCodigo, String filtro, bool? soloConflictos, out cRespuesta respuesta)
        {
            cBindableList<cRemesaTrabBO> remesas = null;
            respuesta = new cRespuesta();

            //Llamada al procedimiento y obtener datos
            cRemesasDL remesasDL = new cRemesasDL();
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;
            parametros.SoloConflictos = soloConflictos;

            try
            {
                remesasDL.ObtenerEfectosARemesar(ref remesas, parametros, filtro, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return remesas ?? new cBindableList<cRemesaTrabBO>();
        }

        /// <summary>
        /// Obtiene una lista enlazable según el usuario
        /// </summary>
        /// <param name="usuarioCodigo">código del usuario</param>
        /// <param name="filtro">filtro que condicionará la búsqueda</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>Lista enlazable (si no se encuentran datos devuelve una lista vacía)</returns>
        public cBindableList<cRemesaTrabBO> ObtenerEfectosARemesarPorUsuario(String usuarioCodigo, String filtro, out cRespuesta respuesta)
        {
            return ObtenerEfectosARemesarPorUsuario(usuarioCodigo, filtro, null, out respuesta);
        }

        /// <summary>
        /// Obtiene una lista enlazable según el usuario
        /// </summary>
        /// <param name="usuarioCodigo">código del usuario</param>
        /// <param name="filtro">filtro que condicionará la búsqueda</param>
        /// <param name="obtenerDatosParaRemesar">True devuelve datos necesarios para crear remesas, false sólo obtiene los datos de la tabla</param>
        /// <param name="soloConflictos">True solo escoger efectos pendientes a remesar que entren en conflicto con facturas a remesar</param>
        /// <param name="respuesta">objeto que indica el resultado de la operación</param>
        /// <returns>Lista enlazable (si no se encuentran datos devuelve una lista vacía)</returns>
        public cBindableList<cRemesaTrabBO> ObtenerEfectosARemesarPorUsuario(String usuarioCodigo, String filtro, bool obtenerDatosParaRemesar, out cRespuesta respuesta)
        {
            cBindableList<cRemesaTrabBO> remesas = null;
            respuesta = new cRespuesta();

            //Llamada al procedimiento y obtener datos
            cRemesasDL remesasDL = new cRemesasDL();
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;
            parametros.ObtenerDatosParaRemesar = obtenerDatosParaRemesar;

            try
            {
                remesasDL.ObtenerEfectosARemesar(ref remesas, parametros, filtro, out respuesta);
            }
            catch (Exception ex)
            {
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return remesas ?? new cBindableList<cRemesaTrabBO>();
        }

        /// <summary>
        /// Realiza la inserción de efectos a remesar a partir de la selección del usuario
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="sociedadCodigo">Código de la sociedad</param>
        /// <param name="regAfectados">Número de registros insertados</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool InsertarEfectosPendientesARemesar(string usuarioCodigo, short sociedadCodigo, out int regAfectados, out cRespuesta respuesta)
        {
            bool resultado = false;
            regAfectados = 0;
            respuesta = new cRespuesta();
            try
            {
                using (TransactionScope scope = cAplicacion.NewTransactionScope())
                {
                    //Actualizar efectos pendientes (Indicándole quien lo ha seleccionado y la fecha)
                    cBindableList<cEfectoPendienteBO> efectosPendientes = cEfectosPendientesBL.ObtenerPendientes(usuarioCodigo, false, sociedadCodigo, false, AcuamaDateTime.Today, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK)
                        for (int i = 0; i < efectosPendientes.Count; i++)
                        {
                            efectosPendientes[i].UsuarioSeleccionRemesa = usuarioCodigo;
                            efectosPendientes[i].FechaSeleccionRemesa = AcuamaDateTime.Now;
                            respuesta = cEfectosPendientesBL.Actualizar(efectosPendientes[i]);
                        }

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
                        parametros.RemesaTrab = new cRemesaTrabBO();
                        parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;
                        parametros.RemesaTrab.SociedadCodigo = sociedadCodigo;

                        cRemesasDL remesasDL = new cRemesasDL();
                        resultado = remesasDL.InsertarEfectosPendientesARemesar(parametros, out regAfectados, out respuesta);
                    }

                    respuesta.Resultado = respuesta.Resultado == ResultadoProceso.SinRegistros ? ResultadoProceso.OK : respuesta.Resultado;

                    if(respuesta.Resultado == ResultadoProceso.OK)
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
        /// Realiza la inserción de los efectos pendientes a remesar
        /// </summary>
        /// <param name="regAfectados">Número de registros insertados</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operacion</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool InsertarEfectosARemesar(cRemesaTrabSeleccionBO remSeleccion, string taskUser, ETaskType? taskType, int? taskNumber, out int regAfectados, out cRespuesta respuesta)
        {
            bool resultado = false;
            regAfectados = 0;
            respuesta = new cRespuesta();
            try
            {
                cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
                parametros.RemesasSeleccion = remSeleccion;

                cRemesasDL remesasDL = new cRemesasDL();
                resultado = remesasDL.InsertarEfectosARemesar(parametros, taskUser, taskType, taskNumber, out regAfectados, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;

        }

        /// <summary>
        /// Borra un registro
        /// </summary>
        /// <param name="remesaTrab">Objeto a borrar</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool BorrarEfectoARemesar(cRemesaTrabBO remesaTrab, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();

            try
            {
                cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
                parametros.RemesaTrab = new cRemesaTrabBO();
                parametros.RemesaTrab.UsuarioCodigo = remesaTrab.UsuarioCodigo;
                parametros.RemesaTrab.ContratoCodigo = remesaTrab.ContratoCodigo;
                parametros.RemesaTrab.PeriodoCodigo = remesaTrab.PeriodoCodigo;
                parametros.RemesaTrab.FacturaCodigo = remesaTrab.FacturaCodigo;
                parametros.RemesaTrab.EfectoPdteCodigo = remesaTrab.EfectoPdteCodigo;
                cRemesasDL remesasDL = new cRemesasDL();
                resultado = remesasDL.BorrarEfectosARemesar(parametros, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Borra un registro que ya está cobrado
        /// </summary>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool BorrarCobrados(out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
            parametros.SoloCobrados = true;

            return new cRemesasDL().BorrarEfectosARemesar(parametros, out respuesta);
        }

        /// <summary>
        /// Actualiza los importes de todas las remesasTrab (facturado y pagado)
        /// </summary>
        /// <returns>Objeto respuesta</returns>
        public static cRespuesta ActualizarImportes()
        {
            return new cRemesasDL().ActualizarImportes();
        }

        /// <summary>
        /// Devuelve el total facturado y el total pagado de los efectos a remesar
        /// </summary>
        /// <param name="usuarioCodigo">código del usuario</param>
        /// <param name="totalFacturado">total facturado</param>
        /// <param name="totalPagado">total pagado</param>
        /// <param name="totalRemesar">total a remesar</param>
        /// <param name="respuesta">total respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool ObtenerTotalesEfectos(String usuarioCodigo, out decimal totalFacturado, out decimal totalPagado, out decimal totalRemesar, out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            totalFacturado = totalPagado = totalRemesar = 0;

            try
            {
                cRemesasDL remesasDL = new cRemesasDL();
                resultado = remesasDL.ObtenerTotalesEfectos(usuarioCodigo, out totalFacturado, out totalPagado, out totalRemesar, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Borra los efectos a remesar de un usuario
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="respuesta">Respuesta</param>
        /// <returns>True si no ha habido errores, false en caso contrario</returns>
        public bool BorrarEfectosPorUsuario(String usuarioCodigo, out cRespuesta respuesta)
        {
            bool resultado;
            respuesta = new cRespuesta();

            try
            {
                cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
                parametros.RemesaTrab = new cRemesaTrabBO();
                parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;

                cRemesasDL remesasDL = new cRemesasDL();
                resultado = remesasDL.BorrarEfectosARemesar(parametros, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Obtiene el objeto Contrato
        /// </summary>
        /// <param name="remesaTrab">Objeto cRemesaTrab</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool ObtenerContrato(ref cRemesaTrabBO remesa, out cRespuesta respuesta)
        {
            respuesta = new cRespuesta();
            if (remesa == null)
            {
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            bool resultado = false;
            try
            {
                cContratoBO contrato = new cContratoBO();

                //En funcióndel valor de CCCVersionCtr cogemos la versión del contrato en la factura, o la última del contrato
                contrato.Codigo = remesa.ContratoCodigo;
                if (remesa.CccVersionCtr == "VF")
                {
                    resultado = remesa.Factura != null ? true : ObtenerFactura(ref remesa, out respuesta);
                    if (resultado)
                    {
                        contrato.Version = remesa.Factura.ContratoVersion.Value;
                        resultado = cContratoBL.Obtener(ref contrato, out respuesta);
                    }
                }
                else
                    resultado = cContratoBL.ObtenerUltimaVersion(ref contrato, out respuesta);
                
                if (respuesta.Resultado == ResultadoProceso.OK)
                    remesa.Contrato = contrato;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Obtiene el objeto Zona
        /// </summary>
        /// <param name="remesaTrab">Objeto cRemesaTrab</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool ObtenerZona(ref cRemesaTrabBO remesa, out cRespuesta respuesta)
        {
            if (remesa == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            bool resultado = false;
            try
            {
                cZonaBO zona = new cZonaBO();
                cZonaBL zonaBL = new cZonaBL();
                zona.Codigo = remesa.ZonaCodigo;

                resultado = zonaBL.Obtener(ref zona, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    remesa.Zona = zona;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Obtiene el objeto Periodo
        /// </summary>
        /// <param name="remesaTrab">Objeto cRemesaTrab</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool ObtenerPeriodo(ref cRemesaTrabBO remesa, out cRespuesta respuesta)
        {
            if (remesa == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            bool resultado = false;
            try
            {
                cPeriodoBO periodo = new cPeriodoBO();
                cPeriodoBL periodoBL = new cPeriodoBL();
                periodo.Codigo = remesa.PeriodoCodigo;

                resultado = periodoBL.Obtener(ref periodo, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    remesa.Periodo = periodo;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Obtiene el objeto Serie
        /// </summary>
        /// <param name="remesaTrab">Objeto cRemesaTrab</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool ObtenerSerie(ref cRemesaTrabBO remesa, out cRespuesta respuesta)
        {
            if (remesa == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            bool resultado = false;
            try
            {
                cSerieBO serie = new cSerieBO();
                serie.Codigo = remesa.SerieCodigo;
                serie.CodSociedad = remesa.SociedadCodigo;

                resultado = cSerieBL.Obtener(ref serie, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    remesa.Serie = serie;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        /// <summary>
        /// Comprueba si existen una factura para remesar
        /// </summary>
        /// <param name="efectoPdteCodigo">Código del efecto pendiente</param>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Devuelve True si si existen facturas a remesar y False en caso contrario</returns>
        public static bool Existe(int efectoPdteCodigo, string usuarioCodigo, out cRespuesta respuesta)
        {
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.RemesaTrab.EfectoPdteCodigo = efectoPdteCodigo;
            parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;

            return new cRemesasDL().Existen(parametros, out respuesta);
        }

        /// Comprueba si existen facturas a remesar con mandatos que no son aceptados para remesarlos.
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Devuelve TRUE si existen, false en caso contrario</returns>
        public static bool ExistenMandatosNoRemesables(string usuarioCodigo, out cRespuesta respuesta)
        {
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;

            return new cRemesasDL().ExistenMandatosNoRemesables(parametros, out respuesta);
        }

        /// <summary>
        /// Comprueba si existen conflictos entre efectos a remesar
        /// </summary>
        /// <param name="usuarioCodigo">Código del usuario</param>
        /// <param name="respuesta">Objeto respuesta</param>
        /// <returns>Devuelve True si si existen conflictos y False en caso contrario</returns>
        public static bool ExistenConflictos(string usuarioCodigo, out cRespuesta respuesta)
        {
            cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.SoloConflictos = true;
            parametros.RemesaTrab = new cRemesaTrabBO();
            parametros.RemesaTrab.UsuarioCodigo = usuarioCodigo;

            return new cRemesasDL().Existen(parametros, out respuesta);
        }

        /// <summary>
        /// Obtiene el objeto Factura
        /// </summary>
        /// <param name="remesaTrab">Objeto cRemesaTrab</param>
        /// <param name="respuesta">Objeto Respuesta con el resultado de la operación</param>
        /// <returns>Devuelve True si la operación se ha realizado correctamente y False en caso contrario</returns>
        public bool ObtenerFactura(ref cRemesaTrabBO remesa, out cRespuesta respuesta)
        {
            if (remesa == null)
            {
                respuesta = new cRespuesta();
                respuesta.Resultado = ResultadoProceso.Error;
                return false;
            }
            bool resultado = false;
            try
            {
                cFacturaBO factura = new cFacturaBO();
                factura.ContratoCodigo = remesa.ContratoCodigo;
                factura.PeriodoCodigo = remesa.PeriodoCodigo;
                factura.FacturaCodigo = remesa.FacturaCodigo;

                resultado = cFacturasBL.ObtenerUltimaVersion(ref factura, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK)
                    remesa.Factura = factura;
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }


















        #region RemesarIBAN V2.0

        private string obtenerVersionRemesa(out cRespuesta respuesta)
        {
            string result = "1.0";

            respuesta = cParametroBL.GetString("REMESA_VERSION", out result);

            return result;
        }

        private string obtenerIDAcreedor(out cRespuesta respuesta)
        {
            string result = string.Empty;
            string sufijo = null;

            respuesta = cParametroBL.GetString("SUFIJO", out sufijo);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                sufijo = cAplicacion.FixedLengthString(sufijo, 3, '0', true, true);
                respuesta = cMandatosBL.GenerarIdentificadorAcreedor(cAplicacion.FixedLengthString(sufijo, 3, '0', true, true), "ES", out result);
            }

            return result;
        }

        private enum ResultRemesa
        {
            OK,
            ERROR_Mandato,
            ERROR_MarcarRemesado,
            ERROR_RegistrarCobro,
            ERROR_XMLRemesa,
            ERROR_BorrandoEfectoRemesa,
            ERROR
        }

        private enum LogRemesa
        {
            INICIO,
            FIN
        }

        private string RemesaLogging(LogRemesa msg, string procedimiento, string mensaje)
        {
            cRespuesta respuesta;
            cErrorLog logging = new cErrorLog();
            logging.Insertar(procedimiento, mensaje, Enum.GetName(msg.GetType(), msg), out respuesta);

            return procedimiento;
        }

        private class ctaBancaria
        {
            private const int LEN = 20;

            public string entidad
            {
                get
                {
                    return this.numero.Length == LEN ? this.numero.Substring(0, 4) : string.Empty;
                }
            }

            public string oficina
            {
                get
                {
                    return this.numero.Length == LEN ? this.numero.Substring(4, 4) : string.Empty;
                }
            }

            public string numero { get; set; }

            public ctaBancaria(string numCta)
            {
                this.numero = numCta ?? string.Empty;
            }
        }

        private cCobroLinBO insertarLineaCobro(cCobroBO cobro, cRemesaTrabBO efecto, out cRespuesta respuesta)
        {
            cCobroLinBO cobroLin = new cCobroLinBO();

            cobroLin.Numero = cobro.Numero;
            cobroLin.SociedadCodigo = cobro.SociedadCodigo;
            cobroLin.Importe = cobro.Importe;
            cobroLin.PeriodoCodigo = efecto.PeriodoCodigo;
            cobroLin.CodigoFactura = efecto.FacturaCodigo;
            cobroLin.PPagoCodigo = cobro.PPagoCodigo;
            cobroLin.VersionFactura = efecto.DatosParaRemesar.FacturaVersion.Value;
            cCobrosLinBL.Insertar(ref cobroLin, out respuesta); //Insertar línea de cobro

            return cobroLin;
        }

        private cCobroBO insertarCobro(string usuarioCodigo, int numRemesa, cBancoBO banco, cRemesaTrabBO efecto, cEfectoPendienteBO efectoPendiente, DateTime fechaCobro, DateTime ahora, out cRespuesta respuesta)
        {
            //Generamos el cobro (cabecera) por la remesa
            cCobroBO cobro = new cCobroBO();
            cobro.SociedadCodigo = banco.SociedadCodigo.Value;
            cobro.PPagoCodigo = banco.PpagoCodigo.Value;
            cobro.MpcCodigo = banco.MpcCodigo.Value;

            //TODO: En los datos de los cobros se le indica al CCC que "no hay datos", si no tiene CCC al ser obligatorio el campo. Posteriormente cuando se implante por completo el IBAN habrá que quitar
            // el CCC de los datos de los medios de pago del cobro
            cIBANBO Iban = new cIBANBO(efecto.DatosParaRemesar.ContratoIBAN);
            cobro.MpcDatos[0] = Iban.Entidad;         // cobMpcDato1
            cobro.MpcDatos[1] = Iban.Oficina;         // cobMpcDato2
            cobro.MpcDatos[2] = Iban.DigitosControl;  // cobMpcDato3
            cobro.MpcDatos[3] = Iban.NumeroCuenta;    // cobMpcDato4
            cobro.MpcDatos[5] = Iban.IBAN;            // cobMpcDato6

            cobro.Importe = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;
            cobro.ContratoCodigo = efecto.ContratoCodigo;
            cobro.FecReg = AcuamaDateTime.Now;
            cobro.Fecha = fechaCobro;
            cobro.DocIden = efecto.DatosParaRemesar.ContratoDocIden;
            cobro.UsuarioCodigo = usuarioCodigo;
            cobro.Nombre = efecto.DatosParaRemesar.ContratoNombre;
            cobro.Concepto = cAplicacion.GetAppLangResource("remesa") + ": " + numRemesa + ". " + cAplicacion.GetAppLangResource("fecha") + ": " + ahora.ToShortDateString();
            cobro.Origen = cCobroBO.EOrigenCobro.Remesa;
            cCobrosBL.Insertar(ref cobro, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
                insertarLineaCobro(cobro, efecto, out respuesta);

            return cobro;
        }

        private cRespuesta marcarRemesado(cEfectoPendienteBO efectoPendiente, string usuarioCodigo, DateTime ahora)
        {
            cRespuesta respuesta = new cRespuesta(ResultadoProceso.OK);

            if (efectoPendiente != null &&
                efectoPendiente.Codigo.HasValue &&
                efectoPendiente.ContratoCodigo.HasValue &&
                efectoPendiente.FacturaCodigo.HasValue &&
                efectoPendiente.SociedadCodigo.HasValue &&
                !String.IsNullOrEmpty(efectoPendiente.PeriodoCodigo))
            {
                respuesta = cEfectosPendientesBL.MarcarRemesado(usuarioCodigo, efectoPendiente.Codigo.Value, efectoPendiente.ContratoCodigo.Value, efectoPendiente.PeriodoCodigo, efectoPendiente.FacturaCodigo.Value, efectoPendiente.SociedadCodigo.Value, ahora);
            }
            return respuesta;
        }

        private cRespuesta marcarRemesado(cRemesaTrabBO efecto, int numRemesa, DateTime ahora)
        {
            //Actualizamos el número y la fecha de la remesa en la tabla FACTURAS
            cRespuesta respuesta;

            cFacturasBL.MarcarRemesada(efecto.FacturaCodigo, efecto.ContratoCodigo, efecto.PeriodoCodigo, efecto.DatosParaRemesar.FacturaVersion.Value, numRemesa, ahora, out respuesta);

            return respuesta;
        }

        private cBancoBO bancoObtener(short bancoCodigo, out cRespuesta respuesta)
        {
            cBancoBO result = new cBancoBO();

            result.Codigo = bancoCodigo;
            new cBancosBL().Obtener(ref result, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                result.NumRemesa = (result.NumRemesa ?? 0) + 1;

                //Guardamos el nuevo numerador de remesas en bancos
                new cBancosBL().Actualizar(result, out respuesta);
            }

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                new cBancosBL().ObtenerSociedad(ref result, out respuesta);
            }

            return result;
        }

        private XmlTextWriter xmlRemesaCabecera(DateTime fecha, DateTime fechaCobro, string identificadorAcreedor, cBancoBO banco, ref StringWriter sw)
        {
            //StringWriter sw = new StringWriter(new StringBuilder(String.Empty));
            XmlTextWriter xmlWriter = new XmlTextWriter(sw);
            xmlWriter.Formatting = Formatting.Indented;
            xmlWriter.Indentation = 3;

            xmlWriter.WriteProcessingInstruction("xml", "version=\"1.0\" encoding=\"utf-8\"");
            xmlWriter.WriteStartElement("Document");
            xmlWriter.WriteAttributeString("xmlns", "urn:iso:std:iso:20022:tech:xsd:pain.008.001.02");
            xmlWriter.WriteAttributeString("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
            xmlWriter.WriteStartElement("CstmrDrctDbtInitn");
            xmlWriter.WriteStartElement("GrpHdr");
            xmlWriter.WriteStartElement("MsgId"); xmlWriter.WriteString("Remesa:" + banco.NumRemesa.ToString() + " (Fecha:" + String.Format("{0:yyyy-MM-dd}", fecha) + ")"); xmlWriter.WriteEndElement(); //identificador del fichero
            xmlWriter.WriteStartElement("CreDtTm"); xmlWriter.WriteString(String.Format("{0:s}", fecha)); xmlWriter.WriteEndElement(); // Fecha del fichero
            xmlWriter.WriteStartElement("NbOfTxs"); xmlWriter.WriteEndElement(); // Número de operaciones
            xmlWriter.WriteStartElement("CtrlSum"); xmlWriter.WriteEndElement(); // Suma de todos los importes
            xmlWriter.WriteStartElement("InitgPty");
            xmlWriter.WriteStartElement("Nm"); xmlWriter.WriteString(ConvertirAISO20022(banco.TitularCuenta)); xmlWriter.WriteEndElement(); // Nombre del acreedor
            xmlWriter.WriteStartElement("Id");
            xmlWriter.WriteStartElement("OrgId");
            xmlWriter.WriteStartElement("Othr");
            xmlWriter.WriteStartElement("Id"); xmlWriter.WriteString(identificadorAcreedor); xmlWriter.WriteEndElement(); // Identificador del acreedor
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("PmtInf");
            xmlWriter.WriteStartElement("PmtInfId"); xmlWriter.WriteString("Remesa:" + banco.NumRemesa.ToString() + " (Fecha:" + String.Format("{0:yyyy-MM-dd}", fecha) + ")"); xmlWriter.WriteEndElement(); // El mismo identificador del fichero, ya que solo hay un acreedor y una fecha de cobro
            xmlWriter.WriteStartElement("PmtMtd"); xmlWriter.WriteString("DD"); xmlWriter.WriteEndElement(); // Por defecto 'DD', solo de admite este DirectDebit

            if (cParametroBL.ObtenerValor("EXPLOTACION") == "AVG")
            {
                xmlWriter.WriteStartElement("BtchBookg"); xmlWriter.WriteString("true"); xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("NbOfTxs"); xmlWriter.WriteEndElement(); // Número de operaciones
                xmlWriter.WriteStartElement("CtrlSum"); xmlWriter.WriteEndElement(); // Suma de todos los importes
            }
            xmlWriter.WriteStartElement("PmtTpInf");
            xmlWriter.WriteStartElement("SvcLvl");
            xmlWriter.WriteStartElement("Cd"); xmlWriter.WriteString("SEPA"); xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("LclInstrm");
            xmlWriter.WriteStartElement("Cd"); xmlWriter.WriteString("CORE"); xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("SeqTp"); xmlWriter.WriteString("RCUR"); xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("ReqdColltnDt"); xmlWriter.WriteString(String.Format("{0:yyyy-MM-dd}", fechaCobro)); xmlWriter.WriteEndElement(); // Fecha del cobro
            xmlWriter.WriteStartElement("Cdtr");
            xmlWriter.WriteStartElement("Nm"); xmlWriter.WriteString(ConvertirAISO20022(banco.TitularCuenta)); xmlWriter.WriteEndElement(); // Nombre del acreedor
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("CdtrAcct");
            xmlWriter.WriteStartElement("Id");
            xmlWriter.WriteStartElement("IBAN"); xmlWriter.WriteString(banco.Iban); xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("Ccy"); xmlWriter.WriteString("EUR"); xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("CdtrAgt");
            xmlWriter.WriteStartElement("FinInstnId");
            xmlWriter.WriteStartElement("BIC"); xmlWriter.WriteString(banco.Bic); xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteStartElement("CdtrSchmeId");
            xmlWriter.WriteStartElement("Id");
            xmlWriter.WriteStartElement("PrvtId");
            xmlWriter.WriteStartElement("Othr");
            xmlWriter.WriteStartElement("Id"); xmlWriter.WriteString(identificadorAcreedor); xmlWriter.WriteEndElement(); // Identificador del acreedor
            xmlWriter.WriteStartElement("SchmeNm");
            xmlWriter.WriteStartElement("Prtry"); xmlWriter.WriteString("SEPA"); xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();
            xmlWriter.WriteEndElement();

            return xmlWriter;
        }

        private string xmlRemesaCobroRaw(bool detallado, cCobroBO cobro, cRemesaTrabBO efecto, decimal pendienteFactura, cMandatoBO mandato, bool mandatoModificado)
        {
            StringWriter sw = new StringWriter(new StringBuilder(String.Empty));
            XmlTextWriter xmlWriter = new XmlTextWriter(sw);
            xmlWriter.Formatting = Formatting.Indented;
            xmlWriter.Indentation = 3;

            string result = string.Empty;

            try
            {
                xmlWriter.WriteStartElement("DrctDbtTxInf");
                xmlWriter.WriteStartElement("PmtId");
                xmlWriter.WriteStartElement("EndToEndId");
                xmlWriter.WriteString(cobro.Numero.ToString()
                    + "-" + cobro.PPagoCodigo.ToString()
                    + "-" + efecto.PeriodoCodigo
                    + "-" + efecto.FacturaCodigo.ToString()
                    + "-" + efecto.ContratoCodigo.ToString()
                    + (efecto.EfectoPendiente != null ? efecto.EfectoPendiente.Codigo.ToString() : String.Empty));
                xmlWriter.WriteEndElement(); //Dato que referencia al adeudo
                xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("InstdAmt");
                xmlWriter.WriteAttributeString("Ccy", "EUR");
                xmlWriter.WriteString(pendienteFactura.ToString("N2").Replace(".", "").Replace(",", "."));
                xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("DrctDbtTx");
                xmlWriter.WriteStartElement("MndtRltdInf");
                xmlWriter.WriteStartElement("MndtId");
                xmlWriter.WriteString(mandato.Referencia);
                xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("DtOfSgntr");
                xmlWriter.WriteString(String.Format("{0:yyyy-MM-dd}", mandato.FechaFirma));
                xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("AmdmntInd");
                xmlWriter.WriteString(mandatoModificado.ToString().ToLower());
                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("DbtrAgt");
                xmlWriter.WriteStartElement("FinInstnId");
                xmlWriter.WriteStartElement("BIC");
                xmlWriter.WriteString(efecto.DatosParaRemesar.ContratoBIC);
                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("Dbtr");
                xmlWriter.WriteStartElement("Nm");
                xmlWriter.WriteString(ConvertirAISO20022(efecto.DatosParaRemesar.ContratoNombre));
                xmlWriter.WriteEndElement(); // Nombre del deudor
                xmlWriter.WriteEndElement();
                xmlWriter.WriteStartElement("DbtrAcct");
                xmlWriter.WriteStartElement("Id");
                xmlWriter.WriteStartElement("IBAN");
                xmlWriter.WriteString(efecto.DatosParaRemesar.ContratoIBAN);
                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();

                if (detallado)
                {
                    //Datos de la serie, número y fecha de factura
                    string datosPrimariosFactura = "FRA.NUM.:"
                        + cAplicacion.FixedLengthString(efecto.DatosParaRemesar.FacturaSerie.HasValue ? efecto.DatosParaRemesar.FacturaSerie.ToString() : String.Empty, 2, '0', true, true)
                        + "."
                        + (!String.IsNullOrWhiteSpace(efecto.DatosParaRemesar.FacturaNumero) ? efecto.DatosParaRemesar.FacturaNumero : String.Empty)
                        + " "
                        + (efecto.DatosParaRemesar.FacturaFecha.HasValue ? efecto.DatosParaRemesar.FacturaFecha.Value.ToShortDateString() : String.Empty)
                        + ", ";

                    //Datos de lectura anterior y actual de la factura
                    string datosLecturaFactura = String.Empty;
                    if (efecto.DatosParaRemesar.FacturaLecturaFecha.HasValue)
                    {
                        datosLecturaFactura = "Lecturas:" +
                        " Anterior: " + (efecto.DatosParaRemesar.FacturaLecturaAnteriorFecha.HasValue ? efecto.DatosParaRemesar.FacturaLecturaAnteriorFecha.Value.ToString("dd/MM") : String.Empty) + " " + (efecto.DatosParaRemesar.FacturaLecturaAnterior.HasValue ? efecto.DatosParaRemesar.FacturaLecturaAnterior.ToString() : String.Empty) + "," +
                        " Actual: " + (efecto.DatosParaRemesar.FacturaLecturaFecha.Value.ToString("dd/MM")) + " " + (efecto.DatosParaRemesar.FacturaLectura.HasValue ? efecto.DatosParaRemesar.FacturaLectura.Value.ToString() : String.Empty) + "," +
                        " Cns.: " + (efecto.DatosParaRemesar.FacturaConsumo.HasValue ? efecto.DatosParaRemesar.FacturaConsumo.ToString() : String.Empty) + "m3" +
                        ", ";
                    }

                    //Datos de importes de la factura    
                    string datosImportesFactura = String.Empty;
                    if (efecto.Pagado == 0)
                        datosImportesFactura = "TOTAL: " + efecto.FacturaTotal.ToString("N2");
                    else
                        datosImportesFactura = "A.CTA:" + efecto.Pagado.ToString("N2") + " TOTAL: " + efecto.FacturaTotal.ToString("N2");

                    xmlWriter.WriteStartElement("RmtInf");
                    xmlWriter.WriteStartElement("Ustrd"); xmlWriter.WriteString(datosPrimariosFactura + datosLecturaFactura + datosImportesFactura); xmlWriter.WriteEndElement(); // Datos de ampliación del adeudo
                    xmlWriter.WriteEndElement();
                }

                xmlWriter.WriteEndElement();

                result = sw.ToString();
            }
            catch
            {
                result = string.Empty;
            }

            return result;
        }
        
        private StringBuilder xmlRemesaCierre(ref XmlTextWriter xmlWriter, ref StringWriter sw, int remesados, decimal totalRemesa)
        {
            StringBuilder result = new StringBuilder();

            try
            {
                xmlWriter.WriteRaw(Environment.NewLine);

                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();
                xmlWriter.WriteEndElement();
                xmlWriter.Close();

                sw.Close();
                result.Append(sw.ToString());

                //Actualizar datos posteriormente calculados
                result.Replace("<NbOfTxs />", "<NbOfTxs>" + remesados + "</NbOfTxs>");
                result.Replace("<CtrlSum />", "<CtrlSum>" + totalRemesa.ToString("N2").Replace(".", "").Replace(",", ".") + "</CtrlSum>");

                // Ya realizado la conversión a ISO20022, debemos deshacer los cambios que hace la generación del XML porque ya se hacen los cambios oportunos al convertirlo
                // Por ejemplo al convertir el & a &amp; el XML lo volverá a convertir quedando &ampamp; y eso no debe ser así.
                result.Replace("&amp;quot;", "&quot;");
                result.Replace("&amp;apos;", "&apos;");
                result.Replace("&amp;lt;", "&lt;");
                result.Replace("&amp;gt;", "&gt;");
                result.Replace("&amp;amp;", "&amp;");
            }
            catch
            {
                result = null;
            }
            return result;
        }
        
        public cEfectoPendienteBO ObtenerEfectoPendienteARemesar(cRemesaTrabBO efecto, cRespuesta respuesta)
        {
            return cEfectosPendientesBL.Obtener(efecto.EfectoPdteCodigo.Value, efecto.ContratoCodigo, efecto.PeriodoCodigo, efecto.FacturaCodigo, efecto.SociedadCodigo, out respuesta);
        }

        private bool validarEfectoRemesa(cRemesaTrabBO efecto)
        {
            //Hay IBAN y BIC 
            bool result = false;
            int lenBIC = (efecto.DatosParaRemesar.ContratoBIC ?? string.Empty).Length;

            result = !string.IsNullOrEmpty(efecto.DatosParaRemesar.ContratoIBAN)
                   && !string.IsNullOrEmpty(efecto.DatosParaRemesar.ContratoBIC)
                   && (lenBIC == 11 || lenBIC == 8)
                   && (efecto.DatosParaRemesar.ContratoIBAN.Length <= 34); //El IBAN consta de un máximo de 34 caracteres alfanuméricos.

            return result;
        }

        private bool validarEfectoPendiente(cEfectoPendienteBO efectoPendiente)
        {
            //Es un efecto pendiente a remesar mientras no este remesado ya ni rechazado

            bool result = true;

            if (efectoPendiente != null)
            {
                result = !efectoPendiente.FechaRemesada.HasValue && !efectoPendiente.FechaRechazado.HasValue;
            }

            return result;
        }

        private bool esMandatoObsoleto(cMandatoBO mandato)
        {
            DateTime ahora = AcuamaDateTime.Now;

            bool result = false;

            if (mandato.FechaUltimoUso.HasValue)
            {
                DateTime obsoleteDate = ((DateTime)mandato.FechaUltimoUso).AddMonths(36);
                result = (ahora > obsoleteDate);
            }
            return result;
        }

        private bool esMandatoValido(cMandatoBO mandato)
        {
            bool result = true;

            result = mandato.FechaFirma.HasValue
                && (mandato.EstadoActual == cMandatoBO.EEstado.Activo || mandato.EstadoActual == cMandatoBO.EEstado.Registrado);

            return result;
        }

        private cMandatoBO obtenerMandato(string referenciaMandato, DateTime ahora, out cRespuesta respuesta)
        {
            cMandatoBO result = new cMandatoBO();
            result = cMandatosBL.Obtener(referenciaMandato, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                if (esMandatoValido(result) && esMandatoObsoleto(result))
                {
                    result.FechaUltimaMod = ahora;
                    result.EstadoActual = cMandatoBO.EEstado.Obsoleto;
                    respuesta = cMandatosBL.Actualizar(result);
                }
            }

            return result;
        }

        private bool usarMandato(ref cMandatoBO mandato, DateTime ahora, out cRespuesta respuesta)
        {
            //Comprobar si se modifico el mandato tras el último uso de él
            respuesta = new cRespuesta(ResultadoProceso.OK);
            bool result = mandato.FechaUltimoUso.HasValue && mandato.FechaUltimaMod.HasValue && mandato.FechaUltimaMod > mandato.FechaUltimoUso;

            if (result)
            {
                //Actualizar la fecha de última modificación del mandato.
                mandato.FechaUltimoUso = ahora;
                respuesta = cMandatosBL.Actualizar(mandato);
            }

            return result;
        }

        private string customMessageMandato(cRemesaTrabBO efecto)
        {
            ResultRemesa err = ResultRemesa.ERROR_Mandato;

            string result =  string.Format("[{0}]{1}.", Enum.GetName(err.GetType(), err), Resource.ErrorMandatoNoValido);

            result = result.Replace("@contrato", efecto.ContratoCodigo.ToString())
                           .Replace("@version", efecto.DatosParaRemesar.ContratoVersion.ToString());

            return result;
        }

        private string customMessageRemesaFactura(cRemesaTrabBO efecto, ResultRemesa err)
        {
            return Resource.ErrorRemesaEfectoFactura.Replace("@periodo", efecto.PeriodoCodigo)
               .Replace("@contrato", efecto.ContratoCodigo.ToString())
               .Replace("@facCod", efecto.FacturaCodigo.ToString())
               .Replace("@err", Enum.GetName(err.GetType(), err));
        }

        private string customMessageRemesaFactura(cEfectoPendienteBO efectoPendiente, ResultRemesa err)
        {
            return Resource.ErrorRemesaEfectoPdteFactura.Replace("@codigo", efectoPendiente.Codigo.ToString())
                .Replace("@periodo", efectoPendiente.PeriodoCodigo)
                .Replace("@contrato", efectoPendiente.ContratoCodigo.ToString())
                .Replace("@facCod", efectoPendiente.FacturaCodigo.ToString())
                .Replace("@err", Enum.GetName(err.GetType(), err));
        }

        private string customMessageRemesa(cRemesaTrabBO efecto, int numRemesa)
        {
            return Resource.ErrorRemesa
               .Replace("@remesa", numRemesa.ToString())
               .Replace("@periodo", efecto.PeriodoCodigo)
               .Replace("@contrato", efecto.ContratoCodigo.ToString())
               .Replace("@facCod", efecto.FacturaCodigo.ToString());
        }

        private string RemesarEfecto(bool detallado, cRemesaTrabBO efecto, cEfectoPendienteBO efectoPendiente, DateTime ahora, string usuarioCodigo, int numRemesa, cBancoBO banco, DateTime fechaCobro, out ResultRemesa result, out decimal pendienteFactura)
        {
            cRespuesta respuesta = new cRespuesta();
            bool mandatoModificado = false;
            string strCustomMessage = string.Empty;
            string xmlResult = string.Empty;
            pendienteFactura = 0;

            DateTime fInicio = DateTime.Now;

            try
            {
                using (TransactionScope scope = new TransactionScope())
                {
                    //Obtenemos el mandato para realizar comprobaciones y comprobar que es correcto y se puede remesar
                    //[01]Mandato
                    string referenciaMandato = efectoPendiente != null ? efectoPendiente.ReferenciaMandato : efecto.DatosParaRemesar.ReferenciaMandato;
                    cMandatoBO mandato = obtenerMandato(referenciaMandato, ahora, out respuesta);

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        mandatoModificado = usarMandato(ref mandato, ahora, out respuesta);
                    }

                    if (respuesta.Resultado != ResultadoProceso.OK || !esMandatoValido(mandato))
                    {
                        result = ResultRemesa.ERROR_Mandato;
                        return xmlResult;
                    }

                    //[02]Marcar Remesado
                    if (efectoPendiente != null)
                        respuesta = marcarRemesado(efectoPendiente, usuarioCodigo, ahora);
                    else
                        respuesta = marcarRemesado(efecto, numRemesa, ahora);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                    {
                        result = ResultRemesa.ERROR_MarcarRemesado;
                        return xmlResult;
                    }

                    //[03]Insertar el cobro
                    cCobroBO cobro =
                    insertarCobro(usuarioCodigo, numRemesa, banco, efecto, efectoPendiente, fechaCobro, ahora, out respuesta);

                    if (respuesta.Resultado != ResultadoProceso.OK)
                    {
                        result = ResultRemesa.ERROR_RegistrarCobro;
                        return xmlResult;
                    }

                    //[04]Pendiente factura
                    pendienteFactura = efectoPendiente != null && efectoPendiente.Importe.HasValue ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;

                    //[05]Borramos el efecto del listado de pendientes
                    BorrarEfectoRemesa(efecto, out respuesta);
                    if (respuesta.Resultado != ResultadoProceso.OK)
                    {
                        result = ResultRemesa.ERROR_BorrandoEfectoRemesa;
                        return xmlResult;
                    }

                    //[06]XML para la remesa
                    xmlResult = xmlRemesaCobroRaw(detallado, cobro, efecto, pendienteFactura, mandato, mandatoModificado);

                    if (string.IsNullOrWhiteSpace(xmlResult))
                    {
                        result = ResultRemesa.ERROR_XMLRemesa;
                        return xmlResult;
                    }

                    //[07]Completamos el registro
                    scope.Complete();
                    result = ResultRemesa.OK;
                }
            }
            catch
            {
                result = ResultRemesa.ERROR;
            }
            finally
            {
                RemesaCobroLogging(fInicio, numRemesa, efecto, efectoPendiente);
               
            }

            return xmlResult;
        }


        private bool BorrarEfectoRemesa(cRemesaTrabBO efecto, out cRespuesta respuesta)
        {
            bool resultado;
            respuesta = new cRespuesta();

            try
            {
                cRemesasDL.Parametros parametros = new cRemesasDL.Parametros();
                parametros.RemesaTrab = new cRemesaTrabBO();
                parametros.RemesaTrab.UsuarioCodigo = efecto.UsuarioCodigo;
                parametros.RemesaTrab.ContratoCodigo = efecto.ContratoCodigo;
                parametros.RemesaTrab.PeriodoCodigo = efecto.PeriodoCodigo;
                parametros.RemesaTrab.FacturaCodigo = efecto.FacturaCodigo;
                parametros.RemesaTrab.EfectoPdteCodigo = efecto.EfectoPdteCodigo;

                cRemesasDL remesasDL = new cRemesasDL();
                resultado = remesasDL.BorrarEfectosARemesar(parametros, out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }

            return resultado;
        }

        public String RemesarIBAN_V2(string usuarioCodigo, short bancoCodigo, DateTime fechaCobro, bool detallado, out int numRemesa, out String log, out int remesados, out cRespuesta respuesta, string taskUser, ETaskType? taskType, int? taskNumber)
        {
            StringBuilder result = null;

            #region "variables out"
            log = String.Empty;
            numRemesa = 0;
            remesados = 0;
            #endregion

            cBindableList<cRemesaTrabBO> efectos = new cBindableList<cRemesaTrabBO>();
            cValidator validator = new cValidator();
            decimal pendienteFactura = 0;
            decimal _pendienteFactura = 0;
            ResultRemesa resultRemesaXML;
            decimal totalRemesa = 0;
            DateTime ahora = AcuamaDateTime.Now;
            ctaBancaria cuentaBancaria;
            string strCustomMessage = string.Empty;
            string strErrMessage = string.Empty;
            string identificadorAcreedor = null;
            cBancoBO banco = new cBancoBO();
            string xmlRemesaFactura = string.Empty;
            StringWriter sw = new StringWriter(new StringBuilder(String.Empty));
            XmlTextWriter xmlWriter = null;
            bool cancelar = false;
            respuesta = new cRespuesta();

            try
            {
                do
                {
                    #region do: validar datos, crear la cabecera, incluir las lineas. Si falla redireccionamos al finally.
                    //[001]Actualizamos los importes antes de obtener por si ha habido algún cambio.
                    respuesta = ActualizarImportes();

                    //[002]Obtener los efectos a remesar (Mientras un usuario no haya acabado la transacción para remesar otro quedará a la espera (Ver el procedimiento almacenado))
                    if (respuesta.Resultado == ResultadoProceso.OK)
                        efectos = ObtenerEfectosARemesarPorUsuario(usuarioCodigo, String.Empty, true, out respuesta);

                    //[ERR_00]Si el resultado es ERROR o SIN REGISTROS no realiza la remesa
                    if (respuesta.Resultado != ResultadoProceso.OK)
                    {
                        respuesta.Resultado = ResultadoProceso.Error;
                        break; //** FINALLY **
                    }

                    //Establecer número de pasos de la tarea
                    if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        cTaskManagerBL.SetTotalSteps(taskUser, taskType.Value, taskNumber.Value, efectos.Count);

                    //************************************************
                    //[010]Obtener datos del banco, la sociedad e incrementar el numero de la remesa
                    banco = bancoObtener(bancoCodigo, out respuesta);
                    numRemesa = banco.NumRemesa ?? 0;
                    //************************************************

                    //[ERR_01]Si el resultado es ERROR o SIN REGISTROS no realiza la remesa
                    if (respuesta.Resultado != ResultadoProceso.OK)
                    {
                        respuesta.Resultado = ResultadoProceso.Error;
                        break; //** FINALLY **
                    }

                    //[011]Cuenta bancaria
                    cuentaBancaria = new ctaBancaria(banco.CtaBancaria);

                    if (string.IsNullOrEmpty(cuentaBancaria.entidad))
                    {
                        strCustomMessage = string.Format("{0} {1}: {2}", Resource.bancoCaja, banco.Codigo, Resource.cuentaBancariaNoEsValida);
                        validator.AddCustomMessage(strCustomMessage);
                    }

                    //[012]Acreedor
                    identificadorAcreedor = obtenerIDAcreedor(out respuesta);
                    if (respuesta.Resultado != ResultadoProceso.OK)
                    {
                        strCustomMessage = Resource.errorIdentificadorAcreedor;
                        validator.AddCustomMessage(strCustomMessage);
                    }

                    //[ERR_02]Si el resultado es ERROR no realiza la remesa
                    log = validator.Validate(true);

                    if (log != String.Empty)
                    {
                        respuesta.Resultado = ResultadoProceso.Error;
                        break; //** FINALLY **
                    }


                    //**CABECERA**    
                    xmlWriter = xmlRemesaCabecera(ahora, fechaCobro, identificadorAcreedor, banco, ref sw);


                    //[101]Recorro los efectos a cobrar
                    for (int contEfectos = 0; contEfectos < efectos.Count; contEfectos++)
                    {
                        #region for / [101]Recorro los efectos a cobrar
                        xmlRemesaFactura = string.Empty;

                        cRemesaTrabBO efecto = efectos[contEfectos];

                        strErrMessage = customMessageRemesa(efecto, numRemesa);

                        //Obtener el efecto pendiente a remesar si lo tiene para indicarles el usuario y fecha de remesa
                        cEfectoPendienteBO efectoPendiente = ObtenerEfectoPendienteARemesar(efecto, respuesta);

                        pendienteFactura = (efectoPendiente != null && efectoPendiente.Importe.HasValue) ? efectoPendiente.Importe.Value : efecto.FacturaTotal - efecto.Pagado;

                        //[201]Remesamos los efectos
                        if (respuesta.Resultado == ResultadoProceso.OK && efecto.Pagado < efecto.FacturaTotal)
                        {
                            //Sólo remesamos si hay IBAN/BIC y si el efecto pendiente no está remesado  ni rechazado
                            if (validarEfectoRemesa(efecto) && validarEfectoPendiente(efectoPendiente))
                            {
                                //**ITEM**
                                xmlRemesaFactura = RemesarEfecto(detallado, efecto, efectoPendiente, ahora, usuarioCodigo, numRemesa, banco, fechaCobro, out resultRemesaXML, out _pendienteFactura);

                                switch (resultRemesaXML)
                                {
                                    case ResultRemesa.ERROR_Mandato:
                                        strCustomMessage = customMessageMandato(efecto);
                                        validator.AddCustomMessage(strCustomMessage);
                                         break;
                                    case ResultRemesa.OK:
                                        
                                        xmlWriter.WriteRaw(Environment.NewLine + xmlRemesaFactura);

                                        pendienteFactura = _pendienteFactura;
                                        totalRemesa += pendienteFactura;
                                        remesados = remesados + 1;
                                        break;
                                    default:
                                        strCustomMessage = customMessageRemesaFactura(efecto, resultRemesaXML);
                                        validator.AddCustomMessage(strCustomMessage);
                                        break;
                                }
                            }
                            else
                            {
                                if (!validarEfectoRemesa(efecto))
                                {
                                    strCustomMessage = Resource.errorElContratoXNoTieneCodigoDeCuentaAsociada.Replace("@codigo", efecto.ContratoCodigo.ToString()).Replace("@version", efecto.DatosParaRemesar.ContratoVersion.ToString());
                                    validator.AddCustomMessage(strCustomMessage);
                                }

                                if (!validarEfectoPendiente(efectoPendiente))
                                {
                                    if (efectoPendiente.FechaRemesada.HasValue)
                                        strCustomMessage = Resource.efectoPendienteRemesado;
                                    else if (efectoPendiente.FechaRechazado.HasValue)
                                        strCustomMessage = Resource.efectoPendienteRechazado;

                                    strCustomMessage = strCustomMessage.Replace("@codigo", efectoPendiente.Codigo.ToString()).Replace("@periodo", efectoPendiente.PeriodoCodigo).Replace("@contrato", efectoPendiente.ContratoCodigo.ToString()).Replace("@facCod", efectoPendiente.FacturaCodigo.ToString());
                                    validator.AddCustomMessage(strCustomMessage);
                                }
                            }
                        }

                        //Si estamos ejecutando en modo tarea...
                        if (taskNumber.HasValue && taskType.HasValue && !String.IsNullOrEmpty(taskUser))
                        {
                            //Comprobar si se desea cancelar
                            if (cTaskManagerBL.CancelRequested(taskUser, taskType.Value, taskNumber.Value, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)
                            {
                                cancelar = true;
                                break; //** FINALLY **
                            }
                            //Incrementar el número de pasos
                            cTaskManagerBL.PerformStep(taskUser, taskType.Value, taskNumber.Value);
                        }

                        #endregion
                    }

                    #endregion
                } while (false);
            }

            catch
            {
                if (!string.IsNullOrEmpty(strErrMessage))
                    validator.AddCustomMessage(strErrMessage);
            }

            finally
            {
                
                log += validator.Validate(true);

                #region cerramos el xml de la remesa si está abierto con registros
                if (xmlWriter != null && remesados > 0)
                {
                    result = xmlRemesaCierre(ref xmlWriter, ref sw, remesados, totalRemesa);
                }
                else
                {
                    result = null;
                }
                #endregion

                //Actualizamos los importes antes de obtener por si ha habido algún cambio.
                respuesta = ActualizarImportes();

                if (respuesta.Resultado != ResultadoProceso.OK)
                    result = null;


                if (cancelar && banco != null && banco.NumRemesa != null)
                {
                    //Borramos todos los cobros que se han dado con la remesa.
                    //Quitamos la referencia a la remesa en las facturas.
                    cCobrosBL.BorrarRemesa(banco.NumRemesa??0, ahora, usuarioCodigo, out respuesta);
                    result = null;
                }           
            }

            return result == null ? string.Empty : result.ToString();
        }


        private void RemesaCobroLogging(DateTime fInicio, int numRemesa, cRemesaTrabBO efecto, cEfectoPendienteBO efectoPendiente) 
        {
            try
            {
                DateTime fFin = DateTime.Now;
                string tEjecucion = Math.Round(fFin.Subtract(fInicio).TotalMilliseconds * 0.001, 2, MidpointRounding.AwayFromZero).ToString();
                string mensaje = string.Format("Remesa: {0} | Factura: {1} | Ejecución: {2} seg."
                    , numRemesa
                    , msgFactura(efectoPendiente, efecto)
                    , tEjecucion);

                RemesaLogging(LogRemesa.FIN, MethodBase.GetCurrentMethod().Name, mensaje);
            }
            catch { }
        }

        private string msgFactura(cEfectoPendienteBO efectoPendiente, cRemesaTrabBO efecto)
        {
            string result = "facCod-facCtrCod-facPerCod-facVersion";
            try
            {
                result = string.Format("{0}-{1}-{2}-v{3}"
                   , efectoPendiente != null ? efectoPendiente.FacturaCodigo : efecto.FacturaCodigo
                   , efectoPendiente != null ? efectoPendiente.ContratoCodigo : efecto.ContratoCodigo
                   , efectoPendiente != null ? efectoPendiente.PeriodoCodigo : efecto.PeriodoCodigo
                   , efectoPendiente != null ? 0 : efecto.Factura.Version);
            }
            catch { }

            return result;
        }


        #endregion
    }
}
