#' Armonizar codigos ocupacionales entre CNO 2015 y CO-95
#'
#' Esta funcion resuelve la **ruptura de clasificadores** entre la EPE (hasta
#' 2021, usa CO-95 de 3 digitos, basado en CIUO-88) y la EPEN (desde 2022,
#' usa CNO 2015 de 4 digitos, basado en CIUO-08) y, opcionalmente, aplica la
#' tabla de equivalencias para construir series comparables.
#'
#' El clasificador se determina, en este orden: (1) el argumento
#' `clasificador`; (2) la encuesta declarada en `source`/`fuente`/`encuesta`
#' (EPE o EPEN); (3) los anos de **todas** las filas (`year`, `anio`, `ANIO`,
#' `ANO` o su version con enie): 2021 o antes es CO-95; 2022 o despues, CNO 2015. Una base que mezcla
#' ambos periodos o ambas encuestas produce un error: hay que procesar cada
#' parte por separado. Si una base de 2022 usa CO-95, indicalo con
#' `clasificador = "CO_95"`.
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
#' @param var_ocup Nombre de la variable de codigo ocupacional. Por defecto
#'   se usa el codigo original: `C308_COD` u `occupation_code_raw` (EPEN),
#'   `P204A`/`p204a` (EPE); `occupation_code_4d` solo si no hay original.
#' @param homologar Logico. Si `TRUE`, aplica la tabla de equivalencias
#'   CO-95 <-> CNO 2015 para bases EPE pre-2022 y devuelve la columna
#'   adicionales `cno_homologado`, `cno_candidatos`, `cno_gran_grupo` y
#'   `homologacion_estado`. Por defecto `FALSE`.
#' @param agregar Nivel de agregacion del CNO al que reducir los codigos.
#'   Opciones: `"4d"` (4 digitos, por defecto), `"3d"`, `"2d"`, `"1d"`.
#'   Para bases EPE (CO-95), el maximo disponible y el valor por defecto es
#'   `"3d"`. La homologacion siempre usa el codigo CO-95 completo.
#' @param clasificador `"CNO_2015"`, `"CO_95"` o `NULL` (por defecto) para
#'   detectarlo automaticamente.
#'
#' @return El mismo `data.frame` con columnas adicionales:
#'   \describe{
#'     \item{clasificador}{El clasificador detectado: `"CNO_2015"` o `"CO_95"`.}
#'     \item{cno_cod}{Codigo ocupacional estandarizado al nivel solicitado.
#'       Sale del codigo original (`C308_COD`, `P204A` u
#'       `occupation_code_raw`) completado con ceros a la izquierda; solo si
#'       no existe se usa `occupation_code_4d`.}
#'     \item{cno_discrepancia_4d}{(Solo CNO 2015, si la base trae el codigo
#'       original y `occupation_code_4d`) `TRUE` cuando ambos no coinciden,
#'       por ejemplo 212 -> `"0212"` frente a `"2120"`.}
#'     \item{cno_desc}{Descripcion de la ocupacion (del diccionario interno).}
#'     \item{cno_homologado}{(Solo si `homologar = TRUE`, bases CO-95) Codigo
#'       CNO 2015 de 4 digitos cuando la equivalencia es unica; `NA` si no.}
#'     \item{cno_candidatos}{Todos los codigos CNO 2015 posibles, separados
#'       por `"; "`.}
#'     \item{cno_gran_grupo}{Gran grupo CNO 2015 (1 digito) cuando todos los
#'       candidatos lo comparten; permite comparar a nivel agregado.}
#'     \item{homologacion_estado}{`"unica"`, `"multiples_destinos"`,
#'       `"discrepancia_fuente"`, `"ocupacion_no_especificada"`,
#'       `"codigo_no_encontrado"`, `"formato_invalido"` o `"sin_codigo"`.}
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
                agregar = "4d",
                clasificador = NULL) {

  agregar_por_defecto <- missing(agregar)
  agregar <- match.arg(agregar, c("4d", "3d", "2d", "1d"))

  clasificador <- .resolver_clasificador(data, clasificador)
  if (clasificador == "CO_95" && agregar_por_defecto) agregar <- "3d"

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
  .avisar_codigos_desconocidos(data$cno_cod, dicc_cod, clasificador)
  if (clasificador == "CNO_2015") data <- .comparar_con_procesado(data, var_ocup)

  # Homologar CO-95 -> CNO 2015 si se pide
  if (homologar && clasificador == "CO_95") {
    data <- .homologar_co95(data, cod_completo, data[[var_ocup]])
  } else if (homologar && clasificador == "CNO_2015") {
    cli::cli_warn(
      "La base ya usa CNO 2015. {.arg homologar} no tiene efecto."
    )
  }

  data
}


# Helpers internos --------------------------------------------------------

