<%@ Page Language="C#" MasterPageFile="~/Comun/Principal.master" AutoEventWireup="true" CodeFile="CF002_facturas.aspx.cs" Inherits="Facturacion_CF002_Facturas" Title="Untitled Page" %>
<%@ Register Src="Controles/ctrFacturasFIND.ascx" TagName="ctrFacturasFIND" TagPrefix="uc6" %>
<%@ Register Src="Controles/ctrFacCabCRU.ascx" TagName="ctrFacCabCRU" TagPrefix="uc4" %>
<%@ Register Src="Controles/ctrFacLinCRU.ascx" TagName="ctrFacLinCRU" TagPrefix="uc2" %>
<%@ Register Assembly="System.Web.Extensions, Version=1.0.61025.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" Namespace="System.Web.UI" TagPrefix="asp" %>
<%@ Register Src="../Comun/Controles/ctrBotones.ascx" TagName="ctrBotones" TagPrefix="uc1" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc1" %>
<%@ Register Src="Controles/ctrFacturasPRINT.ascx" TagName="ctrFacturasPRINT" TagPrefix="uc5" %>
<%@ Register Src="../Comun/Controles/ctrGridViewPager.ascx" TagName="ctrGridViewPager" TagPrefix="uc6" %>
<%@ Register Src="../Comun/Controles/OptionSelector.ascx" TagName="OptionSelector" TagPrefix="uc7" %>
<%@ Register Src="~/Comun/Controles/Prompt.ascx" TagName="Prompt" TagPrefix="uc8" %>
<%@ Register Src="../Sistema/Controles/ctrAsignarSociedadYSerie.ascx" TagName="ctrActualizarPreFacturaCerrada" TagPrefix="uc9" %>
<%@ Register Src="../Sistema/Controles/ctrAsignarSociedadYSerie.ascx" TagName="ctrActualizarContratoPreFacturaCerrada" TagPrefix="uc10" %>

