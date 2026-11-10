# Validacion reproducible de los diccionarios usados por etiquetar().
#
# Uso desde la raiz del paquete:
# Rscript data-raw/validar_etiquetas_epen.R [raiz_inei_data_core]
#
# La raiz debe contener epen_departamentos/ y epen_lima/. El script no
# modifica los ZIP: registra cada codigo observado y si pertenece al
# diccionario interno correspondiente.

args <- commandArgs(trailingOnly = TRUE)
raw_root <- if (length(args) >= 1L) {
  args[[1]]
} else {
  file.path("..", "data", "raw", "inei_data_core")
}

if (!dir.exists(raw_root)) {
  stop("No existe la raiz de microdatos: ", raw_root, call. = FALSE)
}

source(file.path("R", "descargar.R"), encoding = "UTF-8")
source(file.path("R", "etiquetar.R"), encoding = "UTF-8")
source(file.path("R", "cno.R"), encoding = "UTF-8")
load(file.path("data", "cno_2015.rda"))

variables <- c(
  C207 = "sexo",
  OCUP300 = "condicion_actividad",
  C366 = "nivel_educativo",
  C310 = "categoria_ocupacional",
  C311 = "sector_institucional",
  C317 = "tamano_empresa",
  C338 = "periodicidad_ingreso",
  AREA = "area_original"
)

