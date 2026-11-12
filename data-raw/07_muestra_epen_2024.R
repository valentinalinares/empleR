# Regenera data/muestra_epen_2024.rda desde la base EPEN corregida de
# ia_empleo_peru. Ejecutar desde la raiz del paquete.
#
# Fuente: ia_empleo_peru, rama main (merge de valentinalinares/ia_empleo_peru#3),
#   _interno/bases/procesadas/epen_persona_departamentos_anual_2022_2025.csv.gz
#   SHA-256 b71df3ff8fa2e2702dd11eed511aa9dd36ac5d3066c5d7b0735bd958229a7800
#   MD5     de25d086b58ab302842c485577e7e6b8
# Esa base se reconstruye desde los ZIP oficiales del modulo 76 con
# _interno/scripts/build_epen_persona_departamentos.py. Respecto de la base
# anterior trae los codigos CNO completados a la izquierda, los
# identificadores reconstruidos (estrato, persona, parentesco, categoria,
# tamano de empresa, periodicidad), sample_id (MUESTRA) y los codigos de
# conglomerado, vivienda y hogar como texto con sus ceros originales.
#
# Se reproduce la misma seleccion que 00_preparar_datasets.R (ano 2024,
# set.seed(42), slice_sample(n = 2000)): son las mismas 2.000 personas que la
# muestra anterior. El script lo verifica antes de guardar. DIVISION_LIMA se
# recupera del ZIP oficial de 2024 porque la base procesada no conserva esa
# variable geografica.

suppressMessages({
  library(dplyr)
  library(readr)
})

base_path <- Sys.getenv(
  "EMPLER_EPEN_BASE",
  unset = file.path(
    "..", "ia_empleo_peru", "_interno", "bases", "procesadas",
    "epen_persona_departamentos_anual_2022_2025.csv.gz"
  )
)
if (!file.exists(base_path)) {
  stop("No se encontro la base EPEN: ", base_path,
       "\nIndica la ruta con la variable de entorno EMPLER_EPEN_BASE.", call. = FALSE)
}
md5_esperado <- "de25d086b58ab302842c485577e7e6b8"
if (!identical(unname(tools::md5sum(base_path)), md5_esperado)) {
  stop("La base EPEN no es la version esperada (MD5 distinto).", call. = FALSE)
}

raw_path <- Sys.getenv(
  "EMPLER_EPEN_RAW_2024",
  unset = file.path(
    "..", "data", "raw", "inei_data_core", "epen_departamentos",
    "2024", "156", "csv", "935-Modulo76.zip"
  )
)
if (!file.exists(raw_path)) {
  stop("No se encontro el ZIP oficial EPEN 2024: ", raw_path,
       "\nIndica la ruta con EMPLER_EPEN_RAW_2024.", call. = FALSE)
}
md5_raw_esperado <- "01c2a0176284822dbde5d85c393b18eb"
if (!identical(unname(tools::md5sum(raw_path)), md5_raw_esperado)) {
  stop("El ZIP EPEN 2024 no es la version esperada (MD5 distinto).", call. = FALSE)
}

base <- readr::read_csv(base_path, col_types = cols(.default = col_character()),
                        progress = FALSE)

set.seed(42)
muestra <- base |>
  filter(year == "2024") |>
  slice_sample(n = 2000)

# Recuperar la division oficial de Lima con la clave completa de persona.
pkgload::load_all(".", quiet = TRUE)
raw <- .leer_zip_inei(raw_path)
claves <- c(
  ".year_key", ".month_key", ".sample_key", ".region_key", ".cluster_key",
  ".dwelling_key", ".household_key", ".person_key"
)
raw_geo <- raw |>
  transmute(
    .year_key = as.character(as.integer(ANIO)),
    .month_key = as.character(as.integer(MES)),
    .sample_key = as.character(MUESTRA),
    .region_key = as.character(as.integer(CCDD)),
    .cluster_key = as.character(CONGLOMERADO),
    .dwelling_key = as.character(SELVIV),
    .household_key = as.character(HOGAR),
    .person_key = as.character(as.integer(C201)),
    hours_week_total = as.numeric(whoraT),
    division_lima = as.integer(DIVISION_LIMA)
  )
stopifnot(!anyDuplicated(raw_geo[claves]))

muestra <- muestra |>
  mutate(
    .year_key = as.character(as.integer(year)),
    .month_key = as.character(as.integer(month)),
    .sample_key = as.character(sample_id),
    .region_key = as.character(as.integer(region_code)),
    .cluster_key = as.character(cluster_id),
    .dwelling_key = as.character(dwelling_id),
    .household_key = as.character(household_id),
    .person_key = as.character(as.integer(person_id))
  ) |>
  left_join(raw_geo, by = claves) |>
  select(-all_of(claves))
rm(raw, raw_geo)

# Tipos: identificadores del muestreo como texto (conservan ceros), codigos
# categoricos como enteros y el resto como en la muestra anterior.
texto  <- c("source", "survey_variant", "period_label", "ubigeo", "domain_code",
            "sample_id", "cluster_id", "dwelling_id", "household_id", "sex",
            "occupation_code_4d")
entero <- c("strata_code", "person_id", "relationship_code",
            "occupational_category_code", "firm_size_code", "income_periodicity_code",
            "division_lima")
numero <- setdiff(names(muestra), c(texto, entero))

muestra <- muestra |>
  mutate(
    across(all_of(entero), as.integer),
    across(all_of(numero), as.numeric)
  )

# Verificar que son las mismas personas que la muestra anterior
anterior <- file.path("data", "muestra_epen_2024.rda")
if (file.exists(anterior)) {
  env <- new.env()
  load(anterior, envir = env)
  previa <- env$muestra_epen_2024
  comunes <- c("month", "region_code", "age", "sex_code", "occupation_code_raw",
               "hours_week", "labor_income_raw", "labor_income_monthly", "weight",
               "area_raw", "occupation_code_4d")
  for (v in comunes) {
    if (!isTRUE(all.equal(previa[[v]], muestra[[v]], check.attributes = FALSE))) {
      stop("La seleccion no reproduce la muestra anterior en ", v, call. = FALSE)
    }
  }
  stopifnot(isTRUE(all.equal(as.numeric(previa$cluster_id), as.numeric(muestra$cluster_id))))
}

stopifnot(
  nrow(muestra) == 2000L,
  ncol(muestra) == 36L,
  !anyNA(muestra$sample_id),
  !anyNA(muestra$strata_code),
  !anyNA(muestra$hours_week_total),
  all(!is.na(muestra$division_lima[muestra$region_code == 15])),
  all(is.na(muestra$division_lima[muestra$region_code != 15])),
  !anyDuplicated(muestra[c("month", "sample_id", "region_code", "cluster_id",
                           "dwelling_id", "household_id", "person_id")])
)

muestra_epen_2024 <- muestra
save(muestra_epen_2024, file = anterior, compress = "bzip2")
