#' Ver el catálogo de fuentes disponibles
#'
#' Muestra un inventario de las encuestas, años y variantes procesadas por el
#' proyecto. Incluye EPEN (departamentos y Lima móvil) y ENAHO anual, con el
#' número de filas y códigos ocupacionales por periodo. En esta versión,
#' [descargar()] solo descarga EPEN; una entrada en el catálogo no implica que
#' todas las fuentes tengan descarga automática desde R.
#'
#' @param fuente Filtrar por fuente: `"EPEN"`, `"ENAHO"` o `"todas"` (por defecto).
#' @param year Filtrar por año. Si es `NULL` (por defecto), devuelve todos los años.
#' @param variante Filtrar por variante: `"departamentos_anual"`, `"lima_movil"`,
#'   `"anual"` o `"todas"` (por defecto).
#'
#' @return Un `data.frame` con columnas:
#'   \describe{
#'     \item{fuente}{Nombre de la encuesta (EPEN, ENAHO).}
#'     \item{variante}{Variante de la encuesta.}
#'     \item{year}{Año de referencia.}
#'     \item{periodo}{Descripción del periodo (trimestre o anual).}
#'     \item{filas}{Número de filas en la base procesada.}
#'     \item{codigos_ocup}{Número de códigos ocupacionales distintos.}
#'   }
#'
#' @export
#'
#' @examples
#' # Ver todo el catálogo
#' catalogo()
#'
#' # Solo EPEN
#' catalogo(fuente = "EPEN")
#'
#' # EPEN departamentos anuales
#' catalogo(fuente = "EPEN", variante = "departamentos_anual")
#'
#' # Un año específico
#' catalogo(year = 2024)
catalogo <- function(fuente = "todas", year = NULL, variante = "todas") {
  datos <- catalogo_fuentes

  if (fuente != "todas") {
    datos <- datos[datos$fuente == toupper(fuente), ]
  }

  if (!is.null(year)) {
    datos <- datos[datos$year %in% year, ]
  }

  if (variante != "todas") {
    datos <- datos[datos$variante == variante, ]
  }

  if (nrow(datos) == 0) {
    cli::cli_warn("No se encontraron entradas con los filtros aplicados.")
  }

  datos
}
