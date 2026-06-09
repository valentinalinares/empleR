#' Descargar microdatos de la EPEN desde el portal del INEI
#'
#' Descarga el modulo de Empleo e Ingresos de la Encuesta Permanente de Empleo
#' Nacional (EPEN) directamente desde el portal de microdatos del INEI
#' (\url{https://proyectos.inei.gob.pe/microdatos/}). Soporta cache local para
#' evitar descargas repetidas.
#'
#' @param year Ano de la encuesta. EPEN disponible: 2022-2025.
#'   Ver [catalogo()] para la lista completa.
#' @param variante Variante de la encuesta:
#'   - `"departamentos_anual"` (por defecto): EPEN nacional anual.
#'   - `"lima_movil"`: EPEN Lima Metropolitana, trimestres moviles.
#' @param periodo Para `variante = "lima_movil"`, el periodo a descargar.
#'   Usar el label exacto del catalogo, e.g. `"Trimestre Movil -(Ene-Feb-Mar)"`.
#'   Ver [catalogo()] para la lista completa de periodos disponibles.
#' @param destfile Ruta local donde cachear el resultado como `.rds`.
#'   Si el archivo ya existe, se usa la version en cache sin descargar.
#'   Si es `NULL` (por defecto), descarga sin guardar cache permanente.
#' @param quiet Logico. Si `TRUE` (por defecto), suprime mensajes de progreso.
#'
#' @return Un `data.frame` con los microdatos crudos del modulo de Empleo e
#'   Ingresos de la EPEN. Las columnas siguen la nomenclatura original del
#'   INEI (e.g. `C308_COD`, `FACTOR07`, `ESTRATO`, `CONGLOME`).
#'   Usar [etiquetar()] para aplicar etiquetas de valor y [cno()] para
#'   agregar descripciones de ocupaciones.
#'
#'   **A diferencia de [muestra_epen_2024], estos datos incluyen todos los
#'   estados laborales**: ocupados, desocupados abiertos, desocupados ocultos
#'   e inactivos. La variable `OCA500` (o equivalente) indica el estado laboral
#'   de cada persona, lo que permite calcular tasas de desempleo y actividad.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Descargar EPEN 2024 departamentos (nivel nacional)
#' epen_2024 <- descargar(year = 2024)
#'
#' # Con cache: si el archivo existe, no vuelve a descargar
#' epen_2024 <- descargar(
#'   year = 2024,
#'   destfile = "datos/epen_2024.rds"
#' )
#'
#' # Ver que periodos estan disponibles para lima_movil 2024
#' catalogo(fuente = "EPEN", variante = "lima_movil", year = 2024)
#'
#' # Descargar un trimestre movil de Lima
#' lima_ene <- descargar(
#'   year    = 2024,
#'   variante = "lima_movil",
#'   periodo  = "Trimestre Movil -(Ene-Feb-Mar)"
#' )
#' }
descargar <- function(year,
                      variante = "departamentos_anual",
                      periodo  = NULL,
                      destfile = NULL,
                      quiet    = TRUE) {

  # Patron de cache: si existe el .rds local, devolverlo directamente
  if (!is.null(destfile) && file.exists(destfile)) {
    cli::cli_inform(c("v" = "Cargando desde cache: {.path {destfile}}"))
    return(readRDS(destfile))
  }

  # Buscar URL en el catalogo interno
  url <- .buscar_url(year = year, variante = variante, periodo = periodo)

  cli::cli_inform(c(
    "i" = "Descargando EPEN {year} / {variante}{ifelse(!is.null(periodo), paste0(' / ', periodo), '')}..."
  ))

  # Descargar ZIP a archivo temporal
  tmp_zip <- tempfile(fileext = ".zip")
  utils::download.file(url, destfile = tmp_zip, mode = "wb", quiet = quiet)

  # Descomprimir y leer el CSV dentro del ZIP
  datos <- .leer_zip_inei(tmp_zip)

  cli::cli_inform(c("v" = "Descargado: {nrow(datos)} filas x {ncol(datos)} columnas."))

  # Guardar cache si se especifico destfile
  if (!is.null(destfile)) {
    saveRDS(datos, file = destfile)
    cli::cli_inform(c("v" = "Guardado en cache: {.path {destfile}}"))
  }

  datos
}


# Helpers internos --------------------------------------------------------

#' @noRd
.buscar_url <- function(year, variante, periodo) {
  cat_url <- url_catalog_epen

  # Filtrar por variante y ano
  sub <- cat_url[cat_url$variant == variante & cat_url$year == year, ]

  if (nrow(sub) == 0) {
    cli::cli_abort(c(
      "No hay URL disponible para EPEN {year} / {variante}.",
      "i" = "Usa {.fn catalogo} para ver las opciones disponibles."
    ))
  }

  # Para departamentos_anual: seleccionar el periodo anual nacional
  if (variante == "departamentos_anual") {
    sub <- sub[grepl("Anual", sub$period, ignore.case = TRUE), ]
  }

  # Para lima_movil: el usuario debe especificar el periodo
  if (variante == "lima_movil") {
    if (is.null(periodo)) {
      cli::cli_abort(c(
        "Para {.val lima_movil} debes especificar el argumento {.arg periodo}.",
        "i" = "Usa {.code catalogo(fuente='EPEN', variante='lima_movil', year={year})} para ver los periodos disponibles."
      ))
    }
    # Busqueda flexible del periodo (sin acentos, case-insensitive)
    sub <- sub[.normalizar(sub$period) == .normalizar(periodo), ]
    if (nrow(sub) == 0) {
      cli::cli_abort(c(
        "Periodo '{periodo}' no encontrado para EPEN {year} / {variante}.",
        "i" = "Usa {.code catalogo(fuente='EPEN', variante='lima_movil', year={year})} para ver los periodos exactos."
      ))
    }
  }

  sub$url[1]
}

#' @noRd
.normalizar <- function(x) {
  x <- tolower(trimws(x))
  # Eliminar acentos
  x <- iconv(x, to = "ASCII//TRANSLIT")
  gsub("[^a-z0-9]", "", x)
}

#' @noRd
.leer_zip_inei <- function(path_zip) {
  dir_tmp <- tempfile()
  dir.create(dir_tmp)
  utils::unzip(path_zip, exdir = dir_tmp)

  # Buscar el CSV dentro del ZIP (puede estar en subcarpetas)
  archivos_csv <- list.files(dir_tmp, pattern = "\\.csv$",
                             full.names = TRUE, recursive = TRUE,
                             ignore.case = TRUE)
  if (length(archivos_csv) == 0) {
    cli::cli_abort(c(
      "No se encontro archivo CSV dentro del ZIP descargado.",
      "i" = "Verifica que la URL del INEI es accesible y el archivo es valido."
    ))
  }

  # Leer con readr, adivinando el separador (INEI usa ; o ,)
  datos <- tryCatch(
    readr::read_csv2(archivos_csv[1], show_col_types = FALSE, locale = readr::locale(encoding = "latin1")),
    error = function(e) {
      readr::read_csv(archivos_csv[1], show_col_types = FALSE, locale = readr::locale(encoding = "latin1"))
    }
  )

  datos
}
