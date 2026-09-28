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
#' @section Bases EPE (CO-95):
#' El indice esta definido en CNO 2015 a 4 digitos. En bases EPE se usa
#' `cno_homologado` (de `cno(homologar = TRUE)`): solo las ocupaciones con
#' equivalencia unica reciben score. Las ambiguas quedan en `NA` con
#' `ia_cobertura = "sin_homologacion"`; nunca se cruza un codigo CO-95 ni un
#' codigo agregado (1-3 digitos) con el indice. En una base que une EPE y
#' EPEN (con la columna `clasificador` de [cno()]) cada fila usa su codigo.
#'
#' @param data `data.frame` con microdatos de EPEN/EPE procesados con [cno()].
#' @param var_cno Variable con el codigo CNO 2015 de 4 digitos. Si es `NULL`
#'   (por defecto) se elige por fila segun la columna `clasificador`:
#'   `cno_cod` para CNO 2015 y `cno_homologado` para CO-95.
#' @param score Que score agregar. Opciones:
#'   - `"mean"` (por defecto): score medio de exposicion por ocupacion.
#'   - `"median"`: score mediano.
#'   - `"ambos"`: agrega tanto media como mediana.
#' @param incluir_tipo Logico. Si `TRUE`, agrega el tipo de impacto
#'   predominante y los conteos de tareas por tipo. Por defecto `FALSE`.
#'
#' @return El mismo `data.frame` (mismas filas y orden) con columnas adicionales:
#'   \describe{
#'     \item{ia_cno}{Codigo CNO 2015 usado para el cruce.}
#'     \item{ia_score_mean}{Score medio de exposicion a IA (0-1).}
#'     \item{ia_score_median}{Score mediano (si `score` es `"median"` o `"ambos"`).}
#'     \item{ia_cobertura}{`"con_score"`, `"sin_score"` (codigo CNO valido
#'       sin score en el indice), `"codigo_no_encontrado"` (4 digitos que no
#'       existen en el CNO 2015), `"sin_homologacion"` (CO-95 sin
#'       equivalencia unica) o `"sin_codigo"`.}
#'     \item{ia_tipo}{Tipo de impacto con mas tareas (`A`, `S` o `N`); `NA`
#'       si hay empate, si la ocupacion no tiene tareas o no esta en el indice.}
#'     \item{ia_empate}{`TRUE` si dos o mas tipos empatan en el maximo;
#'       `NA` si no hay tareas o indice.}
#'     \item{ia_tipo_estado}{`"predominante"`, `"empate"`, `"sin_tareas"` o
#'       `"sin_indice"`.}
#'     \item{ia_total_tareas, tipo_A_aumento, tipo_S_sustitucion, tipo_N_nulo}{
#'       Conteos de tareas del indice.}
#'   }
#'   Las ultimas cuatro filas solo se agregan con `incluir_tipo = TRUE`.
#'
#' @seealso [cobertura()] para resumir la cobertura por encuesta y ano.
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
#' # Ingreso promedio segun tipo de impacto predominante (con diseno muestral)
#' indicadores(epen_2024, "ingreso_promedio", por = "ia_tipo")
#'
#' # Base EPE: el cruce usa cno_homologado automaticamente
#' epe_2019 <- cno(readRDS("epe_2019.rds"), homologar = TRUE) |>
#'   ia_exposicion()
#' cobertura(epe_2019)
#' }
ia_exposicion <- function(data,
                          var_cno = NULL,
                          score = "mean",
                          incluir_tipo = FALSE) {

  score <- match.arg(score, c("mean", "median", "ambos"))

  codigo <- .codigo_para_indice(data, var_cno)
  .validar_codigo_cno4(codigo)

  j <- match(codigo, indice_ia$code)
  data$ia_cno <- codigo
  if (score %in% c("mean", "ambos")) {
    data$ia_score_mean <- indice_ia$mean_exposure_score[j]
  }
  if (score %in% c("median", "ambos")) {
    data$ia_score_median <- indice_ia$median_exposure_score[j]
  }
  data$ia_cobertura <- .estado_cobertura(data, codigo, j)

  if (incluir_tipo) {
    data$ia_total_tareas    <- indice_ia$total_tasks[j]
    data$tipo_A_aumento     <- indice_ia$tipo_A_aumento[j]
    data$tipo_S_sustitucion <- indice_ia$tipo_S_sustitucion[j]
    data$tipo_N_nulo        <- indice_ia$tipo_N_nulo[j]
    tipo <- .tipo_predominante(
      data$tipo_A_aumento, data$tipo_S_sustitucion, data$tipo_N_nulo,
      total = data$ia_total_tareas
    )
    data$ia_tipo        <- tipo$tipo
    data$ia_empate      <- tipo$empate
    data$ia_tipo_estado <- tipo$estado
  }

  .informar_cobertura(data$ia_cobertura)
  data
}


# Helpers internos --------------------------------------------------------

#' @noRd
.codigo_para_indice <- function(data, var_cno) {
  clas <- if ("clasificador" %in% names(data)) data$clasificador else NULL
  es_co95 <- if (is.null(clas)) rep(FALSE, nrow(data)) else clas %in% "CO_95"

  if (!is.null(var_cno)) return(.codigo_explicito(data, var_cno, es_co95))

  if (is.null(clas)) {
    if (!"cno_cod" %in% names(data)) {
      cli::cli_abort(c(
        "No se encontraron codigos ocupacionales.",
        "i" = "Primero aplica {.fn cno} para generar los codigos ocupacionales."
      ))
    }
    return(as.character(data$cno_cod))
  }

  if (any(es_co95) && !"cno_homologado" %in% names(data)) {
    cli::cli_abort(c(
      "La base tiene codigos CO-95 (EPE) sin homologar.",
      "i" = "Aplica {.code cno(homologar = TRUE)} antes de {.fn ia_exposicion}."
    ))
  }
  codigo <- as.character(data$cno_cod)
  if (any(es_co95)) codigo[es_co95] <- as.character(data$cno_homologado[es_co95])
  codigo
}