archivos <- c(
  list.files(
    file.path(raw_root, "epen_departamentos"),
    pattern = "[.]zip$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  ),
  list.files(
    file.path(raw_root, "epen_lima"),
    pattern = "[.]zip$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )
)

if (length(archivos) == 0L) {
  stop("No se encontraron ZIP de la EPEN en: ", raw_root, call. = FALSE)
}

extraer_metadatos <- function(path) {
  partes <- strsplit(normalizePath(path, winslash = "/"), "/", fixed = TRUE)[[1]]
  posicion_variante <- max(which(partes %in% c("epen_departamentos", "epen_lima")))
  data.frame(
    variante = partes[[posicion_variante]],
    year = partes[[posicion_variante + 1L]],
    entrega = partes[[posicion_variante + 2L]],
    archivo = basename(path),
    stringsAsFactors = FALSE
  )
}

resultados <- vector("list", length(archivos) * length(variables))
indice <- 0L

for (path in archivos) {
  metadatos <- extraer_metadatos(path)
  datos <- .leer_zip_inei(path)

  for (variable in names(variables)) {
    indice <- indice + 1L
    diccionario <- variables[[variable]]
    mapa <- .diccionarios_epen[[diccionario]]

    if (!variable %in% names(datos)) {
      resultados[[indice]] <- cbind(
        metadatos,
        data.frame(
          variable = variable,
          codigo = NA_character_,
          etiqueta = NA_character_,
          n = 0L,
          conocido = NA,
          variable_presente = FALSE,
          stringsAsFactors = FALSE
        )
      )
      next
    }

    valores <- as.character(datos[[variable]])
    ausente <- is.na(valores) | trimws(valores) == ""
    conteos <- table(valores[!ausente], useNA = "no")
    codigos <- names(conteos)

    observado <- data.frame(
      variable = variable,
      codigo = codigos,
      etiqueta = unname(mapa[codigos]),
      n = as.integer(conteos),
      conocido = codigos %in% names(mapa),
      variable_presente = TRUE,
      stringsAsFactors = FALSE
    )

    faltantes <- data.frame(
      variable = variable,
      codigo = "<NA>",
      etiqueta = NA_character_,
      n = sum(ausente),
      conocido = NA,
      variable_presente = TRUE,
      stringsAsFactors = FALSE
    )

    resultados[[indice]] <- cbind(
      metadatos[rep(1L, nrow(observado) + 1L), , drop = FALSE],
      rbind(observado, faltantes)
    )
  }
}

resultados <- resultados[seq_len(indice)]
detalle <- do.call(rbind, resultados)
row.names(detalle) <- NULL

dir_salida <- file.path("data-raw", "validation")
dir.create(dir_salida, recursive = TRUE, showWarnings = FALSE)
salida <- file.path(
  dir_salida,
  "2026-11-10_etiquetas_epen_codigos_observados.csv"
)
utils::write.csv(detalle, salida, row.names = FALSE, na = "")

fuente_anual <- paste0(
  "https://www.inei.gob.pe/media/DATOS_ABIERTOS/EPEN_DEP/",
  "DICCIONARIO/2023/Anual-Ener-Dic/Diccionario.pdf"
)
fuente_movil <- paste0(
  "https://www.inei.gob.pe/media/DATOS_ABIERTOS/EPEN/",
  "DICCIONARIO/2023/12-trim-movil-oct-nov-dic23/Diccionario.pdf"
)

fuentes <- data.frame(
  concepto = c(
    "sexo", "condicion_actividad", "nivel_educativo",
    "categoria_ocupacional", "sector_institucional", "tamano_empresa",
    "periodicidad_ingreso", "area"
  ),
  variable_original = c(
    "C207", "OCUP300", "C366", "C310", "C311", "C317", "C338", "AREA"
  ),
  variable_procesada = c(
    "sex_code", "labor_status_code", "education_code",
    "occupational_category_code", "institutional_sector_code",
    "firm_size_code", "income_periodicity_code", "is_rural"
  ),
  columna_etiqueta = c(
    "sex_label", "labor_status_label", "education_label",
    "occupational_category_label", "institutional_sector_label",
    "firm_size_label", "income_periodicity_label", "area_label"
  ),
  diccionario = c(
    "sexo", "condicion_actividad", "nivel_educativo",
    "categoria_ocupacional", "sector_institucional", "tamano_empresa",
    "periodicidad_ingreso", "area_original"
  ),
  pagina_diccionario_anual_2023 = c(
    "3", "12", "11", "4-5", "5", "5", "6", "1"
  ),
  fuente_principal = fuente_anual,
  fuente_complementaria = c(
    "", fuente_movil, "", fuente_movil, "", "", "", ""
  ),
  nota = c(
    "",
    "El diccionario movil, pagina 18, documenta tambien el codigo 0.",
    "",
    paste0(
      "El anual documenta 1-8; el movil, pagina 7, documenta tambien 9-10."
    ),
    "", "", "",
    "AREA usa 1/2; is_rural es una derivacion procesada que usa 0/1."
  ),
  stringsAsFactors = FALSE
)

tabla_diccionario <- do.call(rbind, lapply(seq_len(nrow(fuentes)), function(i) {
  mapa <- .diccionarios_epen[[fuentes$diccionario[[i]]]]
  cbind(
    fuentes[i, setdiff(names(fuentes), "diccionario"), drop = FALSE],
    data.frame(
      codigo = names(mapa),
      etiqueta = unname(mapa),
      stringsAsFactors = FALSE
    )
  )
}))
row.names(tabla_diccionario) <- NULL

salida_diccionario <- file.path(
  dir_salida,
  "2026-11-10_diccionario_etiquetas_epen.csv"
)
utils::write.csv(tabla_diccionario, salida_diccionario,
                 row.names = FALSE, na = "")

# Recorrido real completo con una entrega anual. Se usa 2024 porque es el ano
# de la muestra incluida en el paquete y permite comparar ambos recorridos.
metadatos_archivos <- do.call(rbind, lapply(archivos, extraer_metadatos))
es_anual_2024 <- metadatos_archivos$variante == "epen_departamentos" &
  metadatos_archivos$year == "2024"

if (sum(es_anual_2024) != 1L) {
  stop("Se esperaba exactamente un ZIP anual 2024 para el flujo real.",
       call. = FALSE)
}

datos_reales <- .leer_zip_inei(archivos[es_anual_2024])
variables_presentes <- intersect(
  names(datos_reales),
  names(.especificaciones_etiquetas)
)
codigos_antes <- datos_reales[variables_presentes]
datos_etiquetados <- suppressMessages(etiquetar(datos_reales))
codigos_preservados <- identical(
  codigos_antes,
  datos_etiquetados[variables_presentes]
)
datos_cno <- suppressMessages(cno(
  datos_etiquetados,
  clasificador = "CNO_2015"
))

resumen_flujo <- data.frame(
  variante = "epen_departamentos",
  year = 2024L,
  filas = nrow(datos_reales),
  variables_crudas_etiquetadas = length(variables_presentes),
  columnas_label = sum(grepl("_label$", names(datos_etiquetados))),
  codigos_preservados = codigos_preservados,
  filas_cno_normalizado = sum(!is.na(datos_cno$cno_cod)),
  stringsAsFactors = FALSE
)

salida_flujo <- file.path(
  dir_salida,
  "2026-11-10_flujo_real_epen_2024.csv"
)
utils::write.csv(resumen_flujo, salida_flujo, row.names = FALSE, na = "")

desconocidos <- detalle[
  !is.na(detalle$conocido) & !detalle$conocido,
  ,
  drop = FALSE
]

cat("ZIP revisados:", length(archivos), "\n")
cat("Filas de codigos registradas:", nrow(detalle), "\n")
cat("Codigos fuera del diccionario:", nrow(desconocidos), "\n")
cat("Resultado:", salida, "\n")
cat("Diccionario:", salida_diccionario, "\n")
cat("Flujo real:", salida_flujo, "\n")

if (!codigos_preservados) {
  stop("etiquetar() modifico al menos una columna cruda en el flujo real.",
       call. = FALSE)
}

if (nrow(desconocidos) > 0L) {
  print(unique(desconocidos[c(
    "variante", "year", "entrega", "variable", "codigo"
  )]))
  quit(status = 1L)
}
