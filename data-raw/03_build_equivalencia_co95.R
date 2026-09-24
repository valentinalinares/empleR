# Construye data/co_1995.rda y data/equivalencia_co95.rda (CO-95 -> CNO 2015).
# Ejecutar desde la raiz del paquete.
#
# Fuente oficial: INEI, "Tablas de correspondencia CNO - CIUO - CO"
#   https://www.inei.gob.pe/media/Tablas_de_correspondencia_CNO_CIUO_CO.xlsx
#   (MD5 e8dd77f0d46a7d23da8cb6b2f83b8f6d, descargado el 2026-09-24)
# respaldada por el Clasificador Nacional de Ocupaciones 2015, seccion 5.5 y
# anexos 1 (pp. 372-396) y 2 (pp. 397-424).
#
# data-raw/co_1995/co_1995_correspondencia.xlsx es la copia auditada de las
# tablas derivadas (hojas co_1995, correspondencia, discrepancias y
# metodo_y_fuentes). Se genero con data-raw/co_1995/construir_co_1995.R, que
# puede reconstruirla desde el Excel oficial:
#   source("data-raw/co_1995/construir_co_1995.R")
#   tablas <- construir_co_1995("Tablas_de_correspondencia_CNO_CIUO_CO.xlsx")
#
# Decisiones metodologicas (ver hoja metodo_y_fuentes):
# - Se usa el anexo 1 (CNO2015_CO95) invertido: 604 pares, 370 codigos CO-95.
# - cno2015_unico solo se completa si el codigo CO-95 tiene un unico destino,
#   sin discrepancias entre anexos, y no es 999 (ocupacion no especificada).
# - Los casos con varios destinos NO se asignan automaticamente: elegir el
#   primer candidato o repartir pesos sesgaria el analisis.

if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Instala readxl: install.packages('readxl')", call. = FALSE)
}

archivo <- file.path("data-raw", "co_1995", "co_1995_correspondencia.xlsx")

co_1995 <- as.data.frame(readxl::read_excel(archivo, sheet = "co_1995", col_types = "text"))
co_1995$n_cno2015 <- as.integer(co_1995$n_cno2015)

equivalencia_co95 <- as.data.frame(
  readxl::read_excel(archivo, sheet = "correspondencia", col_types = "text")
)
equivalencia_co95 <- equivalencia_co95[, c(
  "co95", "nombre_co95", "cno2015", "nombre_cno2015", "acuerdo_anexos",
  "n_cno_por_co95", "n_co95_por_cno"
)]
equivalencia_co95$n_cno_por_co95 <- as.integer(equivalencia_co95$n_cno_por_co95)
equivalencia_co95$n_co95_por_cno <- as.integer(equivalencia_co95$n_co95_por_cno)

# Validaciones -------------------------------------------------------------
stopifnot(
  nrow(co_1995) == 370L,
  !anyDuplicated(co_1995$co95),
  all(grepl("^[0-9]{3}$", co_1995$co95)),
  nrow(equivalencia_co95) == 604L,
  all(grepl("^[0-9]{4}$", equivalencia_co95$cno2015)),
  setequal(co_1995$co95, equivalencia_co95$co95),
  sum(!is.na(co_1995$cno2015_unico)) == 236L,
  all(co_1995$estado %in% c(
    "unica", "multiples_destinos", "discrepancia_fuente", "ocupacion_no_especificada"
  ))
)

# cno2015_unico debe ser el unico destino de la tabla larga
unicos <- co_1995[!is.na(co_1995$cno2015_unico), ]
destinos <- split(equivalencia_co95$cno2015, equivalencia_co95$co95)
stopifnot(all(mapply(
  function(co, cno) identical(destinos[[co]], cno),
  unicos$co95, unicos$cno2015_unico
)))

load(file.path("data", "cno_2015.rda"))
sin_catalogo <- setdiff(equivalencia_co95$cno2015, cno_2015$codigo)
if (length(sin_catalogo) > 0) {
  message("Codigos CNO de la correspondencia ausentes en cno_2015: ",
          paste(sin_catalogo, collapse = ", "))
}

print(table(co_1995$estado))

save(co_1995, file = file.path("data", "co_1995.rda"), compress = "bzip2")
save(equivalencia_co95, file = file.path("data", "equivalencia_co95.rda"), compress = "bzip2")
