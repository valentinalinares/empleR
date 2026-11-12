#!/usr/bin/env Rscript

# Contrasta especificaciones del diseño EPEN anual con los CV publicados para
# el ingreso promedio proveniente del trabajo. No modifica los microdatos.

suppressPackageStartupMessages({
  library(data.table)
  library(survey)
})

options(survey.lonely.psu = "adjust")

raw_root <- Sys.getenv(
  "EMPLER_EPEN_RAW_ROOT",
  unset = file.path(
    "C:/Users/VALENTINALINARES/Downloads/ROpenSci/data/raw/inei_data_core",
    "epen_departamentos"
  )
)
zip_path <- file.path(raw_root, "2024", "156", "csv", "935-Modulo76.zip")

if (!file.exists(zip_path)) {
  stop("No se encontró el ZIP EPEN departamental anual 2024.")
}

archivo <- unzip(zip_path, list = TRUE)$Name[[1]]
directorio_temporal <- tempfile("empleR-epen-anual-")
dir.create(directorio_temporal)
on.exit(unlink(directorio_temporal, recursive = TRUE, force = TRUE), add = TRUE)
csv_path <- unzip(zip_path, files = archivo, exdir = directorio_temporal)

columnas <- c(
  "MES", "MUESTRA", "CCDD", "AREA", "CONGLOMERADO", "ESTRATO",
  "C207", "C208", "OCUP300", "ingtrabw", "FAC300_ANUAL"
)
datos <- fread(
  csv_path,
  select = columnas,
  colClasses = "character",
  na.strings = c("", "NA"),
  showProgress = FALSE
)

numero <- function(x) suppressWarnings(as.numeric(x))
for (variable in c("C207", "C208", "OCUP300", "ingtrabw", "FAC300_ANUAL")) {
  datos[[variable]] <- numero(datos[[variable]])
}

datos <- datos[
  OCUP300 == 1 & is.finite(FAC300_ANUAL) & FAC300_ANUAL > 0
]
datos[, ingreso_valido := is.finite(ingtrabw) & ingtrabw > 0]
datos[, upm_mrc := interaction(
  MUESTRA, CCDD, CONGLOMERADO, drop = TRUE, lex.order = TRUE
)]
datos[, upm_mes_mrc := interaction(
  MES, MUESTRA, CCDD, CONGLOMERADO, drop = TRUE, lex.order = TRUE
)]
datos[, estrato_geografico := interaction(
  CCDD, ESTRATO, drop = TRUE, lex.order = TRUE
)]
datos[, estrato_muestra := interaction(
  MUESTRA, CCDD, ESTRATO, drop = TRUE, lex.order = TRUE
)]
datos[, estrato_mes := interaction(
  MES, MUESTRA, CCDD, ESTRATO, drop = TRUE, lex.order = TRUE
)]

oficial <- data.frame(
  dominio = c(
    "total", "hombre", "mujer", "edad_14_24", "edad_25_44",
    "edad_45_mas", "urbana", "rural"
  ),
  estimado_oficial = c(
    1765.9, 1965.7, 1494.0, 1153.6, 1911.0, 1763.7, 1927.6, 915.1
  ),
  cv_oficial = c(0.7, 0.8, 1.0, 0.9, 0.9, 1.1, 0.8, 1.6),
  stringsAsFactors = FALSE
)

crear_diseno <- function(especificacion) {
  switch(especificacion,
    srs = svydesign(ids = ~1, weights = ~FAC300_ANUAL, data = datos),
    upm_compuesta = svydesign(
      ids = ~upm_mrc, weights = ~FAC300_ANUAL, data = datos
    ),
    upm_por_mes = svydesign(
      ids = ~upm_mes_mrc, weights = ~FAC300_ANUAL, data = datos
    ),
    actual_paquete = svydesign(
      ids = ~upm_mrc, strata = ~ESTRATO, weights = ~FAC300_ANUAL,
      data = datos, nest = TRUE
    ),
    estrato_departamento = svydesign(
      ids = ~upm_mrc, strata = ~estrato_geografico,
      weights = ~FAC300_ANUAL, data = datos, nest = TRUE
    ),
    estrato_muestra_departamento = svydesign(
      ids = ~upm_mrc, strata = ~estrato_muestra,
      weights = ~FAC300_ANUAL, data = datos, nest = TRUE
    ),
    estrato_mes_muestra_departamento = svydesign(
      ids = ~upm_mes_mrc, strata = ~estrato_mes,
      weights = ~FAC300_ANUAL, data = datos, nest = TRUE
    )
  )
}

