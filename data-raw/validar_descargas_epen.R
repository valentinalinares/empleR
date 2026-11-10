# Validacion estructural de los ZIP anuales de la EPEN --------------------
#
# Uso:
# Rscript data-raw/validar_descargas_epen.R RUTA_A_EPEN_DEPARTAMENTOS [SALIDA_CSV]
#
# La ruta debe contener los ZIP oficiales organizados en subcarpetas por ano.
# La validacion compara la lectura de empleR con una segunda lectura mediante
# funciones de base R para identificadores y columnas que anteriormente se
# perdian por la inferencia automatica de tipos.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Indica la carpeta que contiene los ZIP anuales de la EPEN.")
}

raw_root <- normalizePath(args[[1]], mustWork = TRUE)
output_csv <- if (length(args) >= 2) args[[2]] else NULL

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Se necesita el paquete pkgload para ejecutar la validacion.")
}
if (!requireNamespace("readr", quietly = TRUE)) {
  stop("Se necesita el paquete readr para ejecutar la validacion.")
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Se necesita el paquete digest para calcular las huellas SHA-256.")
}

pkgload::load_all(".", quiet = TRUE)

zips <- list.files(
  raw_root,
  pattern = "[.]zip$",
  recursive = TRUE,
  full.names = TRUE
)
if (length(zips) == 0) {
  stop("No se encontraron archivos ZIP en la ruta indicada.")
}

columnas_control <- c(
  "CONGLOMERADO", "SELVIV", "HOGAR",
  "C347_T", "C362_7", "C362_8", "D347_T"
)

extraer_csv <- function(path_zip) {
  contenido <- utils::unzip(path_zip, list = TRUE)
  csv <- contenido$Name[grepl("[.]csv$", contenido$Name, ignore.case = TRUE)]
  if (length(csv) != 1) {
    stop("Se esperaba un solo CSV en ", basename(path_zip), ".")
  }
  dir_tmp <- tempfile("validar_epen_")
  dir.create(dir_tmp)
  path_csv <- utils::unzip(path_zip, files = csv, exdir = dir_tmp)
  list(path = path_csv, dir = dir_tmp, member = csv)
}

detectar_delim <- function(path_csv) {
  header <- readLines(path_csv, n = 1, warn = FALSE, encoding = "latin1")
  semicolon <- lengths(regmatches(header, gregexpr(";", header, fixed = TRUE)))
  comma <- lengths(regmatches(header, gregexpr(",", header, fixed = TRUE)))
  if (semicolon >= comma) ";" else ","
}

leer_control_base <- function(path_csv, delim, columnas) {
  header <- readLines(path_csv, n = 1, warn = FALSE, encoding = "latin1")
  nombres <- strsplit(header, delim, fixed = TRUE)[[1]]
  nombres <- sub('^"', "", sub('"$', "", nombres))
  clases <- ifelse(nombres %in% columnas, "character", "NULL")

  utils::read.table(
    path_csv,
    header = TRUE,
    sep = delim,
    quote = '"',
    comment.char = "",
    colClasses = clases,
    na.strings = c("", "NA"),
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "latin1"
  )
}

resultados <- list()
controles <- list()

for (i in seq_along(zips)) {
  path_zip <- zips[[i]]
  year_match <- regmatches(
    path_zip,
    regexpr("(?<![0-9])20(22|23|24|25)(?![0-9])", path_zip, perl = TRUE)
  )
  year <- if (length(year_match) == 0 || !nzchar(year_match)) NA else year_match

  extracted <- extraer_csv(path_zip)
  on.exit(unlink(extracted$dir, recursive = TRUE, force = TRUE), add = TRUE)
  delim <- detectar_delim(extracted$path)
  field_counts <- utils::count.fields(
    extracted$path,
    sep = delim,
    quote = '"',
    comment.char = "",
    blank.lines.skip = FALSE
  )

  elapsed <- system.time(datos <- .leer_zip_inei(path_zip))[["elapsed"]]
  seleccion <- intersect(columnas_control, names(datos))
  control_base <- leer_control_base(extracted$path, delim, seleccion)

  igualdad <- vapply(
    seleccion,
    function(variable) identical(datos[[variable]], control_base[[variable]]),
    logical(1)
  )

  resultados[[i]] <- data.frame(
    year = as.integer(year),
    zip = basename(path_zip),
    zip_member = extracted$member,
    sha256 = digest::digest(file = path_zip, algo = "sha256"),
    rows = nrow(datos),
    columns = ncol(datos),
    parse_problems = nrow(readr::problems(datos)),
    all_columns_character = all(vapply(datos, is.character, logical(1))),
    structural_rows_match = length(field_counts) == nrow(datos) + 1L,
    fields_per_row_match = all(field_counts == ncol(datos)),
    control_columns_match = all(igualdad),
    elapsed_seconds = unname(elapsed),
    stringsAsFactors = FALSE
  )

  if (length(seleccion) > 0) {
    controles[[i]] <- data.frame(
      year = as.integer(year),
      variable = seleccion,
      non_missing = vapply(datos[seleccion], function(x) sum(!is.na(x)), integer(1)),
      leading_zero = vapply(
        datos[seleccion],
        function(x) sum(grepl("^0", x), na.rm = TRUE),
        integer(1)
      ),
      matches_base_reader = unname(igualdad),
      stringsAsFactors = FALSE
    )
  }

  unlink(extracted$dir, recursive = TRUE, force = TRUE)
  rm(datos, control_base)
  invisible(gc())
}

resumen <- do.call(rbind, resultados)
control_detalle <- do.call(rbind, controles)

print(resumen, row.names = FALSE)
if (!is.null(control_detalle)) {
  cat("\nColumnas de control:\n")
  print(control_detalle, row.names = FALSE)
}

fallo <- !resumen$all_columns_character |
  !resumen$structural_rows_match |
  !resumen$fields_per_row_match |
  !resumen$control_columns_match |
  resumen$parse_problems != 0

if (!is.null(output_csv)) {
  dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(resumen, output_csv, row.names = FALSE, na = "")
  if (!is.null(control_detalle)) {
    detalle_path <- sub("[.]csv$", "_columnas.csv", output_csv, ignore.case = TRUE)
    utils::write.csv(control_detalle, detalle_path, row.names = FALSE, na = "")
  }
}

if (any(fallo)) {
  stop("Una o mas validaciones de integridad fallaron.")
}
