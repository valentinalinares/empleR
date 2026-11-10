# Validacion del cruce departamental de mapa() con las bases EPEN anuales.
#
# Uso desde la raiz del paquete:
# Rscript data-raw/validar_mapa_epen.R RUTA_A_EPEN_DEPARTAMENTOS [SALIDA_CSV]
#
# La ruta debe contener los ZIP oficiales del modulo 76 organizados en
# subcarpetas por ano. El script no modifica los ZIP. Para cada ano:
#
# 1. lee el ZIP con el lector de descargar();
# 2. registra las columnas geograficas disponibles;
# 3. cuenta observaciones y suma el factor de expansion por CCDD;
# 4. pasa esa tabla a mapa() (ggplot y leaflet) y comprueba que cada poligono
#    recibe el valor de su codigo UBIGEO, que no se pierde ninguna fila y que
#    los departamentos sin dato se informan.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) {
  stop("Indica la carpeta que contiene los ZIP anuales de la EPEN.", call. = FALSE)
}
raw_root <- normalizePath(args[[1]], mustWork = TRUE)
output_csv <- if (length(args) >= 2L) {
  args[[2]]
} else {
  file.path("data-raw", "validation", "2026-11-10_mapa_epen_departamentos.csv")
}

pkgload::load_all(".", quiet = TRUE)

zips <- list.files(raw_root, pattern = "[.]zip$", recursive = TRUE,
                   full.names = TRUE, ignore.case = TRUE)
if (length(zips) == 0L) {
  stop("No se encontraron ZIP en: ", raw_root, call. = FALSE)
}
anio_de <- function(path) {
  partes <- strsplit(normalizePath(path, winslash = "/"), "/", fixed = TRUE)[[1]]
  as.integer(partes[grepl("^20[0-9]{2}$", partes)][1])
}

patron_geo <- "^(CCDD|CCPP|CCDI|UBIGEO|DEPARTAMENTO|PROVINCIA|DISTRITO|DOMINIO|REGION)$"
resultados <- list()
resumen <- list()

for (zip in zips[order(vapply(zips, anio_de, integer(1)))]) {
  anio <- anio_de(zip)
  datos <- .leer_zip_inei(zip)
  columnas_geo <- grep(patron_geo, names(datos), value = TRUE, ignore.case = TRUE)
  var_peso <- intersect(c("FAC300_ANUAL", "FACTOR"), names(datos))[1]

  peso <- suppressWarnings(as.numeric(datos[[var_peso]]))
  tabla <- data.frame(
    CCDD = sort(unique(datos$CCDD)),
    stringsAsFactors = FALSE
  )
  tabla$n_obs <- as.integer(table(datos$CCDD)[tabla$CCDD])
  tabla$poblacion <- as.numeric(tapply(peso, datos$CCDD, sum, na.rm = TRUE)[tabla$CCDD])

  avisos <- character()
  capturar <- function(expr) {
    withCallingHandlers(expr, warning = function(w) {
      avisos <<- c(avisos, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  }
  g <- capturar(mapa(tabla, "n_obs", tipo = "ggplot"))
  avisos_ggplot <- avisos
  avisos <- character()
  l <- capturar(mapa(tabla, "poblacion", tipo = "leaflet"))
  avisos_leaflet <- avisos

  poligonos <- Filter(function(x) identical(x$method, "addPolygons"), l$x$calls)[[1]]
  etiquetas <- Find(
    function(a) is.character(a) && length(a) == nrow(shapes_departamentos),
    poligonos$args
  )

  esperado <- data.frame(
    departamento = unname(.departamentos_ubigeo),
    CCDD = names(.departamentos_ubigeo),
    stringsAsFactors = FALSE
  )
  esperado$n_obs_esperado <- tabla$n_obs[match(esperado$CCDD, tabla$CCDD)]
  esperado$poblacion_esperada <- tabla$poblacion[match(esperado$CCDD, tabla$CCDD)]

  pos <- match(esperado$departamento, g$data$departamento)
  esperado$n_obs_ggplot <- g$data$n_obs[pos]
  esperado$etiqueta_leaflet <- etiquetas[pos]
  esperado$etiqueta_esperada <- paste0(
    esperado$departamento, ": ",
    .formatear_valor_mapa(esperado$poblacion_esperada)
  )
  esperado$coincide <- (
    (is.na(esperado$n_obs_esperado) & is.na(esperado$n_obs_ggplot)) |
      (!is.na(esperado$n_obs_esperado) & esperado$n_obs_esperado == esperado$n_obs_ggplot)
  ) & esperado$etiqueta_leaflet == esperado$etiqueta_esperada
  esperado$year <- anio

  resultados[[as.character(anio)]] <- esperado
  resumen[[as.character(anio)]] <- data.frame(
    year = anio,
    zip = basename(zip),
    filas = nrow(datos),
    columnas_geograficas = paste(columnas_geo, collapse = ";"),
    codigos_ccdd = nrow(tabla),
    codigos_sin_poligono = sum(is.na(.codigo_a_departamento(tabla$CCDD))),
    filas_asignadas = sum(esperado$n_obs_ggplot, na.rm = TRUE),
    departamentos_sin_dato = paste(esperado$departamento[is.na(esperado$n_obs_ggplot)],
                                   collapse = ";"),
    poligonos_correctos = sum(esperado$coincide),
    avisos_ggplot = paste(avisos_ggplot, collapse = " | "),
    avisos_leaflet = paste(avisos_leaflet, collapse = " | "),
    stringsAsFactors = FALSE
  )
  rm(datos)
  gc(verbose = FALSE)
}

detalle <- do.call(rbind, resultados)
resumen <- do.call(rbind, resumen)
detalle <- detalle[, c("year", "CCDD", "departamento", "n_obs_esperado",
                       "n_obs_ggplot", "poblacion_esperada", "etiqueta_leaflet",
                       "coincide")]

dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(detalle, output_csv, row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(
  resumen,
  sub("[.]csv$", "_resumen.csv", output_csv),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

print(resumen[, c("year", "filas", "columnas_geograficas", "codigos_ccdd",
                  "codigos_sin_poligono", "filas_asignadas",
                  "departamentos_sin_dato", "poligonos_correctos")])
cat("\nAvisos ggplot:\n")
print(unique(resumen$avisos_ggplot))

if (!all(detalle$coincide) || any(resumen$filas_asignadas != resumen$filas)) {
  stop("La validacion del cruce departamental encontro diferencias.", call. = FALSE)
}
cat("\nValidacion completa: todos los poligonos recibieron el valor de su CCDD.\n")