<asp:Content ID="Content1" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">

    <asp:UpdatePanel ID="upTab" runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <!-- CREACION DE PESTAÑAS -->
            <div id="tabFacCab" class="tab selected" runat="server" onclick="javascript:ShowTab('ctl00_ContentPlaceHolder1_tabFacCab','tabFacContent');"></div>
            <div id="tabFacLin" class="tab" runat="server" onclick="javascript:ShowTab('ctl00_ContentPlaceHolder1_tabFacLin','tabLinContent');"></div>
        </ContentTemplate>
    </asp:UpdatePanel>
        
    <div style="display:none"><asp:Button ID="btnDumbPopupDatosActualizarPreFactura" runat="server"/></div>
    <cc1:ModalPopupExtender ID="mpeDatosActualizarPreFactura" runat="server" TargetControlID="btnDumbPopupDatosActualizarPreFactura" BackgroundCssClass="modalBackground" PopupControlID="divActualizarPreFacturaCerrada" />

    <div runat="server" id="divActualizarPreFacturaCerrada" style="display:none" class="controlPopup colorPagina">
        <uc9:ctrActualizarPreFacturaCerrada ID="ctrActualizarPreFacturaCerrada" runat="server" RepeatDirection="Horizontal" Tipo="FV" OnAceptar="ctrActualizarPreFacturaCerrada_Aceptar" OnCancelar="ctrActualizarPreFacturaCerrada_Cancelar" />
    </div>

    <div style="display:none"><asp:Button ID="btnDumbPopupDatosActualizarContratoPreFacturaCerrada" runat="server"/></div>
    <cc1:ModalPopupExtender ID="mpeDatosActualizarContratoPreFactura" runat="server" TargetControlID="btnDumbPopupDatosActualizarContratoPreFacturaCerrada" BackgroundCssClass="modalBackground" PopupControlID="divActualizarContratoPreFacturaCerrada" />

    <div runat="server" id="divActualizarContratoPreFacturaCerrada" style="display:none" class="controlPopup colorPagina">
        <uc10:ctrActualizarContratoPreFacturaCerrada ID="ctrActualizarContratoPreFacturaCerrada" runat="server" RepeatDirection="Horizontal" Tipo="FV" OnAceptar="ctrActualizarContratoPreFacturaCerrada_Aceptar" OnCancelar="ctrActualizarContratoPreFacturaCerrada_Cancelar" />
    </div>
        
    <div id="tabFacContainer" class="tabContainer">
        <!-------------------------->
        <!-------------------------->
        <!--CABECERA DE LA FACTURA-->
        <!-------------------------->
        <!-------------------------->
        
        <div id="tabFacContent" class="tabContent selected">
            <asp:UpdatePanel ID="upFacCab" runat="server" UpdateMode="Conditional">
                <ContentTemplate>
                    <!--Pregunta: "¿Borrar ó Generar Rectificativa con importe 0?-->    
                    <div style="display:none"><asp:Button ID="btnDumbPopupBorrar_o_Anular" runat="server"/></div>
                    <cc1:ModalPopupExtender ID="mpeBorrar_o_Anular" runat="server" TargetControlID="btnDumbPopupBorrar_o_Anular" BehaviorID="bid_Borrar_o_Anular" BackgroundCssClass="modalBackground" PopupControlID="divBorrarOAnular" />
                    <div runat="server" id="divBorrarOAnular" style="display:none" class="controlPopup colorPagina">
                        <uc7:OptionSelector ID="optSel_Borrar_o_Anular" runat="server" RepeatDirection="Horizontal" OnOkClick="optSel_Borrar_o_Anular_OkClick" />
                    </div>
                    
                    <!--Pregunta: "¿Actualizar ó Crear nueva versión de la factura?-->    
                    <div style="display:none"><asp:Button ID="btnDumbPopupActualizar_o_NewVersion" runat="server"/></div>
                    <cc1:ModalPopupExtender ID="mpeActualizar_o_NewVersion" runat="server" TargetControlID="btnDumbPopupActualizar_o_NewVersion" BehaviorID="bid_mpeActualizar_o_NewVersion" BackgroundCssClass="modalBackground" PopupControlID="Actualizar_o_NewVersion" />
                    <div runat="server" id="Actualizar_o_NewVersion" style="display:none" class="controlPopup colorPagina">
                        <uc7:OptionSelector ID="optSel_Actualizar_o_NewVersion" runat="server" RepeatDirection="Horizontal" OnCancelClick="optSel_Actualizar_o_NewVersion_CancelClick" OnOkClick="optSel_Actualizar_o_NewVersion_OkClick" />
                    </div>

                    <asp:ImageButton ID="ibEditarFactura" runat="server" CssClass="invisible" onclick="ibEditarFactura_Click" />
                    
                    <div id="divInfo" class="textoInformativo" style="display:none" runat="server">
                       <div>
                          <span id="spPeriodoCab" class="label" runat="server"></span>
                          <asp:Label ID="lblPeriodoCab" runat="server" />
                       </div>
                       <div>
                          <span id="spContratoCab" class="label" runat="server"></span>
                          <asp:Label ID="lblContraroCab" runat="server" />
                       </div>
                    </div>    
                    
                    <div id="divInfoOtCabecera" runat="server" class="textoInformativo invisible">
                        <div>
                            <span id="spOtSociedad" class="label" runat="server"></span>
                            <asp:Label ID="lbOtSociedad" runat="server"></asp:Label>
                        </div>
                        <div>
                            <span id="spOtSerie" class="label" runat="server"></span>
                            <asp:Label ID="lbOtSerie" runat="server"></asp:Label>
                        </div>
                        <div>
                            <span id="spOtNumero" class="label" runat="server"></span>
                            <asp:Label ID="lbOtNumero" runat="server"></asp:Label>
                        </div>
                    </div>
                    
                    <div id="divHueco" class="facFila" style="display:none" runat="server"></div>
                    
                    <div class="controlBotones">
                        <uc1:ctrBotones ID="ctrBotonesFacCab" runat="server" OnClick="ctrBotonesFacCab_Click" OnModeChanged="ctrBotonesFacCab_ModeChanged" FormModeMgrID="ctrFacCabCRU" />
                        <asp:ImageButton CssClass="invisible" ImageUrl="~/Comun/Imagenes/General/none.gif"  ID="ibActualizarVersionCtr" runat="server" OnClick="ibActualizarVersionCtr_Click"/>                  
                    </div>
                    
                    <!--INICIO DIV GRIDVIEW DE LA CABECERA--> 
                    <div id="gridCab" class="grid" runat="server">
                        <div class="LineaBlanca1Contenedor"><div class="LineaBlanca1"></div></div>
                  		    <asp:GridView ID="gvFacCab" runat="server" AutoGenerateColumns="False" GridLines="None" LinesPerRow="2" AllowPaging="True" CssClass="gv"
                  		    PageSize="16" Width="700px" OnRowCommand="gvFacCab_RowCommand" OnRowDataBound="gvFacCab_RowDataBound"
                            OnDataBound="gvFacCab_OnDataBound">
                                  <Columns>
                                      <asp:TemplateField>
                                          <ItemTemplate>
                            			        <asp:CheckBox ID="cbSeleccionCab" runat="server" CssClass="botonSeleccionGV"/>	
                                                <cc1:ToggleButtonExtender ID="tbeSeleccionCab" runat="server" TargetControlID="cbSeleccionCab" ImageWidth="22" ImageHeight="22" UnCheckedImageUrl="~/Comun/Imagenes/General/bullet_off.png" CheckedImageUrl="~/Comun/Imagenes/General/bullet_on.png"/>
                                          </ItemTemplate>
                                          <HeaderStyle Width="22px"/>
                                          <ItemStyle Height="22px"/>
                                      </asp:TemplateField>

                                      <asp:TemplateField SortExpression="imprimir">
                                          <ItemTemplate>
                                              <asp:ImageButton ID="ibImprimirFac" runat="server" CommandName="Imprimir" CommandArgument="<%#((GridViewRow) Container).RowIndex %>" ImageUrl="~/Comun/Imagenes/General/printer.png" />
                                          </ItemTemplate>
                                          <HeaderStyle Width="22px"/>                                      
                                      </asp:TemplateField>

                                      <asp:TemplateField SortExpression="editar">
                                          <ItemTemplate>
                                              <asp:ImageButton ID="ibEditarCab" runat="server" CommandName="Editar" CommandArgument="<%#((GridViewRow) Container).RowIndex %>" ImageUrl="~/Comun/Imagenes/General/editar_bullet.png" />
                                          </ItemTemplate>
                                          <HeaderStyle Width="22px"/>                                      
                                      </asp:TemplateField>
                                      <asp:TemplateField SortExpression="borrar">
                                           <ItemTemplate>
                                              <asp:ImageButton ID="ibBorrarCab" runat="server" CommandName="Borrar" CommandArgument="<%#((GridViewRow) Container).RowIndex %>" ImageUrl="~/Comun/Imagenes/General/borrar_bullet.png" /> 
                                           </ItemTemplate> 
                                           <HeaderStyle Width="22px"/>                                      
                                      </asp:TemplateField>
                                      <asp:TemplateField HeaderText="PeriodoCodigo" SortExpression="PeriodoCodigo">
                                         <ItemTemplate>
                                              <asp:LinkButton ID="lbPeriodo" runat="server" CommandName="Consultar" Text='<%# Bind("PeriodoCodigo") %>' CommandArgument="<%# ((GridViewRow) Container).RowIndex %>"></asp:LinkButton>
                                              <asp:HiddenField ID="hfFacturaCodigoCab" runat="server" Value='<%# Bind("FacturaCodigo") %>'/>
                                              <asp:HiddenField ID="hfSerieCodigo" runat="server" Value='<%# Bind("SerieCodigo") %>'/>
                                              <asp:HiddenField ID="hfSerScdCod" runat="server" Value='<%# Bind("SociedadCodigo") %>'/>
                                              <asp:HiddenField ID="hfSerieRefti" runat="server" Value='<%# Bind("SerieRectificativa") %>'/>
                                          </ItemTemplate>
                                          <HeaderStyle Width="50px" />
                                      </asp:TemplateField>
                                      
                                      <asp:TemplateField HeaderText="FacCod" SortExpression="FacCod">
                                         <ItemTemplate>
                                              <asp:Label ID="lblFacCod" runat="server" Text='<%# Bind("FacturaCodigo") %>'></asp:Label>
                                          </ItemTemplate>
                                          <HeaderStyle Width="70px" />
                                      </asp:TemplateField>

                                      <asp:TemplateField HeaderText="ZonaCodigo" SortExpression="ZonaCodigo">
                                         <ItemTemplate>
                                              <asp:Label ID="lblZona" runat="server" Text='<%# Bind("ZonaCodigo") %>'></asp:Label>
                                          </ItemTemplate>
                                          <HeaderStyle Width="30px" />
                                      </asp:TemplateField>
                                      <asp:TemplateField HeaderText="ContratoCodigo"  SortExpression="ContratoCodigo">
                                          <ItemTemplate>
                                                <asp:Label ID="lblContrato" runat="server" Text='<%# Bind("ContratoCodigo") %>'></asp:Label>                                         
                                          </ItemTemplate>
                                          <ItemStyle CssClass="campoNumero"/>
                                          <HeaderStyle Width="60px" CssClass="campoNumero"/>
                                      </asp:TemplateField>
                                      <asp:TemplateField HeaderText="Version" SortExpression="Version">
                                         <ItemTemplate>
                                              <asp:Label ID="lblVersion" runat="server" Text='<%# Bind("Version") %>'></asp:Label>
                                         </ItemTemplate>
                                         <ItemStyle CssClass="campoNumero"/>
                                         <HeaderStyle Width="30px" CssClass="campoNumero"/>
                                      </asp:TemplateField>
                                      
                                      <asp:TemplateField HeaderText="Numero" Visible="false" SortExpression="Numero">
                                         <ItemTemplate>
                                              <asp:Label ID="lblNumero" runat="server" Text='<%# Bind("Numero") %>'></asp:Label>
                                          </ItemTemplate>
                                          <HeaderStyle Width="60px"/>
                                      </asp:TemplateField>
                                      
                                      <asp:TemplateField HeaderText="Fecha" SortExpression="Fecha">
                                         <ItemTemplate>
                                              <asp:Label ID="lblFecha" runat="server" Text='<%# Bind("Fecha", "{0:d}") %>'></asp:Label>
                                         </ItemTemplate>
                                         <HeaderStyle Width="70px" />
                                      </asp:TemplateField>
                                      
                                      <asp:TemplateField HeaderText="SerieCodigo"  SortExpression="SerieCodigo">
                                         <ItemTemplate>
                                              <asp:Label ID="lblSerieCodigo" runat="server"></asp:Label>
                                          </ItemTemplate>
                                          <HeaderStyle Width="334px" />
                                      </asp:TemplateField>
                                      
                                      <asp:TemplateField HeaderText="ClienteCodigo" SortExpression="ClienteCodigo">
                                         <ItemTemplate>
                                            <asp:Label ID="lblCliente" runat="server" Text=''></asp:Label>
                                            <asp:HiddenField ID="hfClienteCodigo" runat="server" Value='<%# Bind("ClienteCodigo") %>' />
                                         </ItemTemplate>
                                         <HeaderStyle Width="300px" />
                                      </asp:TemplateField>  
                                      
                                      <asp:TemplateField SortExpression="Consumo">
                                          <ItemTemplate>
                                              <asp:Label ID="lblConsumo" runat="server" Text='<%# Bind("ConsumoFactura") %>'></asp:Label>
                                          </ItemTemplate>
                                          <HeaderStyle Width="30px" CssClass="campoNumero" />
                                          <ItemStyle CssClass="campoNumero" />
                                      </asp:TemplateField>                               
                                      
                                                                            
                                      <asp:TemplateField SortExpression="Importe">
                                          <ItemTemplate>
                                              <asp:Label ID="lblImporte" runat="server" Text=''></asp:Label>
                                          </ItemTemplate>
                                          <HeaderStyle Width="30px" CssClass="campoNumero" />
                                          <ItemStyle CssClass="campoNumero" />
                                      </asp:TemplateField>
                                  </Columns>
                                  <RowStyle CssClass="gridViewRow" />
                                   <%--El paginador del GRID se oculta siempre porque solo hay datos para una página --%>
                                  <PagerTemplate>
                                    <uc6:ctrGridViewPager id="ctrGridViewPagerCab" runat="server" OnIraPagChanged="ctrGridViewPagerCab_IraPagChanged" Visible="false">
                                    </uc6:ctrGridViewPager>
                                  </PagerTemplate>
                                  <PagerStyle HorizontalAlign="Right" CssClass="gvPager" />
                            </asp:GridView>
                        
                        <%--El paginador del GRID se gestiona desde afuera para recuperar los registros de una página a la vez --%>
                        <div id="divFacGridViewPager" class="LineaBlanca1Contenedor">
                           <br>
                            <uc6:ctrGridViewPager id="facGridViewPager" runat="server" OnButtonClick="facGridViewPager_OnButtonClick" OnIraPagChanged="facGridViewPager_IraPagChanged_" EnableViewState="true" Visible="false"/>
                            <asp:HiddenField ID="hfFacGridViewPage" runat="server" />
                        </div>

                        
                            
                        <div id="divLineaDownCab" class="LineaBlanca2gv"></div>
                        <div style="display:none"><asp:HiddenField ID="hfFiltro" runat="server" /></div>
                    </div>
                    <div id="detailCab"  runat="server">
                        <uc4:ctrFacCabCRU ID="ctrFacCabCRU" runat="server" OnClosed="ctrFacCabCRU_Closed" OnRegistroInsertado="ctrFacCabCRU_RegistroInsertado" OnRegistroActualizado="ctrFacCabCRU_RegistroActualizado" />
                    </div>

                    <Acuama:AcuamaDataSource ID="odsFacCab" runat="server" SelectMethod="ObtenerPorFiltro" TypeName="BL.Facturacion.cFacturasBL" OnSelecting="odsFacCab_Selecting"></Acuama:AcuamaDataSource>

                </ContentTemplate>
            </asp:UpdatePanel>
        </div><!--CIERRE tabFacContent-->
        
        <!------------------------>
        <!------------------------>
        <!--LINEAS DE LA FACTURA-->
        <!------------------------>
        <!------------------------>
        <div id="tabLinContent" class="tabContent">
            <asp:UpdatePanel ID="upFacLin" runat="server" UpdateMode="Conditional">
                <ContentTemplate>

                     <!--INICIO DIV INFO CAB EN LIN--> 
                     <div class="facInfoDivContenedor">
                        <asp:UpdatePanel runat="server" id="upInfo" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div>
                                    <span id="spContrato" class="label" runat="server"></span>
                                    <asp:Label ID="lblContrato" runat="server"/>
                                </div>
                                <div>
                                    <span id="spPeriodo" class="label" runat="server"></span>
                                    <asp:Label ID="lblPeriodoDes" runat="server"/>
                                </div>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                    
                    <div class="controlBotones">
                        <uc1:ctrBotones ID="ctrBotonesFacLin" runat="server" OnClick="ctrBotonesFacLin_Click"/>
                    </div>
                    
                    <!--INICIO DIV GRIDVIEW--> 
                    <div id="gridLin" class="grid" runat="server">
                        <div class="LineaBlanca1Contenedor"><div class="LineaBlanca1"></div></div>
                  		    <asp:GridView ID="gvFacLin" runat="server" AutoGenerateColumns="False" GridLines="None" LinesPerRow="2" AllowPaging="True" CssClass="gv" 
                  		    PageSize="16" Width="700px" DataSourceID="odsFacLin" OnRowCommand="gvFacLin_RowCommand" OnRowDataBound="gvFacLin_RowDataBound">
                            <Columns>
                                <asp:TemplateField>
                                    <ItemTemplate>
                            			    <asp:CheckBox ID="cbSeleccion" runat="server" CssClass="botonSeleccionGV"/>	
                                            <cc1:ToggleButtonExtender ID="tbeSeleccion" runat="server" TargetControlID="cbSeleccion" ImageWidth="22" ImageHeight="22" UnCheckedImageUrl="~/Comun/Imagenes/General/bullet_off.png" CheckedImageUrl="~/Comun/Imagenes/General/bullet_on.png"/>
                                    </ItemTemplate>
                                    <HeaderStyle Width="22px"/>
                                </asp:TemplateField>
                                <asp:TemplateField>
                                    <ItemTemplate>
                                        <asp:ImageButton ID="ibEditarGV" runat="server" CommandName="Editar" CommandArgument="<%#((GridViewRow) Container).RowIndex %>" ImageUrl="~/Comun/Imagenes/General/editar_bullet.png" />
                                    </ItemTemplate>
                                    <HeaderStyle Width="22px"/>
                                </asp:TemplateField>
                                <asp:TemplateField>
                                    <ItemTemplate>
                                        <asp:ImageButton ID="ibBorraGV" runat="server" CommandName="Borrar" CommandArgument="<%#((GridViewRow) Container).RowIndex %>" ImageUrl="~/Comun/Imagenes/General/borrar_bullet.png" />
                                    </ItemTemplate>
                                    <HeaderStyle Width="22px" />
                                </asp:TemplateField>
                                <asp:TemplateField SortExpression="faclinDesglose">
                                    <ItemTemplate>
                                        <asp:ImageButton ID="ibFaclinDesglose" runat="server" ImageUrl="~/Comun/Imagenes/General/ver_bullet.png" CommandArgument="<%# ((GridViewRow) Container).RowIndex %>" OnClick="ibFaclinDesglose_Click" />
                                    </ItemTemplate>
                                    <HeaderStyle Width="22px" />
                                </asp:TemplateField>
                                <asp:TemplateField SortExpression="NumeroLinea">
                                    <ItemTemplate>
                                        <asp:LinkButton ID="lblNumeroLin" runat="server" Text='<%# Bind("NumeroLinea") %>' CommandArgument="<%# ((GridViewRow) Container).RowIndex %>" CommandName="Consultar"></asp:LinkButton>
                                        <asp:HiddenField ID="hfFacturaCodigoLineas" runat="server" Value='<%# Bind("FacturaCodigo") %>' />
                                        <asp:HiddenField ID="hfPeriodo" runat="server" Value='<%# Bind("Periodo") %>' />
                                        <asp:HiddenField ID="hfContrato" runat="server" Value='<%# Bind("Contrato") %>' />
                                        <asp:HiddenField ID="hfVersion" runat="server" Value='<%# Bind("Version") %>' />
                                        <asp:HiddenField ID="hfFechaLiq" runat="server" Value='<%# Bind("FechaLiquidacion") %>' />
                                        <asp:HiddenField ID="hfUsrLiq" runat="server" Value='<%# Bind("UsuarioCodigo") %>' />
                                    </ItemTemplate>
                                    <ItemStyle CssClass="campoNumero" />
                                    <HeaderStyle CssClass="campoNumero" Width="50px" />
                                </asp:TemplateField>
                                <asp:TemplateField SortExpression="CodigoServicio">
                                    <ItemTemplate>
                                        <asp:Label ID="lblCodServ" runat="server" Text='<%# Bind("CodigoServicio") %>'></asp:Label>
                                    </ItemTemplate>
                                    <HeaderStyle Width="145px" />
                                </asp:TemplateField>
                                <asp:TemplateField SortExpression="Unidades">
                                    <ItemTemplate>
                                        <asp:Label ID="lblUnidades" runat="server" Text='<%# Bind("Unidades", "{0:N2}") %>'></asp:Label>
                                    </ItemTemplate>
                                    <HeaderStyle Width="50px" CssClass="campoNumero"/>
                                    <ItemStyle CssClass="campoNumero" />
                                </asp:TemplateField>
                                <asp:TemplateField SortExpression="Precio">
                                    <ItemTemplate>
                                        <asp:Label ID="lblPrecio" runat="server" Text='<%# Bind("Precio", "{0:N2}") %>'></asp:Label>
                                    </ItemTemplate>
                                    <HeaderStyle Width="80px" CssClass="campoNumero"/>
                                    <ItemStyle CssClass="campoNumero" />
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="ImporteCuota" SortExpression="ImporteCuota">
                                    <HeaderStyle Width="80px" CssClass="campoNumero"/>
                                    <ItemStyle CssClass="campoNumero" />
                                    <ItemTemplate>
                                        <asp:Label ID="lblImpCuota" runat="server" Text='<%# Bind("ImporteCuota", "{0:N2}") %>'></asp:Label>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Consumo" SortExpression="Consumo">
                                    <ItemTemplate>
                                        <asp:Label ID="lblConsumo" runat="server" Text='<%# Bind("Consumo", "{0:N2}") %>'></asp:Label>
                                    </ItemTemplate>
                                    <HeaderStyle Width="40px" CssClass="campoNumero"/>
                                    <ItemStyle CssClass="campoNumero" />
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="ImporteConsumo" SortExpression="ImporteConsumo">
                                    <ItemTemplate>
                                        <asp:Label ID="lblTotConsumo" runat="server" Text='<%# Bind("ImporteConsumo", "{0:N2}") %>'></asp:Label>
                                    </ItemTemplate>
                                    <HeaderStyle Width="87px" CssClass="campoNumero" />
                                    <ItemStyle CssClass="campoNumero" />
                                </asp:TemplateField>
                                <asp:TemplateField SortExpression="Total">
                                    <ItemTemplate>
                                        <asp:Label ID="lblTotal" runat="server" Text='<%# Bind("Total", "{0:N2}") %>'></asp:Label>
                                    </ItemTemplate>
                                    <HeaderStyle Width="80px" CssClass="campoNumero"/>
                                    <ItemStyle CssClass="campoNumero" />
                                </asp:TemplateField>
                            </Columns>
                            <RowStyle CssClass="gridViewRow" />
                            <PagerStyle CssClass="gvPager" />
                                  <PagerTemplate>
                                    <uc6:ctrGridViewPager id="ctrGridViewPagerLin" runat="server" OnIraPagChanged="ctrGridViewPagerLin_IraPagChanged" />
                                  </PagerTemplate>
                        </asp:GridView>    
                        <div id="divlineadown" class="LineaBlanca2gv"></div>
                    </div>

                    <!-- OBJECTDATASOURCE-->
                    <!--------------------->
                    <!--------------------->
                    <Acuama:AcuamaDataSource ID="odsFacLin" runat="server" SelectMethod="ObtenerLineas" TypeName="BL.Facturacion.cFacturasBL" OnSelecting="odsFacLin_Selecting">
                        <SelectParameters>
                            <asp:Parameter Direction="InputOutput" Name="facturaBO" Type="Object" />
                            <asp:Parameter Direction="Output" Name="respuesta" Type="Object" />
                        </SelectParameters>    
                    </Acuama:AcuamaDataSource>
                    <!--FIN OBJECTDATASOURCE-->
                    <!------------------------>
                    <!------------------------>
                </ContentTemplate>
            </asp:UpdatePanel>            
        </div><!--CIERRE tabLinContent-->
    </div><!--CIERRE tabFacContainer-->  
    
     <!--Div que contiene el control de usuario para insertar y editar las líneas sobre un ModalPopupExtender-->              
    <div id="detailLin" runat="server" class="controlPopup colorPagina" style="display:none">
        <uc2:ctrFacLinCRU ID="ctrFacLinCRU" Detail="true" runat="server" OnClosed="ctrFacLinCRU_Closed" />
    </div>
    <!--ModalpopupExtender asociado al control de usuario ctrFacLinCRU para insertar y editar-->    
    <div style="display:none"><asp:Button ID="btnDumbPopupCRU" runat="server"/></div>
    <cc1:ModalPopupExtender ID="mpeFacLinCRU" runat="server" TargetControlID="btnDumbPopupCRU"
     BackgroundCssClass="modalBackground" PopupControlID="detailLin" />
     
    <!--Div que contiene el control de usuario para imprimir -->         
    <div id="print" runat="server" class="controlPopup colorPagina" style="display:none;">
        <uc5:ctrFacturasPRINT ID="ctrFacturasPRINT" runat="server" OnCerrar="CtrFacturaPRINT_CerrarClick" />           
    </div>
    <div style="display:none"><asp:Button ID="btnDumbPopupPRINT" runat="server"/></div>
    <cc1:ModalPopupExtender ID="mpefacPRINT" runat="server" TargetControlID="btnDumbPopupPRINT"  BackgroundCssClass="modalBackground" PopupControlID="print">
    </cc1:ModalPopupExtender>

    <!--Div que contiene el control de usuario para buscar -->       
    <div id="findCab"  runat="server" class="controlPopup colorPagina" style="display:none;" >
        <uc6:ctrFacturasFIND ID="ctrFacturasFIND" runat="server" OnAceptarClick="CtrFacturasFIND_AceptarClick" OnCancelarClick="CtrFacturasFIND_CancelarClick"/>
    </div>
    <div style="display:none"><asp:Button ID="btnDumbPopupFINDCab" runat="server"/></div>
    <cc1:ModalPopupExtender ID="mpefacFINDCab" runat="server" TargetControlID="btnDumbPopupFINDCab"  BackgroundCssClass="modalBackground" PopupControlID="findCab" />
    
    <asp:UpdatePanel ID="upBotonesOkCancelBuscar" runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <div id="botonesOkCancelModoBuscar" runat="server" class="botonesOkCancelModoBuscar" visible="false">
                <asp:ImageButton CssClass="hoverButton" ID="ibAceptarBuscar" runat="server" ImageUrl="~/Comun/Imagenes/Botones/aceptar.png" OnClick="ibAceptarBuscar_Click"/>
                <asp:ImageButton CssClass="hoverButton" ID="ibCancelarBuscar" runat="server" ImageUrl="~/Comun/Imagenes/Botones/cancelar.png" OnClientClick="parent.HideModalIframe();return false;"/>
            </div>
        </ContentTemplate>
    </asp:UpdatePanel>
    
</asp:Content>

