#' Aplicar etiquetas de valor a variables de la EPEN/EPE
#'
#' Convierte variables codificadas numericamente a factores con etiquetas
#' legibles, siguiendo el diccionario oficial del INEI. Funciona tanto con
#' datos crudos descargados con [descargar()] como con datos ya procesados.
#'
#' @param data `data.frame` con microdatos de EPEN/EPE.
#' @param vars Vector de nombres de variables a etiquetar. Si es `NULL`
#'   (por defecto), etiqueta todas las variables con diccionario disponible.
#' @param as_factor Logico. Si `TRUE` (por defecto), devuelve las variables
#'   etiquetadas como `factor`. Si `FALSE`, devuelve como `character`.
#'
#' @return El mismo `data.frame` con las variables seleccionadas convertidas.
#'
#' @export
#'
#' @examples
#' # Etiquetar todas las variables con diccionario en la muestra
#' muestra_etiquetada <- etiquetar(muestra_epen_2024)
#'
#' # Verificar resultado
#' table(muestra_etiquetada$sex_code)
#'
#' # Solo etiquetar variables especificas
#' muestra_etiquetada <- etiquetar(
#'   muestra_epen_2024,
#'   vars = c("sex_code", "education_code", "institutional_sector_code")
#' )
etiquetar <- function(data, vars = NULL, as_factor = TRUE) {

  # Si no se especifican vars, etiquetar todas las que tienen diccionario
  if (is.null(vars)) {
    vars <- intersect(names(data), names(.diccionarios_epen))
  }

  if (length(vars) == 0) {
    cli::cli_warn("No se encontraron variables con diccionario disponible.")
    return(data)
  }

  for (v in vars) {
    if (!v %in% names(.diccionarios_epen)) {
      cli::cli_warn("Variable '{v}' no tiene diccionario disponible. Omitida.")
      next
    }
    mapa <- .diccionarios_epen[[v]]
    data[[v]] <- .aplicar_etiqueta(data[[v]], mapa, as_factor = as_factor)
  }

  cli::cli_inform(c("v" = "{length(vars)} variable(s) etiquetadas."))
  data
}


# Diccionarios de etiquetas -----------------------------------------------
# Basados en los cuestionarios oficiales EPEN/ENAHO del INEI

#' @noRd
.diccionarios_epen <- list(

  # --- Sexo ----------------------------------------------------------------
  sex_code = c(
    "1" = "Hombre",
    "2" = "Mujer"
  ),

  # --- Condicion de actividad (labor_status_code / OCU500) ----------------
  labor_status_code = c(
    "1" = "Ocupado",
    "2" = "Desocupado abierto",
    "3" = "Desocupado oculto",
    "4" = "Inactivo"
  ),

  # --- Nivel educativo (education_code / P301A) ----------------------------
  education_code = c(
    "1"  = "Sin nivel",
    "2"  = "Inicial",
    "3"  = "Primaria incompleta",
    "4"  = "Primaria completa",
    "5"  = "Secundaria incompleta",
    "6"  = "Secundaria completa",
    "7"  = "Sup. no universitaria incompleta",
    "8"  = "Sup. no universitaria completa",
    "9"  = "Sup. universitaria incompleta",
    "10" = "Sup. universitaria completa",
    "11" = "Postgrado universitario",
    "12" = "No especificado"
  ),

  # --- Sector institucional -----------------------------------------------
  institutional_sector_code = c(
    "1" = "Sector publico",
    "2" = "Empresa privada",
    "3" = "Independiente",
    "4" = "Familiar no remunerado",
    "5" = "Otro"
  ),

  # --- Categoria ocupacional (occupational_category_code / C310) ----------
  occupational_category_code = c(
    "1" = "Empleador / patron",
    "2" = "Trabajador independiente",
    "3" = "Empleado",
    "4" = "Obrero",
    "5" = "Trabajador del hogar",
    "6" = "Trabajador familiar no remunerado",
    "7" = "Otro"
  ),

  # --- Tamano de empresa (firm_size_code) ----------------------------------
  firm_size_code = c(
    "1"  = "1 persona (unipersonal)",
    "2"  = "2 a 5 personas",
    "3"  = "6 a 10 personas",
    "4"  = "11 a 20 personas",
    "5"  = "21 a 50 personas",
    "6"  = "51 a 100 personas",
    "7"  = "101 a 500 personas",
    "8"  = "501 a mas personas",
    "9"  = "No especificado"
  ),

  # --- Zona (is_rural) -----------------------------------------------------
  is_rural = c(
    "0" = "Urbano",
    "1" = "Rural"
  ),

  # --- Periodicidad del ingreso (income_periodicity_code) ------------------
  income_periodicity_code = c(
    "1" = "Diario",
    "2" = "Semanal",
    "3" = "Quincenal",
    "4" = "Mensual",
    "5" = "Anual",
    "6" = "Por hora",
    "7" = "Por destajo",
    "8" = "Otro"
  )
)


# Helpers internos --------------------------------------------------------

#' @noRd
.detectar_year <- function(data) {
  # EPEN procesada usa "year"; datos crudos INEI pueden usar "ANo", "ANIO"
  candidatos <- c("year", "ANo", "ANIO", "anio", "YEAR")
  var_year <- intersect(candidatos, names(data))
  if (length(var_year) == 0) {
    cli::cli_abort(c(
      "No se pudo detectar el ano de la base.",
      "i" = "Asegurate de pasar datos descargados con {.fn descargar}."
    ))
  }
  as.integer(data[[var_year[1]]][1])
}

#' @noRd
.aplicar_etiqueta <- function(x, mapa, as_factor) {
  resultado <- mapa[as.character(x)]
  nombres <- unname(resultado)
  if (as_factor) {
    factor(nombres, levels = unique(unname(mapa)))
  } else {
    nombres
  }
}
