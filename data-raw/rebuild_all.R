#!/usr/bin/env Rscript

# Reconstruye los once datasets distribuidos por empleR en una carpeta
# temporal y compara su contenido con data/. No sobrescribe data/ salvo que la
# persona usuaria defina expresamente EMPLER_DATA_OUTPUT_DIR.

required <- c("digest", "jsonlite")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0L) {
  stop("Faltan paquetes: ", paste(missing, collapse = ", "), call. = FALSE)
}

repo <- Sys.getenv("EMPLER_IA_EMPLEO_REPO", unset = NA_character_)
if (is.na(repo) || !dir.exists(repo)) {
  stop("Define EMPLER_IA_EMPLEO_REPO.", call. = FALSE)
}

pinned_commit <- "d7a179f143bb33a6fef23cd0394d8b3053eb89ec"
git_commit <- tryCatch(
  system2(
    "git", c("-C", shQuote(repo), "rev-parse", "HEAD"),
    stdout = TRUE, stderr = TRUE
  ),
  error = function(e) character()
)
if (length(git_commit) != 1L || !identical(git_commit, pinned_commit)) {
  stop(
    "ia_empleo_peru debe estar exactamente en el commit ", pinned_commit,
    "; se encontro: ", paste(git_commit, collapse = " "),
    call. = FALSE
  )
}

output_dir <- Sys.getenv("EMPLER_DATA_OUTPUT_DIR", unset = NA_character_)
temporary_output <- is.na(output_dir)
if (temporary_output) output_dir <- tempfile("empler-rebuild-")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

Sys.setenv(
  EMPLER_IA_EMPLEO_REPO = repo,
  EMPLER_DATA_OUTPUT_DIR = output_dir
)

expected_inputs <- data.frame(
  input = c(
    "disponibilidad_fuentes.csv",
    "mercado_laboral_periodo.csv.gz",
    "CNO_estructurado.xlsx",
    "equivalenciasciuo_cno.xlsx",
    "anthropic-claude-sonnet-4-6_exposure_index.xlsx",
    "co_1995_correspondencia.xlsx",
    "url_catalog_epen.csv",
    "cno_2015_tareas_5321.txt"
  ),
  path = c(
    file.path(repo, "_interno", "bases", "procesadas", "disponibilidad_fuentes.csv"),
    file.path(repo, "_interno", "bases", "procesadas", "mercado_laboral_periodo.csv.gz"),
    file.path(repo, "_interno", "referencias", "cno", "CNO_estructurado.xlsx"),
    file.path(repo, "_interno", "referencias", "equivalencias", "equivalenciasciuo_cno.xlsx"),
    file.path(repo, "_interno", "referencias", "indices", "anthropic-claude-sonnet-4-6_exposure_index.xlsx"),
    file.path("data-raw", "co_1995", "co_1995_correspondencia.xlsx"),
    file.path("data-raw", "url_catalog_epen.csv"),
    file.path("data-raw", "cno_2015_tareas_5321.txt")
  ),
  sha256_expected = c(
    "8aff65e95e24c87b64e57a9c59c7ac0498d1b251a9b8161ffda1e7ffc19c464a",
    "ced9ac482ce365b8ed217993cf9158dc49292613864d2066592138dffdfa75ab",
    "c6f58dee47343a6c585ff119b48300f033d92ab7ebde52579a02d23fc496f8a6",
    "ea18f19564a1fe1de7c7dd1c51d52ce49b0013b9712b3835ac482774c7fbbfc2",
    "39f80eba71aa08e3af3b6dac73019d0d2d9cce69b3215d6e540b8586c6384eb5",
    "2248ff04132ead92012ccf0f5756548c7133dd6bcb3edc66a09af91df078be36",
    "d6a808fdf2d4951e872eb4f654f4e939600d88096e1ef10edf745efe55664b76",
    "39a42ddd5501c8a62af33b11ba67721dcf1303dc93e2eb09410e18dadc75c93f"
  ),
  stringsAsFactors = FALSE
)

if (any(!file.exists(expected_inputs$path))) {
  stop(
    "Faltan entradas: ",
    paste(expected_inputs$input[!file.exists(expected_inputs$path)], collapse = ", "),
    call. = FALSE
  )
}

expected_inputs$sha256_observed <- vapply(
  expected_inputs$path,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE
)
expected_inputs$verified <- with(
  expected_inputs,
  sha256_observed == sha256_expected
)
if (!all(expected_inputs$verified)) {
  stop(
    "No coinciden las huellas de: ",
    paste(expected_inputs$input[!expected_inputs$verified], collapse = ", "),
    call. = FALSE
  )
}

steps <- c(
  "data-raw/00_preparar_datasets.R",
  "data-raw/02_build_indice_ia.R",
  "data-raw/03_build_equivalencia_co95.R",
  "data-raw/04_corregir_cno_2015.R",
  "data-raw/06_restaurar_tareas_cno_2015.R",
  "data-raw/07_muestra_epen_2024.R",
  "data-raw/01_preparar_shapes.R"
)

