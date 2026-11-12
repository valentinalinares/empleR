# Valida los estimadores puntuales de indicadores() contra los microdatos
# oficiales EPEN 2022-2025 y contra cifras publicadas por el INEI.
#
# Ejecutar desde la raiz del paquete. La ruta por defecto supone que los ZIP
# oficiales estan en ../data/raw; puede cambiarse con EMPLER_EPEN_RAW_ROOT.

suppressPackageStartupMessages({
  library(readr)
})

pkgload::load_all(".", quiet = TRUE)

raw_root <- Sys.getenv(
  "EMPLER_EPEN_RAW_ROOT",
  unset = file.path(
    "..", "data", "raw", "inei_data_core", "epen_departamentos"
  )
)
output_path <- file.path(
  "data-raw", "validation", "2026-11-12_indicadores_epen.csv"
)

archivos <- c(
  `2022` = "790-Modulo76.zip",
  `2023` = "874-Modulo76.zip",
  `2024` = "935-Modulo76.zip",
  `2025` = "1001-Modulo76.zip"
)
ingreso_oficial <- c(`2022` = 1524.0, `2023` = 1674.4,
                     `2024` = 1765.9, `2025` = 1887.2)
ocupados_oficial <- c(`2022` = 17336500, `2023` = 17179800,
                      `2024` = 17322900, `2025` = 17575200)

leer_zip <- function(path) {
  requeridas <- c(
    "MUESTRA", "CCDD", "CONGLOMERADO", "ESTRATO", "OCUP300",
    "FAC300_ANUAL", "FAC_T300", "ingtrabw", "whoraT"
  )
  datos <- .leer_zip_inei(path)
  datos[, intersect(requeridas, names(datos)), drop = FALSE]
}

media_ponderada <- function(x, w, positivo = FALSE) {
  x <- suppressWarnings(as.numeric(x))
  w <- suppressWarnings(as.numeric(w))
  usar <- is.finite(x) & is.finite(w) & w > 0
  if (positivo) usar <- usar & x > 0
  sum(x[usar] * w[usar]) / sum(w[usar])
}

mediana_ponderada_math <- function(x, w) {
  x <- suppressWarnings(as.numeric(x))
  w <- suppressWarnings(as.numeric(w))
  usar <- is.finite(x) & is.finite(w) & x > 0 & w > 0
  x <- x[usar]
  w <- w[usar]
  orden <- order(x)
  x <- x[orden]
  w <- w[orden]
  x[which(cumsum(w) / sum(w) >= 0.5)[1]]
}

resultados <- lapply(names(archivos), function(year) {
  zip_path <- file.path(raw_root, year, "156", "csv", archivos[[year]])
  if (!file.exists(zip_path)) {
    stop("No se encontro el ZIP oficial: ", zip_path, call. = FALSE)
  }
  datos <- leer_zip(zip_path)
  estado <- trimws(datos$OCUP300)
  ocupados <- !is.na(estado) & estado == "1"
  base_ocupada <- datos[ocupados, , drop = FALSE]
  peso <- suppressWarnings(as.numeric(base_ocupada$FAC300_ANUAL))
  peso_valido <- is.finite(peso) & peso > 0

  ingreso <- suppressWarnings(suppressMessages(indicadores(
    datos,
    "ingreso_promedio",
    var_peso = "FAC300_ANUAL"
  )))
  mediana <- suppressWarnings(suppressMessages(indicadores(
    datos,
    "ingreso_mediano",
    var_peso = "FAC300_ANUAL"
  )))
  horas <- suppressWarnings(suppressMessages(indicadores(
    datos,
    "horas_promedio",
    var_peso = "FAC300_ANUAL"
  )))

  data.frame(
    year = as.integer(year),
    md5_zip = unname(tools::md5sum(zip_path)),
    n_filas = nrow(datos),
    n_ocupados = nrow(base_ocupada),
    n_ocupados_peso_ausente = sum(!is.finite(peso)),
    n_ocupados_peso_no_positivo = sum(is.finite(peso) & peso <= 0),
    n_estrato_ausente_peso_valido = sum(
      peso_valido & (
        is.na(base_ocupada$ESTRATO) |
          trimws(base_ocupada$ESTRATO) == ""
      )
    ),
    poblacion_factor = sum(peso[is.finite(peso) & peso > 0]),
    poblacion_oficial = ocupados_oficial[[year]],
    diferencia_poblacion = sum(peso[is.finite(peso) & peso > 0]) -
      ocupados_oficial[[year]],
    ingreso_paquete = ingreso$estimado,
    ingreso_directo = media_ponderada(
      base_ocupada$ingtrabw, base_ocupada$FAC300_ANUAL, positivo = TRUE
    ),
    ingreso_oficial = ingreso_oficial[[year]],
    diferencia_ingreso_oficial = ingreso$estimado - ingreso_oficial[[year]],
    mediana_paquete = mediana$estimado,
    mediana_directa = mediana_ponderada_math(
      base_ocupada$ingtrabw, base_ocupada$FAC300_ANUAL
    ),
    horas_paquete = horas$estimado,
    horas_directas = media_ponderada(
      base_ocupada$whoraT, base_ocupada$FAC300_ANUAL
    ),
    n_ingreso_estimacion = ingreso$n_estimacion,
    n_ingreso_cero = ingreso$n_fuera_definicion,
    n_horas_estimacion = horas$n_estimacion
  )
})

resultados <- do.call(rbind, resultados)

stopifnot(
  max(abs(resultados$ingreso_paquete - resultados$ingreso_directo)) < 1e-8,
  max(abs(resultados$mediana_paquete - resultados$mediana_directa)) < 1e-8,
  max(abs(resultados$horas_paquete - resultados$horas_directas)) < 1e-8,
  max(abs(resultados$diferencia_ingreso_oficial)) <= 0.05,
  max(abs(resultados$diferencia_poblacion)) < 100
)

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(resultados, output_path, na = "")
message("Validacion guardada en ", output_path)
