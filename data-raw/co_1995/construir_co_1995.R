# Correspondencia de ocupaciones de Peru: CO-95 y CNO 2015.
# Fuente INEI consultada el 2026-09-24.
# Dependencia: readxl (install.packages("readxl") si falta).
#
# DECISION: usar CNO2015_CO95 (anexo 1) e invertir sus columnas.
# El anexo 1 tiene 604 pares, 370 CO-95 y 473 CNO 2015.
# El anexo 2 tiene 598 pares y discrepancias en 8 codigos CO-95.
# No se trata esta decision como una correccion oficial del INEI.
# Se conservan TODOS los pares y se senalan las discrepancias.
# Una asignacion automatica exige destino unico y acuerdo entre anexos.
# CO-95 999 (ocupacion no especificada) se conserva pero no se recodifica.
# Los enlaces 0/1 son indicadores de correspondencia, NO ponderadores.
#
# USO:
# source("construir_co_1995.R")
# tablas <- construir_co_1995()  # Descarga temporalmente el Excel oficial.
# # Alternativa: construir_co_1995("Tablas_de_correspondencia_CNO_CIUO_CO.xlsx")
# co_1995 <- tablas$co_1995      # Catalogo: una fila por codigo CO-95.
# co95_cno2015 <- tablas$correspondencia
#
# # Confirmar primero el clasificador de cada archivo en su diccionario.
# epe  <- armonizar_ocupaciones(epe, "P204A", "CO95", tablas)
# epen <- armonizar_ocupaciones(epen, "C308_COD", "CNO2015", tablas)
# # Para p204a en minusculas: usar "p204a" en lugar de "P204A".
# table(epe$estado_mapeo, useNA = "ifany")
# table(epen$estado_mapeo, useNA = "ifany")
#
# La columna datos$co_1995 guarda el CO-95 observado o una conversion unica.
# La columna datos$cno2015 guarda el CNO observado o una conversion unica.
# Los NA derivados son intencionales: no hay una conversion individual unica.
# gran_grupo_cno solo armoniza al primer digito cuando es identificable.
#
# Esta rutina no filtra ocupados, territorio ni periodo, ni altera pesos.
# Reportar cobertura ponderada por encuesta/anio antes de comparar resultados.
# No unir personas directamente con la tabla larga de 604 pares.
# No se ejecuto este archivo en R en la preparacion del entregable:
# la extraccion y las reglas se verificaron por separado en Python.

normalizar_codigo <- function(x, digitos) {
  s <- trimws(as.character(x))
  s <- sub("\\.0+$", "", s)
  s[is.na(x) | s == ""] <- NA_character_
  patron <- paste0("^[0-9]{1,", digitos, "}$")
  ok <- !is.na(s) & grepl(patron, s)
  salida <- rep(NA_character_, length(s))
  salida[ok] <- sprintf(paste0("%0", digitos, "d"), as.integer(s[ok]))
  salida
}

