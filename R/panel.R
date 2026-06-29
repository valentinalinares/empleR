#' Construir panel de viviendas entre trimestres moviles de la EPEN
#'
#' La EPEN Lima Metropolitana tiene un diseno de panel rotante a nivel de
#' vivienda: cada vivienda es encuestada durante varios trimestres consecutivos
#' antes de salir del panel. Esta funcion identifica y enlaza las mismas
#' viviendas entre dos o mas trimestres, permitiendo analisis de transiciones
#' laborales.
#'
#' @details
#' La unidad de seguimiento en la EPEN es la **vivienda** (no el individuo),
#' identificada por la combinacion `cluster_id + dwelling_id + household_id`.
#' El `person_id` no siempre esta disponible en los datos procesados.
#'
#' El panel es aplicable principalmente a la variante `lima_movil`, donde
#' los trimestres se solapan (Ene-Feb-Mar, Feb-Mar-Abr, etc.) permitiendo
#' seguir las mismas viviendas mes a mes.
#'
#' @param data_lista Lista de `data.frame` con microdatos de trimestres
#'   consecutivos. Cada elemento debe ser el resultado de [descargar()] con
#'   `variante = "lima_movil"`. El orden de la lista es el orden temporal.
#' @param vars_id Variables que identifican unicamente a una vivienda entre
#'   trimestres. Por defecto: `c("cluster_id", "dwelling_id", "household_id")`.
#'   Para datos crudos INEI usar: `c("CONGLOME", "VIVIENDA", "HOGAR")`.
#' @param incluir_no_apareados Logico. Si `FALSE` (por defecto), solo incluye
#'   viviendas presentes en TODOS los trimestres. Si `TRUE`, incluye todas
#'   las viviendas con datos en al menos un trimestre.
#' @param labels_trimestre Vector de etiquetas para identificar cada trimestre
#'   en la columna `trimestre`. Si es `NULL`, usa "T1", "T2", etc.
#'
#' @return Un `data.frame` en formato long (una fila por vivienda-trimestre)
#'   con columna `trimestre` indicando el periodo.
#'   Atributo `tasa_apareamiento` con el porcentaje de viviendas apareadas.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Descargar tres trimestres consecutivos de Lima 2024
#' t1 <- descargar(2024, "lima_movil", "Trimestre Movil -(Ene-Feb-Mar)")
#' t2 <- descargar(2024, "lima_movil", "Trimestre Movil -(Feb-Mar-Abr)")
#' t3 <- descargar(2024, "lima_movil", "Trimestre Movil -(Mar-Abr-May)")
#'
#' # Construir panel de viviendas
#' panel_q1 <- panel(
#'   list(t1, t2, t3),
#'   labels_trimestre = c("Ene-Feb-Mar", "Feb-Mar-Abr", "Mar-Abr-May")
#' )
#'
#' # Ver tasa de apareamiento
#' attr(panel_q1, "tasa_apareamiento")
#'
#' # Analizar transiciones: personas que cambiaron de estado laboral
#' library(dplyr)
#' panel_q1 |>
#'   select(cluster_id, dwelling_id, household_id, trimestre, labor_status_code) |>
#'   tidyr::pivot_wider(names_from = trimestre, values_from = labor_status_code)
#' }
panel <- function(data_lista,
                  vars_id = c("cluster_id", "dwelling_id", "household_id"),
                  incluir_no_apareados = FALSE,
                  labels_trimestre = NULL) {

  if (!is.list(data_lista) || length(data_lista) < 2) {
    cli::cli_abort(c(
      "{.arg data_lista} debe ser una lista con al menos 2 data.frames.",
      "i" = "Cada elemento debe ser un trimestre descargado con {.fn descargar}."
    ))
  }

  n_trimestres <- length(data_lista)

  # Etiquetas de trimestre
  if (is.null(labels_trimestre)) {
    labels_trimestre <- paste0("T", seq_len(n_trimestres))
  }
  if (length(labels_trimestre) != n_trimestres) {
    cli::cli_abort("La longitud de {.arg labels_trimestre} debe ser {n_trimestres}.")
  }

  # Verificar que vars_id existen en todos los trimestres
  for (i in seq_along(data_lista)) {
    faltantes <- setdiff(vars_id, names(data_lista[[i]]))
    if (length(faltantes) > 0) {
      cli::cli_abort(c(
        "Variables de identificacion faltantes en el trimestre {i}: {.val {faltantes}}.",
        "i" = "Para datos procesados usa: {.code c('cluster_id','dwelling_id','household_id')}.",
        "i" = "Para datos crudos INEI usa: {.code c('CONGLOME','VIVIENDA','HOGAR')}."
      ))
    }
  }

  # Agregar etiqueta de trimestre y construir clave unica de vivienda
  data_lista <- lapply(seq_along(data_lista), function(i) {
    df <- data_lista[[i]]
    df$.trimestre     <- labels_trimestre[i]
    df$.trimestre_num <- i
    df$.key_vivienda  <- do.call(paste, c(df[, vars_id, drop = FALSE], sep = "|"))
    df
  })

  # Identificar viviendas presentes en todos los trimestres
  keys_por_trim <- lapply(data_lista, function(df) unique(df$.key_vivienda))
  keys_comunes  <- Reduce(intersect, keys_por_trim)
  n_total       <- length(unique(unlist(keys_por_trim)))

  tasa_apareamiento <- if (n_total > 0) {
    round(100 * length(keys_comunes) / n_total, 1)
  } else {
    0
  }

  msg_apareadas <- paste0(
    "Viviendas apareadas en todos los trimestres: ",
    "{length(keys_comunes)} ({tasa_apareamiento}%)"
  )

  cli::cli_inform(c(
    "i" = "Trimestres: {n_trimestres}",
    "i" = "Viviendas unicas: {n_total}",
    "v" = msg_apareadas
  ))

  # Filtrar segun apareamiento
  if (!incluir_no_apareados) {
    data_lista <- lapply(data_lista, function(df) {
      df[df$.key_vivienda %in% keys_comunes, ]
    })
  }

  # Unir en formato long
  resultado <- dplyr::bind_rows(data_lista)

  # Limpiar columnas auxiliares internas
  resultado$.key_vivienda  <- NULL
  resultado$.trimestre_num <- NULL

  # Renombrar columna de trimestre
  names(resultado)[names(resultado) == ".trimestre"] <- "trimestre"

  # Guardar tasa de apareamiento como atributo
  attr(resultado, "tasa_apareamiento") <- tasa_apareamiento
  attr(resultado, "n_viviendas_apareadas") <- length(keys_comunes)
  attr(resultado, "vars_id") <- vars_id

  resultado
}
