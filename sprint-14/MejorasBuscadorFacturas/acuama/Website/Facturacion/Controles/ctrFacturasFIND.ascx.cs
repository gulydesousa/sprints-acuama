using System;
using System.Collections;
using System.Web.UI;
using System.Web.UI.WebControls;
using Acuama;
using BO.Comun;
using BO.Resources;
using BO.Facturacion;
using BL.Facturacion;
using System.Linq;
using System.Collections.Generic;
using BL.Sistema;

public partial class Facturacion_Controles_ctrFacturasFIND : System.Web.UI.UserControl
{
    #region EVENTOS
    public event CommandEventHandler AceptarClick;
    public event EventHandler CancelarClick;
    #endregion


    public List<cFacturaDeudaEstadoBO> EstadosDeuda
    {
        get
        {

            cRespuesta respuesta;
            cBindableList<cFacturaDeudaEstadoBO> result = null;
            cFacturaDeudaEstadosBL estadosDeuda = new cFacturaDeudaEstadosBL();

            try
            {
                result = (cBindableList<cFacturaDeudaEstadoBO>)cAplicacion.GetHttpSessionValue("estadosDeuda");

                if (result == null || result.Count == 0)
                {
                    result = estadosDeuda.ObtenerTodos(out respuesta);
                    cAplicacion.SetHttpSessionValue("estadosDeuda", result);
                }
                
            }
            catch { }
            finally { }

            return result.ToList();
    }

}

    /// <summary>
    /// Propiedad que indica si se ha habilitado la opción de búsqueda de solo facturas que sean electrónicas.
    /// </summary>
    public bool SoloFacturase
    {
        get { return ViewState["soloFacturase"] == null ? false : Convert.ToBoolean(ViewState["soloFacturase"]); }
        set { ViewState["soloFacturase"] = value; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            //asignación de la hoja de estilos
            cssLink.Attributes["href"] = ResolveUrl("~/Facturacion/Controles/ctrFacturas.css?refress=" + AcuamaDateTime.Now.ToString("dd/MM/yyyy"));

            rblOpciones.Items[0].Text = Resource.todas;
            rblOpciones.Items[1].Text = Resource.anuladas;
            rblOpciones.Items[2].Text = Resource.activas;

            rblFacturaE.Items[0].Text = Resource.todas;
            rblFacturaE.Items[1].Text = Resource.facturae;

            ftbContrato.MenuOption = (int)EMenu.Catastro.Contratos;
            ftbOTNumero.MenuOption = (int)EMenu.Almacen.OT_Mantenimiento;
            ftbUsrReg.MenuOption = (int)EMenu.Sistema.Usuarios;
            ftbFacPed.MenuOption = (int)EMenu.Facturacion.Periodos;
            ftbFacZon.MenuOption = (int)EMenu.Catastro.Zonas;
            ftbFacCli.MenuOption = (int)EMenu.Catastro.Clientes;
            lblCtrInmueble.Text = Resource.inmueble;
            ftbCtrInmueble.MenuOption = (int)EMenu.Catastro.Inmuebles;

            inicializarCampos();
        }
    }

    protected void Page_PreRender(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            lblFacPed.Text = Resource.periodo;
            lblFacZon.Text = Resource.zona;
            lblFacNum.Text = Resource.numero;
            lblSerie.Text = Resource.serie;
            lblFacCtr.Text = Resource.contrato;
            lblFacCli.Text = Resource.cliente;
            lblFacFec.Text = Resource.fecha_factura;
            lblFacVer.Text = Resource.version;
            lblOTNumero.Text = Resource.ordentrabajo;
            lblOTSerie.Text = Resource.serieDeOrdenDeTrabajoAbv;
            lblSociedad.Text = Resource.sociedad;
            lblModoFac.Text = Resource.buscar;
            divDesde.InnerText = Resource.desde;
            divHasta.InnerText = Resource.hasta;
            lblFacFecReg.Text = Resource.fechaReg_Abv;
            lblFacUsrReg.Text = Resource.usuario;

            inicializarLabels();
        }

