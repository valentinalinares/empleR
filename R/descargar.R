#' Descargar microdatos de la EPEN desde el portal del INEI
#'
#' Descarga el modulo de Empleo e Ingresos de la Encuesta Permanente de Empleo
#' Nacional (EPEN) directamente desde el portal de microdatos del INEI
#' (\url{https://proyectos.inei.gob.pe/microdatos/}). Soporta cache local para
#' evitar descargas repetidas.
#'
#' @param year Ano de la encuesta. Los anos disponibles dependen de la
#'   variante; ver [catalogo()] para la lista actual.
#' @param variante Variante de la encuesta:
#'   - `"departamentos_anual"` (por defecto): EPEN nacional anual.
#'   - `"lima_movil"`: EPEN Lima Metropolitana, trimestres moviles.
#' @param periodo Para `variante = "lima_movil"`, el periodo a descargar.
#'   Usar el label exacto del catalogo, e.g. `"Trimestre Movil -(Ene-Feb-Mar)"`.
#'   Ver [catalogo()] para la lista completa de periodos disponibles.
#' @param destfile Ruta local donde cachear el resultado como `.rds`.
#'   Si el archivo ya existe, se usa la version en cache solamente cuando
#'   corresponde a la misma encuesta, variante, ano, periodo y URL. Los caches
#'   creados por versiones anteriores, que no guardaban esta informacion, no
#'   se reutilizan automaticamente.
#'   Si es `NULL` (por defecto), descarga sin guardar cache permanente.
#' @param quiet Logico. Si `TRUE` (por defecto), suprime mensajes de progreso.
#'
#' @return Un `data.frame` con los microdatos crudos del modulo de Empleo e
#'   Ingresos de la EPEN. Las columnas siguen la nomenclatura original del
#'   INEI (e.g. `C308_COD`, `FAC300_ANUAL`, `ESTRATO`, `CONGLOMERADO`). Para
#'   conservar codigos y ceros iniciales, todas las columnas se leen como
#'   texto; los campos vacios y el texto `NA` se devuelven como valores
#'   faltantes.
#'   Usar [etiquetar()] para aplicar etiquetas de valor y [cno()] para
#'   agregar descripciones de ocupaciones.
#'
#'   **A diferencia de [muestra_epen_2024], estos datos incluyen todos los
#'   estados laborales**: ocupados, desocupados abiertos, desocupados ocultos
#'   e inactivos. La variable `OCUP300` (o equivalente) indica el estado laboral
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

  # Buscar URL en el catalogo interno
  url <- .buscar_url(year = year, variante = variante, periodo = periodo)
  solicitud <- .solicitud_cache(
    year = year,
    variante = variante,
    periodo = periodo,
    url = url
  )

  if (!is.null(destfile) && file.exists(destfile)) {
    datos <- .leer_cache(destfile, solicitud)
    if (!quiet) {
      cli::cli_inform(c("v" = "Cargando desde cache: {.path {destfile}}"))
    }
    return(datos)
  }

  if (!quiet) {
    cli::cli_inform(c(
      "i" = "Descargando EPEN {year} / {variante}{ifelse(!is.null(periodo), paste0(' / ', periodo), '')}..."
    ))
  }

  # Descargar ZIP a archivo temporal
  tmp_zip <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp_zip, force = TRUE), add = TRUE)
  .descargar_archivo(url, destfile = tmp_zip, quiet = quiet)

  if (!file.exists(tmp_zip) || file.info(tmp_zip)$size == 0) {
    cli::cli_abort("La descarga no produjo un archivo ZIP utilizable.")
  }

  # Descomprimir y leer el CSV dentro del ZIP
  datos <- .leer_zip_inei(tmp_zip)

  if (!quiet) {
    cli::cli_inform(c(
      "v" = "Descargado: {nrow(datos)} filas x {ncol(datos)} columnas."
    ))
  }

  # Guardar cache si se especifico destfile
  if (!is.null(destfile)) {
    .guardar_cache(datos, destfile, solicitud)
    if (!quiet) {
      cli::cli_inform(c("v" = "Guardado en cache: {.path {destfile}}"))
    }
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
    if (!is.null(periodo)) {
      cli::cli_abort(
        "El argumento {.arg periodo} solo se usa con {.val lima_movil}."
      )
    }
    sub <- sub[grepl("Anual", sub$period, ignore.case = TRUE), ]
  }

  # Para lima_movil: el usuario debe especificar el periodo
  if (variante == "lima_movil") {
    if (is.null(periodo)) {
      cli::cli_abort(c(
        "Para {.val lima_movil} debes especificar el argumento {.arg periodo}.",
        "i" = paste0(
          "Usa {.code catalogo(fuente='EPEN', variante='lima_movil', year={year})} ",
          "para ver los periodos disponibles."
        )
      ))
    }
    # Busqueda flexible del periodo (sin acentos, case-insensitive)
    sub <- sub[.normalizar(sub$period) == .normalizar(periodo), ]
    if (nrow(sub) == 0) {
      cli::cli_abort(c(
        "Periodo '{periodo}' no encontrado para EPEN {year} / {variante}.",
        "i" = paste0(
          "Usa {.code catalogo(fuente='EPEN', variante='lima_movil', year={year})} ",
          "para ver los periodos exactos."
        )
      ))
    }
  }

  if (nrow(sub) != 1 || is.na(sub$url[1]) || !nzchar(sub$url[1])) {
    cli::cli_abort(c(
      "No se pudo identificar una URL unica para EPEN {year} / {variante}.",
      "i" = "Se encontraron {nrow(sub)} registros compatibles en el catalogo."
    ))
  }

  sub$url[[1]]
}

