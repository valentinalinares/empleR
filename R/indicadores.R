#' Calcular indicadores del mercado laboral con diseno muestral
#'
#' Calcula indicadores laborales incorporando el diseno muestral complejo de
#' la EPEN mediante el paquete \pkg{survey}. Los datos deben ser microdatos
#' procesados (output de [descargar()]) con al menos ocupados en la muestra.
#'
#' Para obtener tasas de desempleo, actividad y empleo a nivel nacional o
#' regional, usa [resumen_nacional()], que devuelve los indicadores
#' pre-calculados del pipeline INEI con la muestra completa de la PEA.
#'
#' @param data `data.frame` con microdatos de EPEN (output de [descargar()]).
#' @param indicador Nombre del indicador a calcular:
#'   - `"ingreso_promedio"`: Ingreso laboral mensual medio (ocupados).
#'   - `"horas_promedio"`: Horas trabajadas promedio semanales (ocupados).
#'   - `"ingreso_mediano"`: Mediana del ingreso mensual (ocupados).
#' @param por Variable(s) de agrupacion: `"sex"`, `"region_code"`,
#'   `"education_code"`, `"institutional_sector_code"`, etc. `NULL` = nacional.
#' @param var_strata Nombre de la variable de estrato. Detecta automaticamente
#'   `strata_code` (datos procesados) o `ESTRATO` (datos crudos INEI).
#' @param var_psu Nombre de la variable PSU. Detecta automaticamente
#'   `cluster_id` (datos procesados) o `CONGLOME` (datos crudos INEI).
#' @param var_peso Nombre del factor de expansion. Detecta automaticamente
#'   `weight` (procesados) o `FACTOR07` (datos crudos INEI).
#'
#' @return Un `data.frame` con el indicador calculado y error estandar,
#'   agrupado segun `por`.
#'
#' @seealso [resumen_nacional()] para indicadores pre-calculados (incluyendo
#'   tasas de desempleo y actividad). [indicadores_epen] para el dataset
#'   interno con indicadores nacionales precalculados.
#'
#' @export
#'
#' @examples
#' # Ingreso promedio nacional con la muestra interna
#' indicadores(muestra_epen_2024, "ingreso_promedio")
#'
#' # Ingreso promedio por sexo
#' indicadores(muestra_epen_2024, "ingreso_promedio", por = "sex")
#'
#' \dontrun{
#' epen_2024 <- descargar(year = 2024)
#'
#' # Ingreso promedio por departamento (codigo de region 1-25)
#' indicadores(epen_2024, "ingreso_promedio", por = "region_code")
#'
#' # Horas trabajadas por sector institucional
#' indicadores(epen_2024, "horas_promedio", por = "institutional_sector_code")
#' }
indicadores <- function(data,
                        indicador,
                        por        = NULL,
                        var_strata = NULL,
                        var_psu    = NULL,
                        var_peso   = NULL) {

  indicadores_validos <- c("ingreso_promedio", "horas_promedio", "ingreso_mediano")

  if (!indicador %in% indicadores_validos) {
    cli::cli_abort(c(
      "'{indicador}' no es un indicador valido.",
      "i" = "Opciones: {.val {indicadores_validos}}",
      "i" = "Para tasas de desempleo/actividad usa {.fn resumen_nacional}."
    ))
  }

  # Detectar variables de diseno muestral
  var_strata <- var_strata %||% .detectar_var(data, c("strata_code", "ESTRATO", "estrato"))
  var_psu    <- var_psu    %||% .detectar_var(data, c("cluster_id",  "CONGLOME", "conglome"))
  var_peso   <- var_peso   %||% .detectar_var(data, c("weight",      "FACTOR07", "FACTOR", "fexp"))

  if (is.null(var_peso)) {
    cli::cli_abort(c(
      "No se encontro variable de factor de expansion (peso).",
      "i" = "Especificala con {.arg var_peso}."
    ))
  }

  # Descartar var_strata y var_psu si tienen demasiados NAs (>50% de filas)
  .es_util <- function(v, data) {
    if (is.null(v) || !v %in% names(data)) return(FALSE)
    mean(is.na(data[[v]])) < 0.5
  }
  if (!.es_util(var_strata, data)) var_strata <- NULL
  if (!.es_util(var_psu, data))    var_psu    <- NULL

  # Eliminar filas con peso NA o cero
  n_antes  <- nrow(data)
  filas_ok <- !is.na(data[[var_peso]]) & data[[var_peso]] > 0
  data     <- data[filas_ok, ]
  if (nrow(data) < n_antes) {
    cli::cli_warn("{n_antes - nrow(data)} filas eliminadas por peso NA o cero.")
  }

  # Construir diseno muestral
  if (!is.null(var_strata) && !is.null(var_psu)) {
    diseno <- survey::svydesign(
      ids     = stats::as.formula(paste0("~", var_psu)),
      strata  = stats::as.formula(paste0("~", var_strata)),
      weights = stats::as.formula(paste0("~", var_peso)),
      data    = data,
      nest    = TRUE
    )
  } else {
    # Diseno sin estratificacion ni PSU (menos preciso, pero funcional)
    cli::cli_warn("Diseno muestral simplificado: no se encontraron strata/PSU.")
    diseno <- survey::svydesign(
      ids     = ~1,
      weights = stats::as.formula(paste0("~", var_peso)),
      data    = data
    )
  }

  # Filtrar NA en la variable objetivo antes de calcular
  var_objetivo <- switch(indicador,
    ingreso_promedio = "labor_income_monthly",
    ingreso_mediano  = "labor_income_monthly",
    horas_promedio   = "hours_week"
  )

  # Verificar que la variable existe
  if (!var_objetivo %in% names(data)) {
    # Intentar equivalente en datos crudos INEI
    var_objetivo_raw <- switch(indicador,
      ingreso_promedio = .detectar_var(data, c("P529A", "INGRESO", "ING_TOTAL")),
      ingreso_mediano  = .detectar_var(data, c("P529A", "INGRESO", "ING_TOTAL")),
      horas_promedio   = .detectar_var(data, c("P513T", "HORAS", "HRS_TOTAL"))
    )
    if (is.null(var_objetivo_raw)) {
      cli::cli_abort("Variable para '{indicador}' no encontrada en los datos.")
    }
    var_objetivo <- var_objetivo_raw
  }

  formula_var <- stats::as.formula(paste0("~", var_objetivo))

  # Calcular y devolver data.frame limpio con columnas: estimado, error_std
  if (is.null(por)) {
    if (indicador == "ingreso_mediano") {
      res <- survey::svyquantile(formula_var, diseno, quantiles = 0.5, na.rm = TRUE)
    } else {
      res <- survey::svymean(formula_var, diseno, na.rm = TRUE)
    }
    # coef() funciona tanto para svymean como para svyquantile (survey >= 4.1)
    resultado <- data.frame(
      indicador  = indicador,
      estimado   = as.numeric(stats::coef(res)),
      error_std  = as.numeric(survey::SE(res))
    )
  } else {
    formula_por <- stats::as.formula(paste0("~", paste(por, collapse = "+")))
    if (indicador == "ingreso_mediano") {
      res <- survey::svyby(formula_var, by = formula_por, design = diseno,
                           FUN = survey::svyquantile, quantiles = 0.5, na.rm = TRUE)
    } else {
      res <- survey::svyby(formula_var, by = formula_por, design = diseno,
                           FUN = survey::svymean, na.rm = TRUE)
    }
    # Extraer estimado y SE directamente con coef()/SE()
    # (mas robusto que buscar columnas por nombre en el data.frame)
    res_df          <- as.data.frame(res)
    resultado       <- res_df[, c(por), drop = FALSE]
    resultado$indicador <- indicador
    resultado$estimado  <- as.numeric(stats::coef(res))
    resultado$error_std <- as.numeric(survey::SE(res))
  }

  resultado
}


