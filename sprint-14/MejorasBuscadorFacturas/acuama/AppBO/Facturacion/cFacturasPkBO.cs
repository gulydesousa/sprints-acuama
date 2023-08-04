namespace BO.Facturacion
{
    public class cFacturasPkBO
    {

        public int FacCod {get; set;}
        public int FacCtrCod { get; set; }
        public string FacPerCod { get; set; }
        public int FacVersion { get; set; }

        /// <summary>
        /// Constructor de Periodo
        /// </summary>  
        public cFacturasPkBO(int facCod, int facCtrCod, string facPerCod, int facVersion)
        {
            FacCod = facCod;
            FacPerCod = facPerCod;
            FacCtrCod = facCtrCod;
            FacVersion = facVersion;   
        }
    }
}
