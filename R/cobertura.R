#' Cobertura de la homologacion ocupacional y del indice de IA
#'
#' Resume, por encuesta y ano, cuantas observaciones y cuanta poblacion
#' ponderada tienen score de IA, y por que falta en el resto. Distingue la
#' falta de homologacion CO-95 -> CNO 2015 (EPE) de la falta de score en el
#' indice. Revisar este resumen es un paso previo a comparar EPE y EPEN.
#'
#' @param data `data.frame` procesado con [cno()] e [ia_exposicion()].
#' @param por Variables de agrupacion. Por defecto, la encuesta (`source`, o
#'   la derivada de `clasificador`: CO-95 = EPE, CNO 2015 = EPEN) y el ano.
#' @param var_peso Factor de expansion. Si es `NULL` se detecta (`weight`,
#'   `FACTOR07`, `FACTOR`, `fexp`); si no existe, solo se reportan
#'   observaciones.
#'
#' @return Un `data.frame` con una fila por grupo, estado y detalle:
#'   \describe{
#'     \item{estado}{`"con_score"`, `"sin_score"`, `"codigo_no_encontrado"`,
#'       `"sin_homologacion"` o `"sin_codigo"` (ver [ia_exposicion()]).}
#'     \item{detalle}{En bases EPE, el motivo segun `homologacion_estado`:
#'       para `"sin_homologacion"`, `multiples_destinos`,
#'       `discrepancia_fuente`, `ocupacion_no_especificada` o
#'       `codigo_no_encontrado`; para `"sin_codigo"`, `sin_codigo` o
#'       `formato_invalido`. En los demas casos, `NA`.}
#'     \item{n, pct_n}{Observaciones y porcentaje dentro del grupo.}
#'     \item{poblacion, pct_poblacion}{Poblacion expandida y porcentaje dentro
#'       del grupo (`NA` si no hay factor de expansion).}
#'   }
#'
#' @export
#'
#' @examples
#' muestra <- suppressWarnings(ia_exposicion(cno(muestra_epen_2024)))
#' cobertura(muestra)
cobertura <- function(data, por = NULL, var_peso = NULL) {
  if (!"ia_cobertura" %in% names(data)) {
    cli::cli_abort(c(
      "Falta la columna {.field ia_cobertura}.",
      "i" = "Aplica {.fn cno} e {.fn ia_exposicion} antes de {.fn cobertura}."
    ))
  }

  if (is.null(por)) {
    if (!"source" %in% names(data) && "clasificador" %in% names(data)) {
      data$encuesta <- ifelse(data$clasificador == "CO_95", "EPE", "EPEN")
    }
    por <- .por_defecto(data)
  }
  faltantes <- setdiff(por, names(data))
  if (length(faltantes) > 0) {
    cli::cli_abort("Variables de agrupacion inexistentes: {.val {faltantes}}.")
  }

  var_peso <- var_peso %||% .detectar_var(data, c("weight", "FACTOR07", "FACTOR", "fexp"))
  peso <- if (is.null(var_peso)) rep(NA_real_, nrow(data)) else as.numeric(data[[var_peso]])
  if (is.null(var_peso)) {
    cli::cli_inform(c("i" = "Sin factor de expansion: solo se reportan observaciones."))
  } else if (anyNA(peso)) {
    cli::cli_warn("{sum(is.na(peso))} fila(s) con {.field {var_peso}} NA no suman poblacion.")
  }

  detalle <- rep(NA_character_, nrow(data))
  if ("homologacion_estado" %in% names(data)) {
    con_detalle <- data$ia_cobertura %in% c("sin_homologacion", "sin_codigo")
    detalle[con_detalle] <- data$homologacion_estado[con_detalle]
  }

  base <- data.frame(
    data[, por, drop = FALSE],
    estado  = data$ia_cobertura,
    detalle = detalle,
    .peso   = peso,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  grupo <- if (length(por) > 0) interaction(base[por], drop = TRUE, lex.order = TRUE) else factor(rep(1, nrow(base)))

  resultado <- do.call(rbind, lapply(split(base, grupo), .resumir_grupo,
                                     por = por, con_peso = !is.null(var_peso)))

  orden_estado <- c("con_score", "sin_score", "codigo_no_encontrado", "sin_homologacion", "sin_codigo")
  claves <- c(as.list(resultado[por]), list(match(resultado$estado, orden_estado), resultado$detalle))
  resultado <- resultado[do.call(order, claves), , drop = FALSE]
  rownames(resultado) <- NULL
  resultado
}


# Helpers internos --------------------------------------------------------

#' @noRd
.por_defecto <- function(data) {
  por <- c(
    intersect(c("source", "encuesta"), names(data))[1],
    .buscar_nombre(names(data), .vars_year)
  )
  por[!is.na(por)]
}

#' @noRd
.resumir_grupo <- function(g, por, con_peso) {
  total_n   <- nrow(g)
  total_pob <- sum(g$.peso, na.rm = TRUE)
  celdas <- split(g, list(g$estado, ifelse(is.na(g$detalle), "", g$detalle)), drop = TRUE)
  do.call(rbind, lapply(celdas, function(cel) {
    pob <- sum(cel$.peso, na.rm = TRUE)
    data.frame(
      cel[1, por, drop = FALSE],
      estado        = cel$estado[1],
      detalle       = cel$detalle[1],
      n             = nrow(cel),
      pct_n         = round(100 * nrow(cel) / total_n, 2),
      poblacion     = if (con_peso) pob else NA_real_,
      pct_poblacion = if (con_peso && total_pob > 0) round(100 * pob / total_pob, 2) else NA_real_,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }))
}
