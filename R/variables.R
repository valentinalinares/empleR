# Nombres de variables por encuesta ----------------------------------------
#
# Alias de las variables que usan los validadores y resumenes. Primero se
# buscan los nombres propios de cada encuesta (bases crudas del INEI) y luego
# los comunes (bases procesadas). Un alias propio de una encuesta nunca se usa
# en la otra: p108 es la edad en la EPE, pero no en la EPEN.

.alias_variables <- list(
  EPE = list(
    year      = c("pano"),
    ocupacion = c("p204a", "P204A"),
    # El factor depende del periodo: si hay varios, hay que elegir uno.
    peso      = c("fa_def19", "fa_def21"),
    condicion = c("ocu200", "OCU200"),
    edad      = c("p108", "P108")
  ),
  EPEN = list(
    year      = c("ANIO"),
    ocupacion = c("C308_COD"),
    peso      = c("FAC300_ANUAL"),
    condicion = c("OCUP300"),
    edad      = c("C208")
  ),
  comun = list(
    year      = NULL, # se completa con .vars_year
    ocupacion = c("occupation_code_raw", "occupation_code_4d"),
    peso      = c("weight"),
    estrato   = c("ESTRATO", "strata_code", "estrato"),
    upm       = c("CONGLOMERADO", "cluster_id", "CONGLOME", "conglome"),
    condicion = c("labor_status_code"),
    edad      = c("age")
  )
)

#' @noRd
.roles_variables <- c("year", "ocupacion", "peso", "estrato", "upm", "condicion", "edad")

#' Detecta las variables de una base EPE o EPEN
#'
#' @param data `data.frame`.
#' @param encuesta `"EPE"` o `"EPEN"`.
#' @param forzadas Lista con nombres ya elegidos por rol, que tienen prioridad.
#' @return Vector con nombre (rol -> variable), `NA` si no se encontro.
#' @noRd
.detectar_variables <- function(data, encuesta = c("EPE", "EPEN"), forzadas = list()) {
  encuesta <- match.arg(encuesta)
  propios <- .alias_variables[[encuesta]]
  comunes <- .alias_variables$comun
  comunes$year <- .vars_year

  vapply(.roles_variables, function(rol) {
    if (!is.null(forzadas[[rol]])) {
      if (!forzadas[[rol]] %in% names(data)) {
        cli::cli_abort("La variable indicada para {rol}, {.field {forzadas[[rol]]}}, no existe.")
      }
      return(forzadas[[rol]])
    }
    presentes_propios <- intersect(propios[[rol]], names(data))
    if (rol == "peso" && length(presentes_propios) > 1) {
      cli::cli_abort(c(
        "La base {encuesta} tiene varios factores de expansion: {.field {presentes_propios}}.",
        "i" = "El factor depende del periodo; indica cual usar para {.field peso}."
      ))
    }
    .buscar_nombre(names(data), c(propios[[rol]], comunes[[rol]]))
  }, character(1))
}