#' @noRd
.normalizar <- function(x) {
  x <- tolower(trimws(x))
  # Eliminar acentos
  x <- iconv(x, to = "ASCII//TRANSLIT")
  gsub("[^a-z0-9]", "", x)
}

#' @noRd
.solicitud_cache <- function(year, variante, periodo, url) {
  list(
    year = as.integer(year),
    variante = as.character(variante),
    periodo = if (is.null(periodo)) NULL else .normalizar(periodo),
    url = as.character(url)
  )
}

#' @noRd
.leer_cache <- function(path, solicitud) {
  cache <- tryCatch(
    readRDS(path),
    error = function(e) {
      cli::cli_abort(
        c("No se pudo leer el cache {.path {path}}.",
          "i" = "Elige otra ruta o retira el archivo danado."),
        parent = e
      )
    }
  )

  es_cache_actual <- is.list(cache) &&
    identical(cache$format, "empleR_descargar_cache") &&
    identical(cache$version, 1L) &&
    !is.null(cache$solicitud) &&
    !is.null(cache$datos)

  if (!es_cache_actual) {
    cli::cli_abort(c(
      "El archivo {.path {path}} no contiene metadatos de cache compatibles.",
      "i" = paste0(
        "Fue creado por una version anterior o no pertenece a {.pkg empleR}. ",
        "Elige otra ruta o retira ese archivo para volver a descargar."
      )
    ))
  }

  if (!identical(cache$solicitud, solicitud)) {
    cli::cli_abort(c(
      "El cache {.path {path}} corresponde a otra descarga.",
      "i" = paste0(
        "No se reutilizo para evitar mezclar anos, variantes, periodos o URLs. ",
        "Elige otra ruta de cache."
      )
    ))
  }

  cache$datos
}

#' @noRd
.guardar_cache <- function(datos, path, solicitud) {
  dir_destino <- dirname(path)
  if (!dir.exists(dir_destino)) {
    ok <- dir.create(dir_destino, recursive = TRUE, showWarnings = FALSE)
    if (!ok && !dir.exists(dir_destino)) {
      cli::cli_abort("No se pudo crear la carpeta de cache {.path {dir_destino}}.")
    }
  }

  cache <- list(
    format = "empleR_descargar_cache",
    version = 1L,
    solicitud = solicitud,
    datos = datos
  )
  saveRDS(cache, file = path)
  invisible(path)
}

#' @noRd
.descargar_archivo <- function(url, destfile, quiet) {
  estado <- tryCatch(
    utils::download.file(
      url,
      destfile = destfile,
      mode = "wb",
      quiet = quiet
    ),
    error = function(e) {
      cli::cli_abort("No se pudo descargar {.url {url}}.", parent = e)
    }
  )

  if (!identical(estado, 0L)) {
    cli::cli_abort("La descarga de {.url {url}} termino con estado {estado}.")
  }

  invisible(destfile)
}

