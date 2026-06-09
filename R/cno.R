#' Armonizar codigos ocupacionales entre CNO 2015 y CO-95
#'
#' Esta funcion resuelve la **ruptura de clasificadores** entre la EPE (hasta
#' 2021, usa CO-95 de 3 digitos, basado en CIUO-88) y la EPEN (desde 2022,
#' usa CNO 2015 de 4 digitos, basado en CIUO-08). Detecta automaticamente el
#' clasificador correcto segun el ano de la base y, opcionalmente, aplica la
#' tabla de equivalencias para construir series comparables.
#'
#' La variable ocupacional en EPEN es `C308_COD`; en ENAHO es `P505R4`.
#' En EPE (Lima historica) la variable puede diferir segun el ano.
#'
#' @param data `data.frame` con microdatos de EPEN/EPE.
#' @param var_ocup Nombre de la variable de codigo ocupacional.
#'   Por defecto se detecta automaticamente (`C308_COD` para EPEN,
#'   segun el ano de la base).
#' @param homologar Logico. Si `TRUE`, aplica la tabla de equivalencias
#'   CO-95 <-> CNO 2015 para bases EPE pre-2022 y devuelve la columna
#'   adicional `cno_homologado`. Por defecto `FALSE`.
#' @param agregar Nivel de agregacion del CNO al que reducir los codigos.
#'   Opciones: `"4d"` (4 digitos, por defecto), `"3d"`, `"2d"`, `"1d"`.
#'   Para bases EPE (CO-95), el maximo disponible es `"3d"`.
#'
#' @return El mismo `data.frame` con columnas adicionales:
#'   \describe{
#'     \item{clasificador}{El clasificador detectado: `"CNO_2015"` o `"CO_95"`.}
#'     \item{cno_cod}{Codigo ocupacional estandarizado al nivel solicitado.}
#'     \item{cno_desc}{Descripcion de la ocupacion (del diccionario interno).}
#'     \item{cno_homologado}{(Solo si `homologar = TRUE`) Codigo CNO 2015
#'       equivalente para bases CO-95.}
#'   }
#'
#' @export
#'
#' @examples
#' # Con la muestra incluida en el paquete
#' cno(muestra_epen_2024)
#'
#' \dontrun{
#' epen_2024 <- descargar(year = 2024)
#'
#' # Agregar descripcion CNO al nivel de 4 digitos
#' epen_2024 <- cno(epen_2024)
#'
#' # Agregar descripcion CNO al nivel de 2 digitos (subgrupos principales)
#' epen_2024 <- cno(epen_2024, agregar = "2d")
#'
#' # Homologar base EPE 2019 a CNO 2015 para comparar con EPEN 2024
#' epe_2019  <- descargar(year = 2019)
#' epen_2024 <- descargar(year = 2024)
#'
#' epe_2019  <- cno(epe_2019,  homologar = TRUE)
#' epen_2024 <- cno(epen_2024, homologar = TRUE)
#' # Ahora ambas bases tienen cno_homologado comparable
#' }
cno <- function(data,
                var_ocup = NULL,
                homologar = FALSE,
                agregar = "4d") {

  # Detectar ano y clasificador
  year <- .detectar_year(data)
  clasificador <- .detectar_clasificador(year)

  cli::cli_inform(c(
    "i" = "Ano detectado: {year}",
    "i" = "Clasificador: {clasificador}"
  ))

  # Detectar variable ocupacional si no se especifica
  if (is.null(var_ocup)) {
    var_ocup <- .detectar_var_ocup(data, clasificador)
  }

  if (!var_ocup %in% names(data)) {
    cli::cli_abort(c(
      "La variable '{var_ocup}' no existe en los datos.",
      "i" = "Especifica el nombre correcto con el argumento {.arg var_ocup}."
    ))
  }

  # Agregar columna de clasificador detectado
  data$clasificador <- clasificador

  # Cargar diccionario segun clasificador
  dicc_ocup <- if (clasificador == "CNO_2015") cno_2015 else co_1995

  # Reducir a nivel de agregacion solicitado
  data$cno_cod <- .agregar_codigo(data[[var_ocup]],
                                  agregar = agregar,
                                  clasificador = clasificador)

  # Unir descripcion
  data <- dplyr::left_join(
    data,
    dicc_ocup[, c("codigo", "descripcion")],
    by = c("cno_cod" = "codigo")
  )
  data <- dplyr::rename(data, cno_desc = "descripcion")

  # Homologar CO-95 -> CNO 2015 si se pide
  if (homologar && clasificador == "CO_95") {
    data <- dplyr::left_join(
      data,
      equivalencia_cno[, c("co_95", "cno_2015")],
      by = c("cno_cod" = "co_95")
    )
    data <- dplyr::rename(data, cno_homologado = "cno_2015")
    cli::cli_inform(c(
      "v" = "Columna {.field cno_homologado} agregada con equivalencias CNO 2015."
    ))
  } else if (homologar && clasificador == "CNO_2015") {
    cli::cli_warn(
      "La base ya usa CNO 2015. {.arg homologar} no tiene efecto."
    )
  }

  data
}


# Helpers internos --------------------------------------------------------

#' @noRd
.detectar_clasificador <- function(year) {
  # EPEN (2022+): CNO 2015 (4 digitos, CIUO-08)
  # EPE (hasta 2021): CO-95 (3 digitos, CIUO-88)
  if (year >= 2022) "CNO_2015" else "CO_95"
}

#' @noRd
.detectar_var_ocup <- function(data, clasificador) {
  # Variables candidatas segun clasificador y fuente de datos
  # EPEN procesada: occupation_code_4d (ya estandarizada a 4 digitos)
  # EPEN cruda INEI: C308_COD
  # ENAHO procesada: occupation_code_4d o P505R4
  if (clasificador == "CNO_2015") {
    candidatos <- c("occupation_code_4d", "C308_COD", "P505R4", "cod_ocup")
  } else {
    candidatos <- c("occupation_code_4d", "occupation_code_raw", "P505R3", "cod_ocup")
  }
  encontrada <- intersect(candidatos, names(data))
  if (length(encontrada) == 0) {
    cli::cli_abort(c(
      "No se pudo detectar la variable de codigo ocupacional.",
      "i" = "Especificala con el argumento {.arg var_ocup}."
    ))
  }
  encontrada[1]
}

#' @noRd
.agregar_codigo <- function(x, agregar, clasificador) {
  digitos <- as.integer(substr(agregar, 1, 1))
  max_dig  <- if (clasificador == "CNO_2015") 4L else 3L
  if (digitos > max_dig) {
    cli::cli_warn(
      "El clasificador {clasificador} solo tiene hasta {max_dig} digitos. \\
       Usando {max_dig}d."
    )
    digitos <- max_dig
  }
  substr(as.character(x), 1, digitos)
}