#' @noRd
.codigo_explicito <- function(data, var_cno, es_co95) {
  if (!var_cno %in% names(data)) {
    cli::cli_abort(c(
      "La variable '{var_cno}' no existe en los datos.",
      "i" = "Primero aplica {.fn cno} para generar los codigos ocupacionales."
    ))
  }
  if (any(es_co95) && var_cno == "cno_cod") {
    cli::cli_abort(c(
      "{.field cno_cod} contiene codigos CO-95 en {sum(es_co95)} fila(s).",
      "i" = "El indice usa CNO 2015: aplica {.code cno(homologar = TRUE)} y usa {.field cno_homologado}."
    ))
  }
  as.character(data[[var_cno]])
}

#' @noRd
.validar_codigo_cno4 <- function(codigo) {
  invalidos <- unique(codigo[!is.na(codigo) & !grepl("^[0-9]{4}$", codigo)])
  if (length(invalidos) > 0) {
    cli::cli_abort(c(
      "El indice de IA solo se cruza con codigos CNO 2015 de 4 digitos.",
      "x" = "Codigos invalidos: {.val {utils::head(invalidos, 5)}}{if (length(invalidos) > 5) ', ...' else ''}",
      "i" = "Usa {.code cno(agregar = \"4d\")}; los codigos agregados o CO-95 no son validos."
    ))
  }
  invisible(codigo)
}

#' @noRd
.estado_cobertura <- function(data, codigo, j) {
  estado <- ifelse(!is.na(j), "con_score", "sin_score")
  en_catalogo <- codigo %in% cno_2015$codigo[cno_2015$nivel == 4]
  estado[is.na(j) & !en_catalogo] <- "codigo_no_encontrado"
  sin_cod <- is.na(codigo)
  estado[sin_cod] <- "sin_codigo"
  if ("homologacion_estado" %in% names(data) && "clasificador" %in% names(data)) {
    es_co95 <- data$clasificador %in% "CO_95"
    sin_hom <- es_co95 & sin_cod &
      !data$homologacion_estado %in% c("sin_codigo", "formato_invalido")
    estado[sin_hom] <- "sin_homologacion"
  }
  estado
}

#' @noRd
.informar_cobertura <- function(estado) {
  n <- length(estado)
  if (n == 0) return(invisible())
  cuenta <- function(x) sum(estado == x)
  pct <- function(x) round(100 * cuenta(x) / n, 1)
  msgs <- c("i" = "Filas con score de IA: {cuenta('con_score')} ({pct('con_score')}%).")
  if (cuenta("sin_homologacion") > 0) {
    msgs <- c(msgs, "!" = paste0(
      "{cuenta('sin_homologacion')} ({pct('sin_homologacion')}%) sin equivalencia ",
      "CO-95 -> CNO 2015 unica."
    ))
  }
  if (cuenta("sin_score") > 0) {
    msgs <- c(msgs, "!" = "{cuenta('sin_score')} ({pct('sin_score')}%) con codigo CNO sin score en el indice.")
  }
  if (cuenta("codigo_no_encontrado") > 0) {
    msgs <- c(msgs, "!" = paste0(
      "{cuenta('codigo_no_encontrado')} ({pct('codigo_no_encontrado')}%) con codigo ",
      "de 4 digitos que no existe en el CNO 2015."
    ))
  }
  if (cuenta("sin_codigo") > 0) {
    msgs <- c(msgs, "!" = "{cuenta('sin_codigo')} ({pct('sin_codigo')}%) sin codigo ocupacional.")
  }
  msgs <- c(msgs, "i" = "Resumen por encuesta y ano: {.fn cobertura}.")
  if (cuenta("con_score") < n) cli::cli_warn(msgs) else cli::cli_inform(msgs)
}

#' @noRd
.tipo_predominante <- function(n_a, n_s, n_n, total = NULL) {
  conteos <- cbind(A = n_a, S = n_s, N = n_n)
  n <- nrow(conteos)
  tipo   <- rep(NA_character_, n)
  empate <- rep(NA, n)
  estado <- rep("sin_indice", n)

  en_indice <- stats::complete.cases(conteos)
  sin_tareas <- en_indice & rowSums(conteos) == 0
  if (!is.null(total)) sin_tareas <- sin_tareas | (en_indice & (is.na(total) | total == 0))
  estado[sin_tareas] <- "sin_tareas"

  ok <- en_indice & !sin_tareas
  if (any(ok)) {
    sub <- conteos[ok, , drop = FALSE]
    maximo <- apply(sub, 1, max)
    n_max <- rowSums(sub == maximo)
    es_empate <- n_max > 1
    ganador <- colnames(sub)[max.col(sub, ties.method = "first")]
    tipo[ok]   <- ifelse(es_empate, NA_character_, ganador)
    empate[ok] <- es_empate
    estado[ok] <- ifelse(es_empate, "empate", "predominante")
  }
  list(tipo = tipo, empate = empate, estado = estado)
}