construir_co_1995 <- function(archivo = NULL, verificar_version = TRUE) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop('Falta readxl. Ejecuta install.packages("readxl").')
  }
  url <- "https://www.inei.gob.pe/media/Tablas_de_correspondencia_CNO_CIUO_CO.xlsx"
  md5_esperado <- "e8dd77f0d46a7d23da8cb6b2f83b8f6d"
  if (is.null(archivo)) {
    archivo <- tempfile(fileext = ".xlsx")
    on.exit(unlink(archivo), add = TRUE)
    utils::download.file(url, archivo, mode = "wb", quiet = TRUE)
  }
  if (!file.exists(archivo)) stop("No existe el archivo indicado.")
  md5 <- unname(tools::md5sum(archivo))
  if (verificar_version && !identical(md5, md5_esperado)) {
    stop(paste("El Excel difiere de la copia auditada el 2026-09-24.",
               "Revisa su version antes de usar verificar_version = FALSE."))
  }

  leer_pares <- function(hoja, inversa = FALSE) {
    x <- readxl::read_excel(archivo, sheet = hoja, skip = 4,
                           col_names = FALSE, col_types = "text",
                           .name_repair = "minimal")
    a <- if (inversa) 4L else 1L
    b <- if (inversa) 1L else 4L
    y <- data.frame(
      co95 = normalizar_codigo(x[[a]], 3),
      nombre_co95 = trimws(gsub("[[:space:]]+", " ", x[[a + 1L]])),
      cno2015 = normalizar_codigo(x[[b]], 4),
      nombre_cno2015 = trimws(gsub("[[:space:]]+", " ", x[[b + 1L]])),
      enlace_co95_original = suppressWarnings(as.integer(x[[a + 2L]])),
      enlace_cno2015_original = suppressWarnings(as.integer(x[[b + 2L]])),
      fila_excel = seq_len(nrow(x)) + 4L,
      stringsAsFactors = FALSE
    )
    y <- y[!is.na(y$co95) & !is.na(y$cno2015), , drop = FALSE]
    if (anyDuplicated(y[c("co95", "cno2015")])) {
      stop(paste("Pares duplicados en", hoja))
    }
    y
  }

  a1 <- leer_pares("CNO2015_CO95", inversa = TRUE)
  a2 <- leer_pares("CO95_CNO2015")
  a3 <- readxl::read_excel(archivo, sheet = "CNO2015_CIUO2008", skip = 4,
                          col_names = FALSE, col_types = "text",
                          .name_repair = "minimal")
  validos <- unique(stats::na.omit(normalizar_codigo(a3[[2]], 4)))
  if (!setequal(a1$cno2015, validos)) {
    stop("El anexo 1 no coincide con los codigos CNO del anexo 3.")
  }
  clave <- function(x) paste(x$co95, x$cno2015, sep = ":")
  k1 <- clave(a1)
  k2 <- clave(a2)
  d1 <- a1[!k1 %in% k2, , drop = FALSE]
  d2 <- a2[!k2 %in% k1, , drop = FALSE]
  d1$presencia <- rep("solo_anexo1", nrow(d1))
  d2$presencia <- rep("solo_anexo2", nrow(d2))
  discrepancias <- rbind(d1, d2)
  discrepancias$cno_en_catalogo <- discrepancias$cno2015 %in% validos
  conflicto_co <- unique(discrepancias$co95)
  conflicto_cno <- unique(discrepancias$cno2015)

  lista_co <- lapply(split(a1$cno2015, a1$co95), function(z) sort(unique(z)))
  lista_cno <- lapply(split(a1$co95, a1$cno2015), function(z) sort(unique(z)))
  estado <- function(n, conflicto) {
    ifelse(conflicto, "discrepancia_fuente",
           ifelse(n == 1L, "unica", "multiples_destinos"))
  }
  candidato_unico <- function(z) if (length(z) == 1L) z else NA_character_

  co_1995 <- data.frame(
    co95 = names(lista_co),
    nombre_co95 = a2$nombre_co95[match(names(lista_co), a2$co95)],
    n_cno2015 = lengths(lista_co),
    cno2015_candidatos = vapply(lista_co, paste, character(1), collapse = "; "),
    cno2015_unico = vapply(lista_co, candidato_unico, character(1)),
    estado = estado(lengths(lista_co), names(lista_co) %in% conflicto_co),
    gran_grupo_cno = vapply(lista_co, function(z) {
      candidato_unico(unique(substr(z, 1L, 1L)))
    }, character(1)),
    row.names = NULL, stringsAsFactors = FALSE
  )
  conflicto <- co_1995$estado == "discrepancia_fuente"
  co_1995$cno2015_unico[conflicto] <- NA_character_
  co_1995$gran_grupo_cno[conflicto] <- NA_character_
  no_especificada <- co_1995$co95 == "999"
  co_1995$estado[no_especificada] <- "ocupacion_no_especificada"
  co_1995$cno2015_unico[no_especificada] <- NA_character_
  co_1995$gran_grupo_cno[no_especificada] <- NA_character_

  cno_2015 <- data.frame(
    cno2015 = names(lista_cno),
    nombre_cno2015 = a1$nombre_cno2015[match(names(lista_cno), a1$cno2015)],
    n_co95 = lengths(lista_cno),
    co95_candidatos = vapply(lista_cno, paste, character(1), collapse = "; "),
    co95_unico = vapply(lista_cno, candidato_unico, character(1)),
    estado = estado(lengths(lista_cno), names(lista_cno) %in% conflicto_cno),
    row.names = NULL, stringsAsFactors = FALSE
  )
  cno_2015$co95_unico[cno_2015$estado == "discrepancia_fuente"] <- NA_character_

  a1$acuerdo_anexos <- ifelse(k1 %in% k2, "si", "solo_anexo1")
  a1$n_cno_por_co95 <- lengths(lista_co)[match(a1$co95, names(lista_co))]
  a1$n_co95_por_cno <- lengths(lista_cno)[match(a1$cno2015, names(lista_cno))]
  a1$enlace_co95_coherente <- a1$enlace_co95_original == as.integer(a1$n_cno_por_co95 > 1L)
  a1$enlace_cno_coherente <- a1$enlace_cno2015_original == as.integer(a1$n_co95_por_cno > 1L)
  a1 <- a1[order(a1$co95, a1$cno2015), , drop = FALSE]
  rownames(a1) <- NULL
  stopifnot(!anyDuplicated(co_1995$co95), !anyDuplicated(cno_2015$cno2015))
  if (verificar_version) {
    stopifnot(nrow(a1) == 604L, nrow(a2) == 598L,
              nrow(co_1995) == 370L, nrow(cno_2015) == 473L,
              nrow(discrepancias) == 12L, length(conflicto_co) == 8L,
              sum(!is.na(co_1995$cno2015_unico)) == 236L,
              sum(!is.na(cno_2015$co95_unico)) == 381L)
  }
  list(co_1995 = co_1995, cno_2015 = cno_2015,
       correspondencia = a1, anexo2_original = a2,
       discrepancias = discrepancias, fuente = url, md5 = md5)
}