filtrar_dominio <- function(diseno, dominio) {
  switch(dominio,
    total = diseno,
    hombre = subset(diseno, C207 == 1),
    mujer = subset(diseno, C207 == 2),
    edad_14_24 = subset(diseno, C208 >= 14 & C208 <= 24),
    edad_25_44 = subset(diseno, C208 >= 25 & C208 <= 44),
    edad_45_mas = subset(diseno, C208 >= 45),
    urbana = subset(diseno, AREA == "1"),
    rural = subset(diseno, AREA == "2")
  )
}

estimar <- function(diseno, dominio) {
  diseno <- filtrar_dominio(diseno, dominio)
  diseno <- subset(diseno, ingreso_valido)
  ajuste <- svymean(~ingtrabw, diseno, na.rm = TRUE, deff = "replace")
  estimado <- as.numeric(coef(ajuste))
  error <- as.numeric(SE(ajuste))
  data.frame(
    estimado = estimado,
    error_std = error,
    cv = 100 * error / estimado,
    deff = as.numeric(deff(ajuste))
  )
}

especificaciones <- c(
  "srs",
  "upm_compuesta",
  "upm_por_mes",
  "actual_paquete",
  "estrato_departamento",
  "estrato_muestra_departamento",
  "estrato_mes_muestra_departamento"
)

resultados <- do.call(rbind, lapply(especificaciones, function(especificacion) {
  diseno <- crear_diseno(especificacion)
  do.call(rbind, lapply(oficial$dominio, function(dominio) {
    cbind(
      especificacion = especificacion,
      dominio = dominio,
      estimar(diseno, dominio),
      stringsAsFactors = FALSE
    )
  }))
}))
rownames(resultados) <- NULL
resultados <- merge(resultados, oficial, by = "dominio", sort = FALSE)
resultados$diferencia_estimado <- resultados$estimado - resultados$estimado_oficial
resultados$diferencia_cv <- resultados$cv - resultados$cv_oficial

resumen <- aggregate(
  cbind(
    abs_dif_estimado = abs(resultados$diferencia_estimado),
    abs_dif_cv = abs(resultados$diferencia_cv)
  ),
  by = list(especificacion = resultados$especificacion),
  FUN = mean
)

conteo_upm_mes <- unique(datos[, .(MES, upm_mrc)])[, .N, by = upm_mrc]
conteo_upm_estrato <- unique(datos[, .(ESTRATO, upm_mrc)])[
  , .N, by = ESTRATO
]
diagnostico <- data.frame(
  year = 2024L,
  md5_zip = unname(tools::md5sum(zip_path)),
  n_ocupados_peso_valido = nrow(datos),
  n_ingreso_valido = sum(datos$ingreso_valido),
  n_upm_compuestas = uniqueN(datos$upm_mrc),
  n_upm_mes = uniqueN(datos$upm_mes_mrc),
  n_upm_en_mas_de_un_mes = sum(conteo_upm_mes$N > 1),
  n_estrato_faltante = sum(is.na(datos$ESTRATO)),
  n_estratos_publicados = uniqueN(datos$ESTRATO),
  n_estratos_solitarios = sum(conteo_upm_estrato$N == 1L),
  n_estratos_geograficos = uniqueN(datos$estrato_geografico),
  stringsAsFactors = FALSE
)

cat("Diagnóstico de la base anual:\n")
print(diagnostico, row.names = FALSE)
cat("\nDiferencias absolutas medias frente a ocho celdas oficiales:\n")
print(resumen[order(resumen$abs_dif_cv), ], row.names = FALSE, digits = 6)
cat("\nResultados nacionales:\n")
print(resultados[resultados$dominio == "total", ], row.names = FALSE, digits = 7)

dir.create("data-raw/validation", recursive = TRUE, showWarnings = FALSE)
write.csv(
  resultados,
  "data-raw/validation/2026-11-12_diseno_epen_anual_2024.csv",
  row.names = FALSE, na = ""
)
write.csv(
  resumen,
  "data-raw/validation/2026-11-12_diseno_epen_anual_resumen.csv",
  row.names = FALSE, na = ""
)
write.csv(
  diagnostico,
  "data-raw/validation/2026-11-12_diseno_epen_anual_diagnostico.csv",
  row.names = FALSE, na = ""
)
