<%@ Control Language="C#" AutoEventWireup="true" CodeFile="ctrFacturasFIND.ascx.cs" Inherits="Facturacion_Controles_ctrFacturasFIND" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc1" %>
<%@ Register Src="~/Comun/Controles/DateTimePicker.ascx" TagName="DateTimePicker" TagPrefix="uc5" %>
<%@ Register Src="~/Comun/Controles/FinderTextBox.ascx" TagName="FinderTextBox" TagPrefix="uc2" %>
<%@ Register Src="../../Comun/Controles/FinderTextBox.ascx" TagName="FinderTextBox" TagPrefix="uc1" %>
<link id="cssLink" runat="server" href="ctrFacturas.css" rel="stylesheet" type="text/css" />
    
<div class="facFindContenedor"><!--Div que engloba al control de usuario-->
    <asp:UpdatePanel ID="upFind" runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <div class="lineaSuperiorModalPopup"></div>
            <div class="imagenCabeceraPopup">
              <asp:Image id="imgBuscarFac" runat="server" CssClass="imagenCabeceraPopup" ImageUrl="~/Comun/Imagenes/General/buscar.png"></asp:Image>
            </div>
            <div  class="cabecera">
                <asp:Label id="lblModoFac" runat="server"></asp:Label>
            </div>
            <div  class="modalPopupDivContenido">
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacPed" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <uc2:FinderTextBox ID="ftbFacPed" CssClass="faccolumna facFindc02" runat="server" ValueWidth="345" />
                </div>
               
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacZon" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <uc2:FinderTextBox ID="ftbFacZon" CssClass="faccolumna facFindc02" runat="server" ValueWidth="345" />
                </div>
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacNum" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <asp:TextBox ID="tbFacNum" runat="server" CssClass="faccolumna  facFindc02" MaxLength="50" Width="345px"></asp:TextBox>
                </div>
                
                <div class="facfila facFilaFind">
                     <asp:Label ID="lblSociedad" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                     <asp:DropDownList ID="ddlSociedad" runat="server" CssClass="faccolumna  facFindc02" DataSourceID="odsSociedades" AutoPostBack="true" DataTextField="Nombre" DataValueField="Codigo" OnDataBound="ddl_DataBound" Width="352px"/>
                </div>
                
                <Acuama:AcuamaDataSource ID="odsSociedades" runat="server" SelectMethod="ObtenerTodos" TypeName="BL.Sistema.cSociedadBL">
                    <SelectParameters>
                        <asp:Parameter Direction="Output" Name="respuesta" Type="Object" />
                    </SelectParameters>
                </Acuama:AcuamaDataSource>
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblSerie" runat="server" CssClass="faccolumna facFindc01 label">ñññ Serie</asp:Label>
                    <asp:DropDownList ID="ddlSerie" runat="server" CssClass="faccolumna  facFindc02" DataSourceID="odsSeries" DataTextField="Descripcion" DataValueField="Codigo" OnDataBound="ddl_DataBound" Width="352px"/>
                </div>
                
                <Acuama:AcuamaDataSource ID="odsSeries" runat="server" SelectMethod="ObtenerPorScdYTipo" TypeName="BL.Sistema.cSerieBL" OnSelecting="odsSerie_Selecting">
                    <SelectParameters>
                        <asp:ControlParameter ControlID="ddlSociedad" DefaultValue="" Name="sociedad" PropertyName="SelectedValue" Type="Int16" />
                        <asp:Parameter DefaultValue="FV" Name="tipo" Type="String" />
                        <asp:Parameter Direction="Output" Name="respuesta" Type="Object" />
                    </SelectParameters>
                </Acuama:AcuamaDataSource> 
                
                                            
            <div class="facfila facFilaFind">
                <asp:Label ID="lblCtrInmueble" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                <div class="faccolumna  facFindc02"><uc1:FinderTextBox ID="ftbCtrInmueble" runat="server" ValueMaxLength="50" ValueWidth="345" MultipleValueFieldSeparator = ";"/></div>
            </div>

                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacCtr" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <div class="faccolumna  facFindc02">
                        <uc2:FinderTextBox ID="ftbContrato" runat="server" ValueWidth="345" MultipleValueFieldSeparator = ";" MultipleValueFieldIndex = "0"/>
                    </div>
                </div>
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacCli" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <uc2:FinderTextBox ID="ftbFacCli" CssClass="faccolumna facFindc02" runat="server" ValueWidth="345" />
                </div>

                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacVer" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <asp:TextBox ID="tbFacVer" runat="server" CssClass="faccolumna  facFindc02" MaxLength="50" Width="345px"></asp:TextBox>
                </div>
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacUsrReg" runat="server" CssClass="faccolumna facFindc01 label">ñññ Usuario reg.</asp:Label>
                    <uc2:FinderTextBox ID="ftbUsrReg" CssClass="faccolumna facFindc02" runat="server" ValueWidth="345" />
                </div>
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblOTNumero" runat="server" CssClass="faccolumna facFindc01 label">ñññ Orden de trabajo</asp:Label>
                    <uc2:FinderTextBox ID="ftbOTNumero" CssClass="faccolumna  facFindc02" runat="server" ValueWidth="345" MultipleValueFieldSeparator = ";" MultipleValueFieldIndex = "0"  />
                </div>
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblOTSerie" runat="server" CssClass="faccolumna facFindc01 label">ñññ Serie OT</asp:Label>
                    <asp:DropDownList ID="ddlOTSerie" runat="server" CssClass="faccolumna  facFindc02" DataSourceID="odsOTSeries" DataTextField="Descripcion" DataValueField="Codigo" OnDataBound="ddl_DataBound" Width="352px"/>
                </div>
               
               <Acuama:AcuamaDataSource ID="odsOTSeries" runat="server" SelectMethod="ObtenerPorScdYTipo" TypeName="BL.Sistema.cSerieBL" OnSelecting="odsOTSerie_Selecting">
                    <SelectParameters>
                        <asp:ControlParameter ControlID="ddlSociedad" DefaultValue="" Name="sociedad" PropertyName="SelectedValue" Type="Int16" />
                        <asp:Parameter DefaultValue="OT" Name="tipo" Type="String" />
                        <asp:Parameter Direction="Output" Name="respuesta" Type="Object" />
                    </SelectParameters>
                </Acuama:AcuamaDataSource> 



                                                
               <div class="facfila facFilaFind" style="height:18px !important">
                    <div class="faccolumna facFindc02 label" runat="server" id="divDesde"></div>
                    <div class="faccolumna facFindc04 label" runat="server" id="divHasta"></div>
                </div>

                <!--* * * IMPORTE TOTAL DE LAS FACTURAS * * *-->
                <div ID="divFacTotal" class="facfila facFilaFind" runat="server">
                    <asp:Label   ID="lblFacTotal"  runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <asp:TextBox ID="tbFacTotalD" runat="server" CssClass="faccolumna facFindc02" MaxLength="11" Width="70px"></asp:TextBox>
                    <asp:TextBox ID="tbFacTotalH" runat="server" CssClass="faccolumna facFindc04" MaxLength="11" Width="70px"></asp:TextBox>
                </div>
                
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacFec" runat="server" CssClass="faccolumna facFindc01 label">ñññFecha</asp:Label>
                    <uc5:DateTimePicker ID="dtpFacFecD" runat="server" mode="Date" PopupPosition="TopRight" CssClass="faccolumna facFindc02"/>
                    <uc5:DateTimePicker ID="dtpFacFecH" runat="server" mode="Date" PopupPosition="TopRight" CssClass="faccolumna facFindc04"/>
                </div>
                
                <div class="facfila facFilaFind">
                    <asp:Label ID="lblFacFecReg" runat="server" CssClass="faccolumna facFindc01 label">ñññFecha Reg</asp:Label>
                    <uc5:DateTimePicker ID="dtpFacFecRegD" runat="server" mode="Date" PopupPosition="TopRight" CssClass="faccolumna facFindc02"/>
                    <uc5:DateTimePicker ID="dtpFacFecRegH" runat="server" mode="Date" PopupPosition="TopRight" CssClass="faccolumna facFindc04"/>
                </div>
                
                <div class="facfila facFilaFind">
                    <asp:RadioButtonList CssClass="faccolumna facFindc02 label" ID="rblOpciones" runat="server" RepeatDirection="Horizontal" style="left:110px !important">
                        <asp:ListItem Selected="True"></asp:ListItem>
                        <asp:ListItem></asp:ListItem>
                        <asp:ListItem></asp:ListItem>
                    </asp:RadioButtonList>                  
                </div>
                
                <div class="facfila facFilaFind" >
                    <asp:RadioButtonList CssClass="faccolumna facFindc02 label" ID="rblFacturaE" runat="server" RepeatDirection="Horizontal" style="left:110px !important">
                        <asp:ListItem Selected="True"></asp:ListItem>
                        <asp:ListItem></asp:ListItem>
                    </asp:RadioButtonList>
                </div>
                
                <!--* * * ESTADO DE LA DEUDA * * *-->
                <div class="facfila facFilaFind" style="margin-top:12px;" id="divEstadoDeuda" runat="server">
                    
                    <asp:Label ID="lblFacEstadoDeuda" runat="server" CssClass="faccolumna facFindc01 label"></asp:Label>
                    <asp:RadioButtonList ID="rbFacDeudaEstados" runat="server" RepeatDirection="Horizontal" RepeatLayout="Table" RepeatColumns="3" CssClass="faccolumna facFindc02" style="left:110px !important" >
                    </asp:RadioButtonList>
                </div>

                <div class="lineaInferiorModalPopup" style="position:relative; margin-top:25px"></div>

                <div class="botonesOkCancel">
                    <asp:ImageButton ID="ibAceptar" runat="server" CssClass="hoverButton btnControlAceptar" ImageUrl="~/Comun/Imagenes/Botones/aceptar.png" OnClick="ibAceptar_Click"/>
                    <asp:ImageButton CssClass="hoverButton" ID="ibVaciar" runat="server" ImageUrl="~/Comun/Imagenes/Botones/limpiar.png" OnClick="ibVaciar_Click"  />
                    <asp:ImageButton ID="ibCancelar" runat="server" CssClass="hoverButton btnControlCancelar" ImageUrl="~/Comun/Imagenes/Botones/cancelar.png" OnClick="ibCancelar_Click"/>
                </div>

                
            </div>
            
        </ContentTemplate>
    </asp:UpdatePanel>
    
    
</div>    
