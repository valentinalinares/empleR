# Construye data/indice_ia.rda desde el indice final Sonnet 2026-06-15.
# Ejecutar desde la raiz del paquete.

source_dir <- Sys.getenv(
  "EMPLER_INDICE_IA_DIR",
  unset = paste0(
    "C:/Users/VALENTINALINARES/OneDrive - Universidad del Pacifico/",
    "Desktop/CIUP/IA_Empleo_Peru/2026-06-15_VRI_Fiorella/",
    "VRI 2026 - Fiorella/01_Indice_exposicion"
  )
)

if (!dir.exists(source_dir)) {
  source_dir <- paste0(
    "C:/Users/VALENTINALINARES/OneDrive - Universidad del Pacífico/",
    "Desktop/CIUP/IA_Empleo_Peru/2026-06-15_VRI_Fiorella/",
    "VRI 2026 – Fiorella/01_Indice_exposicion"
  )
}

index_file <- file.path(source_dir, "02_exposure_index_por_ocupacion.xlsx")
agreement_file <- file.path(source_dir, "04_agreement_summary.json")

if (!file.exists(index_file)) {
  stop("No se encontro el archivo del indice: ", index_file, call. = FALSE)
}

if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Instala readxl para reconstruir indice_ia: install.packages('readxl')", call. = FALSE)
}

indice_ia <- readxl::read_excel(index_file)

rename_map <- c(
  "%_alta_exposicion" = "pct_alta_exposicion",
  "%_media_alta_exp" = "pct_media_alta_exp",
  "%_sustitucion" = "pct_sustitucion",
  "%_aumento" = "pct_aumento"
)

for (old_name in names(rename_map)) {
  if (old_name %in% names(indice_ia)) {
    names(indice_ia)[names(indice_ia) == old_name] <- rename_map[[old_name]]
  }
}

required_cols <- c(
  "code",
  "occupation_group",
  "total_tasks",
  "mean_exposure_score",
  "median_exposure_score",
  "max_score",
  "min_score",
  "std_score",
  "tasks_muy_baja_exp",
  "tasks_baja_exp",
  "tasks_media_exp",
  "tasks_alta_exp",
  "tasks_muy_alta_exp",
  "tipo_A_aumento",
  "tipo_S_sustitucion",
  "tipo_N_nulo",
  "pct_alta_exposicion",
  "pct_media_alta_exp",
  "pct_sustitucion",
  "pct_aumento",
  "tasks_and_classifications"
)

missing_cols <- setdiff(required_cols, names(indice_ia))
if (length(missing_cols) > 0) {
  stop("Faltan columnas en el indice IA: ", paste(missing_cols, collapse = ", "), call. = FALSE)
}

indice_ia <- indice_ia[, required_cols]
indice_ia$code <- as.character(indice_ia$code)

if (anyDuplicated(indice_ia$code) > 0) {
  stop("El indice IA tiene codigos CNO duplicados.", call. = FALSE)
}

score_cols <- c(
  "mean_exposure_score",
  "median_exposure_score",
  "max_score",
  "min_score",
  "pct_alta_exposicion",
  "pct_media_alta_exp",
  "pct_sustitucion",
  "pct_aumento"
)

score_values <- unlist(indice_ia[score_cols], use.names = FALSE)
if (any(score_values < 0 | score_values > 1, na.rm = TRUE)) {
  stop("Los scores y porcentajes del indice IA deben estar en escala 0-1.", call. = FALSE)
}

if (file.exists(agreement_file) && requireNamespace("jsonlite", quietly = TRUE)) {
  agreement <- jsonlite::fromJSON(agreement_file)
  if (!is.null(agreement$total_tasks) &&
      !isTRUE(all.equal(sum(indice_ia$total_tasks), agreement$total_tasks))) {
    stop("El total de tareas del indice no coincide con 04_agreement_summary.json.", call. = FALSE)
  }
}

dir.create("data", showWarnings = FALSE)
save(indice_ia, file = file.path("data", "indice_ia.rda"), compress = "bzip2")
