# Validacion remota del catalogo de Lima movil ----------------------------
#
# Uso:
# Rscript data-raw/validar_lima_movil.R [SALIDA_CSV]
#
# Descarga secuencialmente cada ZIP registrado en el catalogo, valida su
# estructura con el lector de empleR y elimina el archivo temporal al terminar.

args <- commandArgs(trailingOnly = TRUE)
output_csv <- if (length(args) >= 1) args[[1]] else NULL

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

catalogo_lima <- url_catalog_epen[
  url_catalog_epen$variant == "lima_movil",
  c("year", "period", "url")
]
catalogo_lima <- catalogo_lima[order(catalogo_lima$year, catalogo_lima$period), ]

if (nrow(catalogo_lima) == 0) {
  stop("El catalogo no contiene registros de Lima movil.")
}
if (anyDuplicated(catalogo_lima[c("year", "period")])) {
  stop("El catalogo contiene solicitudes duplicadas de Lima movil.")
}

validar_estructura <- function(path_zip, datos) {
  contenido <- utils::unzip(path_zip, list = TRUE)
  csv <- contenido$Name[grepl("[.]csv$", contenido$Name, ignore.case = TRUE)]
  if (length(csv) != 1) {
    stop("Se esperaba un solo CSV dentro del ZIP.")
  }

  dir_tmp <- tempfile("validar_lima_")
  dir.create(dir_tmp)
  on.exit(unlink(dir_tmp, recursive = TRUE, force = TRUE), add = TRUE)
  path_csv <- utils::unzip(path_zip, files = csv, exdir = dir_tmp)
  header <- readLines(path_csv, n = 1, warn = FALSE, encoding = "latin1")
  semicolon <- lengths(regmatches(header, gregexpr(";", header, fixed = TRUE)))
  comma <- lengths(regmatches(header, gregexpr(",", header, fixed = TRUE)))
  delim <- if (semicolon >= comma) ";" else ","
  fields <- utils::count.fields(
    path_csv,
    sep = delim,
    quote = '"',
    comment.char = "",
    blank.lines.skip = FALSE
  )

  list(
    member = csv,
    structural_rows_match = length(fields) == nrow(datos) + 1L,
    fields_per_row_match = all(fields == ncol(datos))
  )
}

resultados <- vector("list", nrow(catalogo_lima))

for (i in seq_len(nrow(catalogo_lima))) {
  solicitud <- catalogo_lima[i, ]
  tmp_zip <- tempfile(fileext = ".zip")
  inicio <- proc.time()[["elapsed"]]

  resultado <- tryCatch({
    url_catalogo <- .buscar_url(
      solicitud$year,
      "lima_movil",
      solicitud$period
    )
    if (!identical(url_catalogo, solicitud$url)) {
      stop("La URL encontrada no coincide con el registro del catalogo.")
    }

    .descargar_archivo(solicitud$url, tmp_zip, quiet = TRUE)
    datos <- .leer_zip_inei(tmp_zip)
    estructura <- validar_estructura(tmp_zip, datos)

    data.frame(
      year = solicitud$year,
      period = solicitud$period,
      url = solicitud$url,
      zip = basename(solicitud$url),
      zip_member = estructura$member,
      sha256 = digest::digest(file = tmp_zip, algo = "sha256"),
      size_bytes = file.info(tmp_zip)$size,
      rows = nrow(datos),
      columns = ncol(datos),
      parse_problems = nrow(readr::problems(datos)),
      all_columns_character = all(vapply(datos, is.character, logical(1))),
      structural_rows_match = estructura$structural_rows_match,
      fields_per_row_match = estructura$fields_per_row_match,
      status = "ok",
      error = NA_character_,
      elapsed_seconds = proc.time()[["elapsed"]] - inicio,
      stringsAsFactors = FALSE
    )
  }, error = function(e) {
    data.frame(
      year = solicitud$year,
      period = solicitud$period,
      url = solicitud$url,
      zip = basename(solicitud$url),
      zip_member = NA_character_,
      sha256 = NA_character_,
      size_bytes = if (file.exists(tmp_zip)) file.info(tmp_zip)$size else NA_real_,
      rows = NA_integer_,
      columns = NA_integer_,
      parse_problems = NA_integer_,
      all_columns_character = NA,
      structural_rows_match = NA,
      fields_per_row_match = NA,
      status = "error",
      error = conditionMessage(e),
      elapsed_seconds = proc.time()[["elapsed"]] - inicio,
      stringsAsFactors = FALSE
    )
  })

  resultados[[i]] <- resultado
  unlink(tmp_zip, force = TRUE)
  message(
    sprintf(
      "[%d/%d] %s %s: %s",
      i,
      nrow(catalogo_lima),
      solicitud$year,
      solicitud$period,
      resultado$status
    )
  )
  invisible(gc())
}

resumen <- do.call(rbind, resultados)
print(resumen[c(
  "year", "period", "rows", "columns", "parse_problems",
  "structural_rows_match", "fields_per_row_match", "status", "error"
)], row.names = FALSE)

if (!is.null(output_csv)) {
  dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(resumen, output_csv, row.names = FALSE, na = "")
}

fallo <- resumen$status != "ok" |
  resumen$parse_problems != 0 |
  !resumen$all_columns_character |
  !resumen$structural_rows_match |
  !resumen$fields_per_row_match

if (any(fallo, na.rm = TRUE) || anyNA(fallo)) {
  stop("Una o mas descargas de Lima movil no superaron la validacion.")
}
