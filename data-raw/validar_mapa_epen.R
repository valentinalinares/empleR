# Valida mapa() contra los ZIP oficiales anuales de la EPEN.
#
# Uso desde la raiz del paquete:
# Rscript data-raw/validar_mapa_epen.R RUTA_EPEN_DEPARTAMENTOS [SALIDA_CSV]
#
# La validacion no deriva la geografia esperada de R/mapa.R. Usa como
# referencia independiente el catalogo oficial versionado en
# data-raw/validation/epen_ambitos_departamentales_oficiales.csv y contrasta
# con CCDD y DIVISION_LIMA de cada ZIP.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) {
  stop("Indica la carpeta que contiene los ZIP anuales de la EPEN.", call. = FALSE)
}

raw_root <- normalizePath(args[[1]], mustWork = TRUE)
output_csv <- if (length(args) >= 2L) {
  args[[2]]
} else {
  file.path(
    "data-raw", "validation", "2026-11-11_mapa_epen_ambitos.csv"
  )
}
catalogo_path <- file.path(
  "data-raw", "validation", "epen_ambitos_departamentales_oficiales.csv"
)

pkgload::load_all(".", quiet = TRUE)

catalogo <- utils::read.csv(
  catalogo_path,
  colClasses = "character",
  check.names = FALSE,
  fileEncoding = "UTF-8"
)
if (nrow(catalogo) != 25L || anyDuplicated(catalogo$geo_id)) {
  stop("El catalogo oficial debe contener 25 geo_id unicos.", call. = FALSE)
}

