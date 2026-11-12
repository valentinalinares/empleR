#!/usr/bin/env Rscript

# Contraste reproducible del diseño muestral EPEN con errores publicados por
# el INEI. No modifica microdatos ni objetos del paquete.

suppressPackageStartupMessages(library(survey))

options(survey.lonely.psu = "adjust")

raiz <- Sys.getenv(
  "EMPLER_EPEN_LIMA_RAW_ROOT",
  unset = file.path(
    "C:/Users/VALENTINALINARES/Downloads/ROpenSci/data/raw/inei_data_core",
    "epen_lima"
  )
)

fuentes <- data.frame(
  year = c(2024L, 2025L),
  zip = file.path(
    raiz,
    c("2024/45/csv/929-Modulo76.zip", "2025/45/csv/995-Modulo76.zip")
  ),
  peso = c("fa_ond24", "fa_ond25"),
  stringsAsFactors = FALSE
)

if (any(!file.exists(fuentes$zip))) {
  stop("Faltan uno o más ZIP EPEN trimestrales requeridos.")
}

# Valores de los cuadros 1.13 de errores muestrales. El INEI redondea
# estimados y errores a un decimal, CV a dos y DEFF a cuatro.
oficial <- data.frame(
  year = rep(c(2024L, 2025L), each = 12),
  indicador = rep(rep(c("actividad", "ocupacion"), each = 6), 2),
  dominio = rep(c(
    "total", "hombre", "mujer", "edad_14_24", "edad_25_44", "edad_45_mas"
  ), 4),
  estimado_oficial = c(
    65.6, 74.5, 57.5, 41.1, 84.6, 60.5,
    94.5, 95.0, 93.9, 87.2, 95.2, 96.0,
    66.5, 75.9, 58.0, 41.6, 84.7, 62.0,
    95.0, 95.0, 95.0, 86.1, 96.1, 96.5
  ),
  error_std_oficial = c(
    0.5, 0.7, 0.8, 1.3, 0.7, 0.9,
    0.3, 0.4, 0.5, 1.3, 0.5, 0.4,
    0.6, 0.7, 0.8, 1.3, 0.7, 0.9,
    0.3, 0.4, 0.5, 1.4, 0.4, 0.4
  ),
  cv_oficial = c(
    0.82, 0.96, 1.35, 3.15, 0.83, 1.51,
    0.35, 0.45, 0.53, 1.52, 0.49, 0.43,
    0.84, 0.89, 1.35, 3.11, 0.82, 1.44,
    0.32, 0.44, 0.48, 1.64, 0.41, 0.40
  ),
  deff_oficial = c(
    1.2297, 1.2058, 1.2410, 1.3666, 1.3713, 1.3929,
    1.2831, 1.2807, 1.2187, 1.2644, 1.4583, 1.0363,
    1.3676, 1.1594, 1.3161, 1.3176, 1.3521, 1.4597,
    1.2770, 1.2684, 1.3248, 1.3176, 1.2837, 1.1542
  ),
  stringsAsFactors = FALSE
)

numero <- function(x) suppressWarnings(as.numeric(x))

leer_periodo <- function(fila) {
  archivo <- unzip(fila$zip, list = TRUE)$Name[[1]]
  datos <- read.csv(
    unz(fila$zip, archivo),
    colClasses = "character",
    na.strings = c("", "NA"),
    check.names = FALSE
  )

  for (v in c("MUESTRA", "REGION", "ESTRATO", "C207", "C208", "OCUP300", "RESIDENT")) {
    datos[[v]] <- numero(datos[[v]])
  }
  datos$peso <- numero(datos[[fila$peso]])
  datos$actividad <- as.numeric(datos$OCUP300 %in% c(1, 2))
  datos$ocupacion <- as.numeric(datos$OCUP300 == 1)
  datos$upm_mrc <- interaction(
    datos$MUESTRA, datos$REGION, datos$CONGLOMERADO,
    drop = TRUE, lex.order = TRUE
  )
  datos$upm_mes_mrc <- interaction(
    datos$MES, datos$MUESTRA, datos$REGION, datos$CONGLOMERADO,
    drop = TRUE, lex.order = TRUE
  )
  estrato_texto <- ifelse(
    is.na(datos$ESTRATO), "SIN_DATO", as.character(datos$ESTRATO)
  )
  datos$estrato_publicado <- match(estrato_texto, unique(estrato_texto))

  pet <- !is.na(datos$C208) & datos$C208 >= 14 & datos$RESIDENT == 1
  valida <- is.finite(datos$peso) & datos$peso > 0 &
    !is.na(datos$CONGLOMERADO) & nzchar(trimws(datos$CONGLOMERADO))
  datos <- datos[pet & valida, , drop = FALSE]
  datos$year_validacion <- fila$year
  datos
}

