#' Armonizar codigos ocupacionales entre CNO 2015 y CO-95
#'
#' Esta funcion resuelve la **ruptura de clasificadores** entre la EPE (hasta
#' 2021, usa CO-95 de 3 digitos, basado en CIUO-88) y la EPEN (desde 2022,
#' usa CNO 2015 de 4 digitos, basado en CIUO-08). Detecta automaticamente el
#' clasificador correcto segun el ano de la base y, opcionalmente, aplica la
#' tabla de equivalencias para construir series comparables.
#'
#' La variable ocupacional en EPEN es `C308_COD`; en EPE es `P204A`
#' (`p204a`); en ENAHO es `P505R4`.
#'
#' La homologacion CO-95 -> CNO 2015 usa la tabla de correspondencia oficial
#' del INEI (ver [co_1995]). Solo se asigna un codigo CNO 2015 cuando la
#' equivalencia es **unica**: 125 codigos CO-95 tienen varios destinos (por
#' ejemplo, 262 "Economistas y planificadores" corresponde a CNO 2412 y 2631)
#' y en esos casos `cno_homologado` queda en `NA`. Elegir un candidato o
#' repartir los pesos requiere una decision metodologica explicita del
#' analista. Revisa siempre la cobertura con
#' `table(datos$homologacion_estado)` antes de comparar series.
#'
#' @param data `data.frame` con microdatos de EPEN/EPE.
#' @param var_ocup Nombre de la variable de codigo ocupacional.
#'   Por defecto se detecta automaticamente (`C308_COD` para EPEN,
#'   segun el ano de la base).
#' @param homologar Logico. Si `TRUE`, aplica la tabla de equivalencias
#'   CO-95 <-> CNO 2015 para bases EPE pre-2022 y devuelve la columna
#'   adicionales `cno_homologado`, `cno_candidatos`, `cno_gran_grupo` y
#'   `homologacion_estado`. Por defecto `FALSE`.
#' @param agregar Nivel de agregacion del CNO al que reducir los codigos.
#'   Opciones: `"4d"` (4 digitos, por defecto), `"3d"`, `"2d"`, `"1d"`.
#'   Para bases EPE (CO-95), el maximo disponible y el valor por defecto es
#'   `"3d"`. La homologacion siempre usa el codigo CO-95 completo.
#'
#' @return El mismo `data.frame` con columnas adicionales:
#'   \describe{
#'     \item{clasificador}{El clasificador detectado: `"CNO_2015"` o `"CO_95"`.}
#'     \item{cno_cod}{Codigo ocupacional estandarizado al nivel solicitado.}
#'     \item{cno_desc}{Descripcion de la ocupacion (del diccionario interno).}
#'     \item{cno_homologado}{(Solo si `homologar = TRUE`, bases CO-95) Codigo
#'       CNO 2015 de 4 digitos cuando la equivalencia es unica; `NA` si no.}
#'     \item{cno_candidatos}{Todos los codigos CNO 2015 posibles, separados
#'       por `"; "`.}
#'     \item{cno_gran_grupo}{Gran grupo CNO 2015 (1 digito) cuando todos los
#'       candidatos lo comparten; permite comparar a nivel agregado.}
#'     \item{homologacion_estado}{`"unica"`, `"multiples_destinos"`,
#'       `"discrepancia_fuente"`, `"ocupacion_no_especificada"`,
#'       `"codigo_no_encontrado"` o `"sin_codigo"`.}
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
#' # (descargar() aun no cubre EPE; leer la base EPE obtenida del INEI)
#' epe_2019 <- readRDS("epe_2019.rds")
#' epe_2019 <- cno(epe_2019, homologar = TRUE)
#' table(epe_2019$homologacion_estado)
#'
#' # Comparacion a nivel de gran grupo (mayor cobertura que 4 digitos)
#' epen_2024 <- cno(epen_2024, agregar = "1d")
#' # epe_2019$cno_gran_grupo es comparable con epen_2024$cno_cod
#' }
cno <- function(data,
                var_ocup = NULL,
                homologar = FALSE,
                agregar = "4d") {

  agregar_por_defecto <- missing(agregar)
  agregar <- match.arg(agregar, c("4d", "3d", "2d", "1d"))

  # Detectar ano y clasificador
  year <- .detectar_year(data)
  clasificador <- .detectar_clasificador(year)
  if (clasificador == "CO_95" && agregar_por_defecto) agregar <- "3d"

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

  # Diccionario de descripciones (una fila por codigo; match() conserva filas)
  if (clasificador == "CNO_2015") {
    dicc_cod  <- cno_2015$codigo
    dicc_desc <- cno_2015$descripcion
  } else {
    dicc_cod  <- co_1995$co95
    dicc_desc <- co_1995$nombre_co95
  }

  # Normalizar a codigo completo (ceros a la izquierda) y agregar al nivel pedido
  cod_completo <- .normalizar_codigo(data[[var_ocup]], clasificador)
  data$cno_cod <- .agregar_codigo(cod_completo,
                                  agregar = agregar,
                                  clasificador = clasificador)
  data$cno_desc <- dicc_desc[match(data$cno_cod, dicc_cod)]

  # Homologar CO-95 -> CNO 2015 si se pide
  if (homologar && clasificador == "CO_95") {
    data <- .homologar_co95(data, cod_completo)
  } else if (homologar && clasificador == "CNO_2015") {
    cli::cli_warn(
      "La base ya usa CNO 2015. {.arg homologar} no tiene efecto."
    )
  }

  data
}


# Helpers internos --------------------------------------------------------

#' @noRd
.homologar_co95 <- function(data, cod_co95) {
  # Se usa el catalogo co_1995 (una fila por codigo CO-95), nunca la tabla
  # larga equivalencia_co95: unir con ella replicaria personas y pesos.
  j <- match(cod_co95, co_1995$co95)
  data$cno_homologado      <- co_1995$cno2015_unico[j]
  data$cno_candidatos      <- co_1995$cno2015_candidatos[j]
  data$cno_gran_grupo      <- co_1995$gran_grupo_cno[j]
  data$homologacion_estado <- co_1995$estado[j]
  data$homologacion_estado[is.na(j)] <- "codigo_no_encontrado"
  data$homologacion_estado[is.na(cod_co95)] <- "sin_codigo"

  pct_unica <- round(100 * mean(!is.na(data$cno_homologado)), 1)
  cli::cli_inform(c(
    "v" = "Columna {.field cno_homologado} agregada con equivalencias CNO 2015.",
    "i" = "{pct_unica}% de las filas tiene una equivalencia unica.",
    "i" = paste0(
      "Los casos con varios destinos quedan en NA; ver {.field cno_candidatos} ",
      "y {.field homologacion_estado}."
    )
  ))
  data
}

#' @noRd
.normalizar_codigo <- function(x, clasificador) {
  # Codigos como texto con ceros a la izquierda: 11 -> "011" (CO-95),
  # 111 -> "0111" (CNO 2015). Valores no numericos o demasiado largos -> NA.
  digitos <- if (clasificador == "CNO_2015") 4L else 3L
  s <- sub("\\.0+$", "", trimws(as.character(x)))
  ok <- !is.na(s) & grepl(paste0("^[0-9]{1,", digitos, "}$"), s)
  salida <- rep(NA_character_, length(s))
  salida[ok] <- formatC(as.integer(s[ok]), width = digitos, flag = "0")
  salida
}

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
    # EPE cruda INEI: P204A / p204a (CO-95)
    candidatos <- c("occupation_code_4d", "occupation_code_raw", "P204A", "p204a",
                    "P505R3", "cod_ocup")
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