armonizar_ocupaciones <- function(datos, variable, clasificador, tablas) {
  clasificador <- match.arg(clasificador, c("CO95", "CNO2015"))
  if (!variable %in% names(datos)) stop(paste("Falta la variable", variable))
  original <- datos[[variable]]
  es_co95 <- clasificador == "CO95"
  codigo <- normalizar_codigo(original, if (es_co95) 3 else 4)
  dic <- if (es_co95) tablas$co_1995 else tablas$cno_2015
  llave <- if (es_co95) dic$co95 else dic$cno2015
  if (anyDuplicated(llave) || anyNA(llave)) stop("El diccionario no tiene clave unica valida.")
  # match() es seguro AQUI porque el diccionario tiene una fila por clave.
  # No usarlo directamente sobre la correspondencia larga con claves repetidas.
  j <- match(codigo, llave)
  encontrado <- !is.na(j)
  observado <- codigo
  observado[!encontrado] <- NA_character_
  salida <- datos
  salida$ocupacion_codigo_original <- as.character(original)
  salida$ocupacion_codigo_normalizado <- codigo
  salida$clasificador_original <- rep(clasificador, nrow(datos))
  if (es_co95) {
    salida$co_1995 <- observado
    salida$cno2015 <- dic$cno2015_unico[j]
    salida$ocupacion_candidatos <- dic$cno2015_candidatos[j]
    salida$gran_grupo_cno <- dic$gran_grupo_cno[j]
  } else {
    salida$co_1995 <- dic$co95_unico[j]
    salida$cno2015 <- observado
    salida$ocupacion_candidatos <- dic$co95_candidatos[j]
    salida$gran_grupo_cno <- substr(observado, 1L, 1L)
  }
  salida$estado_mapeo <- dic$estado[j]
  salida$estado_mapeo[!encontrado] <- "codigo_no_encontrado"
  formato_invalido <- !is.na(original) & trimws(as.character(original)) != "" & is.na(codigo)
  salida$estado_mapeo[formato_invalido] <- "formato_invalido"
  faltante <- is.na(original) | trimws(as.character(original)) == ""
  salida$estado_mapeo[faltante] <- "sin_codigo"
  stopifnot(nrow(salida) == nrow(datos), identical(salida[[variable]], original))
  salida
}