#' @noRd
.leer_zip_inei <- function(path_zip) {
  contenido <- tryCatch(
    suppressWarnings(utils::unzip(path_zip, list = TRUE)),
    error = function(e) {
      cli::cli_abort("El archivo descargado no es un ZIP valido.", parent = e)
    }
  )
  nombres_csv <- contenido$Name[grepl("\\.csv$", contenido$Name,
                                      ignore.case = TRUE)]

  if (length(nombres_csv) == 0) {
    cli::cli_abort(c(
      "No se encontro archivo CSV dentro del ZIP descargado.",
      "i" = "Verifica que la URL del INEI es accesible y el archivo es valido."
    ))
  }

  if (length(nombres_csv) > 1) {
    cli::cli_abort(c(
      "El ZIP contiene mas de un archivo CSV y no se puede elegir sin ambiguedad.",
      "i" = "Archivos encontrados: {paste(nombres_csv, collapse = ', ')}"
    ))
  }

  nombre_csv <- nombres_csv[[1]]
  nombre_normalizado <- gsub("\\\\", "/", nombre_csv)
  if (grepl("(^|/)\\.\\.(/|$)", nombre_normalizado) ||
        grepl("^(/|[A-Za-z]:)", nombre_normalizado)) {
    cli::cli_abort("El ZIP contiene una ruta de archivo no segura.")
  }

  # Se lee el archivo directamente desde el ZIP. En Windows, algunos ZIP del
  # INEI codifican de forma distinta los acentos del nombre interno (por
  # ejemplo, "Publicacion"). Extraerlo y volver a localizarlo por su ruta
  # puede fallar aunque el contenido sea valido; la conexion unz() evita esa
  # conversion del nombre.
  abrir_csv <- function() {
    tryCatch(
      unz(path_zip, nombre_csv, open = "rb"),
      error = function(e) {
        cli::cli_abort("No se pudo abrir el CSV dentro del ZIP.", parent = e)
      }
    )
  }

  # Detectar el separador (INEI usa ; o ,) contando en la cabecera.
  # read_csv2 no falla con archivos separados por coma: los lee como una sola
  # columna, por eso no sirve como fallback con tryCatch.
  leer_cabecera <- function() {
    conexion <- abrir_csv()
    on.exit(close(conexion), add = TRUE)
    readLines(conexion, n = 1, warn = FALSE, encoding = "latin1")
  }
  cabecera <- leer_cabecera()
  n_pyc  <- lengths(regmatches(cabecera, gregexpr(";", cabecera, fixed = TRUE)))
  n_coma <- lengths(regmatches(cabecera, gregexpr(",", cabecera, fixed = TRUE)))
  delim  <- if (n_pyc >= n_coma) ";" else ","

  # Los microdatos crudos se leen como texto. Esto evita que el muestreo usado
  # para inferir tipos convierta valores validos en NA y conserva ceros a la
  # izquierda en los identificadores.
  leer_datos <- function() {
    conexion <- abrir_csv()
    on.exit(close(conexion), add = TRUE)
    readr::read_delim(
      conexion,
      delim = delim,
      col_types = readr::cols(.default = readr::col_character()),
      na = c("", "NA"),
      trim_ws = FALSE,
      show_col_types = FALSE,
      progress = FALSE,
      name_repair = "minimal",
      locale = readr::locale(encoding = "latin1")
    )
  }
  datos <- leer_datos()

  problemas <- readr::problems(datos)
  if (nrow(problemas) > 0) {
    cli::cli_abort(c(
      "El CSV presenta {nrow(problemas)} problema(s) de lectura.",
      "i" = "No se devolvieron datos para evitar una importacion incompleta."
    ))
  }

  if (anyDuplicated(names(datos))) {
    duplicados <- unique(names(datos)[duplicated(names(datos))])
    cli::cli_abort(
      "El CSV contiene nombres de columna duplicados: {paste(duplicados, collapse = ', ')}."
    )
  }

  datos
}
