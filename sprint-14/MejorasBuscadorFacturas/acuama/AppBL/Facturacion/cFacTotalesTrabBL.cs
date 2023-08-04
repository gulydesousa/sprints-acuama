using BO.Facturacion;
using BO.Comun;
using DL.Facturacion;
using System;

namespace BL.Facturacion
{
    public class cFacTotalesTrabBL
    {
        public cRespuesta Insertar(cBindableList<cFacturaBO> facs)
        {
            cRespuesta result = new cRespuesta();
            cFacTotalesTrabDL objDL = new cFacTotalesTrabDL();

            objDL.Insertar(facs, out result);

            return result;
        }

        public bool Borrar(out cRespuesta respuesta)
        {
            bool resultado = false;
            respuesta = new cRespuesta();
            try
            {
                cFacTotalesTrabDL objDL = new cFacTotalesTrabDL();
                resultado = objDL.Borrar(out respuesta);
            }
            catch (Exception ex)
            {
                resultado = false;
                cExcepciones.ControlarER(ex, TipoExcepcion.Error, out respuesta);
            }
            return resultado;
        }
    }
}
