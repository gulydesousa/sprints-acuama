using BO.Facturacion;
using BO.Comun;
using DL.Facturacion;

namespace BL.Facturacion
{
    public class cFacturaDeudaEstadosBL
    {
      public cRespuesta Obtener(ref cFacturaDeudaEstadoBO estadoBO)
        {
            cRespuesta respuesta = new cRespuesta();
            new cFacturaDeudaEstadosDL().Obtener(ref estadoBO, out respuesta);
            return respuesta;
        }

       public cBindableList<cFacturaDeudaEstadoBO> ObtenerTodos(out cRespuesta respuesta)
        {
            cBindableList<cFacturaDeudaEstadoBO> result = new cBindableList<cFacturaDeudaEstadoBO>();
 
            new cFacturaDeudaEstadosDL().ObtenerTodos(ref result, out respuesta);

            return result;
        }
    }

}
