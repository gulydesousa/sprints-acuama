using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace WindowsFormsApplication1
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();

            this.openFileDialog = new System.Windows.Forms.OpenFileDialog();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            string tipoReg;
            string servicio;
            string facBase;
            string facImp;
            string facTotal;

            decimal iFacBase;
            decimal iFacImp;
            decimal iFacTotal;

            StringBuilder[] Lineas = new StringBuilder[7];
            string strResult;


            try
            {
                string idApremio = "15";

                using (var reader = new StreamReader(@"C:\GdeSousa\[DEV]\[20201215]GUADALAJARA_SII Noviembre[SYR-207506]\APREMIOS\apremios_" + idApremio + @"\apremios_" + idApremio + ".txt", Encoding.Default))
                {
                    using (var writer = new StreamWriter(@"C:\GdeSousa\[DEV]\[20201215]GUADALAJARA_SII Noviembre[SYR-207506]\APREMIOS\apremios_" + idApremio + @"\2decApremios_" + idApremio + ".txt"))
                    {
                        string linea;
                        while ((linea = reader.ReadLine()) != null)
                        {
                            strResult = linea;

                            if (linea.Substring(0, 2) == "01")
                            {
                                strResult = linea.Substring(0, 24);

                                Lineas[0] = new StringBuilder(linea.Substring(24, 70));
                                Lineas[1] = new StringBuilder(linea.Substring(94, 70));
                                Lineas[2] = new StringBuilder(linea.Substring(164, 70));
                                Lineas[3] = new StringBuilder(linea.Substring(234, 70));
                                Lineas[4] = new StringBuilder(linea.Substring(304, 70));
                                Lineas[5] = new StringBuilder(linea.Substring(374, 70));
                                Lineas[6] = new StringBuilder(linea.Substring(444, 70));

                                var i = 0;
                                foreach (StringBuilder svc in Lineas)
                                {


                                    servicio = svc.ToString().Substring(0, 48).Trim();
                                    facBase = svc.ToString().Substring(48, 8);
                                    facImp = svc.ToString().Substring(56, 6);
                                    facTotal = svc.ToString().Substring(62, 8);

                                    if (!string.IsNullOrEmpty(servicio))
                                    {
                                        iFacBase = Math.Round(decimal.Parse(facBase) * 0.0001M, 2);
                                        iFacImp = Math.Round(decimal.Parse(facImp) * 0.0001M, 2);
                                        iFacTotal = Math.Round(decimal.Parse(facTotal) * 0.0001M, 2);

                                        facBase = Convert.ToInt32(iFacBase * 10000).ToString("00000").PadLeft(8);
                                        facImp = Convert.ToInt32(iFacImp * 10000).ToString("00000").PadLeft(6);
                                        facTotal = Convert.ToInt32(iFacTotal * 10000).ToString("00000").PadLeft(8);

                                        //Lineas[i]= svc.Remove(48, 22).Insert(48, facBase + facImp + facTotal);
                                    }
                                    strResult += Lineas[i].ToString();
                                    i++;
                                }
                                strResult += linea.Substring(514, 98);
                            }
                            writer.WriteLine(strResult);
                        }
                    }
                }
            }

            catch (IOException)
            {
            }


        }


        private class registro
        {
            public int linea { get; set; }
            public string anio { get; set; }
            public string registro00 { get; set; }

            public string factura { get; set; }
            public string importe { get; set; }

           
            private decimal _total;

            private List<lineaDesglose> Desglose = new List<lineaDesglose>();

            public decimal totalLineas {
                get { return this.Desglose.Sum(x => x.total); }
            }

            public decimal totalCabecera {
                get { return Math.Round(decimal.Parse(importe) * 0.01M, 2); }
            }

            public void insertDesglose(string strLinea, int indice)
            {
                lineaDesglose linea = new lineaDesglose { importe = strLinea.Substring(4, 12), tipoIVA = strLinea.Substring(16, 2), importeIVA = strLinea.Substring(18, 12), indice = indice };
                this.Desglose.Add(linea);
            }

            public lineaDesglose maxBaseDesglose {
                get { return Desglose.OrderByDescending(x => x.baseImponible).FirstOrDefault(); }
            }

            public decimal importeAjuste {
                get { return totalCabecera - totalLineas; }
            }
        }

        private class lineaDesglose {

            public int indice { get; set; }
            public string importe { get; set; }
            public string tipoIVA { get; set; }
            public string importeIVA { get; set; }


            private decimal _total;
            private decimal _impuesto;
            private decimal _base;

            public decimal importeImpuesto
            {
                get { return Math.Round(decimal.Parse(importeIVA) * 0.01M, 2); }
            }

            public decimal baseImponible
            {
                get { return Math.Round(decimal.Parse(importe) * 0.01M, 2); }
            }

            public decimal total
            {
                get { return Math.Round(decimal.Parse(importe) * 0.01M, 2) + Math.Round(decimal.Parse(importeIVA) * 0.01M, 2); }
            }

            public string ajustarBase(decimal impAjuste)
            {
                decimal fclBase = this.baseImponible + impAjuste;
                return Convert.ToInt32(fclBase * 100).ToString("000000000000").PadLeft(12);
            }


        }





        private void button2_Click(object sender, EventArgs e)
        {
            try
            {
                string idApremio = "14";
                int indice = 0;
                registro apremio = null;

                using (var reader = new StreamReader(@"C:\GdeSousa\[DEV]\[20201221]GUADALAJARA_Apremios IncidenciaRedondeo[SYR-207165]\APREMIOS\apremios_" + idApremio + @"\apremios_" + idApremio + ".txt", Encoding.Default))
                {
                    using (var writer = new StreamWriter(@"C:\GdeSousa\[DEV]\[20201221]GUADALAJARA_Apremios IncidenciaRedondeo[SYR-207165]\APREMIOS\apremios_" + idApremio + @"\ERR_TOTAL_" + idApremio + ".csv"))
                    {
                        string linea;

                        while ((linea = reader.ReadLine()) != null)
                        {
                            //Para contar la linea del archivo
                            indice++;

                            switch (linea.Substring(0, 2))
                            {
                                case "00":
                                    if (indice == 1)
                                        writer.WriteLine(string.Format("{0};{1};{2};{3};{4};{5}", "Linea", "Registro00", "Factura", "Importe", "TotalCabecera", "TotalLineas"));
                                    else if (apremio.totalCabecera != apremio.totalLineas)
                                    {
                                        writer.WriteLine(string.Format("{0};{1};{2};{3};{4};{5}", apremio.linea, apremio.registro00, apremio.factura, apremio.importe, apremio.totalCabecera, apremio.totalLineas));
                                    }

                                    apremio = new registro { factura = linea.Substring(12, 7), importe = linea.Substring(24, 12), linea = indice, registro00 = linea.Substring(0, 46) };
                                    break;

                                case "03":
                                    apremio.insertDesglose(linea, indice);
                                    break;

                                default:
                                    break;
                            }
                        }
                    }
                }

            }

            catch (IOException ex)
            {

            }

        }


        #region Ajustar Desgloses

        private string directorioSalida(string filePath)
        {
            var directoryPath = Path.GetDirectoryName(filePath);
            var subdirectoryPath = Path.Combine(directoryPath, DateTime.Now.ToString("yyyyMMdd_HHmmss"));

            if (!Directory.Exists(subdirectoryPath))
            {
                Directory.CreateDirectory(subdirectoryPath);
            }

            return subdirectoryPath;
        }

        private string ficheroEntradaTxt()
        {
            string directorioTrabajo = string.Empty;

            openFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*";

            if (openFileDialog.ShowDialog() == DialogResult.OK)
            {
                directorioTrabajo = openFileDialog.FileName;
            }

            return directorioTrabajo;
        }

        private void btnAjustarDesgloses_Click(object sender, EventArgs e)
        {
            try
            {
                string ficheroEntrada = ficheroEntradaTxt();

                if (string.IsNullOrEmpty(ficheroEntrada)) return;

                string dirResult = directorioSalida(ficheroEntrada);
                string ficheroSalida = Path.Combine(dirResult, Path.GetFileNameWithoutExtension(ficheroEntrada) + "_ajustado.txt");
                string ficheroAjustes = Path.Combine(dirResult, Path.GetFileNameWithoutExtension(ficheroEntrada) + "_ajustes.csv");

                string idApremio = this.txtApremio.Text;
                int indice = 0;
                string linea = string.Empty;
                registro apremio = null;
                string tipoLinea = "BOF";

                Dictionary<int, string> buffer = new Dictionary<int, string>();


                using (var reader = new StreamReader(ficheroEntrada, Encoding.Default))
                {
                    using (StreamWriter writer = new StreamWriter(ficheroSalida, false, Encoding.Default))
                    {
                        using (var ajustes = new StreamWriter(ficheroAjustes))
                        {
                            do
                            {
                                linea = reader.ReadLine();
                                //Para contar la linea del archivo
                                indice++;

                                if (linea == null)
                                    tipoLinea = "EOF";
                                else if (indice == 1)
                                    tipoLinea = "BOF";

                                else
                                    tipoLinea = linea.Substring(0, 2);

                                buffer.Add(indice, linea);

                                switch (tipoLinea)
                                {
                                    case "BOF":
                                        apremio = new registro { factura = linea?.Substring(12, 7), importe = linea?.Substring(24, 12), linea = indice, registro00 = linea?.Substring(0, 46) };
                                        ajustes.WriteLine(string.Format("{0};{1};{2};{3};{4};{5}", "Linea", "Registro00", "Factura", "Importe", "TotalCabecera", "TotalLineas"));
                                        break;
                                    case "EOF":
                                    case "00":
                                        if (apremio.importeAjuste != 0)
                                        {
                                            lineaDesglose lineaAjuste = apremio.maxBaseDesglose;
                                            int key = lineaAjuste.indice;
                                            buffer[key] = buffer[key].Remove(4, 12).Insert(4, lineaAjuste.ajustarBase(apremio.importeAjuste));

                                            ajustes.WriteLine(string.Format("{0};{1};{2};{3};{4};{5}", apremio.linea, apremio.registro00, apremio.factura, apremio.importe, apremio.totalCabecera, apremio.totalLineas));

                                        }

                                        foreach (string buff in buffer.OrderBy(x => x.Key).Select(x => x.Value))
                                        {
                                            if (buff != null)
                                                writer.WriteLine(buff);
                                        }

                                        buffer = new Dictionary<int, string>();
                                        apremio = new registro { factura = linea?.Substring(12, 7), importe = linea?.Substring(24, 12), linea = indice, registro00 = linea?.Substring(0, 46) };
                                        break;

                                    case "03":
                                        apremio.insertDesglose(linea, indice);
                                        break;

                                    default:
                                        break;
                                }

                            } while (tipoLinea != "EOF");
                        }
                    }
                }

            }

            catch (IOException ex)
            {

            }

        }

        #endregion

        private void button4_Click(object sender, EventArgs e)
        {
            string idApremio = this.txtApremio.Text;

            string directorioTrabajo = @"C:\GdeSousa\[DEV]\[20201221]GUADALAJARA_Apremios IncidenciaRedondeo[SYR-207165]\APREMIO16\apremios_{0}\{1}0000apremios_{0}.{2}";

            string ficheroEntrada = string.Format(directorioTrabajo, idApremio, "", "txt");

            string ficheroSalida2017 = string.Format(directorioTrabajo, idApremio, "2017", "txt");
            string ficheroSalida2018 = string.Format(directorioTrabajo, idApremio, "otros", "txt");

            string facturas2017 = string.Format(directorioTrabajo, idApremio, "2017", "csv");
            string facturas2018 = string.Format(directorioTrabajo, idApremio, "otros", "csv");

            StreamReader reader = new StreamReader(ficheroEntrada, Encoding.Default);

            StreamWriter txt2017 = new StreamWriter(ficheroSalida2017, false, Encoding.Default);
            StreamWriter txt2018 = new StreamWriter(ficheroSalida2018, false, Encoding.Default);

            StreamWriter csv2017 = new StreamWriter(facturas2017, false, Encoding.Default);
            StreamWriter csv2018 = new StreamWriter(facturas2018, false, Encoding.Default);

            try
            {
               
                int indice = 0;
                string linea = string.Empty;
                registro apremio = null;
                string tipoLinea = "BOF";
                string anio;

                Dictionary<int, string> buffer = new Dictionary<int, string>();

                do
                {
                    linea = reader.ReadLine();
                    //Para contar la linea del archivo
                    indice++;

                    if (linea == null)
                        tipoLinea = "EOF";
                    else if (indice == 1)
                        tipoLinea = "BOF";
                    else
                        tipoLinea = linea.Substring(0, 2);

                    //buffer.Add(indice, linea);

                    switch (tipoLinea)
                    {
                        case "BOF":
                            apremio = new registro { factura = linea?.Substring(12, 7), importe = linea?.Substring(24, 12), linea = indice, registro00 = linea?.Substring(0, 46), anio = linea?.Substring(8, 4) };
                            csv2017.WriteLine(string.Format("{0};{1};{2};{3};{4};{5};{6};{7}", "Linea", "Registro00", "Factura", "Importe", "TotalCabecera", "TotalLineas", "Año", "Ajustado"));
                            csv2018.WriteLine(string.Format("{0};{1};{2};{3};{4};{5};{6};{7}", "Linea", "Registro00", "Factura", "Importe", "TotalCabecera", "TotalLineas", "Año", "Ajustado"));
                            buffer.Add(indice, linea);
                            break;
                        case "EOF":
                        case "00":
                            if (apremio.anio == "2017")
                                csv2017.WriteLine(string.Format("{0};{1};{2};{3};{4};{5};{6};{7}", apremio.linea, apremio.registro00, apremio.factura, apremio.importe, apremio.totalCabecera, apremio.totalLineas, apremio.anio, apremio.importeAjuste != 0 ? "SI" : "NO"));
                            else
                                csv2018.WriteLine(string.Format("{0};{1};{2};{3};{4};{5};{6};{7}", apremio.linea, apremio.registro00, apremio.factura, apremio.importe, apremio.totalCabecera, apremio.totalLineas, apremio.anio, apremio.importeAjuste != 0 ? "SI" : "NO"));

                            if (apremio.importeAjuste != 0)
                            {
                                lineaDesglose lineaAjuste = apremio.maxBaseDesglose;
                                int key = lineaAjuste.indice;
                                buffer[key] = buffer[key].Remove(4, 12).Insert(4, lineaAjuste.ajustarBase(apremio.importeAjuste));
                            }

                            foreach (string buff in buffer.OrderBy(x => x.Key).Select(x => x.Value))
                            {
                                if (buff == null)
                                { }
                                else if (apremio.anio == "2017")
                                { txt2017.WriteLine(buff); }
                                else
                                { txt2018.WriteLine(buff); }
                            }

                            buffer = new Dictionary<int, string>();
                            buffer.Add(indice, linea);
                            apremio = new registro { factura = linea?.Substring(12, 7), importe = linea?.Substring(24, 12), linea = indice, registro00 = linea?.Substring(0, 46), anio = linea?.Substring(8, 4)};
                            break;

                        case "03":
                            buffer.Add(indice, linea);
                            apremio.insertDesglose(linea, indice);
                            break;

                        default:
                            buffer.Add(indice, linea);
                            break;
                    }

                } while (tipoLinea != "EOF");


            } //TRY

            catch (IOException ex)
            {

            }
            finally {
                csv2017.Close();
                csv2018.Close();
                txt2017.Close();
                txt2018.Close();
            }


        }//button4_Click

        private void button5_Click(object sender, EventArgs e)
        {
            string idApremio = this.txtApremio.Text;

            string directorioTrabajo = @"C:\GdeSousa\[DEV]\[20201222]GUADALAJARA_Apremios IncidenciaRedondeo[SYR-207165]\[APREMIOS16]\{1}apremios_{0}.{2}";

            string ficheroEntrada = string.Format(directorioTrabajo, idApremio, "", "txt");
            string ficheroSalida = string.Format(directorioTrabajo, idApremio, "0000", "txt");

            string facturasCSV = string.Format(directorioTrabajo, idApremio, "", "csv");
            
            StreamReader reader = new StreamReader(ficheroEntrada, Encoding.Default);
            StreamWriter writer = new StreamWriter(ficheroSalida, false, Encoding.Default);
            StreamWriter csv = new StreamWriter(facturasCSV, false, Encoding.Default);
         

            try
            {

                int indice = 0;
                string linea = string.Empty;
                registro apremio = null;
                string tipoLinea = "BOF";
                string anio;

                Dictionary<int, string> buffer = new Dictionary<int, string>();

                do
                {
                    linea = reader.ReadLine();
                    //Para contar la linea del archivo
                    indice++;

                    if (linea == null)
                        tipoLinea = "EOF";
                    else if (indice == 1)
                        tipoLinea = "BOF";
                    else
                        tipoLinea = linea.Substring(0, 2);


                    switch (tipoLinea)
                    {
                        case "BOF":
                            apremio = new registro { factura = linea?.Substring(12, 7), importe = linea?.Substring(24, 12), linea = indice, registro00 = linea?.Substring(0, 46), anio = linea?.Substring(325, 4) };
                            csv.WriteLine(string.Format("{0};{1};{2};{3};{4};{5};{6};{7}", "Linea", "Registro00", "Factura", "Importe", "TotalCabecera", "TotalLineas", "Año", "Ajustado"));

                            linea = linea != null && linea.Substring(8, 4) == "0000" ? linea.Remove(8, 4).Insert(8, apremio.anio) : linea;
                            buffer.Add(indice, linea);
                            break;
                        case "EOF":
                        case "00":
                            csv.WriteLine(string.Format("{0};{1};{2};{3};{4};{5};{6};{7}", apremio.linea, apremio.registro00, apremio.factura, apremio.importe, apremio.totalCabecera, apremio.totalLineas, apremio.anio, apremio.importeAjuste != 0 ? "SI" : "NO"));

                            if (apremio.importeAjuste != 0)
                            {
                                lineaDesglose lineaAjuste = apremio.maxBaseDesglose;
                                int key = lineaAjuste.indice;
                                buffer[key] = buffer[key].Remove(4, 12).Insert(4, lineaAjuste.ajustarBase(apremio.importeAjuste));
                            }

                            

                            foreach (string buff in buffer.OrderBy(x => x.Key).Select(x => x.Value))                            {
                                if (buff == null)
                                {
                                }
                                else 
                                {
                                    writer.WriteLine(buff);
                                }
                            }

                            buffer = new Dictionary<int, string>();
                            apremio = new registro { factura = linea?.Substring(12, 7), importe = linea?.Substring(24, 12), linea = indice, registro00 = linea?.Substring(0, 46), anio = linea?.Substring(325, 4) };
                            linea = linea != null && linea.Substring(8, 4) == "0000" ? linea.Remove(8, 4).Insert(8, apremio.anio) : linea;
                            buffer.Add(indice, linea);
                            break;

                        case "03":
                            buffer.Add(indice, linea);
                            apremio.insertDesglose(linea, indice);
                            break;

                        default:
                            buffer.Add(indice, linea);
                            break;
                    }

                } while (tipoLinea != "EOF");


            } //TRY

            catch (IOException ex)
            {

            }
            finally
            {
                csv.Close();
                writer.Close();
                reader.Close();
            }
        }//button5_Click

        private void button6_Click(object sender, EventArgs e)
        {
            string idApremio = this.txtApremio.Text;

            string directorioTrabajo = @"C:\GdeSousa\[DEV]\[20201223]GUADALAJARA_Apremios IncidenciaRedondeo[SYR-207165]\[APREMIOS16]\{1}apremios_{0}.{2}";

            string ficheroOK = string.Format(directorioTrabajo, idApremio, "OK", "txt");
            string ficheroKO = string.Format(directorioTrabajo, idApremio, "KO", "txt");

            string ficheroOK_OK = string.Format(directorioTrabajo, idApremio, "OK_OK", "txt");
            string ficheroOK_KO = string.Format(directorioTrabajo, idApremio, "OK_KO", "txt");

            string facturasCSV = string.Format(directorioTrabajo, idApremio, "", "csv");

            StreamReader readerOK = new StreamReader(ficheroOK, Encoding.Default);
            StreamReader readerKO = new StreamReader(ficheroKO, Encoding.Default);

            StreamWriter writerOK = new StreamWriter(ficheroOK_OK, false, Encoding.Default);
            StreamWriter writerKO = new StreamWriter(ficheroOK_KO, false, Encoding.Default);

            StreamWriter salida;

            StreamWriter csv = new StreamWriter(facturasCSV, false, Encoding.Default);


            try
            {
                string lineaOK = string.Empty;
                string lineaKO = string.Empty;
                string ejercicioKO = string.Empty;

                int indice = 0;
                string tipoLinea = "BOF";

                //registro apremio = null;
                //string anio;

                Dictionary<int, string> buffer = new Dictionary<int, string>();

                do
                {
                    lineaOK = readerOK.ReadLine();
                    lineaKO = readerKO.ReadLine();

                    //Para contar la linea del archivo
                    indice++;
                    
                    if (lineaOK == null)
                        tipoLinea = "EOF";
                    else if (indice == 1)
                        tipoLinea = "BOF";
                    else

                        tipoLinea = lineaOK.Substring(0, 2);

                    
                    switch (tipoLinea)
                    {
                        case "BOF":
                            buffer.Add(indice, lineaOK);
                            ejercicioKO = lineaKO.Substring(8, 4); 
                            break;
                        case "EOF":
                        case "00":
                            salida = buffer.OrderBy(x => x.Key).First().Value.Substring(8, 4)==ejercicioKO? writerOK:writerKO;
                            foreach (string buff in buffer.OrderBy(x => x.Key).Select(x => x.Value))
                            {
                                if (buff != null) salida.WriteLine(buff);
                            }
                            buffer.Clear();
                            buffer.Add(indice, lineaOK);
                            ejercicioKO = lineaKO?.Substring(8, 4);
                            break;

                        case "03":
                            buffer.Add(indice, lineaOK);
                            break;

                        default:
                            buffer.Add(indice, lineaOK);
                            break;
                    }

                } while (tipoLinea != "EOF");
                

                } //TRY

            catch (IOException ex)
            {

            }
            finally
            {
                csv.Close();
                
                writerOK.Close();
                writerKO.Close();
                readerOK.Close();
                readerKO.Close();
            }
        }



        
    }
    }
