#' Cruzar ocupaciones con el indice de exposicion a inteligencia artificial
#'
#' Agrega a los microdatos el indice de exposicion a IA generativa por
#' ocupacion, construido con Claude Sonnet 4.6 (Anthropic). El indice
#' mide el grado en que las tareas de cada ocupacion pueden ser asistidas
#' o sustituidas por IA generativa, usando un score continuo de 0 a 1.
#'
#' @details
#' El indice fue construido evaluando las tareas de cada ocupacion del
#' Clasificador Nacional de Ocupaciones (CNO 2015) con tres corridas
#' independientes del modelo Claude Sonnet 4.6, consolidando el resultado
#' por consenso. Cada tarea recibe:
#' \itemize{
#'   \item Un **score continuo** (0-1) de exposicion.
#'   \item Un **tipo de impacto**: `A` (aumento/augmentation),
#'     `S` (sustitucion), `N` (impacto nulo).
#' }
#' El indice final por ocupacion es la media de los scores de sus tareas.
#' Correlacion con el indice de la OIT: r = 0.85.
#'
#' @param data `data.frame` con microdatos de EPEN/EPE que incluya
#'   codigos CNO (resultado de aplicar [cno()]).
#' @param var_cno Nombre de la variable con el codigo CNO 2015 en `data`.
#'   Por defecto `"cno_cod"` (generada por [cno()]).
#' @param score Que score agregar. Opciones:
#'   - `"mean"` (por defecto): score medio de exposicion por ocupacion.
#'   - `"median"`: score mediano.
#'   - `"ambos"`: agrega tanto media como mediana.
#' @param incluir_tipo Logico. Si `TRUE`, agrega tambien el tipo de impacto
#'   predominante (`A`, `S`, `N`) por ocupacion. Por defecto `FALSE`.
#'
#' @return El mismo `data.frame` con columnas adicionales:
#'   \describe{
#'     \item{ia_score_mean}{Score medio de exposicion a IA (0-1).}
#'     \item{ia_score_median}{Score mediano (solo si `score = "ambos"`).}
#'     \item{ia_tipo}{Tipo de impacto predominante (solo si `incluir_tipo = TRUE`).}
#'   }
#'
#' @export
#'
#' @examples
#' # Con la muestra incluida
#' muestra <- cno(muestra_epen_2024)
#' muestra <- ia_exposicion(muestra)
#'
#' # Ver distribucion de exposicion
#' hist(muestra$ia_score_mean, main = "Exposicion a IA", xlab = "Score (0-1)")
#'
#' \dontrun{
#' epen_2024 <- descargar(year = 2024) |>
#'   cno() |>
#'   ia_exposicion(score = "ambos", incluir_tipo = TRUE)
#'
#' # Exposicion media por departamento (con diseno muestral)
#' indicadores(epen_2024, "ingreso_promedio", por = "departamento")
#' }
ia_exposicion <- function(data,
                          var_cno = "cno_cod",
                          score = "mean",
                          incluir_tipo = FALSE) {

  if (!var_cno %in% names(data)) {
    cli::cli_abort(c(
      "La variable '{var_cno}' no existe en los datos.",
      "i" = "Primero aplica {.fn cno} para generar los codigos ocupacionales."
    ))
  }

  # Cargar indice de IA (dataset interno del paquete)
  # Columnas reales: code | occupation_group | mean_exposure_score | median_exposure_score | ...
  idx <- indice_ia

  # Seleccionar columnas a unir segun argumento score
  cols_unir <- "code"
  if (score %in% c("mean", "ambos"))   cols_unir <- c(cols_unir, "mean_exposure_score")
  if (score %in% c("median", "ambos")) cols_unir <- c(cols_unir, "median_exposure_score")
  if (incluir_tipo) {
    cols_unir <- c(cols_unir, "tipo_A_aumento", "tipo_S_sustitucion", "tipo_N_nulo")
  }

  idx_sub <- idx[, cols_unir]

  # Asegurar que el codigo CNO sea character en ambas tablas para el join
  data[[var_cno]] <- as.character(data[[var_cno]])
  idx_sub$code    <- as.character(idx_sub$code)

  # Join por codigo CNO (var_cno en data <-> "code" en indice_ia)
  data <- dplyr::left_join(
    data,
    idx_sub,
    by = stats::setNames("code", var_cno)
  )

  # Renombrar columnas para consistencia
  if ("mean_exposure_score" %in% names(data)) {
    data <- dplyr::rename(data, ia_score_mean = "mean_exposure_score")
  }
  if ("median_exposure_score" %in% names(data)) {
    data <- dplyr::rename(data, ia_score_median = "median_exposure_score")
  }
  if ("tipo_impacto" %in% names(data)) {
    data <- dplyr::rename(data, ia_tipo = "tipo_impacto")
  }

  # Informar sobre ocupaciones sin score
  sin_score <- sum(is.na(data$ia_score_mean))
  if (sin_score > 0) {
    pct <- round(100 * sin_score / nrow(data), 1)
    cli::cli_warn(c(
      "!" = "{sin_score} filas ({pct}%) tienen codigo CNO sin score de IA.",
      "i" = "Puede deberse a codigos sin cobertura en el indice (22 codigos en 2024)."
    ))
  }

  data
}
