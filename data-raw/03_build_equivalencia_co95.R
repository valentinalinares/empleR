# Construye data/equivalencia_co95.rda: tabla de equivalencias CO-95 -> CNO 2015.
# Ejecutar desde la raiz del paquete.
#
# Fuente: INEI, "Clasificador Nacional de Ocupaciones 2015" (Lima, 2016),
# seccion "Tablas de correspondencia": Codigo de Ocupaciones 1995 (CO-95)
# -> CNO 2015, construida al nivel mas desagregado de ambos clasificadores.
#   https://www.inei.gob.pe/media/Clasificador_Nacional_de_Ocupaciones_2015.pdf
#   https://www.inei.gob.pe/clasificador/  (tablas de correspondencia)
#
# Pasos:
# 1. Descargar la tabla de correspondencia CO-95 / CNO 2015 del INEI (Excel si
#    esta disponible; si solo existe el PDF, extraerla a Excel/CSV, por ejemplo
#    con tabulizer o copiandola, y revisar codigos con ceros a la izquierda).
# 2. Guardarla como CSV con las columnas: co_95, desc_co_95, cno_2015,
#    desc_cno_2015 (codigos como texto). Si un codigo CO-95 tiene varios
#    equivalentes, poner primero el enlace principal: cno() usa el primero.
# 3. Definir EMPLER_EQUIV_CO95 con la ruta del CSV y ejecutar este script.
# 4. Documentar el dataset en R/data.R (bloque "equivalencia_co95") y
#    agregarlo a _pkgdown.yml.

source_file <- Sys.getenv("EMPLER_EQUIV_CO95", unset = "equivalencia_co95_cno2015.csv")

if (!file.exists(source_file)) {
  stop("No se encontro la tabla CO-95 -> CNO 2015: ", source_file, call. = FALSE)
}

equivalencia_co95 <- utils::read.csv(
  source_file,
  colClasses = "character",
  encoding = "UTF-8"
)

required_cols <- c("co_95", "desc_co_95", "cno_2015", "desc_cno_2015")
missing_cols <- setdiff(required_cols, names(equivalencia_co95))
if (length(missing_cols) > 0) {
  stop("Faltan columnas: ", paste(missing_cols, collapse = ", "), call. = FALSE)
}

equivalencia_co95 <- equivalencia_co95[, required_cols]
equivalencia_co95$co_95 <- trimws(equivalencia_co95$co_95)
equivalencia_co95$cno_2015 <- trimws(equivalencia_co95$cno_2015)

# Validaciones: CO-95 hasta 3 digitos en EPE, CNO 2015 de 4 digitos
if (any(!grepl("^[0-9]{1,3}$", equivalencia_co95$co_95))) {
  stop("Hay codigos co_95 con formato invalido (se esperan 1-3 digitos).", call. = FALSE)
}
if (any(!grepl("^[0-9]{4}$", equivalencia_co95$cno_2015))) {
  stop("Hay codigos cno_2015 que no tienen 4 digitos.", call. = FALSE)
}

load("data/cno_2015.rda")
sin_match <- setdiff(equivalencia_co95$cno_2015, cno_2015$codigo)
if (length(sin_match) > 0) {
  warning(length(sin_match), " codigos cno_2015 no existen en cno_2015: ",
          paste(utils::head(sin_match, 10), collapse = ", "), call. = FALSE)
}

n_multiples <- sum(duplicated(equivalencia_co95$co_95))
cat("equivalencia_co95:", nrow(equivalencia_co95), "enlaces,",
    length(unique(equivalencia_co95$co_95)), "codigos CO-95,",
    n_multiples, "enlaces adicionales (uno a muchos)\n")

save(equivalencia_co95, file = file.path("data", "equivalencia_co95.rda"), compress = "bzip2")
