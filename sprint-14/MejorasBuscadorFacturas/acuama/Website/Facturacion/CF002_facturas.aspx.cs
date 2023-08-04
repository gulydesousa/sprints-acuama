using System;
using System.Collections;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Acuama;
using BO.Facturacion;
using BO.Comun;
using BO.Resources;
using BO.Catastro;
using BO.Almacen;
using BO.Sistema;
using BL.Almacen;
using BL.Catastro;
using BL.Cobros;
using BL.Comun;
using BL.Facturacion;
using BL.Sistema;
using Acuama.WebControls;

public partial class Facturacion_CF002_Facturas : PageBase
{
    #region Paginación Optimizada

    //METODO
    private void gvPaging_SetNumberOfPages(Comun_Controles_ctrGridViewPager gvPager, GridView gv, AcuamaDataSource ds)
    {
        gvPager.Visible = gvPager.SetNumberOfPages(gv, ds);
        //upFacCab.Update();
    }

    //METODO
    private string gvPaging_MoveToPage(string pagina, Comun_Controles_ctrGridViewPager gvPager, GridView gv, AcuamaDataSource ds, string accion = "")
    {
        string result;

        int? pageNumber = pFormularios.GetPageMove(pagina, accion);
        result = gvPager.MoveToPage(pageNumber, gv, ds);

        return result;
    }

    //METODO
    private void facGridViewPager_IraPag()
    {
        string pagina = hfFacGridViewPage.Value;

        hfFacGridViewPage.Value =
        gvPaging_MoveToPage(pagina, facGridViewPager, gvFacCab, odsFacCab);
    }


    //EVENTO: GridView.OnDataBound
    //Para actualizar la posición del paginador
    protected void gvFacCab_OnDataBound(object sender, EventArgs e)
    {
        gvPaging_SetNumberOfPages(facGridViewPager, gvFacCab, odsFacCab);
    }

    //EVENTO: GridView.OnButtonClick
    //Para navegar en la paginación por los botones.
    protected void facGridViewPager_OnButtonClick(object sender, EventArgs e)
    {
        string accion = ((Button)sender).CommandArgument;

        hfFacGridViewPage.Value=
        gvPaging_MoveToPage(facGridViewPager.PaginaIr, facGridViewPager, gvFacCab, odsFacCab, accion);
    }


    //EVENTO: GridViewPager.OnIraPagChanged
    //Para cambiar el indice de paginación.
    protected void facGridViewPager_IraPagChanged_(object sender, CommandEventArgs e)
    {
        string pagina = e.CommandArgument.ToString();

        hfFacGridViewPage.Value =
        gvPaging_MoveToPage(pagina, facGridViewPager, gvFacCab, odsFacCab);
    }
    
    #endregion



    private bool esCanal()
    {        
        return CodigoExplotacion.Equals("008");
    }

    private bool hayQueAplicarDiferidosSoloEnUnaFactura()
    {
        bool aplicarDiferidosSoloEnUnaFactura = false;
        cRespuesta respuesta = new cRespuesta();
        cFacturaBO facturaParaActualizar = new cFacturaBO();

        string zona = string.Empty;
        string periodo = string.Empty;

        if (facturaBO != null)
        {
            zona = facturaBO.ZonaCodigo;
            periodo = facturaBO.PeriodoCodigo;
        }
        else
        {
            ctrFacCabCRU.RellenarObjeto(ref facturaParaActualizar);
            zona = facturaParaActualizar.ZonaCodigo;
            periodo = facturaParaActualizar.PeriodoCodigo;
        }

        if (!string.IsNullOrEmpty(zona) && !string.IsNullOrEmpty(periodo))
            aplicarDiferidosSoloEnUnaFactura = cFacturasBL.ObtenerAplicarDiferidosSoloEnUnaFactura(zona, periodo, out respuesta);

        return (aplicarDiferidosSoloEnUnaFactura && respuesta.Resultado == ResultadoProceso.OK);
    }

    protected int DeletingGridViewRowIndex
    {
        get { return ViewState["deletingGridViewRowIndex"] == null ? -1 : Convert.ToInt32(ViewState["deletingGridViewRowIndex"]); }
        set { ViewState["deletingGridViewRowIndex"] = value; }
    }

    cFacturaBO facturaBO;

    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        ctrBotonesFacCab.Add("actualizarVersionCtr", "~/Comun/Imagenes/Botones/actualizar.png", Resource.actualizarVersionCtr, Comun_Controles_ctrBotones.Permisos.Modificar);
        ctrBotonesFacCab.Add("generarRectificativa", "~/Comun/Imagenes/Botones/rectificar.png", Resource.generarRectificativa, Comun_Controles_ctrBotones.Permisos.Modificar);
               
        if (esCanal())
        {            
            ctrBotonesFacCab.Add("CierreRectificativaeHija", "~/Comun/Imagenes/Botones/aceptar.png", Resource.cierreFacturacion, Comun_Controles_ctrBotones.Permisos.Modificar);
            ctrBotonesFacCab.Add("aplicacionDiferidos", "~/Comun/Imagenes/Botones/diferidos.png", Resource.aplicacionDeDiferidos, Comun_Controles_ctrBotones.Permisos.Modificar);
        }
        ctrBotonesFacCab.Add("mostrarDatosRegistro", "~/Comun/Imagenes/Botones/time.png", Resource.mostrarDatosRegistro, Comun_Controles_ctrBotones.Permisos.Ninguno);
        ctrBotonesFacCab.Add("actualizarContrato", "~/Comun/Imagenes/Botones/change.png", Resource.actualizarContratoEnFactura, Comun_Controles_ctrBotones.Permisos.Ninguno);
        ctrBotonesFacCab.Add("efectoPendienteRemesa", "~/Comun/Imagenes/Botones/money.png", Resource.efectosPendientesRemesar, Comun_Controles_ctrBotones.Permisos.Ninguno);
        ctrBotonesFacCab.Add("linkFacturaE", "~/Comun/Imagenes/Botones/earth.png", Resource.enlaceFacturaElectronica, Comun_Controles_ctrBotones.Permisos.Ninguno);
        ctrBotonesFacCab.Add("estadosFacturaE", "~/Comun/Imagenes/Botones/subrogar.png", Resource.historicoEstadosFacturaElectronica, Comun_Controles_ctrBotones.Permisos.Ninguno);
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            ctrBotonesFacLin.SetVisible("buscar",false);
            gvFacCab.AlternatingRowStyle.BackColor = cVarios.ColorHex2Object(pFormularios.GetColorSeccion(this.Page, "secciones"));
            gvFacLin.AlternatingRowStyle.BackColor = cVarios.ColorHex2Object(pFormularios.GetColorSeccion(this.Page, "secciones"));

            tabFacLin.Visible = false;

            ctrBotonesFacCab.SetVisible("borrar_marcados", false);
            ctrBotonesFacCab.SetVisible("marcar", false);
            ctrBotonesFacCab.SetVisible("desmarcar", false);
            ctrBotonesFacLin.SetVisible("imprimir", false);
            ctrBotonesFacLin.SetVisible("buscar", false);
            ctrBotonesFacLin.SetVisible("marcar", false);
            ctrBotonesFacLin.SetVisible("desmarcar", false);
            ctrBotonesFacLin.SetVisible("borrar_marcados", false);

            //Si estamos en modo búsqueda (llamada desde otro formulario):
            if (Server.UrlDecode(Request.QueryString["accion"]) == "buscar")
                botonesOkCancelModoBuscar.Visible = true;

            optSel_Borrar_o_Anular.Title = Resource.elijaUnaAccion;
            optSel_Borrar_o_Anular.Items.Add(new ListItem(Resource.anular, "anular"));
            optSel_Borrar_o_Anular.Items.Add(new ListItem(Resource.borrar, "borrar"));
            optSel_Borrar_o_Anular.OnOkClientClick = "HideModalPopup('bid_Borrar_o_Anular');";
            optSel_Borrar_o_Anular.OnCancelClientClick = optSel_Borrar_o_Anular.OnOkClientClick + "return false;";

