using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using Acuama;
using BO.Resources;
using BO.Comun;
using BO.Sistema;
using BL.Facturacion;

public partial class Cobros_CR018_LiquidarFacturasPendientesCobro : PageBase
{
    protected override void OnInit(EventArgs e)
    {
        //Código del usuario
        taskManager.User = ((cUsuarioBO)cAplicacion.GetHttpSessionValue("usuario")).Codigo;
        base.OnInit(e);
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            tab.InnerHtml = Resource.liquidarServicios;
            cabecera.InnerHtml = Resource.liquidarServicios;

            divDesde.InnerHtml = Resource.desde;
            divHasta.InnerHtml = Resource.hasta;
            divFecha.InnerHtml = Resource.fecha_factura;
            divPeriodo.InnerHtml = Resource.periodo;
            divServicio.InnerHtml = Resource.servicio;
            divUso.InnerHtml = Resource.uso;
            divTarifa.InnerHtml = Resource.tarifa;

            ftbPeriodoD.MenuOption = ftbPeriodoH.MenuOption = (int)EMenu.Facturacion.Periodos;
        }
    }

    protected void ibAceptar_Click(object sender, ImageClickEventArgs e)
    {
        cRespuesta respuesta = null;

        if (ValidarForm())
        {
            int facturasProcesadas;
            int? usoCodigo = String.IsNullOrEmpty(ddlUso.SelectedValue) ? null : (int?)Convert.ToInt32(ddlUso.SelectedValue);
            short? servicio = String.IsNullOrEmpty(ddlServicio.SelectedValue) ? null : (short?)Convert.ToInt16(ddlServicio.SelectedValue);
            short? tarifaD = String.IsNullOrEmpty(ddlTarifaD.SelectedValue) ? null : (short?)Convert.ToInt16(ddlTarifaD.SelectedValue);
            short? tarifaH = String.IsNullOrEmpty(ddlTarifaH.SelectedValue) ? null : (short?)Convert.ToInt16(ddlTarifaH.SelectedValue);
            string log = String.Empty;

            respuesta = cFacturasBL.LiquidarPendientesDeCobro(servicio, dtpFechaD.GetDate, dtpFechaH.GetDate, String.IsNullOrEmpty(ftbPeriodoD.Value) ? null : ftbPeriodoD.Value, String.IsNullOrEmpty(ftbPeriodoH.Value) ? null : ftbPeriodoH.Value, ((cUsuarioBO)cAplicacion.GetHttpSessionValue("usuario")).Codigo, tarifaD, tarifaH, usoCodigo, out log, out facturasProcesadas);

            if (respuesta.Resultado == ResultadoProceso.OK)
                MsgBox.ShowMsg(up, Resource.info, Resource.seHanProcesadoXRegistros.Replace("@registros", facturasProcesadas.ToString()) + (String.IsNullOrEmpty(log) ? String.Empty : Environment.NewLine + log), MsgBox.MsgType.Information);
            else
                MsgBox.ShowMsgIfError(up, respuesta);
        }
    }

    protected void ibProgramar_Click(object sender, ImageClickEventArgs e)
    {
        if (ValidarForm())
        {
            taskManager.CreateNewTask();

            taskManager.AddParameter("usoCodigo", "{{text:uso}}", ddlUso.SelectedValue, false);
            taskManager.AddParameter("servicio", "{{text:servicio}}", ddlServicio.SelectedValue, false);
            taskManager.AddParameter("fechaFacturaD", "{{text:fecha_factura}} ({{text:desde}})", dtpFechaD.GetDateTimeString, false);
            taskManager.AddParameter("fechaFacturaH", "{{text:fecha_factura}} ({{text:hasta}})", dtpFechaH.GetDateTimeString, false);
            taskManager.AddParameter("periodoD", "{{text:periodo}} ({{text:desde}})", ftbPeriodoD.Value, false);
            taskManager.AddParameter("periodoH", "{{text:periodo}} ({{text:hasta}})", ftbPeriodoH.Value, false);
            taskManager.AddParameter("tarifaD", "{{text:tarifa}} ({{text:desde}})", ddlTarifaD.SelectedValue, false);
            taskManager.AddParameter("tarifaH", "{{text:tarifa}} ({{text:hasta}})", ddlTarifaH.SelectedValue, false);

            taskManager.RequestParametersFinished();
        }
    }

    protected void ibVaciar_Click(object sender, ImageClickEventArgs e)
    {
        pFormularios.ResetDropDownLists(up.ContentTemplateContainer.Controls);
        dtpFechaD.Clear();
        dtpFechaH.Clear();
        ftbPeriodoD.Clear();
        ftbPeriodoH.Clear();
    }

    protected void ddl_DataBound(object sender, EventArgs e)
    {
        ((DropDownList)sender).Items.Insert(0, new ListItem("(" + Resource.ninguno + ")", String.Empty));
    }

    protected bool ValidarForm()
    {
        pValidator validador = new pValidator();

        validador.AddRequiredField(ddlServicio, divServicio.InnerHtml);
        validador.AddDateFormat(dtpFechaD, divFecha.InnerHtml + " (" + divDesde.InnerHtml + ")");
        validador.AddDateFormat(dtpFechaH, divFecha.InnerHtml + " (" + divHasta.InnerHtml + ")");

        return !MsgBox.ShowMsg(up, Resource.error, validador.Validate(true), MsgBox.MsgType.Error);
    }
}
