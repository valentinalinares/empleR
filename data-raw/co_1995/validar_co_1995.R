# Compara la salida de construir_co_1995() (desde el Excel oficial del INEI)
# con los datasets empaquetados co_1995 y equivalencia_co95.
# Ejecutar desde la raiz del paquete:
#
#   source("data-raw/co_1995/validar_co_1995.R")
#   res <- validar_co_1995("Tablas_de_correspondencia_CNO_CIUO_CO.xlsx")
#   # o sin argumento: descarga el Excel oficial del INEI
#
# Detiene la ejecucion si alguna comprobacion falla y devuelve la tabla de
# comprobaciones.

source(file.path("data-raw", "co_1995", "construir_co_1995.R"))

validar_co_1995 <- function(archivo = NULL, verificar_version = TRUE) {
  tablas <- construir_co_1995(archivo, verificar_version = verificar_version)

  env <- new.env()
  load(file.path("data", "co_1995.rda"), envir = env)
  load(file.path("data", "equivalencia_co95.rda"), envir = env)
  pkg_co <- env$co_1995
  pkg_eq <- env$equivalencia_co95

  nuevo_co <- tablas$co_1995
  nuevo_eq <- tablas$correspondencia

  i <- match(pkg_co$co95, nuevo_co$co95)
  mismo <- function(a, b) identical(as.character(a), as.character(b))
  clave <- function(x) sort(paste(x$co95, x$cno2015, sep = ":"))
  k_pkg <- paste(pkg_eq$co95, pkg_eq$cno2015, sep = ":")
  k_new <- paste(nuevo_eq$co95, nuevo_eq$cno2015, sep = ":")
  j <- match(k_pkg, k_new)

  checks <- c(
    "codigos CO-95 identicos"        = setequal(pkg_co$co95, nuevo_co$co95),
    "nombres CO-95"                  = mismo(pkg_co$nombre_co95, nuevo_co$nombre_co95[i]),
    "numero de destinos"             = mismo(pkg_co$n_cno2015, nuevo_co$n_cno2015[i]),
    "candidatos CNO 2015"            = mismo(pkg_co$cno2015_candidatos, nuevo_co$cno2015_candidatos[i]),
    "equivalencia unica"             = mismo(pkg_co$cno2015_unico, nuevo_co$cno2015_unico[i]),
    "estados"                        = mismo(pkg_co$estado, nuevo_co$estado[i]),
    "gran grupo"                     = mismo(pkg_co$gran_grupo_cno, nuevo_co$gran_grupo_cno[i]),
    "pares CO-95/CNO identicos"      = identical(clave(pkg_eq), clave(nuevo_eq)),
    "acuerdo entre anexos"           = mismo(pkg_eq$acuerdo_anexos, nuevo_eq$acuerdo_anexos[j]),
    "nombres CNO 2015"               = mismo(pkg_eq$nombre_cno2015, nuevo_eq$nombre_cno2015[j]),
    "604 pares anexo 1"              = nrow(nuevo_eq) == 604L,
    "598 pares anexo 2"              = nrow(tablas$anexo2_original) == 598L,
    "370 codigos CO-95"              = nrow(nuevo_co) == 370L,
    "473 codigos CNO 2015"           = nrow(tablas$cno_2015) == 473L,
    "12 pares discrepantes"          = nrow(tablas$discrepancias) == 12L,
    "8 CO-95 con discrepancia"       = sum(nuevo_co$estado == "discrepancia_fuente") == 8L,
    "236 equivalencias unicas"       = sum(!is.na(nuevo_co$cno2015_unico)) == 236L
  )

  resultado <- data.frame(comprobacion = names(checks), ok = unname(checks))
  print(resultado, row.names = FALSE)
  cat("\nEstados (Excel oficial):\n")
  print(table(nuevo_co$estado))
  cat("MD5 del Excel:", tablas$md5, "\n")
  if (!all(checks)) stop("Hay diferencias con los datos empaquetados.", call. = FALSE)
  invisible(resultado)
}