            optSel_Actualizar_o_NewVersion.Title = Resource.elijaUnaAccion;
            optSel_Actualizar_o_NewVersion.Items.Add(new ListItem(Resource.actualizar, "actualizar"));
            optSel_Actualizar_o_NewVersion.Items.Add(new ListItem(Resource.crearNuevaVersion, "crearNuevaVersion"));

        }
    }

    protected void optSel_Borrar_o_Anular_OkClick(object sender, CommandEventArgs e)
    {
        cRespuesta respuesta = new cRespuesta();

        if ((string)e.CommandArgument == "borrar")
            respuesta = BorrarFactura(DeletingGridViewRowIndex);
        else if ((string)e.CommandArgument == "anular")
        {
            respuesta = GenerarRectificativa(DeletingGridViewRowIndex);

            if(respuesta.Resultado == ResultadoProceso.OK)
                MsgBox.ShowMsg(upFacCab, Resource.info, Resource.infoFacturaAnulada, MsgBox.MsgType.Information);
        }

        if (respuesta.Resultado == ResultadoProceso.OK)
            gvFacCab.DataBind();
        else
            MsgBox.ShowMsg(upFacCab, Resource.error, respuesta.Ex.Message, MsgBox.MsgType.Error);

        DeletingGridViewRowIndex = -1;
    }

    protected void optSel_Actualizar_o_NewVersion_OkClick(object sender, CommandEventArgs e)
    {
        if ((string)e.CommandArgument == "actualizar")
            ctrFacCabCRU.CambiarModo(FormMode.Edit);
        else if ((string)e.CommandArgument == "crearNuevaVersion")
            MostrarMensajeEstablecerSociedadYSerie();
    }

    protected void optSel_Actualizar_o_NewVersion_CancelClick(object sender, EventArgs e)
    {
        mpeActualizar_o_NewVersion.Hide();
        upFacCab.Update();
    }

    protected void Page_PreRender(object sender, EventArgs e)
    {
        cRespuesta respuesta;
        if (!Page.IsPostBack)
        {
            spContrato.InnerText = Resource.contrato;
            spPeriodo.InnerText = Resource.periodo;

            //Idiomas de las columnas del GridView de las Cabeceras de Factura
            pFormularios.GetGVColumn("PeriodoCodigo", gvFacCab).HeaderText = Resource.periodo;
            pFormularios.GetGVColumn("SerieCodigo", gvFacCab).HeaderText = Resource.serie;
            pFormularios.GetGVColumn("Numero", gvFacCab).HeaderText = Resource.numero;
            pFormularios.GetGVColumn("ZonaCodigo", gvFacCab).HeaderText = Resource.zona;
            pFormularios.GetGVColumn("ContratoCodigo", gvFacCab).HeaderText = Resource.contrato;
            pFormularios.GetGVColumn("Version", gvFacCab).HeaderText = Resource.versionFacturaAbv;
            pFormularios.GetGVColumn("Fecha", gvFacCab).HeaderText = Resource.fecha;
            pFormularios.GetGVColumn("ClienteCodigo", gvFacCab).HeaderText = Resource.cliente;
            pFormularios.GetGVColumn("Importe", gvFacCab).HeaderText = Resource.importe;
            pFormularios.GetGVColumn("Consumo", gvFacCab).HeaderText = Resource.consumo;
            pFormularios.GetGVColumn("FacCod", gvFacCab).HeaderText = Resource.codigo;
            pFormularios.GetGVColumn("FacCod", gvFacCab).Visible = false;

            //Idiomas de las columnas del GridView de las Lineas de Factura
            pFormularios.GetGVColumn("NumeroLinea", gvFacLin).HeaderText = Resource.linea;
            pFormularios.GetGVColumn("CodigoServicio", gvFacLin).HeaderText = Resource.servicio;
            pFormularios.GetGVColumn("Precio", gvFacLin).HeaderText = Resource.precio;
            pFormularios.GetGVColumn("Unidades", gvFacLin).HeaderText = Resource.cantidad;
            pFormularios.GetGVColumn("ImporteCuota", gvFacLin).HeaderText = Resource.cuota;
            pFormularios.GetGVColumn("Consumo", gvFacLin).HeaderText = Resource.consumo;
            pFormularios.GetGVColumn("ImporteConsumo", gvFacLin).HeaderText = Resource.totConsumo;
            pFormularios.GetGVColumn("Total", gvFacLin).HeaderText = Resource.total;
            
            //Idiomas de las pestañas
            tabFacCab.InnerHtml = Resource.facturas.ToUpper();
            tabFacLin.InnerHtml = Resource.lineas.ToUpper();

            //Si se abre este form en modo consulta, filtramos para que sólo aparezca ese registro
            //en el grid y llamamos a la función consultar indicando el nº de línea (la primera)
            if (Server.UrlDecode(Request.QueryString["accion"]) == "consultar")
            {
                gvFacCab.DataSourceID = "odsFacCab";
                if (gvFacCab.Rows.Count == 1)
                    gvFacCab_RowCommand(gvFacCab, new GridViewCommandEventArgs(this, new CommandEventArgs("Consultar", 0)));
                else
                    MsgBox.ShowMsg(upFacCab, Resource.info, Resource.errorNoExiste, MsgBox.MsgType.Information);
            }
            else
            {
                if ((Request.QueryString["contratoCodigo"] != null) && (Server.UrlDecode(Request.QueryString["periodoCodigo"]).StartsWith("000")))
                {
                    divHueco.Style["display"] = divInfo.Style["display"] = String.Empty;
                    spPeriodoCab.InnerHtml = string.Format("{0}:", Resource.periodo);
                    spContratoCab.InnerHtml = string.Format("{0}:", Resource.contrato); 
                    lblPeriodoCab.Text = Server.UrlDecode(Request.QueryString["periodoCodigo"]);
                    lblContraroCab.Text = Server.UrlDecode(Request.QueryString["contratoCodigo"]);

                    pFormularios.GetGVColumn("Numero", gvFacCab).Visible = pFormularios.GetGVColumn("SerieCodigo", gvFacCab).Visible = true;

                    pFormularios.GetGVColumn("FacCod", gvFacCab).Visible = pFormularios.GetGVColumn("ClienteCodigo", gvFacCab).Visible = pFormularios.GetGVColumn("Consumo", gvFacCab).Visible = pFormularios.GetGVColumn("ZonaCodigo", gvFacCab).Visible = pFormularios.GetGVColumn("Version", gvFacCab).Visible = pFormularios.GetGVColumn("ContratoCodigo", gvFacCab).Visible = pFormularios.GetGVColumn("PeriodoCodigo", gvFacCab).Visible = pFormularios.GetGVColumn("borrar", gvFacCab).Visible = pFormularios.GetGVColumn("editar", gvFacCab).Visible = false;
                    pFormularios.GetGVColumn("Importe", gvFacCab).HeaderStyle.Width = 200;
                    
                    botonesOkCancelModoBuscar.Visible = true;
                    ctrBotonesFacCab.Visible = false;
                    
                    SortedList campoBusqueda = new SortedList();

                    campoBusqueda["periodo"] = Server.UrlDecode(Request.QueryString["periodoCodigo"]);
                    campoBusqueda["contrato"] = Server.UrlDecode(Request.QueryString["contratoCodigo"]);

                    hfFiltro.Value = cFacturasBL.ConstruirFiltroSQL(campoBusqueda, out respuesta);

                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        gvFacCab.DataSourceID = "odsFacCab";
                        gvFacCab.DataBind();
                        upFacCab.Update();
                    }
                }
                else
                {
                    if (Request.QueryString["otCtrCod"] != null && Request.QueryString["otSociedad"] != null && Request.QueryString["otSerie"] != null && Request.QueryString["otNumero"] != null)
                    {
                        //Asignar visibilidad y valores a los campos de información de la orden de trabajo
                        pFormularios.SetHtmlControlVisible(divInfoOtCabecera, true);

                        cOrdenTrabajoBO ordenTrabajoBO = new cOrdenTrabajoBO();
                        ordenTrabajoBO.Serscd = Convert.ToInt16(Server.UrlDecode(Request.QueryString["otSociedad"]));
                        ordenTrabajoBO.Sercod = Convert.ToInt16(Server.UrlDecode(Request.QueryString["otSerie"]));
                        ordenTrabajoBO.Numero = Convert.ToInt32(Server.UrlDecode(Request.QueryString["otNumero"]));
                        ordenTrabajoBO.ContratoCodigo = Convert.ToInt32(Server.UrlDecode(Request.QueryString["otCtrCod"]));

                        cOrdenTrabajoBL.ObtenerSerie(ref ordenTrabajoBO, out respuesta);
                        cOrdenTrabajoBL.ObtenerSociedad(ref ordenTrabajoBO, out respuesta);

                        spOtSociedad.InnerHtml = Resource.sociedad;
                        lbOtSociedad.Text = string.Format(": {0}- {1}",ordenTrabajoBO.Serscd, ordenTrabajoBO.SociedadBO.Nombre);

                        spOtSerie.InnerHtml = Resource.serie;
                        lbOtSerie.Text = string.Format(": {0}- {1}", ordenTrabajoBO.Sercod, ordenTrabajoBO.SerieBO.Descripcion);

                        spOtNumero.InnerHtml = Resource.numero;
                        lbOtNumero.Text = string.Format(": {0}", ordenTrabajoBO.Numero.ToString());

                        //Ocultar botones no válidos
                        ctrBotonesFacCab.SetVisible("insertar", false);
                        ctrBotonesFacCab.SetVisible("imprimir", false);
                        ctrBotonesFacCab.SetVisible("buscar", false);

                        //Rellenar datos información de la orden de trabajo y del contrato
                        gvFacCab.DataSourceID = "odsFacCab";
                        gvFacCab.DataBind();
                        upFacCab.Update();
                    }
                    else
                    {
                        divInfo.Style["display"] = "none";
                        mpefacFINDCab.Show();
                    }
                }
            }
        }
 
        //Establecer visibilidad de las pestañas
        tabFacLin.Visible = (ctrFacCabCRU.Modo == FormMode.Edit || ctrFacCabCRU.Modo == FormMode.ReadOnly);
        upTab.Update();

        //Bloquea el menu cuando se esta Insertando o Editando una linea
        if (ctrFacCabCRU.Modo == FormMode.Edit || ctrFacCabCRU.Modo == FormMode.Insert)
            ((Comun_Principal)Master).BloquearMenu(true);
        else
            ((Comun_Principal)Master).BloquearMenu(false);

        //Deshabilitar los controles innecesarios
        ((ImageButton)(ctrFacCabCRU.FindControl("imbfCabAceptar"))).Visible = !((ctrFacCabCRU.Modo == FormMode.ReadOnly) && (Server.UrlDecode(Request.QueryString["accion"]) == "consultar" ));        

        //Dibuja la página en función del modo en que nos encontremos
        //CABECERA
        pFormularios.EstablecerVisibilidadCliente(gridCab, detailCab, ctrFacCabCRU.Modo);
        ctrBotonesFacCab.SetVisible("actualizarVersionCtr", ctrFacCabCRU.Modo == FormMode.ReadOnly && !ctrFacCabCRU.EsFacturaRectif);
        ctrBotonesFacCab.SetVisible("generarRectificativa", !ctrFacCabCRU.EsPreFactura && ctrFacCabCRU.Modo == FormMode.ReadOnly && !ctrFacCabCRU.EsFacturaRectif);

        if (esCanal())
        {
            ctrBotonesFacCab.SetVisible("CierreRectificativaeHija", false);
            ctrBotonesFacCab.SetVisible("aplicacionDiferidos", false);

            cFacturaBO facturaParaActualizar = new cFacturaBO();
            ctrFacCabCRU.RellenarObjeto(ref facturaParaActualizar);

            int num = 0;

            if (facturaParaActualizar.Numero != null)
            {
                try
                {
                    num = Int32.Parse(facturaParaActualizar.Numero);
                }
                catch (FormatException)
                {
                    num = 0;
                }

                if (num < 0)
                {
                    ctrBotonesFacCab.SetVisible("CierreRectificativaeHija", !ctrFacCabCRU.EsPreFactura
                                                                           && ctrFacCabCRU.Modo == FormMode.ReadOnly
                                                                           && !ctrFacCabCRU.EsFacturaRectif);
                    ctrBotonesFacCab.SetVisible("aplicacionDiferidos", !ctrFacCabCRU.EsPreFactura
                                                                           && ctrFacCabCRU.Modo == FormMode.ReadOnly
                                                                           && !ctrFacCabCRU.EsFacturaRectif
                                                                           && hayQueAplicarDiferidosSoloEnUnaFactura());
                    ctrBotonesFacCab.SetVisible("generarRectificativa", false);
                }
                else
                {
                    ctrBotonesFacCab.SetVisible("CierreRectificativaeHija", false);
                    ctrBotonesFacCab.SetVisible("aplicacionDiferidos", false);
                }
            }

        }
        ctrBotonesFacCab.SetVisible("actualizarContrato", ctrFacCabCRU.Modo == FormMode.ReadOnly && !ctrFacCabCRU.EsFacturaRectif && ctrFacCabCRU.EsContratoBajaPorCambioTitular);

        string periodoInicio = cParametroBL.ObtenerValor("PERIODO_INICIO", out respuesta);

        //Solo se podrán mostrar efectos pendientes e insertarlos si es un periodo de contado o igual o mayor al periodo de inicio
        bool periodoCorrecto = respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrEmpty(ctrFacCabCRU.PeriodoCodigo) && (ctrFacCabCRU.PeriodoCodigo.StartsWith("000") || Convert.ToInt32(ctrFacCabCRU.PeriodoCodigo) >= Convert.ToInt32(periodoInicio));
        
        //Se debe poder generar un efecto a remesar siempre que no sea preFactura y que no este cobrada la totalidad del importe más los importes de los efectos pendientes que no este ni rechazados ni remesado.
        ctrBotonesFacCab.SetVisible("efectoPendienteRemesa", ctrFacCabCRU.Modo == FormMode.ReadOnly && periodoCorrecto && !ctrFacCabCRU.EsFacturaRectif && !ctrFacCabCRU.EsPreFactura && !ctrFacCabCRU.EsPreFacturaCerrada);
        ctrBotonesFacCab.SetVisible("mostrarDatosRegistro", ctrFacCabCRU.Modo == FormMode.ReadOnly);
        ctrBotonesFacCab.SetVisible("linkFacturaE", ctrFacCabCRU.Modo == FormMode.ReadOnly && ctrFacCabCRU.EsFacturaElectronica);
        ctrBotonesFacCab.SetVisible("estadosFacturaE", ctrFacCabCRU.Modo == FormMode.ReadOnly && ctrFacCabCRU.EsFacturaElectronica);
        
        //LINEAS
        //si la factura es una rectificativa ó es pre factura se puede editar
        ctrBotonesFacLin.SetVisible("borrar_marcados", (ctrFacLinCRU.EsFacturaDeHoy || ctrFacCabCRU.EsPreFactura) || ActualUserIsAdmin());
        ctrBotonesFacLin.SetVisible("marcar", (ctrFacLinCRU.EsFacturaDeHoy || ctrFacCabCRU.EsPreFactura) || ActualUserIsAdmin());
        ctrBotonesFacLin.SetVisible("desmarcar", (ctrFacLinCRU.EsFacturaDeHoy || ctrFacCabCRU.EsPreFactura) || ActualUserIsAdmin());
        ctrBotonesFacLin.SetVisible("insertar", ((ctrFacLinCRU.EsFacturaDeHoy || ctrFacCabCRU.EsPreFactura) && !ctrFacCabCRU.EsFacturaRectif) || ActualUserIsAdmin());

        upFacCab.Update();
    }
    
    #region CABECERA DE FACTURA
    /********************* CABECERA DE FACTURA *************************/

    protected void ctrBotonesFacCab_Click(object sender, CommandEventArgs e)
    {
        cRespuesta respuesta = null;
        cFacturaBO facturaParaActualizar = new cFacturaBO();
        bool existeApremio = false;
        switch ((string)e.CommandArgument)
        {
            case "insertar":
                ctrFacCabCRU.CambiarModo(FormMode.Insert);
                break;
            case "buscar":
                mpefacFINDCab.Show();
                break;
            case "actualizarVersionCtr":
                ctrFacCabCRU.RellenarObjeto(ref facturaParaActualizar);
                existeApremio = cApremiosLinBL.Existe(facturaParaActualizar.FacturaCodigo.Value, facturaParaActualizar.PeriodoCodigo, facturaParaActualizar.ContratoCodigo.Value, facturaParaActualizar.Version.Value, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                    MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                else
                {
                    //Comprobamos si la versión del contrato es igual a la ultima.
                    cFacturasBL.ObtenerContratoUltimaVersion(ref facturaParaActualizar, out respuesta);
                    if (facturaParaActualizar.Contrato != null && facturaParaActualizar.ContratoVersion.Value != facturaParaActualizar.Contrato.Version)
                        //lanzo el mensaje preguntando si esta seguro de continuar.
                        ScriptManager.RegisterStartupScript(upFacCab, typeof(string), "actualizar version contrato", MsgBox.GenerateConfirmJSCode(this.Page, ibActualizarVersionCtr, Resource.pregunta, Resource.confActualizarVersionCtr, false), true);
                    else
                        MsgBox.ShowMsg(upFacCab, Resource.info, Resource.infoContratoTieneUltimaVersión.Replace("@item", facturaParaActualizar.ContratoCodigo.Value.ToString()), MsgBox.MsgType.Information);
                }
                break;
            case "volver":
                ctrFacCabCRU.CambiarModo(FormMode.Nothing);
                #region Paginación Optimizada
                facGridViewPager_IraPag();
                #endregion
                break;
            case "editar":
                ctrFacCabCRU.RellenarObjeto(ref facturaParaActualizar);
                existeApremio = cApremiosLinBL.Existe(facturaParaActualizar.FacturaCodigo.Value, facturaParaActualizar.PeriodoCodigo, facturaParaActualizar.ContratoCodigo.Value, facturaParaActualizar.Version.Value, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                    MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                else
                {
                    if (facturaParaActualizar.ContratoCodigo.HasValue && facturaParaActualizar.ContratoVersion.HasValue)
                        EditarFactura(facturaParaActualizar.ContratoCodigo.Value, facturaParaActualizar.ContratoVersion.Value);
                    else
                        MsgBox.ShowMsg(upFacCab, Resource.error, Resource.errorProducidoError, MsgBox.MsgType.Error);
                }
                break;
            case "imprimir":
                // si imprimimos desde el modo consulta de una factura
                if (ctrFacCabCRU.Modo == FormMode.ReadOnly)
                    ctrFacCabCRU.Imprimir();
                else  // si estamos en el listado principal
                {
                    ctrFacturasPRINT.Inicializar();
                    mpefacPRINT.Show();
                }
                break;
            case "generarRectificativa":
                ctrFacCabCRU.RellenarObjeto(ref facturaParaActualizar);

                /*
                // Sólo se permite borrar si la factura no se ha enviado aún al SII o si se ha enviado de forma correcta
                string estadoFactura = cFacturasSIIBL.GetEstadoFacturaSII(
                   facturaParaActualizar.FacturaCodigo.Value, facturaParaActualizar.PeriodoCodigo, 
                   facturaParaActualizar.ContratoCodigo.Value, facturaParaActualizar.Version.Value, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK || respuesta.Resultado == ResultadoProceso.SinRegistros)
                {
                    if (!string.IsNullOrEmpty(estadoFactura) && !estadoFactura.Equals("S"))
                    {
                        MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.NoRectificarPorSII, MsgBox.MsgType.Information);
                        break;
                    }
                }
                /////////////
                */

                existeApremio = cApremiosLinBL.Existe(facturaParaActualizar.FacturaCodigo.Value, facturaParaActualizar.PeriodoCodigo, facturaParaActualizar.ContratoCodigo.Value, facturaParaActualizar.Version.Value, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                    MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                else
                {
                    if (String.IsNullOrWhiteSpace(facturaParaActualizar.Numero) && !facturaParaActualizar.SerieCodigo.HasValue && !facturaParaActualizar.SociedadCodigo.HasValue && !ctrFacCabCRU.EsPreFactura)
                        mpeDatosActualizarPreFactura.Show();
                    else
                        ctrFacCabCRU.GenerarRectificativa(false);
                }
                break;
                
            case "CierreRectificativaeHija":
                ctrFacCabCRU.GenerarCierreRectificativaeHijas();
                break;
            case "aplicacionDiferidos":
                ctrFacCabCRU.AplicacionDiferidosRectificativas();
                break;
            case "actualizarContrato":
                ctrFacCabCRU.RellenarObjeto(ref facturaParaActualizar);
                existeApremio = cApremiosLinBL.Existe(facturaParaActualizar.FacturaCodigo.Value, facturaParaActualizar.PeriodoCodigo, facturaParaActualizar.ContratoCodigo.Value, facturaParaActualizar.Version.Value, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                    MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                else
                {
                    if (ctrFacCabCRU.EsPreFacturaCerrada)
                        mpeDatosActualizarContratoPreFactura.Show();
                    else
                        ctrFacCabCRU.ActualizarContratoEnFactura(null, null);
                }
                break;
            case "mostrarDatosRegistro":
                //Crear la tabla a mostrar
                MsgBox.KeyValueTable table = new MsgBox.KeyValueTable();
                
                //Fecha de registro:
                if(ctrFacCabCRU.facturaBO.FechaRegistro.HasValue)
                    table.AddRow(Resource.fechaRegistro, ctrFacCabCRU.facturaBO.FechaRegistro.Value.ToString());
                
                //Usuario de registro:
                if (!String.IsNullOrEmpty(ctrFacCabCRU.facturaBO.UsuarioRegistro))
                    table.AddRow(Resource.usuarioDeRegistro, ctrFacCabCRU.facturaBO.UsuarioRegistro);


                //Usuario que ha contabilizado la factura
                if (!String.IsNullOrEmpty(ctrFacCabCRU.facturaBO.UsuarioContabilizacion))
                    table.AddRow(Resource.usuarioContabilizacion, ctrFacCabCRU.facturaBO.UsuarioContabilizacion);
                //Usuario que ha anulado la contabilización de la factura
                if (!String.IsNullOrEmpty(ctrFacCabCRU.facturaBO.UsuarioContabilizacionAnulada))
                    table.AddRow(Resource.usrAnuContabilizacion, ctrFacCabCRU.facturaBO.UsuarioContabilizacionAnulada);

                //Lector
                if (ctrFacCabCRU.facturaBO.LectorCodigoContratista.HasValue && ctrFacCabCRU.facturaBO.LectorCodigoEmpleado.HasValue)
                {
                    cEmpleadoBO empleadoLector = cEmpleadoBL.Obtener(ctrFacCabCRU.facturaBO.LectorCodigoEmpleado.Value, ctrFacCabCRU.facturaBO.LectorCodigoContratista.Value, out respuesta);
                    if(respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrEmpty(empleadoLector.Nombre))
                        table.AddRow(Resource.lector, empleadoLector.Nombre);
                }

                //Inspector
                if (ctrFacCabCRU.facturaBO.InspectorCodigoContratista.HasValue && ctrFacCabCRU.facturaBO.InspectorCodigoEmpleado.HasValue)
                {
                    cEmpleadoBO empleadoInspector = cEmpleadoBL.Obtener(ctrFacCabCRU.facturaBO.InspectorCodigoEmpleado.Value, ctrFacCabCRU.facturaBO.InspectorCodigoContratista.Value, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrEmpty(empleadoInspector.Nombre))
                        table.AddRow(Resource.inspector, empleadoInspector.Nombre);
                }

                //Mostrar la tabla
                table.Show(upFacCab);
                break;
        }
    }

    protected void EditarFactura(int contratoCodigo, short versionContrato)
    {
        //Comprobar si el contrato es comunitario u hijo, si lo es mostrar aviso
        cRespuesta respuesta;
        cContratoBO contrato = new cContratoBO();
        bool esHijo = false;
        bool esCtrComunitario = cContratoBL.ExistenContratosParticulares(contratoCodigo, out respuesta);

        if (respuesta.Resultado == ResultadoProceso.OK)
        {
            contrato.Codigo = contratoCodigo;
            contrato.Version = versionContrato;
            cContratoBL.Obtener(ref contrato, out respuesta);
            esHijo = contrato.ContratoComunitarioCodigo.HasValue;
        }

        if (!MsgBox.ShowMsgIfError(upFacCab, respuesta))
        {
            //Mostrar aviso si el contrato es comunitario o hijo de un contrato comunitario
            if (esHijo || esCtrComunitario)
            {
                string mensaje = esCtrComunitario ? Resource.contratoEsComunitario : String.Empty;
                mensaje += esHijo ? (!String.IsNullOrEmpty(mensaje) ? "<br/>" : String.Empty) + Resource.contratoVinculadoCtrComunitario.Replace("@item", contrato.ContratoComunitarioCodigo.ToString()) : String.Empty;
                ScriptManager.RegisterStartupScript(upFacCab, typeof(string), "contrato comunitario o hijo", MsgBox.GenerateConfirmJSCode(this.Page, ibEditarFactura, Resource.pregunta, mensaje + Resource.deseaContinuar, false), true);
            }
            else
                ibEditarFactura_Click(null, null);
        }
    }

    public void ibEditarFactura_Click(object sender, ImageClickEventArgs e)
    {
        if(((cUsuarioBO)cAplicacion.GetHttpSessionValue("usuario")).Perfil.Administrador && ctrFacCabCRU.EsPreFacturaCerrada)
            mpeActualizar_o_NewVersion.Show();
        else
            MostrarMensajeEstablecerSociedadYSerie();
    }

    protected void ctrBotonesFacCab_ModeChanged(object sender, EventArgs e)
    {
        //Abrir el mantenimiento de efectos pendientes de remesar
        string url = cMenuPerfilBL.GetURL((int)EMenu.Cobros.EfectosPendientes, ((cMenuPerfilBO)cAplicacion.GetHttpSessionValue("menuPerfil")).CodPerfil, "obtener=porFactura&periodoCodigo=" + ctrFacCabCRU.PeriodoCodigo + "&facturaCodigo=" + ctrFacCabCRU.FacturaCodigo.ToString() + "&contratoCodigo=" + ctrFacCabCRU.ContratoCodigo.ToString() + "&sociedadCodigo=" + ctrFacCabCRU.SociedadCodigo.ToString() + "&facturaVersion=" + ctrFacCabCRU.FacturaVersion.ToString() + "&contratoVersion=" + ctrFacCabCRU.VersionContrato.ToString());
        ctrBotonesFacCab.GetImageButton("efectoPendienteRemesa").OnClientClick =  pFormularios.GenerateModalPopupJSCode(ResolveUrl(url) , null,  ctrBotonesFacCab.GetImageButton("efectoPendienteRemesa").UniqueID ) + "return false;";
        
        ctrBotonesFacLin.KeepVisible("volver", ctrBotonesFacCab.GetVisible("volver"));
        upFacLin.Update();
    }

    protected void ibActualizarVersionCtr_Click(object sender, EventArgs e)
    {
        cRespuesta respuesta = null;
        string log = String.Empty;
        cFacturaBO factura = ctrFacCabCRU.ObtenerFacturaActual(out respuesta);
        if (respuesta.Resultado == ResultadoProceso.OK)
        {
            ctrFacCabCRU.RellenarObjeto(ref factura);
            cFacturasBL.ObtenerContratoUltimaVersion(ref factura, out respuesta);
        }
        if(respuesta.Resultado == ResultadoProceso.OK)
        {
            /* TODO:Sería conveniente sacarlo a una tabla o ponerlo en un enumerado para no tener todos los códigos de error aquí directamente
             
                Códigos de error para DNI no válido, se actualizará la factura SIN GENERAR NUEVA VERSION DE FACTURA, 
                dándo lugar a un nuevo envío.
                - Errores que provocan el rechazo del envío completo
                   4109, // El NIF no está identificado. NIF: XXXX
                   4111, // El NIF tiene un formato erróneo.
                -  Errores que provocan el rechazo de la factura (o de la petición completa si el error se produce en la cabecera)
	               1100, // Valor o tipo incorrecto del campo: XXXXX (sólo para campo NIF)
                   1104,  // Valor del campo ID incorrecto
                   1116, // El NIF no está identificado. NIF:XXXXX
                   1117, // El NIF no está identificado. NIF:XXXXX. NOMBRE_RAZON:YYYYY
                   1153, // El NIF tiene un formato erróneo
                   1168,  // El valor del CodigoPais solo puede ser 'ES' cuando el IDType sea '07'
                   1169, // El campo ID no contiene un NIF con formato correcto.
                   
                -  Errores que producen la aceptación y registro de la factura en el sistema (posteriormente deben ser corregidos)
                   2011 // El NIF de la contraparte no está censado
            */
            bool existeCodError = false;
            string codigoErrorSII = cFacturasSIIBL.GetCodigoErrorUltimoEnvio(factura.FacturaCodigo.Value, factura.PeriodoCodigo, factura.ContratoCodigo.Value, factura.Version.Value, out respuesta);
            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                for (int i = 0; (i < cFacturasSIILoteBL.errores_reenvio.Length && !existeCodError); i++)
                {
                    if (codigoErrorSII == cFacturasSIILoteBL.errores_reenvio[i])
                        existeCodError = true;
                }
            }
            if (existeCodError)
            {
                factura.ContratoVersion = factura.Contrato.Version;
                factura.ClienteCodigo = factura.Contrato.TitularCodigo;
                cFacturasBL.Actualizar(factura, false, out log, out respuesta);
            }
            else
            {
                if (respuesta.Resultado == ResultadoProceso.OK)
                {
                    //Si para esta factura y documento de identidad existe una respuesta SERES errónea, la factura se ACTUALIZARÁ SIN GENERAR RECTIFICATIVA
                    string compradorDocIden = (String.IsNullOrEmpty(factura.Contrato.PagadorDocIden) ? factura.Contrato.TitularDocIden : factura.Contrato.PagadorDocIden);
                    cBindableList<cSERESBO> seresConError = cSERESBL.ObtenerErroneos(factura.Numero, compradorDocIden, out respuesta);
                    if (seresConError.Count > 0)
                    {
                        factura.ContratoVersion = factura.Contrato.Version;
                        factura.ClienteCodigo = factura.Contrato.TitularCodigo;
                        cFacturasBL.Actualizar(factura, false, out log, out respuesta);
                    }
                    else
                    {
                        cFacturasBL.ActualizarVersionContrato(ref factura, ((cUsuarioBO)cAplicacion.GetHttpSessionValue("usuario")).Codigo, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                            ctrFacCabCRU.MensajeCobrosManuales(factura.FacturaCodigo.Value, factura.PeriodoCodigo, factura.ContratoCodigo.Value);
                    }
                }
                else
                    MsgBox.ShowMsgIfError(upFacCab, respuesta);
            }
        }
        if (respuesta.Resultado == ResultadoProceso.OK)
        {
            gvFacCab.DataBind();
            ctrFacCabCRU.RellenarCampos(factura);
            upFacCab.Update();
        }
        MsgBox.ShowMsgIfError(upFacCab, respuesta);
    }

    protected void CtrFacturasFIND_AceptarClick(object sender, CommandEventArgs e)
    {
        gvFacCab.DataSourceID = "odsFacCab";
        hfFiltro.Value = e.CommandArgument.ToString();
        mpefacFINDCab.Hide();
        pFormularios.GridViewGoToPage(gvFacCab, 0);
        upFacCab.Update();
    }

    protected void CtrFacturasFIND_CancelarClick(object sender, EventArgs e)
    {
        mpefacFINDCab.Hide();
    }

    protected cFacturaBO ObtenerCamposClaveSeleccionCAB(int gridViewRow)
    {
        facturaBO = new cFacturaBO();
        facturaBO.FacturaCodigo = (short?)Convert.ToInt16(((HiddenField)gvFacCab.Rows[gridViewRow].FindControl("hfFacturaCodigoCab")).Value);
        facturaBO.PeriodoCodigo = ((LinkButton)gvFacCab.Rows[gridViewRow].FindControl("lbPeriodo")).Text;
        facturaBO.ContratoCodigo = Convert.ToInt32(((Label)gvFacCab.Rows[gridViewRow].FindControl("lblContrato")).Text);
        facturaBO.Version = Convert.ToInt16(((Label)gvFacCab.Rows[gridViewRow].FindControl("lblVersion")).Text);
        facturaBO.SerieCodigo = ((HiddenField)gvFacCab.Rows[gridViewRow].FindControl("hfSerieCodigo")).Value == String.Empty ? null : (short?)Convert.ToInt16(((HiddenField)gvFacCab.Rows[gridViewRow].FindControl("hfSerieCodigo")).Value);
        facturaBO.SociedadCodigo = ((HiddenField)gvFacCab.Rows[gridViewRow].FindControl("hfSerScdCod")).Value == String.Empty ? null : (short?)Convert.ToInt16(((HiddenField)gvFacCab.Rows[gridViewRow].FindControl("hfSerScdCod")).Value);
        facturaBO.Numero = ((Label)gvFacCab.Rows[gridViewRow].FindControl("lblNumero")).Text == String.Empty ? null : ((Label)gvFacCab.Rows[gridViewRow].FindControl("lblNumero")).Text;
        facturaBO.Fecha = ((Label)gvFacCab.Rows[gridViewRow].FindControl("lblFecha")).Text == String.Empty ? null : (DateTime?)Convert.ToDateTime(((Label)gvFacCab.Rows[gridViewRow].FindControl("lblFecha")).Text);
       
        return facturaBO;
    }

    protected bool PasarSeleccionACRU(cFacturaBO facturaConCamposClave, bool editable)
    {
        bool resultado = false;
        cRespuesta respuesta = new cRespuesta();
        
        if (cFacturasBL.Obtener(ref facturaBO, out respuesta))
        {
            //Indicamos al control de lineas si la fecha de factura es de hoy
            ctrFacLinCRU.EsFacturaDeHoy = facturaBO.FechaRegistro.Value.ToShortDateString() == AcuamaDateTime.Today.ToShortDateString();
            ctrFacLinCRU.Editable = editable;
            ctrFacLinCRU.SociedadCodigo = facturaBO.SociedadCodigo; 
            bool zonaPeriodoAbierto = (new cPerzonaBL().ZonaYPeriodoAbierto(facturaBO.ZonaCodigo, facturaBO.PeriodoCodigo, out respuesta));
            ctrFacCabCRU.EsPreFactura = ctrFacLinCRU.EsPrefactura = !facturaBO.SerieCodigo.HasValue && !facturaBO.SociedadCodigo.HasValue && zonaPeriodoAbierto;
            ctrFacCabCRU.EsFacturaElectronica = !String.IsNullOrEmpty(facturaBO.EnvSERES);
            ctrFacCabCRU.RellenarCampos(facturaBO);
            ctrFacCabCRU.EsPreFacturaCerrada = String.IsNullOrWhiteSpace(facturaBO.Numero) && !facturaBO.SerieCodigo.HasValue && !facturaBO.SociedadCodigo.HasValue && !ctrFacCabCRU.EsPreFactura;
            cContratoBO contratoUltimaVersion = new cContratoBO();
            if (facturaBO.ContratoCodigo.HasValue)
            {
                contratoUltimaVersion.Codigo = facturaBO.ContratoCodigo.Value;
                cContratoBL.ObtenerUltimaVersion(ref contratoUltimaVersion, out respuesta);
                if(respuesta.Resultado == ResultadoProceso.OK)
                    ctrFacLinCRU.EsContratoPadre = cContratoBL.ExistenContratosParticulares(contratoUltimaVersion.Codigo, out respuesta);
            }

            ctrFacCabCRU.ContratoNuevo = contratoUltimaVersion.CodigoNuevo;
            ctrFacCabCRU.EsContratoBajaPorCambioTitular = respuesta.Resultado == ResultadoProceso.OK && contratoUltimaVersion != null && contratoUltimaVersion.CodigoNuevo.HasValue;

            if ( !String.IsNullOrEmpty(facturaBO.Numero) && facturaBO.ContratoCodigo.HasValue && facturaBO.ContratoVersion.HasValue)
            {
                cContratoBO contrato = new cContratoBO();
                contrato.Codigo = facturaBO.ContratoCodigo.Value;
                contrato.Version = facturaBO.ContratoVersion.Value;
                cContratoBL.Obtener(ref contrato, out respuesta);

                if(respuesta.Resultado == ResultadoProceso.OK)
                {
                    string compradorDocIden = (String.IsNullOrEmpty(contrato.PagadorDocIden) ? contrato.TitularDocIden : contrato.PagadorDocIden);
                    cSERESBO seres = cSERESBL.ObtenerUltimoLinkPorFactura(facturaBO.Numero, facturaBO.Fecha, compradorDocIden, out respuesta);
                    
                    if (respuesta.Resultado == ResultadoProceso.OK && !String.IsNullOrEmpty(seres.Link))
                        ctrBotonesFacCab.GetImageButton("linkFacturaE").OnClientClick = "javascript:window.open('" + seres.Link.Replace("&amp;", "&") + "')";
                    else
                        ctrBotonesFacCab.GetImageButton("linkFacturaE").OnClientClick = MsgBox.GenerateShowMsgJSCode(this.Page, Resource.info, Resource.noEnlaceAsociado, MsgBox.MsgType.Information);

                    //Histórico de estados SERES
                    string fechaFactura = "&fechafactura=" + (facturaBO.Fecha == null ? "" : facturaBO.Fecha.ToStringFormat("yyyy-MM-dd HH:mm:ss.FFF"));
                    string url = cMenuPerfilBL.GetURL((int)EMenu.Facturacion.EstadosSERES, ((cMenuPerfilBO)cAplicacion.GetHttpSessionValue("menuPerfil")).CodPerfil, "numerofactura=" + facturaBO.Numero + "&compradorDocIden=" + compradorDocIden + fechaFactura);
                    ctrBotonesFacCab.GetImageButton("estadosFacturaE").OnClientClick = pFormularios.GenerateModalPopupJSCode(ResolveUrl(url), null, ctrBotonesFacCab.GetImageButton("estadosFacturaE").UniqueID) + "return false;";
                }
            }

            ConstruirCabeceraInfo(facturaBO);
            ctrFacLinCRU.InicializarLin(facturaBO);
            gvFacLin.DataBind();
            upFacLin.Update();

            resultado = true;
        }

        MsgBox.ShowMsgIfError(upFacCab, respuesta);
        return resultado;
    }

    protected void gvFacCab_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        cRespuesta respuesta = null;
        switch (e.CommandName)
        {
            case "Consultar":
                bool editable = RegistroEditable(Convert.ToInt32(e.CommandArgument));
                if (PasarSeleccionACRU(ObtenerCamposClaveSeleccionCAB(Convert.ToInt32(e.CommandArgument)), editable))
                {
                    ctrBotonesFacCab.SetVisible("editar", editable || ActualUserIsAdmin());
                    ctrFacCabCRU.CambiarModo(FormMode.ReadOnly);
                }
                break;
            case "Editar":
                #region EDITAR
                if (RegistroEditable(Convert.ToInt32(e.CommandArgument)))
                {
                    if (PasarSeleccionACRU(ObtenerCamposClaveSeleccionCAB(Convert.ToInt32(e.CommandArgument)), true))
                    {
                        cFacturaBO factura = ctrFacCabCRU.ObtenerFacturaActual(out respuesta);
                        bool existeApremio = cApremiosLinBL.Existe(factura.FacturaCodigo.Value, factura.PeriodoCodigo, factura.ContratoCodigo.Value, factura.Version.Value, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                            MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                        else
                        {
                            if (respuesta.Resultado == ResultadoProceso.OK && factura.ContratoCodigo.HasValue && factura.ContratoVersion.HasValue)
                                EditarFactura(factura.ContratoCodigo.Value, factura.ContratoVersion.Value);
                            else
                                MsgBox.ShowMsg(upFacCab, Resource.error, Resource.errorProducidoError, MsgBox.MsgType.Error);
                        }
                    }
                }
                else 
                    MsgBox.ShowMsg(upFacCab, Resource.error, Resource.debeExistirSerieRelacionada, MsgBox.MsgType.Error);

                #endregion
                break;
            case "Borrar":
                #region BORRAR
                respuesta = new cRespuesta();
                facturaBO = ObtenerCamposClaveSeleccionCAB(Convert.ToInt32(e.CommandArgument));

                /*
                // Sólo se permite borrar si la factura no se ha enviado aún al SII o si se ha enviado de forma correcta
                string estadoFactura = cFacturasSIIBL.GetEstadoFacturaSII(
                   facturaBO.FacturaCodigo.Value, facturaBO.PeriodoCodigo, facturaBO.ContratoCodigo.Value, facturaBO.Version.Value, out respuesta);

                if (respuesta.Resultado == ResultadoProceso.OK || respuesta.Resultado == ResultadoProceso.SinRegistros)
                {
                    if (!string.IsNullOrEmpty(estadoFactura) && !estadoFactura.Equals("S"))
                    {
                        MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.NoAnularPorSII, MsgBox.MsgType.Information);
                        break;
                    }
                }
                /////////////
                */

                //Si el usuario es admin, preguntamos si quiere borrar la factura o generar una rectificativa.
                //Si es una prefactura, no preguntamos, directamente se borra
                if (ActualUserIsAdmin())
                {
                    if (!String.IsNullOrWhiteSpace(facturaBO.Numero))
                    {
                        DeletingGridViewRowIndex = Convert.ToInt32(e.CommandArgument);
                        mpeBorrar_o_Anular.Show();
                    }
                    else
                        respuesta = BorrarFactura(Convert.ToInt32(e.CommandArgument));
                }
                //Si no es administrador...
                else if (RegistroEditable(Convert.ToInt32(e.CommandArgument)))
                {
                    bool existeApremio = cApremiosLinBL.Existe(facturaBO.FacturaCodigo.Value, facturaBO.PeriodoCodigo, facturaBO.ContratoCodigo.Value, facturaBO.Version.Value, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                        MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                    else
                    {
                        if (String.IsNullOrWhiteSpace(facturaBO.Numero))
                            //borramos la factura de la BD
                            respuesta = BorrarFactura(Convert.ToInt32(e.CommandArgument));
                        else
                        {
                            //generar una rectificativa: duplicamos la factura y modificamos de la nueva factura las unidades de las líneas a cero.
                            respuesta = GenerarRectificativa(Convert.ToInt32(e.CommandArgument));
                            if (respuesta.Resultado == ResultadoProceso.OK)
                                MsgBox.ShowMsg(upFacCab, Resource.info, Resource.infoFacturaAnulada, MsgBox.MsgType.Information);
                            else
                                MsgBox.ShowMsg(upFacCab, Resource.error, Resource.debeExistirSerieRelacionada, MsgBox.MsgType.Error);
                        }
                    }
                }
                else
                    MsgBox.ShowMsg(upFacCab, Resource.info, !String.IsNullOrWhiteSpace(facturaBO.Numero) ? Resource.infoNoSePuedeAnular : Resource.infoNoSePuedeBorrar, MsgBox.MsgType.Information);

                if (respuesta.Resultado == ResultadoProceso.OK)
                    gvFacCab.DataBind();
                MsgBox.ShowMsgIfError(upFacCab, respuesta);
                #endregion
                break;
            case "Imprimir":
                #region IMPRIMIR
                if (PasarSeleccionACRU(ObtenerCamposClaveSeleccionCAB(Convert.ToInt32(e.CommandArgument)), true))
                {
                    facturaBO = ctrFacCabCRU.ObtenerFacturaActual(out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK && facturaBO.ContratoCodigo.HasValue && facturaBO.FacturaCodigo.HasValue && facturaBO.Version.HasValue && !String.IsNullOrEmpty(facturaBO.PeriodoCodigo))
                    {
                        // Recoger parámetros
                        int contrato = facturaBO.ContratoCodigo.Value;
                        short codigo = facturaBO.FacturaCodigo.Value;
                        string periodo = facturaBO.PeriodoCodigo;
                        short version = facturaBO.Version.Value;

                        bool duplicado = false;
                        string firmarFactura = String.Empty;
                        string waterMarkImageFilePath = duplicado ? Server.MapPath("~/imagenes/watermark_DUPLICADO.png").Replace("\\", "/") : String.Empty;

                        string script = "window.open('" + ResolveUrl("~/Facturacion/facturas.ashx?codigo=" + codigo + "&periodo=" + periodo + "&contrato=" + contrato + "&version=" + version + "&duplicado=" + duplicado + "&firmarFactura=" + firmarFactura + "&waterMarkImageFilePath=" + waterMarkImageFilePath) + "', '_self', 'location=yes');";
                        ScriptManager.RegisterStartupScript(Page, typeof(string), "visualizar factura", script, true);

                        //Limpiar caché para que al pulsar el botón volver del navegador no se quede en el pdf (Firefox versión escritorio windows)
                        Response.Cache.SetCacheability(HttpCacheability.NoCache);
                        Response.Cache.SetExpires(AcuamaDateTime.Now);
                        Response.Cache.SetNoServerCaching();
                        Response.Cache.SetNoStore();
                    }
                    else
                        MsgBox.ShowMsg(upFacCab, Resource.error, respuesta.Ex.Message, MsgBox.MsgType.Error);
                }else
                    MsgBox.ShowMsg(upFacCab, Resource.error, Resource.errorProducidoError, MsgBox.MsgType.Error);

            #endregion
            break;
        }
    }

    protected cRespuesta BorrarFactura(int gridViewRowIndex)
    {
        cFacturaBO factura = ObtenerCamposClaveSeleccionCAB(gridViewRowIndex);
        //BORRA la factura y sus líneas 
        cRespuesta respuesta = null;

        cFacturasBL.Borrar(facturaBO, out respuesta);
        return respuesta;
    }

    protected cRespuesta GenerarRectificativa(int gridViewRowIndex)
    {
        cFacturaBO factura = ObtenerCamposClaveSeleccionCAB(gridViewRowIndex);

        //Genera una rectificativa con el importe de sus líneas a 0 (Anula la factura) 
        cRespuesta respuesta = null;

         cFacturasBL.Obtener(ref facturaBO, out respuesta);
        if (respuesta.Resultado == ResultadoProceso.OK)
        {
            string log;
            cFacturasBL.Anular(facturaBO, ((cUsuarioBO)cAplicacion.GetHttpSessionValue("usuario")).Codigo, out log, out respuesta);

            if (!MsgBox.ShowMsgIfError(upFacCab, respuesta) && !String.IsNullOrEmpty(log))
                MsgBox.ShowMsg(upFacCab, Resource.info, log, MsgBox.MsgType.Information);
            if (respuesta.Resultado == ResultadoProceso.OK)
                ctrFacCabCRU.MensajeCobrosManuales(facturaBO.FacturaCodigo.Value, facturaBO.PeriodoCodigo, facturaBO.ContratoCodigo.Value);
        }

        return respuesta;
    }

    /// <summary>
    /// Comprueba si el registro seleccionado en el gridView se puede editar.
    /// NO se puede editar si:
    /// Si esta de baja o anulada.
    /// Si la serie no tiene serie relacionada y la factura NO esta abierta.(si la factura esta abierta no es necesario comprobar la serie rectificativa )
    /// </summary>
    /// <param name="gridViewRow">indice del grid</param>
    /// <returns>True si el registro es editable, false en caso contrario </returns>
    protected bool RegistroEditable(int gridViewRow)
    {
        bool resultado = true;
        cRespuesta respuesta = null;
        facturaBO = ObtenerCamposClaveSeleccionCAB(gridViewRow);

        //si el registro tiene serie reftificativa no se podra editar ya que se ha anulado o dado de baja
        if (((HiddenField)gvFacCab.Rows[gridViewRow].FindControl("hfSerieRefti")).Value == String.Empty)
        {
            //Si la factura está aperturada(serie, sociedad y número igual a null) no hay que comprobar si existe serie relacionada
            if (facturaBO.SerieCodigo.HasValue && facturaBO.SociedadCodigo.HasValue && !String.IsNullOrWhiteSpace(facturaBO.Numero) && facturaBO.Fecha.Value.ToShortDateString() != AcuamaDateTime.Today.ToShortDateString())
            {
                //Sólo dejamos editar si la serie de la factura tiene alguna serie relacionada
                cFacturasBL.ObtenerSerie(ref facturaBO, out respuesta);
                if (!MsgBox.ShowMsgIfError(upFacCab, respuesta))
                    if (facturaBO.Serie.SerieCodRel == 0 && facturaBO.Serie.SerieSociedadRel == 0)
                        resultado = false;
            }
        }
        else
            resultado = false;

        return resultado;
    }

    protected void gvFacCab_RowDataBound(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType == DataControlRowType.DataRow)
        {
            cRespuesta respuesta = null;
            bool resultado = false;

            cFacturaBO factura = (cFacturaBO)e.Row.DataItem;
            if (factura != null)
            {
                
                resultado = cFacturasBL.ObtenerContrato(ref factura, out respuesta);
                if (resultado && factura.Contrato != null)
                    ((Label)e.Row.FindControl("lblCliente")).Text = factura.Contrato.PagadorNombre != String.Empty ? factura.Contrato.PagadorNombre : factura.Contrato.TitularNombre;
                
                //Si el cliente se obtiene de la tabla de clientes y no está almacenado en el contrato, se debe rellenar el gridview con el nombre del cliente que está almacenado en la tabla clientes
                if (((Label)e.Row.FindControl("lblCliente")).Text == String.Empty && ((HiddenField)e.Row.FindControl("hfClienteCodigo")).Value != String.Empty)
                {
                    //A partir del código del cliente se obtiene el nombre almacenado en la tabla de clientes y se asigna a la columna del nombre en el gridview de contratos
                    cClienteBO cliente = new cClienteBO();
                    cliente.Codigo = Convert.ToInt32(((HiddenField)e.Row.FindControl("hfClienteCodigo")).Value);
                    cClienteBL.Obtener(ref cliente, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK)
                        ((Label)e.Row.FindControl("lblCliente")).Text = cliente.Nombre;
                }

                if (pFormularios.GetGVColumn("SerieCodigo", gvFacCab).Visible && ((HiddenField)e.Row.FindControl("hfSerieCodigo")).Value != String.Empty && !String.IsNullOrEmpty(((HiddenField)e.Row.FindControl("hfSerScdCod")).Value))
                {
                    cSerieBO serie = new cSerieBO();
                    serie.Codigo= Convert.ToInt16(((HiddenField)e.Row.FindControl("hfSerieCodigo")).Value);
                    serie.CodSociedad= Convert.ToInt16(((HiddenField)e.Row.FindControl("hfSerScdCod")).Value);
                    cSerieBL.Obtener(ref serie, out respuesta);

                    if (respuesta.Resultado == ResultadoProceso.OK)
                        ((Label)e.Row.FindControl("lblSerieCodigo")).Text = serie.Descripcion; 
                }

                //Obtener importe facturado
                respuesta = cFacturasBL.ObtenerImporteFacturado(ref factura, null);

                if (((Label)e.Row.FindControl("lblContrato")).Text != String.Empty && ((Label)e.Row.FindControl("lblVersion")).Text != String.Empty)
                {
                    ((Label)e.Row.FindControl("lblImporte")).Text = factura.TotalFacturado.HasValue ? factura.TotalFacturado.Value.ToString("N2") : "--";
//                    ((Label)e.Row.FindControl("lblCobrado")).Text = factura.TotalCobrado.HasValue ?  factura.TotalCobrado.Value.ToString("N2") : "--";
                }

                //Confirmación de borrado
                ((ImageButton)e.Row.FindControl("ibBorrarCab")).OnClientClick = MsgBox.GenerateConfirmJSCode(this.Page, (ImageButton)e.Row.FindControl("ibBorrarCab"), Resource.pregunta, string.Format("{0} <br/> {1}", Resource.confborrado.Replace("@item", string.Format("{0}: {1},  ", Resource.periodo, ((LinkButton)e.Row.FindControl("lbPeriodo")).Text) + string.Format("{0}: {1},  ", Resource.contrato, ((Label)e.Row.FindControl("lblContrato")).Text) + string.Format("{0}: {1}", Resource.version, ((Label)e.Row.FindControl("lblVersion")).Text)), Resource.confBorrarRegistroYLineas));

                //para asignar el texto a los tooltip
                ((CheckBox)e.Row.FindControl("cbSeleccionCab")).ToolTip = Resource.seleccionar;
                ((ImageButton)e.Row.FindControl("ibBorrarCab")).Attributes["title"] = Resource.borrar;
                ((ImageButton)e.Row.FindControl("ibEditarCab")).Attributes["title"] = Resource.editar;

                ((CheckBox)e.Row.FindControl("cbSeleccionCab")).Visible = (factura.SerieRectificativa == null) && (Request.QueryString["accion"] == "buscar");
                ((ImageButton)e.Row.FindControl("ibBorrarCab")).Visible = (factura.SerieRectificativa == null);
                
                // Se puede editar si no es rectificativa, o si lo es pero no se ha enviado bien al SII
                bool editable = (factura.SerieRectificativa == null);

                /*
                if (!editable) // Si es rectificativa
                {
                    string estadoFactura = cFacturasSIIBL.GetEstadoFacturaSII(
                       factura.FacturaCodigo, factura.PeriodoCodigo, factura.ContratoCodigo, factura.Version, out respuesta);

                    if (respuesta.Resultado == ResultadoProceso.OK || respuesta.Resultado == ResultadoProceso.SinRegistros)
                        editable = (!string.IsNullOrEmpty(estadoFactura) && !estadoFactura.Equals("S"));
                }
                /////////////
                */

                ((ImageButton)e.Row.FindControl("ibEditarCab")).Visible = editable; // (factura.SerieRectificativa == null);

                
                if (factura.FechaFactRectificativa == null)//Sólo para las facturas activas
                {
                    bool existeApremio = cApremiosLinBL.Existe(factura.FacturaCodigo.Value, factura.PeriodoCodigo, factura.ContratoCodigo.Value, factura.Version.Value, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                    {
                        //Establecer de color naranja las facturas en estado apremiado
                        ((LinkButton)e.Row.FindControl("lbPeriodo")).CssClass = "valorApremiado";
                        e.Row.CssClass = "gridViewRow valorApremiado";
                    }
                    else
                    {
                        //Obtener el importe cobrado
                        respuesta = cFacturasBL.ObtenerImporteCobrado(ref factura, null);
                        //Establecer de color rojo las facturas que tienen un importe pendiente
                        if ((factura.TotalFacturado.HasValue ? factura.TotalFacturado.Value : 0) - (factura.TotalCobrado.HasValue ? factura.TotalCobrado.Value : 0) > 0) // totalFact - totalCob > 0)
                        {
                            ((LinkButton)e.Row.FindControl("lbPeriodo")).CssClass = "valorNegativo";
                            e.Row.CssClass = "gridViewRow valorNegativo";
                        }
                    }
                }
            }

            //Si estamos en modo buscar, sólo permitimos seleccionar una fila:
            if (Request.QueryString["accion"] == "buscar")
                ((CheckBox)e.Row.FindControl("cbSeleccionCab")).Attributes["onclick"] = "javascript:UnselectAllRowsGV('" + ((CheckBox)e.Row.FindControl("cbSeleccionCab")).ClientID + "');";
        }
        else
        {
            //Establecer número de filas en el paginador
            if (e.Row.RowType == DataControlRowType.Pager)
                ((Comun_Controles_ctrGridViewPager)e.Row.FindControl("ctrGridViewPagerCab")).SetNumberOfPages(gvFacCab);
        }
    }

    protected void ctrGridViewPagerCab_IraPagChanged(object sender, CommandEventArgs e)
    {
        //Ir a una página determinada
        pFormularios.GridViewGoToPage(gvFacCab, e.CommandArgument);
    }

    protected void ctrGridViewPagerLin_IraPagChanged(object sender, CommandEventArgs e)
    {
        //Ir a una página determinada
        pFormularios.GridViewGoToPage(gvFacLin, e.CommandArgument);
    }

    protected void CtrFacturaPRINT_CerrarClick(object sender, EventArgs e)
    {
        mpefacPRINT.Hide();
    }

    protected void ctrFacCabCRU_RegistroInsertado(object sender, CommandEventArgs e)
    {
        cRespuesta respuesta = null;
        facturaBO = (cFacturaBO)e.CommandArgument;
        ConstruirCabeceraInfo(facturaBO);
        ctrFacLinCRU.InicializarLin(facturaBO);
        bool facAperturada = new cPerzonaBL().ZonaYPeriodoAbierto(facturaBO.ZonaCodigo, facturaBO.PeriodoCodigo, out respuesta);

        if (respuesta.Resultado == ResultadoProceso.OK)
        {
            ctrFacCabCRU.EsPreFactura = facturaBO.SerieCodigo == null && facturaBO.SociedadCodigo == null && facAperturada;
            ctrFacCabCRU.EsPreFacturaCerrada = String.IsNullOrWhiteSpace(facturaBO.Numero) && !facturaBO.SerieCodigo.HasValue && !facturaBO.SociedadCodigo.HasValue && !ctrFacCabCRU.EsPreFactura;
            ctrFacLinCRU.Editable = ctrFacLinCRU.EsFacturaDeHoy = true;
            ctrFacLinCRU.SociedadCodigo = facturaBO.SociedadCodigo;

            cContratoBO contratoUltimaVersion = new cContratoBO();
            if (facturaBO.ContratoCodigo.HasValue)
            {
                contratoUltimaVersion.Codigo = facturaBO.ContratoCodigo.Value;
                cContratoBL.ObtenerUltimaVersion(ref contratoUltimaVersion, out respuesta);
            }

            ctrFacCabCRU.ContratoNuevo = contratoUltimaVersion.CodigoNuevo;
            ctrFacCabCRU.EsContratoBajaPorCambioTitular = respuesta.Resultado == ResultadoProceso.OK && contratoUltimaVersion != null && contratoUltimaVersion.CodigoNuevo.HasValue;

            gvFacLin.DataBind();
            upFacLin.Update();
        }
        else
            MsgBox.ShowMsgIfError(upFacCab, respuesta);
    }

    protected void ctrFacCabCRU_RegistroActualizado(object sender, CommandEventArgs e)
    {
        cRespuesta respuesta;
        cFacturaBO factura = ctrFacCabCRU.ObtenerFacturaActual(out respuesta);
        if (respuesta.Resultado == ResultadoProceso.OK)
        {
            ctrFacLinCRU.InicializarLin(factura);
            gvFacLin.DataBind();
            upFacLin.Update();
        }
        else
            MsgBox.ShowMsgIfError(upFacCab, respuesta);
    }

    protected void ctrFacCabCRU_Closed(object sender, EventArgs e)
    {
        ScriptManager.RegisterStartupScript(upFacCab, typeof(string), "select first tab", tabFacCab.Attributes["onclick"], true); //Mostrar la primera pestaña
        gvFacCab.DataBind();
        upFacCab.Update();
    }

    protected void odsFacCab_Selecting(object sender, ObjectDataSourceSelectingEventArgs e)
    {
        e.InputParameters.Clear();

        if (Request.QueryString["otCtrCod"] != null && Request.QueryString["otSociedad"] != null && Request.QueryString["otSerie"] != null && Request.QueryString["otNumero"] != null)
        {
            cOrdenTrabajoBO ot = new cOrdenTrabajoBO();
            ot.ContratoCodigo = Convert.ToInt32(Server.UrlDecode(Request.QueryString["otCtrCod"]));
            ot.Serscd = Convert.ToInt16(Server.UrlDecode(Request.QueryString["otSociedad"]));
            ot.Sercod = Convert.ToInt16(Server.UrlDecode(Request.QueryString["otSerie"]));
            ot.Numero = Convert.ToInt32(Server.UrlDecode(Request.QueryString["otNumero"]));

            odsFacCab.SelectMethod = "ObtenerPorContratoYOrdenTrabajo";
            e.InputParameters.Add("ot", ot);
        }
        else if (Server.UrlDecode(Request.QueryString["accion"]) == "consultar")
        {
            cFacturaBO facturaBO = new cFacturaBO();
            facturaBO.FacturaCodigo = Convert.ToInt16(Server.UrlDecode(Request.QueryString["facturaCodigo"]));
            facturaBO.ContratoCodigo = Convert.ToInt32(Server.UrlDecode(Request.QueryString["codigoContrato"]));
            facturaBO.PeriodoCodigo = Server.UrlDecode(Request.QueryString["periodoContrato"]);
            facturaBO.Version = Convert.ToInt16(Server.UrlDecode(Request.QueryString["versionFactura"]));

            odsFacCab.SelectMethod = "ObtenerLista";
            e.InputParameters.Add("factura", facturaBO);
        }
        else
        {
            odsFacCab.SelectMethod = "ObtenerPorFiltro";
            e.InputParameters.Add("filtro", hfFiltro.Value);
            e.InputParameters.Add("estadoDeuda", ctrFacturasFIND.EstadoDeuda);
            #region Paginación Optimizada
            e.InputParameters.Add("pageSize", gvFacCab.PageSize);
            e.InputParameters.Add("pageIndex", gvFacCab.PageIndex);
            e.InputParameters.Add("totalRowCount", odsFacCab.LastSelectTotalRowCount);
            #endregion
            e.InputParameters.Add("soloFacturase", ctrFacturasFIND.SoloFacturase);

        }
        e.InputParameters.Add("respuesta", null);
    }

    protected void ctrActualizarPreFacturaCerrada_Aceptar(object sender, EventArgs e)
    {
        if (ctrActualizarPreFacturaCerrada.SociedadCodigo.HasValue && ctrActualizarPreFacturaCerrada.SerieCodigo.HasValue)
        {
            cFacturaBO preFactura = new cFacturaBO();
            ctrFacCabCRU.RellenarObjeto(ref preFactura);
            preFactura.SociedadCodigo = ctrActualizarPreFacturaCerrada.SociedadCodigo;
            preFactura.SerieCodigo = ctrActualizarPreFacturaCerrada.SerieCodigo;

            ctrFacCabCRU.Sociedad = preFactura.SociedadCodigo;
            ctrFacCabCRU.Serie = preFactura.SerieCodigo;
            ctrFacCabCRU.Numero = preFactura.Numero;
            ctrFacCabCRU.RellenarCamposPrefactura();

            mpeDatosActualizarPreFactura.Hide();
            ctrFacCabCRU.CambiarModo(FormMode.Edit);

            if (ctrFacCabCRU.EsPreFacturaCerrada)
                ctrFacCabCRU.GenerarRectificativa(ctrFacCabCRU.EsPreFacturaCerrada);
        }
    }

    protected void ctrActualizarPreFacturaCerrada_Cancelar(object sender, EventArgs e)
    {
        mpeDatosActualizarPreFactura.Hide();
    }

    protected void ctrActualizarContratoPreFacturaCerrada_Aceptar(object sender, EventArgs e)
    {
        cRespuesta respuesta = new cRespuesta();
        if (ctrActualizarContratoPreFacturaCerrada.SociedadCodigo.HasValue && ctrActualizarContratoPreFacturaCerrada.SerieCodigo.HasValue)
        {
            ctrFacCabCRU.ActualizarContratoEnFactura(ctrActualizarContratoPreFacturaCerrada.SociedadCodigo, ctrActualizarContratoPreFacturaCerrada.SerieCodigo);
            mpeDatosActualizarContratoPreFactura.Hide();
        }
    }

    protected void ctrActualizarContratoPreFacturaCerrada_Cancelar(object sender, EventArgs e)
    {
        mpeDatosActualizarContratoPreFactura.Hide();
    }

    protected void MostrarMensajeEstablecerSociedadYSerie()
    {
        cFacturaBO facActPre = new cFacturaBO();
        ctrActualizarPreFacturaCerrada.Inicializar();

        ctrFacCabCRU.RellenarObjeto(ref facActPre);
        if (String.IsNullOrWhiteSpace(facActPre.Numero) && !facActPre.SerieCodigo.HasValue && !facActPre.SociedadCodigo.HasValue)
        {
            if (!ctrFacCabCRU.EsPreFactura && !ctrFacCabCRU.EsFacturaRectif)
                mpeDatosActualizarPreFactura.Show();
            else
                ctrFacCabCRU.CambiarModo(FormMode.Edit);
        }
        else
            ctrFacCabCRU.CambiarModo(FormMode.Edit);
    }

    #endregion

    #region LINEAS DE FACTURA
    /********************* LINEAS DE FACTURA *************************/
    protected void ctrBotonesFacLin_Click(object sender, CommandEventArgs e)
    {
        cRespuesta respuesta = null;
        switch ((string)e.CommandArgument)
        {
            case "insertar":
                facturaBO = new cFacturaBO();
                bool existeApremio = false;
                ctrFacLinCRU.RellenarObjetoCamposClave(ref facturaBO);
                if(facturaBO != null)
                    existeApremio = cApremiosLinBL.Existe(facturaBO.FacturaCodigo.Value, facturaBO.PeriodoCodigo, facturaBO.ContratoCodigo.Value, facturaBO.Version.Value, out respuesta);
                if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                    MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                else
                {
                    ctrFacLinCRU.EscaladosYTotalesVisibles(true);
                    ctrFacLinCRU.CambiarModo(FormMode.Insert);
                    mpeFacLinCRU.Show();
                }
                break;
            case "borrar_marcados":
                cLineaFacturaBO lineaFacturaBO = new cLineaFacturaBO();
                respuesta = new cRespuesta();
                cLineasFacturaBL cLineasFacturaBL = new cLineasFacturaBL();
                string error = String.Empty;
                int filas = gvFacLin.Rows.Count;

                for (int i = 0; i < filas; i++)
                {
                    if (((CheckBox)gvFacLin.Rows[i].FindControl("cbSeleccion")).Checked)
                    {
                        facturaBO = new cFacturaBO();
                        ctrFacLinCRU.RellenarObjetoCamposClave(ref facturaBO);
                        lineaFacturaBO.FacturaCodigo = facturaBO.FacturaCodigo.Value;
                        lineaFacturaBO.Periodo = facturaBO.PeriodoCodigo;
                        lineaFacturaBO.Contrato = facturaBO.ContratoCodigo.Value;
                        lineaFacturaBO.Version = facturaBO.Version.Value;
                        lineaFacturaBO.NumeroLinea = int.Parse(((LinkButton)gvFacLin.Rows[i].FindControl("lblNumeroLin")).Text);
                        if (!cLineasFacturaBL.Borrar(lineaFacturaBO, out respuesta))
                            error += respuesta.Ex.Message;
                    }
                }
                MsgBox.ShowMsg(upFacLin, Resource.error, error, MsgBox.MsgType.Error);
                ctrFacCabCRU.ActualizarGridsYTotales();
                gvFacLin.DataBind();
                break;
            case "volver":
                ctrFacCabCRU.CambiarModo(FormMode.Nothing); //Cierra el CRU de cabecera desde los botones de líneas
                break;
        }
    }

    protected cLineaFacturaBO ObtenerCamposClaveSeleccionLIN(int gridViewRow)
    {
        cLineaFacturaBO lineasFacturaBO = new cLineaFacturaBO();
        lineasFacturaBO.FacturaCodigo = Convert.ToInt16(((HiddenField)gvFacLin.Rows[gridViewRow].FindControl("hfFacturaCodigoLineas")).Value);
        lineasFacturaBO.Periodo = ((HiddenField)gvFacLin.Rows[gridViewRow].FindControl("hfPeriodo")).Value;
        lineasFacturaBO.Contrato = Convert.ToInt32(((HiddenField)gvFacLin.Rows[gridViewRow].FindControl("hfContrato")).Value);
        lineasFacturaBO.Version = Convert.ToInt16(((HiddenField)gvFacLin.Rows[gridViewRow].FindControl("hfVersion")).Value);
        lineasFacturaBO.NumeroLinea = Convert.ToInt32(((LinkButton)gvFacLin.Rows[gridViewRow].FindControl("lblNumeroLin")).Text);
        return lineasFacturaBO;
    }

    protected void gvFacLin_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        cLineaFacturaBO lineaFacturaBO;
        cRespuesta respuesta;
        cLineasFacturaBL clineasFacturaBL = new cLineasFacturaBL();
        string explotacionCodigo = cParametroBL.ObtenerValor("EXPLOTACION_CODIGO");
        bool existeApremio = false;

        switch (e.CommandName)
        {
            case "Consultar":
            case "Editar":
                #region EDITAR
                lineaFacturaBO = ObtenerCamposClaveSeleccionLIN(Convert.ToInt32(e.CommandArgument));
                //Si hay un cambio de tarifa a mitad de periodo (Guadalajara 01/09/2017) no permitimos editar las líneas para que no se quede mal el reparto de consumos y escalados
                if (!ActualUserIsAdmin() && (!ctrFacCabCRU.EsPreFactura && explotacionCodigo == "004" && e.CommandName == "Editar" && (cFacturasBL.ExisteCambioTarifa(lineaFacturaBO.Periodo, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)))
                    MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturasConRepartoCambioTarifa, MsgBox.MsgType.Warning);
                else
                {
                    clineasFacturaBL.Obtener(ref lineaFacturaBO, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK)
                    {
                        existeApremio = cApremiosLinBL.Existe(lineaFacturaBO.FacturaCodigo, lineaFacturaBO.Periodo, lineaFacturaBO.Contrato, lineaFacturaBO.Version, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                            MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                        else
                        {
                            ctrFacLinCRU.Editable = ((ImageButton)gvFacLin.Rows[Convert.ToInt32(e.CommandArgument)].FindControl("ibEditarGV")).Visible;
                            ctrFacLinCRU.RellenarCampos(lineaFacturaBO);
                            if (e.CommandName == "Editar")
                                ctrFacLinCRU.CambiarModo(FormMode.Edit);
                            else if (e.CommandName == "Consultar")
                                ctrFacLinCRU.CambiarModo(FormMode.ReadOnly);
                            mpeFacLinCRU.Show();
                        }
                    }
                }
                #endregion
                break;
            case "Borrar":
                #region BORRAR
                 lineaFacturaBO = ObtenerCamposClaveSeleccionLIN(Convert.ToInt32(e.CommandArgument));
                 
                /*
                 // Sólo se permite borrar si la factura no se ha enviado aún al SII o si se ha enviado de forma correcta
                 string estadoFactura = cFacturasSIIBL.GetEstadoFacturaSII(
                    lineaFacturaBO.FacturaCodigo, lineaFacturaBO.Periodo, lineaFacturaBO.Contrato, lineaFacturaBO.Version, out respuesta);

                 if (respuesta.Resultado == ResultadoProceso.OK || respuesta.Resultado == ResultadoProceso.SinRegistros)
                 {                  
                     if (!string.IsNullOrEmpty(estadoFactura) && !estadoFactura.Equals("S"))
                     {
                         MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.NoAnularPorSII, MsgBox.MsgType.Information);
                        break;
                     }
                 }
                 */

                //Si hay un cambio de tarifa a mitad de periodo (Guadalajara 01/09/2017) no permitimos editar las líneas para que no se quede mal el reparto de consumos y escalados
                if (!ActualUserIsAdmin() && (!ctrFacCabCRU.EsPreFactura && explotacionCodigo == "004" && (cFacturasBL.ExisteCambioTarifa(lineaFacturaBO.Periodo, out respuesta) && respuesta.Resultado == ResultadoProceso.OK)))
                    MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturasConRepartoCambioTarifa, MsgBox.MsgType.Warning);
                else
                {
                    existeApremio = cApremiosLinBL.Existe(lineaFacturaBO.FacturaCodigo, lineaFacturaBO.Periodo, lineaFacturaBO.Contrato, lineaFacturaBO.Version, out respuesta);
                    if (respuesta.Resultado == ResultadoProceso.OK && existeApremio)
                        MsgBox.ShowMsg(upFacCab, Resource.advertencia, Resource.infoFacturaBloqueadaGestionViaApremio, MsgBox.MsgType.Warning);
                    else
                    {
                        clineasFacturaBL.Borrar(lineaFacturaBO, out respuesta);
                        if (respuesta.Resultado == ResultadoProceso.OK)
                        {
                            ctrFacCabCRU.ActualizarGridsYTotales();
                            gvFacLin.DataBind();
                        }
                        else
                            MsgBox.ShowMsg(upFacLin, Resource.error, respuesta.Ex.Message, MsgBox.MsgType.Error);
                    }
                }
                #endregion
                break;
        }
    }

    protected void gvFacLin_RowDataBound(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType == DataControlRowType.DataRow)
        {
            cLineasFacturaBL lineasFacturaBL = new cLineasFacturaBL();
            cRespuesta respuesta = null;
            cLineaFacturaBO lineaFacturaBO = (cLineaFacturaBO)e.Row.DataItem;
            bool resultado = false;
            if (lineaFacturaBO != null)
            {
                resultado = lineasFacturaBL.ObtenerServicio(ref lineaFacturaBO, out respuesta);
                if (resultado && lineaFacturaBO.Servicio != null)
                {
                    if (lineaFacturaBO.Servicio.Descripcion == null)
                        lineaFacturaBO.Servicio.Descripcion = String.Empty;
                    ((Label)e.Row.FindControl("lblCodServ")).Text = string.Format("{0}-{1}", lineaFacturaBO.Servicio.Codigo, lineaFacturaBO.Servicio.Descripcion);
                }
            }

            //Ocultamos los botones del grid si la factura es una rectificativa
            bool editable = (facturaBO.SerieRectificativa == null && ctrFacLinCRU.EsFacturaDeHoy) || ctrFacCabCRU.EsPreFactura || ActualUserIsAdmin();
            ((CheckBox)e.Row.FindControl("cbSeleccion")).Visible = editable;
            ((ImageButton)e.Row.FindControl("ibBorraGV")).Visible = editable;
            ((ImageButton)e.Row.FindControl("ibEditarGV")).Visible = editable;
            
            //Línea liquidada, aplicar otro color para destacar
            ((HiddenField)e.Row.FindControl("hfFechaLiq")).Value = lineaFacturaBO.FechaLiquidacion.HasValue ? lineaFacturaBO.FechaLiquidacion.Value.ToShortDateString() : String.Empty;
            if (!String.IsNullOrEmpty(((HiddenField)e.Row.FindControl("hfFechaLiq")).Value))
            {
                ((LinkButton)e.Row.FindControl("lblNumeroLin")).CssClass += "valorLiquidado";
                e.Row.CssClass += "valorLiquidado gridViewRow";
                e.Row.ToolTip = string.Format("{0}: {1}-{2}", Resource.liquidado, ((HiddenField)(e.Row.FindControl("hfFechaLiq"))).Value, ((HiddenField)(e.Row.FindControl("hfUsrLiq"))).Value);
            }

            if (e.Row.FindControl("lblNumeroLin") != null)
                ((ImageButton)e.Row.FindControl("ibBorraGV")).OnClientClick = MsgBox.GenerateConfirmJSCode(this.Page, (ImageButton)e.Row.FindControl("ibBorraGV"), Resource.pregunta, Resource.confborrado.Replace("@item", ((LinkButton)e.Row.FindControl("lblNumeroLin")).Text) );

            //para asignar el texto a los tooltip
            ((CheckBox)e.Row.FindControl("cbSeleccion")).ToolTip = Resource.seleccionar;
            ((ImageButton)e.Row.FindControl("ibBorraGV")).Attributes["title"] = Resource.borrar;
            ((ImageButton)e.Row.FindControl("ibEditarGV")).Attributes["title"] = Resource.editar;
            
            //Datos para visualizar el desglose.
            string facturaCodigo, periodoCodigo, contratoCodgio, version, numeroLinea = String.Empty;
            facturaCodigo = ((HiddenField)e.Row.FindControl("hfFacturaCodigoLineas")).Value;
            periodoCodigo = ((HiddenField)e.Row.FindControl("hfPeriodo")).Value;
            contratoCodgio = ((HiddenField)e.Row.FindControl("hfContrato")).Value;
            version = ((HiddenField)e.Row.FindControl("hfVersion")).Value;
            numeroLinea = ((LinkButton)e.Row.FindControl("lblNumeroLin")).Text;
            string url = cMenuPerfilBL.GetURL((int)EMenu.Facturacion.Linea_Factura_Desglose, ((cMenuPerfilBO)cAplicacion.GetHttpSessionValue("menuPerfil")).CodPerfil, "facturaCodigo=" + facturaCodigo + "&periodoCodigo=" + periodoCodigo + "&contratoCodigo=" + contratoCodgio + "&version=" + version + "&numeroLinea=" + numeroLinea);
            ((ImageButton)e.Row.FindControl("ibfaclinDesglose")).OnClientClick =  pFormularios.GenerateModalPopupJSCode(ResolveUrl(url) , null,  ((ImageButton)e.Row.FindControl("ibfaclinDesglose")).UniqueID ) + "return false;";
            ((ImageButton)e.Row.FindControl("ibfaclinDesglose")).Attributes["title"] = Resource.desgloseLineaFactura;
            ((ImageButton)e.Row.FindControl("ibfaclinDesglose")).Visible = new cLineasFacturaBL().TieneDesglose(Convert.ToInt16(facturaCodigo), periodoCodigo, Convert.ToInt32(contratoCodgio), Convert.ToInt16(version), Convert.ToInt32(numeroLinea), out respuesta);
            MsgBox.ShowMsgIfError(upFacLin, respuesta);

            if (e.Row.FindControl("lblNumeroLin") != null)
                ((ImageButton)e.Row.FindControl("ibBorraGV")).OnClientClick = MsgBox.GenerateConfirmJSCode(this.Page, (ImageButton)e.Row.FindControl("ibBorraGV"), Resource.pregunta, string.Format("{0}. {1}", Resource.confborrado.Replace("@item", ((LinkButton)e.Row.FindControl("lblNumeroLin")).Text), ((ImageButton)e.Row.FindControl("ibfaclinDesglose")).Visible ? Resource.confirmBorrarTambienDesgloses : String.Empty));
        }
        else
        {
            //Establecer número de filas en el paginador
            if (e.Row.RowType == DataControlRowType.Pager)
                ((Comun_Controles_ctrGridViewPager)e.Row.FindControl("ctrGridViewPagerLin")).SetNumberOfPages(gvFacLin);
        }
    }

    protected void ibFaclinDesglose_Click(object sender, ImageClickEventArgs e)
    {
        gvFacLin.DataBind();
    }

    protected void odsFacLin_Selecting(object sender, ObjectDataSourceSelectingEventArgs e)
    {
        if (facturaBO == null)
        {
            facturaBO = new cFacturaBO();
            //Obtener las campos clave (periodo,contrato,version)de lineas
            ctrFacLinCRU.RellenarObjetoCamposClave(ref facturaBO);
        }
        //Asignamos el valor del parámetro factura
        e.InputParameters["facturaBO"] = facturaBO;
    }

    protected void ctrFacLinCRU_Closed(object sender, EventArgs e)
    {
        mpeFacLinCRU.Hide();
        gvFacLin.DataBind();
        ctrFacCabCRU.ActualizarGridsYTotales();
        upFacLin.Update();
    }

    #endregion

    #region FUNCIONES PROPIAS
    /// <summary>
    /// Construye la cabecera info con los datos a los que pertenecen las lineas
    /// </summary>
    /// <param name="facturaBO"> Objeto de facturas</param>
    protected void ConstruirCabeceraInfo(cFacturaBO facturaBO)
    {
        if (facturaBO != null && facturaBO.ContratoCodigo.HasValue && facturaBO.ContratoVersion.HasValue)
        {
            cRespuesta respuesta = null;
            cFacturasBL.ObtenerPeriodo(ref facturaBO, out respuesta);

            if (respuesta.Resultado == ResultadoProceso.OK)
            {
                lblContrato.Text = string.Format(": {0}", facturaBO.ContratoCodigo.ToString());
                lblPeriodoDes.Text = string.Format(": {0}", facturaBO.Periodo.Descripcion);
            }
            else
                MsgBox.ShowMsg(upFacCab, Resource.error, respuesta.Ex.Message, MsgBox.MsgType.Error);
        }
    }

    protected void ibAceptarBuscar_Click(object sender, ImageClickEventArgs e)
    {
        string seleccion = String.Empty;

        //Cogemos el seleccionado y cerramos la ventana
        for (int i = 0; (i < gvFacCab.Rows.Count && seleccion == String.Empty); i++)
            if (((CheckBox)gvFacCab.Rows[i].FindControl("cbSeleccionCab")).Checked)
            {
                seleccion = ((Label)gvFacCab.Rows[i].FindControl("lblContrato")).Text;
                seleccion += ";" + ((LinkButton)gvFacCab.Rows[i].FindControl("lbPeriodo")).Text;
                seleccion += ";" + ((Label)gvFacCab.Rows[i].FindControl("lblVersion")).Text;
                seleccion += ";" + ((Label)gvFacCab.Rows[i].FindControl("lblFacCod")).Text;
            }

        if (seleccion == String.Empty)
            MsgBox.ShowMsg(upFacCab, Resource.info, Resource.debeSeleccionarAlgunElemento, MsgBox.MsgType.Information);
        else
            ScriptManager.RegisterStartupScript(upFacCab, typeof(string), "busquedaFinalizada", "parent.HideModalIframe('" + seleccion + "');", true);

    }

#endregion

}