step_results <- lapply(steps, function(script) {
  message("Ejecutando ", script)
  error <- tryCatch(
    {
      sys.source(script, envir = new.env(parent = globalenv()))
      NA_character_
    },
    error = function(e) conditionMessage(e)
  )
  data.frame(
    script = script,
    status = if (is.na(error)) "generado" else "fallido",
    detail = if (is.na(error)) "" else error,
    stringsAsFactors = FALSE
  )
})
step_results <- do.call(rbind, step_results)

load_one <- function(path) {
  env <- new.env(parent = emptyenv())
  objects <- load(path, envir = env)
  if (length(objects) != 1L) {
    stop("Se esperaba un objeto en ", path, call. = FALSE)
  }
  env[[objects]]
}

same_content <- function(reference, rebuilt) {
  if (!identical(names(reference), names(rebuilt))) return(FALSE)
  if (!identical(dim(reference), dim(rebuilt))) return(FALSE)
  if (inherits(reference, "sf") || inherits(rebuilt, "sf")) {
    if (!requireNamespace("sf", quietly = TRUE) ||
        !inherits(reference, "sf") || !inherits(rebuilt, "sf")) {
      return(FALSE)
    }
    reference_geometry <- sf::st_as_binary(sf::st_geometry(reference))
    rebuilt_geometry <- sf::st_as_binary(sf::st_geometry(rebuilt))
    if (!identical(reference_geometry, rebuilt_geometry)) return(FALSE)
    reference <- sf::st_drop_geometry(reference)
    rebuilt <- sf::st_drop_geometry(rebuilt)
  }
  isTRUE(all.equal(
    as.data.frame(reference), as.data.frame(rebuilt),
    check.attributes = FALSE, tolerance = 0
  ))
}

objects <- sub("[.]rda$", "", list.files("data", pattern = "[.]rda$"))
objects <- sort(objects)
comparisons <- lapply(objects, function(object) {
  reference_path <- file.path("data", paste0(object, ".rda"))
  rebuilt_path <- file.path(output_dir, paste0(object, ".rda"))
  if (!file.exists(rebuilt_path)) {
    return(data.frame(
      object = object, status = "omitido", rows = NA_integer_,
      columns = NA_integer_, content_equal = FALSE,
      binary_equal = FALSE, sha256_reference = NA_character_,
      sha256_rebuilt = NA_character_, stringsAsFactors = FALSE
    ))
  }
  reference <- load_one(reference_path)
  rebuilt <- load_one(rebuilt_path)
  sha_reference <- digest::digest(
    reference_path, algo = "sha256", file = TRUE
  )
  sha_rebuilt <- digest::digest(rebuilt_path, algo = "sha256", file = TRUE)
  equal <- same_content(reference, rebuilt)
  data.frame(
    object = object,
    status = if (equal) "verificado" else "diferente",
    rows = if (is.data.frame(rebuilt)) nrow(rebuilt) else length(rebuilt),
    columns = if (is.data.frame(rebuilt)) ncol(rebuilt) else NA_integer_,
    content_equal = equal,
    binary_equal = identical(sha_reference, sha_rebuilt),
    sha256_reference = sha_reference,
    sha256_rebuilt = sha_rebuilt,
    stringsAsFactors = FALSE
  )
})
comparisons <- do.call(rbind, comparisons)

report_dir <- file.path("data-raw", "validation")
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(
  expected_inputs[c("input", "sha256_expected", "sha256_observed", "verified")],
  file.path(report_dir, "2026-11-14_rebuild_inputs.csv"),
  row.names = FALSE
)
write.csv(
  step_results,
  file.path(report_dir, "2026-11-14_rebuild_steps.csv"),
  row.names = FALSE
)
write.csv(
  comparisons,
  file.path(report_dir, "2026-11-14_rebuild_datasets.csv"),
  row.names = FALSE
)

environment <- list(
  validation_date = "2026-11-14",
  R = R.version.string,
  platform = R.version$platform,
  ia_empleo_peru_commit = pinned_commit,
  seed_muestra_epen_2024 = 20261114,
  packages = as.list(vapply(
    c("dplyr", "readr", "readxl", "sf", "geoperu", "digest", "jsonlite"),
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )),
  output_was_temporary = temporary_output
)
jsonlite::write_json(
  environment,
  file.path(report_dir, "2026-11-14_rebuild_environment.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)

print(step_results, row.names = FALSE)
print(comparisons, row.names = FALSE)

if (any(step_results$status == "fallido") ||
    any(comparisons$status != "verificado")) {
  stop("La reconstruccion no quedo completamente verificada.", call. = FALSE)
}

message("Reconstruccion verificada para ", nrow(comparisons), " datasets.")