        estilosEstadosDeuda();
    }

    protected void ibVaciar_Click(object sender, ImageClickEventArgs e)
    {
        pFormularios.ClearTextBoxes(upFind.ContentTemplateContainer.Controls);
        ftbContrato.Clear();
        ftbOTNumero.Clear();
        dtpFacFecD.Clear();
        dtpFacFecH.Clear();
        dtpFacFecRegD.Clear();
        dtpFacFecRegH.Clear();
        ftbUsrReg.Clear();
        ftbFacPed.Clear();
        ftbFacCli.Clear();
        ftbFacZon.Clear();
        rblOpciones.Items[0].Selected = true;
        rblOpciones.Items[1].Selected = rblOpciones.Items[2].Selected = false;

        rblFacturaE.Items[0].Selected = true;
        rblFacturaE.Items[1].Selected = false;
        ftbCtrInmueble.Clear();
        pFormularios.ResetDropDownList(ddlSociedad);

        vaciarCampos();
    }

    protected void ibAceptar_Click(object sender, ImageClickEventArgs e)
    {
        if (ValidarForm())
        {
            cRespuesta respuesta;
            if (AceptarClick != null)
            {
                string filtro = ConstruirFiltro(out respuesta);
                if (respuesta.Resultado != ResultadoProceso.Error)
                    AceptarClick(this, new CommandEventArgs("filtro", filtro));
                else
                    MsgBox.ShowMsg(upFind, Resource.error, respuesta.Ex.Message, MsgBox.MsgType.Error);
            }
        }
    }

    protected void ibCancelar_Click(object sender, ImageClickEventArgs e)
    {
        if (CancelarClick != null)
            CancelarClick(this, null);
    }

    protected bool ValidarForm()
    {
        pValidator validador = new pValidator();

        validador.AddDateFormat(dtpFacFecD, lblFacFec.Text + "(" + divDesde.InnerHtml + ")");
        validador.AddDateFormat(dtpFacFecH, lblFacFec.Text + "(" + divHasta.InnerHtml + ")");
        validador.AddDateFormat(dtpFacFecRegD, lblFacFecReg.Text + "(" + divDesde.InnerHtml + ")");
        validador.AddDateFormat(dtpFacFecRegH, lblFacFecReg.Text + "(" + divHasta.InnerHtml + ")");

        validador.AddFechaAnterior(dtpFacFecD, dtpFacFecH, lblFacFec.Text + "(" + divDesde.InnerHtml + ")", lblFacFec.Text + "(" + divHasta.InnerHtml + ")");
        validador.AddFechaAnterior(dtpFacFecRegD, dtpFacFecRegH, lblFacFecReg.Text + "(" + divDesde.InnerHtml + ")", lblFacFecReg.Text + "(" + divHasta.InnerHtml + ")");

        #region TotalFacturado
        validador.AddDecimalPrecision(tbFacTotalD, 12, 4, Resource.totalFactura);
        validador.AddDecimalPrecision(tbFacTotalH, 12, 4, Resource.totalFactura);
        #endregion

        return !MsgBox.ShowMsg(upFind, Resource.error, validador.Validate(true), MsgBox.MsgType.Error);
    }

    protected void ddl_DataBound(object sender, EventArgs e)
    {
        ((DropDownList)sender).Items.Insert(0, new ListItem("(" + Resource.ninguno + ")", String.Empty));
    }

    protected void odsOTSerie_Selecting(object sender, ObjectDataSourceSelectingEventArgs e)
    {
        //Si el código de la sociedad no es un short, no permitimos Data Bind
        short sociedad;
        e.Cancel = !short.TryParse(ddlSociedad.SelectedValue, out sociedad);
        if (e.Cancel)
            ddlOTSerie.Items.Clear();
    }

    protected void odsSerie_Selecting(object sender, ObjectDataSourceSelectingEventArgs e)
    {
        //Si el código de la sociedad no es un short, no permitimos Data Bind
        short sociedad;
        e.Cancel = !short.TryParse(ddlSociedad.SelectedValue, out sociedad);
        if (e.Cancel)
            ddlSerie.Items.Clear();
    }


    #region FUNCIONES PROPIAS

    /// <summary>
    /// Añadir los textos de los campos del control a la lista ordenada y llama a un método
    /// de la capa lógica pasándole por parámetro esa lista y la respuesta, para construir el filtroSQL
    /// </summary>
    /// <param name="respuesta">Objeto respuesta</param>
    /// <returns>String que contiene el filtro</returns>
    protected string ConstruirFiltro(out cRespuesta respuesta)
    {
        SortedList campoBusqueda = new SortedList();

        campoBusqueda["periodo"] = ftbFacPed.Value;
        campoBusqueda["zona"] = ftbFacZon.Value;
        campoBusqueda["numero"] = tbFacNum.Text;
        campoBusqueda["serie"] = ddlSerie.SelectedValue;
        campoBusqueda["inmueble"] = ftbCtrInmueble.Value;
        campoBusqueda["sociedad"] = ddlSociedad.SelectedValue;
        campoBusqueda["contrato"] = ftbContrato.Value;
        campoBusqueda["cliente"] = ftbFacCli.Value;
        campoBusqueda["usuarioReg"] = ftbUsrReg.Value;
        campoBusqueda["fechaFacD"] = dtpFacFecD.DateInputText;
        campoBusqueda["fechaFacH"] = dtpFacFecH.DateInputText;
        campoBusqueda["fechaFacRegD"] = dtpFacFecRegD.DateInputText;
        campoBusqueda["fechaFacRegH"] = dtpFacFecRegH.DateInputText;
        campoBusqueda["version"] = tbFacVer.Text;

        campoBusqueda["serieOT"] = ddlOTSerie.SelectedValue;
        campoBusqueda["otNumero"] = ftbOTNumero.Value;

        if (rblOpciones.SelectedIndex != 0)
            campoBusqueda["activas"] = rblOpciones.SelectedIndex == 2;

        campoBusqueda["fctTotalD"] = tbFacTotalD.Text == string.Empty && tbFacTotalH.Text != string.Empty ? System.Data.SqlTypes.SqlMoney.MinValue.ToString() : tbFacTotalD.Text;
        campoBusqueda["fctTotalH"] = tbFacTotalD.Text != string.Empty && tbFacTotalH.Text == string.Empty ? System.Data.SqlTypes.SqlMoney.MaxValue.ToString() : tbFacTotalH.Text;

        campoBusqueda["estadoDeuda"] = rbFacDeudaEstados.SelectedValue;


        SoloFacturase = rblFacturaE.SelectedIndex == 1;

        return cFacturasBL.ConstruirFiltroSQL(campoBusqueda, out respuesta);
    }

    #endregion


    #region "Buscador por totales facturados"
    public int EstadoDeuda { 
        get {
            int result = -1;

            int.TryParse(rbFacDeudaEstados.SelectedValue, out result);

            return result;
        } 
    
    }

    private bool facTotales_ON
    {
        get
        {
            bool result = false;

            string value = string.Empty;
            cParametroBL.GetString("FACTOTALES", out value);

            result = !string.IsNullOrEmpty(value) && value == "ON";

            return result;
        }
    }

    private void estilosEstadosDeuda()
    {
        string toolTip;

        //string strStyle = "display:block; float:left; width:115px; border-style:none;padding-right:20px;text-align:left;";

        foreach (ListItem chk in rbFacDeudaEstados.Items)
        {
            try
            {
                toolTip = this.EstadosDeuda.FirstOrDefault(x => x.Codigo == int.Parse(chk.Value)).ToolTip;
                chk.Attributes.Add("title", toolTip);
            }
            catch { }

            //chk.Attributes.Add("style", strStyle);
            chk.Attributes.Add("class", "rbItemList");
        }
    }

    private void inicializarEstadosDeuda()
    {
        List<cFacturaDeudaEstadoBO> result;
     
        rbFacDeudaEstados.Items.Add(new ListItem(Resource.todos, "-1"));
        rbFacDeudaEstados.Items[0].Selected = true;

        try
        {
            result = this.EstadosDeuda;
            foreach (cFacturaDeudaEstadoBO item in result)
            {
                ListItem chk = new ListItem(item.Descripcion, item.Codigo.ToString());
                chk.Attributes.Add("title", item.ToolTip);
                rbFacDeudaEstados.Items.Add(chk);
            }

            estilosEstadosDeuda();
        }
        catch { }
        finally { }
    }

    private void inicializarLabels()
    {
        lblFacTotal.Text = Resource.totalFacturado;
        lblFacEstadoDeuda.Text = Resource.DeudaEstado;
    }

    private void inicializarCampos()
    {
        inicializarLabels();
        inicializarEstadosDeuda();

        divFacTotal.Visible = facTotales_ON;
        divEstadoDeuda.Visible = facTotales_ON;
    }

    private void vaciarCampos()
    {
        #region Edo.Deuda
        foreach (ListItem item in rbFacDeudaEstados.Items)
        {
            item.Selected = (item.Value == "-1");
        }

        inicializarEstadosDeuda();
        #endregion
    }

    
    #endregion
}