# Construye los datasets tabulares base de empleR.
#
# Requiere un checkout de ia_empleo_peru en el commit fijado en
# data-raw/README.md. Indica su ruta con EMPLER_IA_EMPLEO_REPO.
# Las correcciones posteriores de cno_2015 se aplican con los scripts 04 y 06.

required <- c("dplyr", "readr", "readxl")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0L) {
  stop("Faltan paquetes: ", paste(missing, collapse = ", "), call. = FALSE)
}

repo <- Sys.getenv("EMPLER_IA_EMPLEO_REPO", unset = NA_character_)
if (is.na(repo) || !dir.exists(repo)) {
  stop(
    "Define EMPLER_IA_EMPLEO_REPO con el checkout fijado de ia_empleo_peru.",
    call. = FALSE
  )
}

output_dir <- Sys.getenv("EMPLER_DATA_OUTPUT_DIR", unset = "data")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

interno <- file.path(repo, "_interno")
paths <- c(
  catalogo = file.path(
    interno, "bases", "procesadas", "disponibilidad_fuentes.csv"
  ),
  indicadores = file.path(
    interno, "bases", "procesadas", "mercado_laboral_periodo.csv.gz"
  ),
  cno = file.path(interno, "referencias", "cno", "CNO_estructurado.xlsx"),
  equivalencia = file.path(
    interno, "referencias", "equivalencias", "equivalenciasciuo_cno.xlsx"
  ),
  url = file.path("data-raw", "url_catalog_epen.csv")
)

if (any(!file.exists(paths))) {
  stop(
    "Faltan entradas: ", paste(names(paths)[!file.exists(paths)], collapse = ", "),
    call. = FALSE
  )
}

catalogo_fuentes <- readr::read_csv(
  paths[["catalogo"]], show_col_types = FALSE
) |>
  dplyr::rename(
    variante = survey_variant,
    periodo = period_label,
    filas = rows,
    codigos_ocup = occupation_codes
  ) |>
  dplyr::select(
    fuente = source, variante, year, periodo, filas, codigos_ocup
  )

indicadores_epen <- readr::read_csv(
  paths[["indicadores"]], show_col_types = FALSE
)

cno_2015 <- readxl::read_excel(paths[["cno"]]) |>
  dplyr::mutate(nivel = as.integer(level)) |>
  dplyr::rename(
    codigo = code,
    descripcion = title,
    descripcion_extendida = description
  ) |>
  dplyr::select(
    codigo, descripcion, nivel, descripcion_extendida, tasks, tasks_clean
  )

equivalencia_cno <- readxl::read_excel(paths[["equivalencia"]])
if (ncol(equivalencia_cno) != 6L) {
  stop("La tabla de equivalencias ya no tiene seis columnas.", call. = FALSE)
}
# El archivo esta fijado por SHA-256. Se asignan nombres por posicion porque
# readxl representa las tildes de los encabezados de forma distinta segun el
# locale de Windows (por ejemplo, `Código` puede llegar como `C<U+00F3>digo`).
names(equivalencia_cno) <- c(
  "desc_ciuo_2008", "cod_ciuo_2008", "enlace_ciuo_cno",
  "desc_cno_2015", "cod_cno_2015", "enlace_cno_ciuo"
)
equivalencia_cno <- equivalencia_cno |>
  dplyr::select(
    cod_ciuo_2008, desc_ciuo_2008, cod_cno_2015, desc_cno_2015,
    enlace_ciuo_cno, enlace_cno_ciuo
  )

url_catalog_epen <- readr::read_csv(
  paths[["url"]],
  col_types = readr::cols(
    variant = readr::col_character(),
    year = readr::col_integer(),
    period = readr::col_character(),
    survey_code = readr::col_double(),
    module_code = readr::col_double(),
    url = readr::col_character()
  )
) |>
  dplyr::select(
    variant, year, period, survey_code, module_code, url
  )

outputs <- list(
  catalogo_fuentes = catalogo_fuentes,
  indicadores_epen = indicadores_epen,
  cno_2015 = cno_2015,
  equivalencia_cno = equivalencia_cno,
  url_catalog_epen = url_catalog_epen
)

for (name in names(outputs)) {
  assign(name, outputs[[name]])
  save(
    list = name,
    file = file.path(output_dir, paste0(name, ".rda")),
    compress = "bzip2"
  )
  message(name, ": ", nrow(outputs[[name]]), " filas")
}