#' Consultar indicadores nacionales pre-calculados (EPEN/ENAHO)
#'
#' Devuelve indicadores del mercado laboral a nivel nacional ya calculados
#' para todos los periodos disponibles. Incluye tasas de desempleo, actividad
#' y empleo que requieren la PEA completa (no solo ocupados).
#'
#' @param fuente `"EPEN"`, `"ENAHO"` o `"todas"` (por defecto).
#' @param year Filtrar por ano. `NULL` devuelve todos los anos.
#' @param variante Filtrar por variante. `NULL` devuelve todas las variantes.
#'
#' @return Un `data.frame` con columnas:
#'   `source`, `survey_variant`, `year`, `period_label`,
#'   `activity_rate_pet`, `employment_rate_pet`, `unemployment_rate_pea`,
#'   `income_monthly_weighted_mean`, `hours_week_weighted_mean`, y mas.
#'
#' @export
#'
#' @examples
#' # Ver indicadores EPEN
#' resumen_nacional(fuente = "EPEN")
#'
#' # Tasa de desempleo EPEN departamentos por ano
#' resumen_nacional("EPEN", variante = "departamentos_anual") |>
#'   subset(select = c(year, unemployment_rate_pea, activity_rate_pet))
resumen_nacional <- function(fuente = "todas", year = NULL, variante = NULL) {
  datos <- indicadores_epen

  if (fuente != "todas") {
    datos <- datos[toupper(datos$source) == toupper(fuente), ]
  }
  if (!is.null(year)) {
    datos <- datos[datos$year %in% year, ]
  }
  if (!is.null(variante)) {
    datos <- datos[datos$survey_variant == variante, ]
  }

  if (nrow(datos) == 0) {
    cli::cli_warn("No se encontraron indicadores con los filtros aplicados.")
  }

  datos
}


# Helpers internos --------------------------------------------------------

#' @noRd
`%||%` <- function(x, y) if (!is.null(x)) x else y

#' @noRd
.detectar_var <- function(data, candidatos) {
  encontrada <- intersect(candidatos, names(data))
  if (length(encontrada) == 0) return(NULL)
  encontrada[1]
}