crear_diseno <- function(datos, especificacion) {
  switch(especificacion,
    srs = svydesign(ids = ~1, weights = ~peso, data = datos),
    upm = svydesign(ids = ~CONGLOMERADO, weights = ~peso, data = datos),
    upm_compuesta = svydesign(ids = ~upm_mrc, weights = ~peso, data = datos),
    upm_por_mes = svydesign(ids = ~upm_mes_mrc, weights = ~peso, data = datos),
    upm_compuesta_estrato_publicado = svydesign(
      ids = ~upm_mrc, strata = ~estrato_publicado, weights = ~peso,
      data = datos, nest = TRUE
    ),
    upm_por_mes_estrato_publicado = svydesign(
      ids = ~upm_mes_mrc, strata = ~estrato_publicado, weights = ~peso,
      data = datos, nest = TRUE
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
    edad_45_mas = subset(diseno, C208 >= 45)
  )
}

estimar <- function(diseno, indicador, dominio) {
  diseno <- filtrar_dominio(diseno, dominio)
  if (indicador == "actividad") {
    ajuste <- svymean(~actividad, diseno, na.rm = TRUE, deff = "replace")
  } else {
    diseno <- subset(diseno, actividad == 1)
    ajuste <- svymean(~ocupacion, diseno, na.rm = TRUE, deff = "replace")
  }
  estimado <- as.numeric(coef(ajuste)) * 100
  error <- as.numeric(SE(ajuste)) * 100
  data.frame(
    estimado = estimado,
    error_std = error,
    cv = 100 * error / estimado,
    deff = as.numeric(deff(ajuste))
  )
}

especificaciones <- c(
  "srs",
  "upm",
  "upm_compuesta",
  "upm_por_mes",
  "upm_compuesta_estrato_publicado",
  "upm_por_mes_estrato_publicado"
)

resultados <- list()
diagnostico <- list()

for (i in seq_len(nrow(fuentes))) {
  fila <- fuentes[i, ]
  datos <- leer_periodo(fila)
  objetivos <- oficial[oficial$year == fila$year, ]
  tab_upm <- table(datos$upm_mrc, datos$MES) > 0
  diagnostico[[i]] <- data.frame(
    year = fila$year,
    n_personas_pet = nrow(datos),
    n_upm_compuestas = length(unique(datos$upm_mrc)),
    n_upm_mes = length(unique(datos$upm_mes_mrc)),
    n_upm_en_mas_de_un_mes = sum(rowSums(tab_upm) > 1),
    n_estrato_faltante = sum(is.na(datos$ESTRATO)),
    n_estratos_publicados = length(unique(datos$ESTRATO[!is.na(datos$ESTRATO)])),
    stringsAsFactors = FALSE
  )

  for (esp in especificaciones) {
    diseno <- crear_diseno(datos, esp)
    for (j in seq_len(nrow(objetivos))) {
      calculo <- estimar(diseno, objetivos$indicador[j], objetivos$dominio[j])
      resultados[[length(resultados) + 1L]] <- cbind(
        year = fila$year,
        especificacion = esp,
        indicador = objetivos$indicador[j],
        dominio = objetivos$dominio[j],
        calculo,
        stringsAsFactors = FALSE
      )
    }
  }
}

resultados <- do.call(rbind, resultados)
diagnostico <- do.call(rbind, diagnostico)
resultados <- merge(
  resultados, oficial,
  by = c("year", "indicador", "dominio"), all.x = TRUE, sort = FALSE
)
resultados$diferencia_estimado <- resultados$estimado - resultados$estimado_oficial
resultados$diferencia_error_std <- resultados$error_std - resultados$error_std_oficial
resultados$diferencia_cv <- resultados$cv - resultados$cv_oficial
resultados$diferencia_deff <- resultados$deff - resultados$deff_oficial

resumen <- aggregate(
  cbind(
    abs_dif_estimado = abs(resultados$diferencia_estimado),
    abs_dif_error = abs(resultados$diferencia_error_std),
    abs_dif_cv = abs(resultados$diferencia_cv),
    abs_dif_deff = abs(resultados$diferencia_deff)
  ),
  by = list(especificacion = resultados$especificacion),
  FUN = mean
)

cat("Diagnóstico de las bases:\n")
print(diagnostico, row.names = FALSE)
cat("\nDiferencias absolutas medias frente a 24 celdas oficiales:\n")
print(resumen[order(resumen$abs_dif_cv), ], row.names = FALSE, digits = 6)
cat("\nTotales por periodo:\n")
print(resultados[resultados$dominio == "total", ], row.names = FALSE, digits = 6)

dir.create("data-raw/validation", recursive = TRUE, showWarnings = FALSE)
write.csv(
  resultados,
  "data-raw/validation/2026-11-12_diseno_epen_lima_ond_2024_2025.csv",
  row.names = FALSE, na = ""
)
write.csv(
  resumen,
  "data-raw/validation/2026-11-12_diseno_epen_resumen_especificaciones.csv",
  row.names = FALSE, na = ""
)
write.csv(
  diagnostico,
  "data-raw/validation/2026-11-12_diseno_epen_diagnostico.csv",
  row.names = FALSE, na = ""
)
