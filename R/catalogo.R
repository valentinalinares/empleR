#' Ver el catalogo de fuentes disponibles
#'
#' Muestra un inventario de todas las encuestas, anos y variantes disponibles
#' para descargar con [descargar()]. Incluye EPEN (departamentos y Lima movil)
#' y ENAHO anual, con el numero de filas y codigos ocupacionales por periodo.
#'
#' @param fuente Filtrar por fuente: `"EPEN"`, `"ENAHO"` o `"todas"` (por defecto).
#' @param year Filtrar por ano. Si es `NULL` (por defecto), devuelve todos los anos.
#' @param variante Filtrar por variante: `"departamentos_anual"`, `"lima_movil"`,
#'   `"anual"` o `"todas"` (por defecto).
#'
#' @return Un `data.frame` con columnas:
#'   \describe{
#'     \item{fuente}{Nombre de la encuesta (EPEN, ENAHO).}
#'     \item{variante}{Variante de la encuesta.}
#'     \item{year}{Ano de referencia.}
#'     \item{periodo}{Descripcion del periodo (trimestre o anual).}
#'     \item{filas}{Numero de filas en la base procesada.}
#'     \item{codigos_ocup}{Numero de codigos ocupacionales distintos.}
#'   }
#'
#' @export
#'
#' @examples
#' # Ver todo el catalogo
#' catalogo()
#'
#' # Solo EPEN
#' catalogo(fuente = "EPEN")
#'
#' # EPEN departamentos anuales
#' catalogo(fuente = "EPEN", variante = "departamentos_anual")
#'
#' # Un ano especifico
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