#' @noRd
.homologar_co95 <- function(data, cod_co95, original) {
  # Se usa el catalogo co_1995 (una fila por codigo CO-95), nunca la tabla
  # larga equivalencia_co95: unir con ella replicaria personas y pesos.
  j <- match(cod_co95, co_1995$co95)
  data$cno_homologado      <- co_1995$cno2015_unico[j]
  data$cno_candidatos      <- co_1995$cno2015_candidatos[j]
  data$cno_gran_grupo      <- co_1995$gran_grupo_cno[j]
  data$homologacion_estado <- co_1995$estado[j]
  data$homologacion_estado[is.na(j)] <- "codigo_no_encontrado"
  vacio <- is.na(original) | trimws(as.character(original)) == ""
  data$homologacion_estado[is.na(cod_co95) & !vacio] <- "formato_invalido"
  data$homologacion_estado[vacio] <- "sin_codigo"

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
.comparar_con_procesado <- function(data, var_ocup) {
  # Si la base trae el codigo original y occupation_code_4d, compara ambos.
  # cno_cod siempre sale de var_ocup; la discrepancia queda en
  # cno_discrepancia_4d (TRUE/FALSE; NA si falta alguno de los dos).
  var_raw <- intersect(c("C308_COD", "occupation_code_raw"), names(data))
  if (!"occupation_code_4d" %in% names(data) || length(var_raw) == 0) return(data)
  var_raw <- if (var_ocup %in% var_raw) var_ocup else var_raw[1]

  desde_raw  <- .normalizar_codigo(data[[var_raw]], "CNO_2015")
  procesado  <- .normalizar_codigo(data$occupation_code_4d, "CNO_2015")
  data$cno_discrepancia_4d <- ifelse(
    is.na(desde_raw) | is.na(procesado), NA, desde_raw != procesado
  )

  n <- sum(data$cno_discrepancia_4d, na.rm = TRUE)
  if (n > 0) {
    i <- which(data$cno_discrepancia_4d)[1]
    usado <- if (var_ocup == "occupation_code_4d") "occupation_code_4d" else var_raw
    cli::cli_warn(c(
      "{n} fila(s) donde {.field occupation_code_4d} no coincide con {.field {var_raw}}.",
      "i" = paste0(
        "Ejemplo: {.field {var_raw}} = {.val {data[[var_raw]][i]}} -> {.val {desde_raw[i]}}, ",
        "pero {.field occupation_code_4d} = {.val {data$occupation_code_4d[i]}}."
      ),
      "i" = "{.field cno_cod} usa {.field {usado}}; las filas quedan marcadas en {.field cno_discrepancia_4d}."
    ))
  }
  data
}

#' @noRd
.avisar_codigos_desconocidos <- function(cod, dicc_cod, clasificador) {
  desconocidos <- !is.na(cod) & !cod %in% dicc_cod
  if (!any(desconocidos)) return(invisible())
  codigos <- sort(unique(cod[desconocidos]))
  msgs <- c(
    "{sum(desconocidos)} fila(s) con codigos que no existen en el {clasificador}: {.val {utils::head(codigos, 8)}}."
  )
  # Patron tipico: codigo de 3 digitos completado con un cero a la derecha
  # (211 -> "2110") en vez de a la izquierda (211 -> "0211").
  if (clasificador == "CNO_2015") {
    corregidos <- paste0("0", substr(codigos, 1, 3))
    rellenados <- grepl("0$", codigos) & corregidos %in% dicc_cod
    if (any(rellenados)) {
      msgs <- c(msgs, "i" = paste0(
        "{sum(rellenados)} parece(n) completado(s) con un cero a la derecha ",
        "(p. ej. {.val {codigos[rellenados][1]}} deberia ser {.val {corregidos[rellenados][1]}}); ",
        "revisa la variable original o usa {.arg var_ocup} con el codigo crudo."
      ))
    }
  }
  cli::cli_warn(msgs)
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
.resolver_clasificador <- function(data, clasificador = NULL) {
  validos <- c("CNO_2015", "CO_95")
  years <- .detectar_years(data)
  years_obs <- sort(unique(years[!is.na(years)]))

  # 1. Clasificador indicado por el usuario: se respeta, pero se avisa si
  #    contradice los anos de la base.
  if (!is.null(clasificador)) {
    clasificador <- match.arg(clasificador, validos)
    esperado <- unique(.clasificador_por_year(years_obs))
    if (length(esperado) > 0 && !all(esperado == clasificador)) {
      cli::cli_warn(c(
        "{.arg clasificador} = {.val {clasificador}} no coincide con los anos de la base ({years_obs}).",
        "i" = "Se usa el clasificador indicado."
      ))
    }
    cli::cli_inform(c("i" = "Clasificador indicado: {clasificador}"))
    return(clasificador)
  }

  # 2. Encuesta declarada en la base (EPE -> CO-95, EPEN -> CNO 2015)
  por_fuente <- .clasificador_por_fuente(data)
  if (!is.null(por_fuente)) {
    cli::cli_inform(c("i" = "Clasificador segun la encuesta de la base: {por_fuente}"))
    return(por_fuente)
  }

  # 3. Anos de todas las filas (no solo la primera)
  if (length(years_obs) == 0) {
    vars_year <- .vars_year
    cli::cli_abort(c(
      "No se pudo determinar el clasificador ocupacional de la base.",
      "i" = "No hay variable de ano con valores validos ({.val {vars_year}}).",
      "i" = "Indicalo con {.code clasificador = \"CO_95\"} o {.code \"CNO_2015\"}."
    ))
  }
  por_year <- unique(.clasificador_por_year(years_obs))
  if (length(por_year) > 1) {
    cli::cli_abort(c(
      "La base mezcla anos con distinto clasificador ocupacional: {years_obs}.",
      "i" = "Hasta 2021 (EPE) se usa CO-95; desde 2022 (EPEN), CNO 2015.",
      "i" = "Aplica {.fn cno} por separado a cada periodo, o indica {.arg clasificador}."
    ))
  }
  if (anyNA(years)) {
    cli::cli_warn("{sum(is.na(years))} fila(s) sin ano; se asume el clasificador del resto.")
  }
  cli::cli_inform(c(
    "i" = "Anos detectados: {years_obs}",
    "i" = "Clasificador: {por_year}"
  ))
  por_year
}

#' @noRd
.clasificador_por_year <- function(years) {
  # EPEN (desde 2022): CNO 2015 (4 digitos, CIUO-08)
  # EPE (hasta 2021): CO-95 (3 digitos, CIUO-88)
  ifelse(years >= 2022, "CNO_2015", "CO_95")
}

#' @noRd
.clasificador_por_fuente <- function(data) {
  col <- intersect(c("source", "fuente", "encuesta"), names(data))
  if (length(col) == 0) return(NULL)
  fuentes <- unique(toupper(trimws(as.character(data[[col[1]]]))))
  fuentes <- fuentes[!is.na(fuentes) & fuentes %in% c("EPE", "EPEN")]
  if (length(fuentes) == 0) return(NULL)
  if (length(fuentes) > 1) {
    cli::cli_abort(c(
      "La base mezcla encuestas EPE y EPEN en {.field {col[1]}}.",
      "i" = "Aplica {.fn cno} por separado a cada encuesta y luego une los resultados."
    ))
  }
  if (fuentes == "EPEN") "CNO_2015" else "CO_95"
}

# Nombres posibles de la variable ano. "A\u00d1O" es ANO con enie; las otras
# variantes cubren archivos latin1 leidos como UTF-8 y nombres sin tilde.
.vars_year <- c(
  "year", "YEAR", "anio", "ANIO", "ano", "ANO", "Ano", "pano",
  "A\u00d1O", "a\u00f1o", "A\u00f1o", "A\u00c3\u2018O", "ANo"
)

#' @noRd
.detectar_years <- function(data) {
  var_year <- .buscar_nombre(names(data), .vars_year)
  if (is.na(var_year)) return(integer(0))
  suppressWarnings(as.integer(as.character(data[[var_year]])))
}

#' @noRd
.buscar_nombre <- function(nombres, candidatos) {
  # Compara por bytes UTF-8: un mismo nombre puede venir marcado como UTF-8,
  # latin1 o sin marca segun como se leyo el archivo y el locale de la sesion.
  a_bytes <- function(x) {
    # Solo se convierte lo marcado como latin1: enc2utf8() sobre texto sin
    # marca depende del locale y puede alterar los bytes.
    lat <- Encoding(x) == "latin1"
    x[lat] <- enc2utf8(x[lat])
    vapply(x, function(z) paste(as.character(charToRaw(z)), collapse = " "), "", USE.NAMES = FALSE)
  }
  # "41 d1 4f": ANO con enie en latin1 sin marcar
  cand <- c(a_bytes(candidatos), "41 d1 4f")
  nom <- a_bytes(nombres)
  i <- match(cand, nom)
  i <- i[!is.na(i)]
  if (length(i) == 0) NA_character_ else nombres[i[1]]
}

#' @noRd
.detectar_var_ocup <- function(data, clasificador) {
  # Variables candidatas segun clasificador y fuente de datos
  # EPEN procesada: occupation_code_4d (ya estandarizada a 4 digitos)
  # EPEN cruda INEI: C308_COD
  # ENAHO procesada: occupation_code_4d o P505R4
  # El codigo original (C308_COD, P204A, occupation_code_raw) tiene
  # prioridad sobre occupation_code_4d: la version procesada puede haberse
  # completado con ceros a la derecha (212 -> "2120").
  if (clasificador == "CNO_2015") {
    candidatos <- c("C308_COD", "occupation_code_raw", "occupation_code_4d", "P505R4", "cod_ocup")
  } else {
    candidatos <- c("P204A", "p204a", "occupation_code_raw", "occupation_code_4d",
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
