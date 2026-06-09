# =============================================================================
# Preparacion de datasets internos del paquete {empleR}
# =============================================================================
# Ejecutar con: source("data-raw/00_preparar_datasets.R")
# desde el directorio raiz del paquete empleR/
# =============================================================================

library(readr)
library(readxl)
library(dplyr)

BASE <- "../ia_empleo_peru/_interno"
PKG  <- "."   # raiz del paquete


# 1. catalogo_fuentes -------------------------------------------------------
# Fuente: disponibilidad_fuentes.csv (ya procesado por el pipeline Python)

catalogo_fuentes <- read_csv(
  file.path(BASE, "bases/procesadas/disponibilidad_fuentes.csv"),
  show_col_types = FALSE
) |>
  rename(
    variante     = survey_variant,
    periodo      = period_label,
    filas        = rows,
    codigos_ocup = occupation_codes
  ) |>
  select(fuente = source, variante, year, periodo, filas, codigos_ocup)

cat("catalogo_fuentes:", nrow(catalogo_fuentes), "filas\n")
save(catalogo_fuentes,
     file = file.path(PKG, "data/catalogo_fuentes.rda"),
     compress = "bzip2")


# 2. indice_ia ---------------------------------------------------------------
# Fuente: anthropic-claude-sonnet-4-6_exposure_index.xlsx
# Columnas reales: code | occupation_group | total_tasks | mean_exposure_score
#                  median_exposure_score | max_score | min_score | std_score |
#                  tasks_* | tipo_A_aumento | tipo_S_sustitucion | tipo_N_nulo |
#                  %_* | tasks_and_classifications

indice_ia <- read_excel(
  file.path(BASE, "referencias/indices/anthropic-claude-sonnet-4-6_exposure_index.xlsx")
) |>
  # Mantener columnas sustantivas, renombrar % para evitar conflictos
  rename(
    pct_alta_exposicion  = `%_alta_exposicion`,
    pct_media_alta_exp   = `%_media_alta_exp`,
    pct_sustitucion      = `%_sustitucion`,
    pct_aumento          = `%_aumento`
  )

cat("indice_ia:", nrow(indice_ia), "ocupaciones,",
    ncol(indice_ia), "columnas\n")
cat("Score medio rango:", round(min(indice_ia$mean_exposure_score, na.rm=TRUE), 3),
    "-", round(max(indice_ia$mean_exposure_score, na.rm=TRUE), 3), "\n")

save(indice_ia,
     file = file.path(PKG, "data/indice_ia.rda"),
     compress = "bzip2")


# 3. cno_2015 ----------------------------------------------------------------
# Fuente: CNO_estructurado.xlsx
# Columnas: code | title | level | description | tasks | occupations | tasks_clean
# Nos quedamos con el nivel jerarquico completo (levels 1-4)

cno_2015 <- read_excel(
  file.path(BASE, "referencias/cno/CNO_estructurado.xlsx")
) |>
  mutate(
    nivel    = as.integer(level),
    n_digits = nchar(trimws(code))
  ) |>
  rename(
    codigo      = code,
    descripcion = title,
    descripcion_extendida = description
  ) |>
  select(codigo, descripcion, nivel, descripcion_extendida, tasks, tasks_clean)

cat("cno_2015:", nrow(cno_2015), "filas (todos los niveles)\n")
cat("Niveles:", table(cno_2015$nivel), "\n")

save(cno_2015,
     file = file.path(PKG, "data/cno_2015.rda"),
     compress = "bzip2")


# 4. equivalencia_cno --------------------------------------------------------
# Fuente: equivalenciasciuo_cno.xlsx
# Esta tabla cruza CIUO-2008 <-> CNO-2015
# Columnas: Grupo Primario CIUO 2008 | Código CIUO 2008 | Enlace...3
#           Grupo Primario CNO 2015  | Código CNO 2015  | Enlace...6

equivalencia_cno <- read_excel(
  file.path(BASE, "referencias/equivalencias/equivalenciasciuo_cno.xlsx")
) |>
  rename(
    desc_ciuo_2008  = `Grupo Primario  CIUO 2008`,
    cod_ciuo_2008   = `Código CIUO 2008`,
    enlace_ciuo_cno = `Enlace...3`,
    desc_cno_2015   = `Grupo Primario CNO 2015`,
    cod_cno_2015    = `Código  CNO  2015`,
    enlace_cno_ciuo = `Enlace...6`
  ) |>
  select(cod_ciuo_2008, desc_ciuo_2008, cod_cno_2015, desc_cno_2015,
         enlace_ciuo_cno, enlace_cno_ciuo)

cat("equivalencia_cno:", nrow(equivalencia_cno), "pares de equivalencia\n")

save(equivalencia_cno,
     file = file.path(PKG, "data/equivalencia_cno.rda"),
     compress = "bzip2")


# 5. muestra_epen_2024 -------------------------------------------------------
# Fuente: epen_persona_departamentos_anual_2022_2025.csv.gz
# Submuestra de 2000 filas de 2024 para ejemplos
# Columnas clave: occupation_code_4d, weight, strata_code, cluster_id,
#                 region_code, ubigeo, labor_status_code, year, etc.

cat("Cargando EPEN departamentos... (puede tardar)\n")
epen_completa <- read_csv(
  file.path(BASE, "bases/procesadas/epen_persona_departamentos_anual_2022_2025.csv.gz"),
  show_col_types = FALSE
)

cat("EPEN completa:", nrow(epen_completa), "filas, anios disponibles:",
    paste(sort(unique(epen_completa$year)), collapse=", "), "\n")

set.seed(42)
muestra_epen_2024 <- epen_completa |>
  filter(year == 2024) |>
  slice_sample(n = 2000) |>
  # Estandarizar occupation_code_4d a character para joins con CNO y el indice
  mutate(occupation_code_4d = as.character(occupation_code_4d))

cat("muestra_epen_2024:", nrow(muestra_epen_2024), "filas,",
    ncol(muestra_epen_2024), "columnas\n")
cat("Columnas:", paste(names(muestra_epen_2024), collapse=" | "), "\n")

save(muestra_epen_2024,
     file = file.path(PKG, "data/muestra_epen_2024.rda"),
     compress = "bzip2")


# Resumen final -------------------------------------------------------------
cat("\n=== Datasets generados en data/ ===\n")
archivos <- list.files(file.path(PKG, "data"), pattern="\\.rda$")
for (f in archivos) {
  sz <- file.size(file.path(PKG, "data", f))
  cat(sprintf("  %-35s %s KB\n", f, round(sz/1024, 1)))
}
cat("Listo!\n")
