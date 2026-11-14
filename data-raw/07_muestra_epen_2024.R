# Construye una muestra EPEN 2024 completamente sintetica para ejemplos y
# pruebas. Ninguna fila corresponde a una persona, vivienda u hogar real.
#
# El generador conserva el esquema de 36 columnas que empleR espera, los 25
# ambitos departamentales de la EPEN y codigos ocupacionales validos. Los
# valores se producen mediante reglas declaradas y una semilla fija; no se
# estiman ni se remuestrean desde los microdatos del INEI.

required <- c("dplyr")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0L) {
  stop("Faltan paquetes: ", paste(missing, collapse = ", "), call. = FALSE)
}

output_dir <- Sys.getenv("EMPLER_DATA_OUTPUT_DIR", unset = "data")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

load(file.path(output_dir, "cno_2015.rda"))
load(file.path(output_dir, "indice_ia.rda"))

codigos_validos <- sort(intersect(
  cno_2015$codigo[cno_2015$nivel == 4L],
  indice_ia$code
))
if (length(codigos_validos) < 100L) {
  stop("No hay suficientes codigos CNO con indice para la muestra.", call. = FALSE)
}

set.seed(20261114)
n <- 2000L
i <- seq_len(n)
grupo_hogar <- (i - 1L) %/% 4L

# Callao (07) se integra con Lima Metropolitana en el dominio 15-1. La lista
# tiene 24 codigos departamentales y Lima se divide en dos, dando 25 ambitos.
regiones <- c(1:6, 8:25)
region_code <- regiones[(grupo_hogar %% length(regiones)) + 1L]
division_lima <- ifelse(
  region_code == 15L,
  ((grupo_hogar %/% length(regiones)) %% 2L) + 1L,
  NA_integer_
)

area_raw <- ifelse(
  region_code == 15L & division_lima == 1L,
  1,
  ifelse((grupo_hogar + region_code) %% 3L == 0L, 2, 1)
)
is_urban <- as.numeric(area_raw == 1)
is_rural <- 1 - is_urban

education_code <- as.numeric(((i * 7L + region_code) %% 12L) + 1L)
sex_code <- as.numeric((i %% 2L) + 1L)
age <- as.numeric(18L + ((i * 13L + grupo_hogar) %% 58L))
hours_week <- as.numeric(pmax(8, pmin(72, round(rnorm(n, 43, 12)))))
hours_week_total <- as.numeric(pmin(
  90,
  hours_week + ifelse(i %% 5L == 0L, (i %% 12L) + 2L, 0L)
))

occupational_category_code <- as.integer(((i * 3L) %% 8L) + 1L)
firm_size_code <- as.integer(((grupo_hogar + i) %% 5L) + 1L)
base_income <- 350 + education_code * 105 + hours_week * 13 +
  is_urban * 180 + occupational_category_code * 25
labor_income_monthly <- as.numeric(round(pmax(
  0,
  base_income * exp(rnorm(n, 0, 0.28)) - ifelse(i %% 17L == 0L, base_income, 0)
), 2))

income_periodicity_code <- as.integer(((i + grupo_hogar) %% 5L) + 1L)
income_periodicity_code[i %% 4L != 0L] <- NA_integer_
labor_income_raw <- labor_income_monthly
labor_income_work_weighted <- as.numeric(round(
  labor_income_monthly + ifelse(i %% 9L == 0L, 75 + (i %% 300L), 0),
  2
))

weight <- as.numeric(round(exp(rnorm(n, log(42), 0.65)), 6))
weight[i %% 25L == 0L] <- NA_real_
institutional_sector_code <- as.numeric(((i + region_code) %% 5L) + 1L)
institutional_sector_code[i %% 2L == 0L] <- NA_real_

occupation_code_4d <- codigos_validos[((i * 11L) %% length(codigos_validos)) + 1L]

muestra_epen_2024 <- data.frame(
  source = rep("EPEN", n),
  survey_variant = rep("departamentos_anual", n),
  period_label = rep("Anual - (Ene-Dic)", n),
  year = rep(2024, n),
  month = as.numeric((grupo_hogar %% 12L) + 1L),
  region_code = as.numeric(region_code),
  ubigeo = rep(NA_character_, n),
  domain_code = rep(NA_character_, n),
  sample_id = as.character((grupo_hogar %% 8L) + 1L),
  strata_code = as.integer(((region_code + area_raw * 2L) %% 8L) + 1L),
  cluster_id = sprintf("%05d", grupo_hogar),
  dwelling_id = sprintf("%04d", (grupo_hogar %% 9999L) + 1L),
  household_id = as.character((grupo_hogar %% 3L) + 1L),
  person_id = as.integer(((i - 1L) %% 4L) + 1L),
  relationship_code = as.integer(((i - 1L) %% 10L) + 1L),
  sex_code = sex_code,
  sex = ifelse(sex_code == 1, "Hombre", "Mujer"),
  age = age,
  labor_status_code = rep(1, n),
  occupation_code_raw = as.numeric(occupation_code_4d),
  occupation_code_4d = occupation_code_4d,
  occupational_category_code = occupational_category_code,
  firm_size_code = firm_size_code,
  hours_week = hours_week,
  income_periodicity_code = income_periodicity_code,
  labor_income_raw = labor_income_raw,
  labor_income_monthly = labor_income_monthly,
  weight = weight,
  is_rural = is_rural,
  is_urban = is_urban,
  labor_income_work_weighted = labor_income_work_weighted,
  education_code = education_code,
  institutional_sector_code = institutional_sector_code,
  area_raw = as.numeric(area_raw),
  hours_week_total = hours_week_total,
  division_lima = division_lima,
  stringsAsFactors = FALSE
)
muestra_epen_2024 <- dplyr::as_tibble(muestra_epen_2024)

clave <- muestra_epen_2024[c(
  "year", "month", "sample_id", "region_code", "cluster_id",
  "dwelling_id", "household_id", "person_id"
)]
stopifnot(
  nrow(muestra_epen_2024) == 2000L,
  ncol(muestra_epen_2024) == 36L,
  !anyDuplicated(clave),
  !anyNA(muestra_epen_2024$sample_id),
  !anyNA(muestra_epen_2024$strata_code),
  all(muestra_epen_2024$occupation_code_4d %in% codigos_validos),
  all(muestra_epen_2024$is_rural + muestra_epen_2024$is_urban == 1),
  all(is.na(muestra_epen_2024$division_lima) ==
        (muestra_epen_2024$region_code != 15))
)

save(
  muestra_epen_2024,
  file = file.path(output_dir, "muestra_epen_2024.rda"),
  compress = "bzip2"
)
