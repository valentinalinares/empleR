#' Calcular indicadores del mercado laboral con diseno muestral
#'
#' Calcula indicadores laborales de la poblacion ocupada incorporando el
#' diseno muestral complejo de la EPEN mediante el paquete \pkg{survey}. Si la
#' base contiene `OCUP300` o `labor_status_code`, conserva de forma explicita
#' el codigo de ocupado. Si no contiene una variable de condicion de actividad,
#' supone que las filas recibidas ya corresponden a personas ocupadas.
#'
#' Para obtener tasas de desempleo, actividad y empleo a nivel nacional o
#' regional, usa [resumen_nacional()], que devuelve los indicadores
#' pre-calculados del pipeline INEI con la muestra completa de la PEA.
#'
#' @param data `data.frame` con microdatos de EPEN (output de [descargar()]).
#' @param indicador Nombre del indicador a calcular:
#'   - `"ingreso_promedio"`: ingreso mensual medio proveniente del trabajo,
#'     sumando ocupaciones principal y secundaria e ingresos extraordinarios.
#'   - `"horas_promedio"`: total medio de horas trabajadas en la semana en
#'     todas las ocupaciones.
#'   - `"ingreso_mediano"`: mediana del mismo ingreso mensual.
#' @param por Variable(s) de agrupacion: `"sex"`, `"region_code"`,
#'   `"education_code"`, `"institutional_sector_code"`, etc. `NULL` = nacional.
#' @param var_strata Nombre de la variable de estrato. Detecta automaticamente
#'   `strata_code` (datos procesados) o `ESTRATO` (datos crudos INEI).
#' @param var_psu Nombre de la variable PSU. Detecta automaticamente
#'   `cluster_id` (datos procesados) o `CONGLOMERADO`/`CONGLOME` (datos crudos
#'   INEI). Si se detecta y la base trae tambien la muestra (`sample_id` o
#'   `MUESTRA`) y la region (`region_code` o `CCDD`), la UPM se forma con las
#'   tres: los numeros de conglomerado se repiten entre departamentos y
#'   muestras, asi que el conglomerado solo no identifica una UPM.
#' @param var_peso Nombre del factor de expansion. Si existe un solo candidato,
#'   lo detecta automaticamente. Si encuentra mas de uno (por ejemplo,
#'   `FAC_T300` y `FAC300_ANUAL`), exige elegirlo de forma explicita.
#' @param var_estado Nombre de la variable de condicion de actividad. Detecta
#'   `labor_status_code` o `OCUP300`. `NULL` permite la deteccion automatica.
#' @param codigo_ocupado Codigo que identifica a las personas ocupadas en
#'   `var_estado`. En la EPEN es `"1"`.
#' @param var_indicador Nombre de la variable numerica que se desea resumir.
#'   Normalmente no hace falta indicarla: para ingreso se usan
#'   `labor_income_work_weighted` o `ingtrabw`, y para horas
#'   `hours_week_total` o `whoraT`. Sirve para solicitar expresamente otro
#'   concepto, como el ingreso o las horas de la ocupacion principal.
#'
#' @return Un `data.frame` con el indicador calculado, el error estandar
#'   provisional y columnas de auditoria: `n_universo`, `n_estimacion`,
#'   `n_sin_peso`, `n_peso_invalido`, `n_sin_indicador`,
#'   `n_indicador_invalido`, `n_fuera_definicion` y
#'   `poblacion_representada`. Los conteos de problemas no son mutuamente
#'   excluyentes.
#'
#' @section Definiciones y tratamiento de faltantes:
#' Los indicadores de ingreso excluyen valores iguales o menores que cero.
#' Esta regla reproduce el ingreso medio oficial de la EPEN, que resume las
#' remuneraciones positivas de trabajadores dependientes e independientes. Las
#' horas incluyen ceros validos. En todos los indicadores se excluyen del
#' calculo los pesos ausentes, no numericos, no finitos o no positivos, y los
#' valores del indicador ausentes, no numericos o no finitos. La salida informa
#' cuantos casos se excluyeron por cada motivo.
#'
#' La mediana usa la regla matematica de [survey::svyquantile()]: el extremo
#' inferior del intervalo donde la funcion de distribucion ponderada alcanza
#' 0.5 (`qrule = "math"`).
#'
#' @section Diseno muestral provisional:
#' Las fichas EPEN describen un diseno probabilistico, estratificado, de areas
#' y bietapico, independiente en cada departamento. La UPM implementada combina
#' muestra, region y conglomerado porque los numeros de conglomerado se
#' reutilizan entre departamentos. El estrato que se usa es `ESTRATO`
#' (`strata_code`), tal como lo publica el INEI.
#'
#' La documentacion publica localizada no especifica la combinacion operativa
#' completa del estrato de varianza, el tratamiento de las visitas panel, las
#' UPM de inclusion forzosa ni las etapas finales de calibracion de
#' `FAC300_ANUAL`. Tampoco explica el tratamiento oficial de filas sin factor,
#' que esta funcion excluye con aviso. Los errores estandar son, por tanto,
#' aproximaciones reproducibles basadas en el diseno publico y no deben
#' presentarse como errores oficiales del INEI.
#'
#' @references
#' INEI. Ficha tecnica EPEN 2024.
#' <https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Ficha_Tecnica.pdf>
#'
#' INEI. Diccionario EPEN 2024.
#' <https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Diccionario.pdf>
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
#' # Ingreso por ambito departamental EPEN; Lima requiere su division
#' indicadores(
#'   epen_2024,
#'   "ingreso_promedio",
#'   por = c("region_code", "division_lima")
#' )
#'
#' # Horas trabajadas por sector institucional
#' indicadores(epen_2024, "horas_promedio", por = "institutional_sector_code")
#' }
indicadores <- function(data,
                        indicador,
                        por        = NULL,
                        var_strata = NULL,
                        var_psu    = NULL,
                        var_peso   = NULL,
                        var_estado = NULL,
                        codigo_ocupado = "1",
                        var_indicador = NULL) {

  indicadores_validos <- c("ingreso_promedio", "horas_promedio", "ingreso_mediano")

  if (!indicador %in% indicadores_validos) {
    cli::cli_abort(c(
      "'{indicador}' no es un indicador valido.",
      "i" = "Opciones: {.val {indicadores_validos}}",
      "i" = "Para tasas de desempleo/actividad usa {.fn resumen_nacional}."
    ))
  }

  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} debe ser un data.frame.")
  }
  if (nrow(data) == 0L) {
    cli::cli_abort("{.arg data} no contiene filas.")
  }
  if (!is.null(por)) {
    faltan_por <- setdiff(por, names(data))
    if (length(faltan_por) > 0L) {
      cli::cli_abort(c(
        "No se encontraron todas las variables de agrupacion.",
        "x" = "Faltan: {.field {faltan_por}}."
      ))
    }
  }

  # Detectar variables de diseno muestral y exigir una eleccion cuando hay
  # mas de un factor compatible con periodos distintos.
  var_strata <- var_strata %||% .detectar_var(data, c("strata_code", "ESTRATO", "estrato"))
  psu_detectada <- is.null(var_psu)
  var_psu    <- var_psu    %||% .detectar_var(data, c("cluster_id", "CONGLOMERADO", "CONGLOME", "conglome"))
  candidatos_peso <- intersect(
    c("weight", "FAC300_ANUAL", "FAC_T300", "FACTOR07", "FACTOR", "fexp"),
    names(data)
  )
  if (is.null(var_peso) && length(candidatos_peso) > 1L) {
    cli::cli_abort(c(
      "Se encontraron varios factores de expansion.",
      "x" = "Candidatos: {.field {candidatos_peso}}.",
      "i" = "Elige el que corresponde al periodo con {.arg var_peso}."
    ))
  }
  var_peso <- var_peso %||% candidatos_peso[1]

  if (is.null(var_peso) || length(var_peso) == 0L || is.na(var_peso)) {
    cli::cli_abort(c(
      "No se encontro variable de factor de expansion (peso).",
      "i" = "Especificala con {.arg var_peso}."
    ))
  }
  if (!var_peso %in% names(data)) {
    cli::cli_abort("La variable de peso {.field {var_peso}} no existe en {.arg data}.")
  }

  # Universo: todos los indicadores admitidos se definen para ocupados.
  var_estado <- var_estado %||% .detectar_var(
    data,
    c("labor_status_code", "OCUP300")
  )
  n_entrada <- nrow(data)
  if (!is.null(var_estado)) {
    if (!var_estado %in% names(data)) {
      cli::cli_abort(
        "La variable de condicion {.field {var_estado}} no existe en {.arg data}."
      )
    }
    estado <- trimws(as.character(data[[var_estado]]))
    es_ocupado <- !is.na(estado) & estado == as.character(codigo_ocupado)
    data <- data[es_ocupado, , drop = FALSE]
    if (nrow(data) == 0L) {
      cli::cli_abort(c(
        "No quedaron personas ocupadas.",
        "i" = "Se uso {.field {var_estado}} == {.val {codigo_ocupado}}."
      ))
    }
    if (nrow(data) < n_entrada) {
      cli::cli_inform(
        "Se conservaron {nrow(data)} de {n_entrada} filas del universo ocupado."
      )
    }
  }

  # Variable objetivo. Los nombres por defecto corresponden a las definiciones
  # publicadas por el INEI, no solo a la ocupacion principal.
  if (is.null(var_indicador)) {
    candidatos_indicador <- switch(indicador,
      ingreso_promedio = c("labor_income_work_weighted", "ingtrabw"),
      ingreso_mediano = c("labor_income_work_weighted", "ingtrabw"),
      horas_promedio = c("hours_week_total", "whoraT")
    )
    var_indicador <- .detectar_var(data, candidatos_indicador)
  }
  if (is.null(var_indicador)) {
    cli::cli_abort(c(
      "No se encontro la variable necesaria para {.val {indicador}}.",
      "i" = "Indicala expresamente con {.arg var_indicador}.",
      "i" = paste0(
        "No se sustituye automaticamente por una variable de la ocupacion ",
        "principal porque mide otro concepto."
      )
    ))
  }
  if (!var_indicador %in% names(data)) {
    cli::cli_abort(
      "La variable del indicador {.field {var_indicador}} no existe en {.arg data}."
    )
  }

  peso <- .normalizar_numero(data[[var_peso]])
  valor <- .normalizar_numero(data[[var_indicador]])
  data$.peso <- peso$valor
  data$.valor <- valor$valor
  data$.peso_faltante <- peso$falta
  data$.peso_invalido <- peso$invalido | (!peso$falta & peso$valor <= 0)
  data$.indicador_faltante <- valor$falta
  data$.indicador_invalido <- valor$invalido
  data$.fuera_definicion <- FALSE
  if (indicador %in% c("ingreso_promedio", "ingreso_mediano")) {
    data$.fuera_definicion <- !valor$falta & !valor$invalido & valor$valor <= 0
  }
  data$.peso_valido <- !data$.peso_faltante & !data$.peso_invalido
  data$.valor_valido <- !data$.indicador_faltante &
    !data$.indicador_invalido & !data$.fuera_definicion
  data$.usar_indicador <- data$.peso_valido & data$.valor_valido

  auditoria <- .resumir_auditoria_indicadores(data, por)
  if (!any(data$.usar_indicador)) {
    cli::cli_abort("No quedaron observaciones validas para calcular el indicador.")
  }

  n_peso_excluido <- sum(!data$.peso_valido)
  if (n_peso_excluido > 0L) {
    cli::cli_warn(
      "{n_peso_excluido} filas no participan por peso ausente o invalido."
    )
  }
  n_valor_excluido <- sum(data$.peso_valido & !data$.valor_valido)
  if (n_valor_excluido > 0L) {
    cli::cli_warn(
      "{n_valor_excluido} filas con peso valido no participan por el valor del indicador."
    )
  }

  # Solo los pesos validos entran al diseno. El indicador se estima como un
  # dominio para conservar la estructura muestral de las demas filas ocupadas.
  data_diseno <- data[data$.peso_valido, , drop = FALSE]

  # Un identificador de diseno incompleto impide construir svydesign(). No se
  # eliminan personas ni se inventan codigos: se conserva el estimador puntual
  # con un diseno simplificado y se deja la advertencia para la fase inferencial.
  .es_util <- function(v, data) {
    if (is.null(v) || !v %in% names(data)) return(FALSE)
    x <- data[[v]]
    !any(is.na(x) | trimws(as.character(x)) == "")
  }
  if (!.es_util(var_strata, data_diseno)) {
    if (!is.null(var_strata)) {
      cli::cli_warn(
        "{.field {var_strata}} esta incompleta; no se usara para el error estandar."
      )
    }
    var_strata <- NULL
  }
  if (!.es_util(var_psu, data_diseno)) {
    if (!is.null(var_psu)) {
      cli::cli_warn(
        "{.field {var_psu}} esta incompleta; no se usara para el error estandar."
      )
    }
    var_psu <- NULL
  }

  # UPM compuesta: muestra + region + conglomerado
  if (psu_detectada && !is.null(var_psu)) {
    data_diseno <- .upm_compuesta(data_diseno, var_psu)
    if (".upm" %in% names(data_diseno)) var_psu <- ".upm"
  }

  # Construir diseno muestral
  if (!is.null(var_strata) && !is.null(var_psu)) {
    cli::cli_inform(
      c("i" = paste0(
        "Diseno muestral provisional: estrato {.field {var_strata}} y UPM ",
        "{.field {var_psu}}; ver {.code ?indicadores}."
      )),
      .frequency = "once", .frequency_id = "empleR_diseno_provisional"
    )
    diseno <- survey::svydesign(
      ids     = stats::reformulate(var_psu),
      strata  = stats::reformulate(var_strata),
      weights = ~.peso,
      data    = data_diseno,
      nest    = TRUE
    )
  } else {
    # Diseno sin estratificacion ni PSU (menos preciso, pero funcional)
    cli::cli_warn("Diseno muestral simplificado: no se encontraron strata/PSU.")
    diseno <- survey::svydesign(
      ids     = ~1,
      weights = ~.peso,
      data    = data_diseno
    )
  }
  diseno <- diseno[data_diseno$.usar_indicador, ]
  formula_var <- ~.valor

  # Calcular y devolver data.frame limpio con columnas: estimado, error_std
  if (is.null(por)) {
    if (indicador == "ingreso_mediano") {
      res <- survey::svyquantile(
        formula_var, diseno, quantiles = 0.5, na.rm = TRUE, qrule = "math"
      )
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
    formula_por <- stats::reformulate(por)
    if (indicador == "ingreso_mediano") {
      res <- survey::svyby(formula_var, by = formula_por, design = diseno,
                           FUN = survey::svyquantile, quantiles = 0.5,
                           na.rm = TRUE, qrule = "math")
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

  if (is.null(por)) {
    resultado <- dplyr::bind_cols(resultado, auditoria)
  } else {
    resultado <- dplyr::left_join(resultado, auditoria, by = por)
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
.upm_compuesta <- function(data, var_psu) {
  var_muestra <- .detectar_var(data, c("sample_id", "MUESTRA"))
  var_region  <- .detectar_var(data, c("region_code", "CCDD"))
  if (is.null(var_muestra) || is.null(var_region)) return(data)
  data$.upm <- paste(data[[var_muestra]], data[[var_region]], data[[var_psu]], sep = "|")
  data
}

#' @noRd
.detectar_var <- function(data, candidatos) {
  encontrada <- intersect(candidatos, names(data))
  if (length(encontrada) == 0) return(NULL)
  encontrada[1]
}

#' @noRd
.normalizar_numero <- function(x) {
  texto <- trimws(as.character(x))
  falta <- is.na(x) | texto %in% c("", "NA", "N/A")
  valor <- suppressWarnings(as.numeric(texto))
  invalido <- !falta & (is.na(valor) | !is.finite(valor))
  valor[falta | invalido] <- NA_real_
  list(valor = valor, falta = falta, invalido = invalido)
}

#' @noRd
.resumir_auditoria_indicadores <- function(data, por = NULL) {
  resumir <- function(x) {
    dplyr::summarise(
      x,
      n_universo = dplyr::n(),
      n_estimacion = sum(.data$.usar_indicador),
      n_sin_peso = sum(.data$.peso_faltante),
      n_peso_invalido = sum(.data$.peso_invalido),
      n_sin_indicador = sum(.data$.indicador_faltante),
      n_indicador_invalido = sum(.data$.indicador_invalido),
      n_fuera_definicion = sum(.data$.fuera_definicion),
      poblacion_representada = sum(
        ifelse(.data$.usar_indicador, .data$.peso, 0),
        na.rm = TRUE
      )
    )
  }
  if (is.null(por)) {
    return(resumir(data))
  }
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(por))) |>
    resumir() |>
    dplyr::ungroup()
}