zips <- list.files(
  raw_root,
  pattern = "[.]zip$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
if (length(zips) == 0L) {
  stop("No se encontraron ZIP en: ", raw_root, call. = FALSE)
}

anio_de <- function(path) {
  partes <- strsplit(
    normalizePath(path, winslash = "/"),
    "/",
    fixed = TRUE
  )[[1]]
  candidatos <- partes[grepl("^20[0-9]{2}$", partes)]
  if (length(candidatos) != 1L) {
    stop("No se pudo identificar un solo ano en: ", path, call. = FALSE)
  }
  as.integer(candidatos)
}

geo_id_original <- function(ccdd, division_lima) {
  ccdd_chr <- trimws(as.character(ccdd))
  division_chr <- trimws(as.character(division_lima))
  ccdd_num <- suppressWarnings(as.integer(ccdd_chr))
  invalido <- is.na(ccdd_num) | ccdd_num < 1L | ccdd_num > 25L
  if (any(invalido)) {
    stop("CCDD contiene valores invalidos en los ZIP oficiales.", call. = FALSE)
  }
  codigo <- sprintf("%02d", ccdd_num)

  falta_lima <- codigo == "15" & !division_chr %in% c("1", "2")
  sobra_lima <- codigo != "15" & !is.na(division_chr) & division_chr != ""
  if (any(falta_lima)) {
    stop("Hay filas CCDD 15 sin DIVISION_LIMA 1 o 2.", call. = FALSE)
  }
  if (any(sobra_lima)) {
    stop("Hay DIVISION_LIMA fuera de CCDD 15.", call. = FALSE)
  }

  ifelse(codigo == "15", paste0("15-", division_chr), codigo)
}

extraer_etiquetas <- function(leaflet, n) {
  llamadas <- Filter(
    function(x) identical(x$method, "addPolygons"),
    leaflet$x$calls
  )
  if (length(llamadas) != 1L) {
    stop("No se encontro una sola llamada addPolygons.", call. = FALSE)
  }
  etiquetas <- Find(
    function(x) is.character(x) && length(x) == n,
    llamadas[[1]]$args
  )
  if (is.null(etiquetas)) {
    stop("No se pudieron extraer las etiquetas de leaflet.", call. = FALSE)
  }
  etiquetas
}

capturar_avisos <- function(expr) {
  avisos <- character()
  valor <- withCallingHandlers(
    expr,
    warning = function(w) {
      avisos <<- c(avisos, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(valor = valor, avisos = avisos)
}

detalle_anual <- list()
resumen_anual <- list()
orden <- order(vapply(zips, anio_de, integer(1)))

for (zip in zips[orden]) {
  anio <- anio_de(zip)
  datos <- .leer_zip_inei(zip)
  requeridas <- c("CCDD", "DIVISION_LIMA", "FAC300_ANUAL")
  faltantes <- setdiff(requeridas, names(datos))
  if (length(faltantes) > 0L) {
    stop(
      "Faltan columnas en ", basename(zip), ": ",
      paste(faltantes, collapse = ", "),
      call. = FALSE
    )
  }

  geo_id <- geo_id_original(datos$CCDD, datos$DIVISION_LIMA)
  observados <- sort(unique(geo_id))
  if (!setequal(observados, catalogo$geo_id)) {
    stop(
      "Los ambitos del ZIP ", basename(zip),
      " no coinciden con el catalogo oficial.",
      call. = FALSE
    )
  }

  peso <- suppressWarnings(as.numeric(datos$FAC300_ANUAL))
  n_obs <- table(factor(geo_id, levels = catalogo$geo_id))
  poblacion <- tapply(
    peso,
    factor(geo_id, levels = catalogo$geo_id),
    sum,
    na.rm = TRUE
  )
  tabla <- data.frame(
    CCDD = catalogo$CCDD,
    DIVISION_LIMA = catalogo$DIVISION_LIMA,
    n_obs = as.integer(n_obs),
    poblacion = as.numeric(poblacion),
    stringsAsFactors = FALSE
  )
  tabla$DIVISION_LIMA[tabla$DIVISION_LIMA == ""] <- NA_character_

  gg <- capturar_avisos(mapa(tabla, "n_obs", tipo = "ggplot"))
  lf <- capturar_avisos(mapa(tabla, "poblacion", tipo = "leaflet"))
  etiquetas <- extraer_etiquetas(lf$valor, nrow(catalogo))

  pos <- match(catalogo$geo_id, gg$valor$data$geo_id)
  obtenido_n <- gg$valor$data$n_obs[pos]
  esperado_etiqueta <- paste0(
    catalogo$ambito_epen,
    ": ",
    .formatear_valor_mapa(tabla$poblacion)
  )
  coincide <- obtenido_n == tabla$n_obs & etiquetas[pos] == esperado_etiqueta

  detalle_anual[[as.character(anio)]] <- data.frame(
    year = anio,
    geo_id = catalogo$geo_id,
    CCDD = catalogo$CCDD,
    DIVISION_LIMA = catalogo$DIVISION_LIMA,
    ambito_epen = catalogo$ambito_epen,
    n_obs_esperado = tabla$n_obs,
    n_obs_mapa = obtenido_n,
    poblacion_esperada = tabla$poblacion,
    etiqueta_leaflet = etiquetas[pos],
    coincide = coincide,
    stringsAsFactors = FALSE
  )
  resumen_anual[[as.character(anio)]] <- data.frame(
    year = anio,
    zip = basename(zip),
    filas = nrow(datos),
    ambitos_originales = length(observados),
    ambitos_mapa = nrow(gg$valor$data),
    filas_asignadas = sum(obtenido_n),
    poligonos_correctos = sum(coincide),
    avisos_ggplot = paste(gg$avisos, collapse = " | "),
    avisos_leaflet = paste(lf$avisos, collapse = " | "),
    stringsAsFactors = FALSE
  )

  rm(datos)
  gc(verbose = FALSE)
}

detalle <- do.call(rbind, detalle_anual)
resumen <- do.call(rbind, resumen_anual)
dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(
  detalle,
  output_csv,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
resumen_csv <- sub("[.]csv$", "_resumen.csv", output_csv)
utils::write.csv(
  resumen,
  resumen_csv,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

print(resumen[, c(
  "year", "filas", "ambitos_originales", "ambitos_mapa",
  "filas_asignadas", "poligonos_correctos"
)])

if (!all(detalle$coincide) ||
    any(resumen$filas_asignadas != resumen$filas) ||
    any(resumen$ambitos_originales != 25L) ||
    any(resumen$ambitos_mapa != 25L)) {
  stop("La validacion de los ambitos EPEN encontro diferencias.", call. = FALSE)
}

cat(
  "\nValidacion completa: 25 de 25 ambitos correctos en cada ano; ",
  "todas las filas fueron asignadas.\n",
  sep = ""
)
