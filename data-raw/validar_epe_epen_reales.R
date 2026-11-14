#!/usr/bin/env Rscript

# Integracion con microdatos reales EPE 2021 y EPEN 2024. El contraste usa el
# mismo trimestre movil (octubre-noviembre-diciembre), pero no interpreta el
# cambio entre anos: las encuestas y su cobertura territorial no son identicas.

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Se necesita el paquete pkgload para cargar empleR.")
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Se necesita el paquete digest para calcular SHA-256.")
}

pkgload::load_all(".", quiet = TRUE)
source("data-raw/validar_bases_reales.R", local = TRUE)

raw_root <- Sys.getenv(
  "EMPLER_INEI_RAW_ROOT",
  unset = NA_character_
)

if (is.na(raw_root)) {
  stop("Define EMPLER_INEI_RAW_ROOT con la carpeta raiz de los ZIP del INEI.")
}

fuentes <- data.frame(
  encuesta = c("EPE", "EPEN"),
  year = c(2021L, 2024L),
  periodo = c("Oct-Nov-Dic", "Oct-Nov-Dic"),
  variante = c("epe_lima", "epen_lima"),
  zip = c(
    "epe_lima/2021/45/csv/751-Modulo76.zip",
    "epen_lima/2024/45/csv/929-Modulo76.zip"
  ),
  factor = c("fa_ond21", "fa_ond24"),
  ocupacion = c("p204a", "C308_COD"),
  condicion = c("ocu200", "OCUP300"),
  edad = c("p108", "C208"),
  sexo = c("p107", "C207"),
  residente = c("resident", "RESIDENT"),
  ficha = c(
    paste0(
      "https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/",
      "DocumentosMetodologicos/2021-45/Ficha_Tecnica.pdf"
    ),
    paste0(
      "https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/",
      "DocumentosMetodologicos/2024-45/Ficha_Tecnica.pdf"
    )
  ),
  errores = c(
    paste0(
      "https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/",
      "DocumentosMetodologicos/2021-45/Error_Muestral_por_Trimestre.pdf"
    ),
    paste0(
      "https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/",
      "DocumentosMetodologicos/2024-45/Error_Muestral_por_Trimestre.pdf"
    )
  ),
  distritos_lima = c(43L, 43L),
  distritos_callao = c(6L, 7L),
  stringsAsFactors = FALSE
)

zip_paths <- file.path(raw_root, fuentes$zip)

if (any(!file.exists(zip_paths))) {
  stop("Falta uno o mas ZIP EPE/EPEN requeridos para la validacion.")
}

leer_zip <- function(path) {
  contenido <- unzip(path, list = TRUE)
  if (nrow(contenido) != 1L) {
    stop("Se esperaba un solo CSV dentro de ", basename(path), ".")
  }
  read.csv(
    unz(path, contenido$Name[[1]]),
    colClasses = "character",
    na.strings = c("", "NA"),
    check.names = FALSE
  )
}

numero <- function(x) suppressWarnings(as.numeric(x))

epe <- leer_zip(zip_paths[fuentes$encuesta == "EPE"])
epen <- leer_zip(zip_paths[fuentes$encuesta == "EPEN"])

resultado_flujo <- validar_bases(
  epe,
  epen,
  vars_epe = list(peso = "fa_ond21"),
  vars_epen = list(peso = "fa_ond24"),
  filtro_epe = function(d) numero(d$resident) == 1,
  filtro_epen = function(d) numero(d$RESIDENT) == 1
)

especificaciones <- list(
  EPE = list(
    datos = epe,
    year = "pano",
    month = "pmes",
    age = "p108",
    sex = "p107",
    resident = "resident",
    status = "ocu200",
    weight = "fa_ond21",
    occupation = "p204a",
    psu = c("submuestra", "conglome"),
    strata = "estrato"
  ),
  EPEN = list(
    datos = epen,
    year = "ANIO",
    month = "MES",
    age = "C208",
    sex = "C207",
    resident = "RESIDENT",
    status = "OCUP300",
    weight = "fa_ond24",
    occupation = "C308_COD",
    psu = c("MUESTRA", "REGION", "CONGLOMERADO"),
    strata = "ESTRATO"
  )
)

preparar <- function(especificacion) {
  d <- especificacion$datos
  age <- numero(d[[especificacion$age]])
  sex <- numero(d[[especificacion$sex]])
  resident <- numero(d[[especificacion$resident]])
  status <- numero(d[[especificacion$status]])
  weight <- numero(d[[especificacion$weight]])
  occupation <- trimws(as.character(d[[especificacion$occupation]]))
  valid_weight <- is.finite(weight) & weight > 0
  pet <- resident == 1 & age >= 14 & valid_weight
  active <- status %in% c(1, 2)
  occupied <- status == 1
  psu <- interaction(
    d[especificacion$psu], drop = TRUE, lex.order = TRUE
  )
  list(
    data = d,
    age = age,
    sex = sex,
    status = status,
    weight = weight,
    occupation = occupation,
    valid_weight = valid_weight,
    pet = pet,
    active = active,
    occupied = occupied,
    psu = psu,
    strata = d[[especificacion$strata]],
    month = d[[especificacion$month]]
  )
}

preparados <- lapply(especificaciones, preparar)

resumen_muestra <- do.call(rbind, lapply(names(preparados), function(encuesta) {
  x <- preparados[[encuesta]]
  especificacion <- especificaciones[[encuesta]]
  resident <- numero(x$data[[especificacion$resident]])
  age <- numero(x$data[[especificacion$age]])
  resident_14 <- resident == 1 & age >= 14
  pet <- x$pet
  active <- pet & x$active
  occupied <- pet & x$occupied
  data.frame(
    encuesta = encuesta,
    year = fuentes$year[fuentes$encuesta == encuesta],
    n_filas = nrow(x$data),
    n_residentes_14 = sum(resident_14, na.rm = TRUE),
    n_pet_estimacion = sum(pet),
    n_pea = sum(active),
    n_ocupados = sum(occupied),
    n_residentes_14_sin_peso = sum(
      resident_14 & !x$valid_weight,
      na.rm = TRUE
    ),
    n_ocupados_sin_peso = sum(
      resident_14 & x$occupied & !x$valid_weight,
      na.rm = TRUE
    ),
    n_ocupados_sin_codigo = sum(
      occupied & (is.na(x$occupation) | x$occupation == "")
    ),
    poblacion_ocupada = sum(x$weight[occupied]),
    n_upm_compuestas = length(unique(x$psu[pet])),
    n_estrato_faltante = sum(
      pet & (is.na(x$strata) | trimws(as.character(x$strata)) == "")
    ),
    n_estratos_publicados = length(unique(
      x$strata[pet & !is.na(x$strata) & trimws(as.character(x$strata)) != ""]
    )),
    stringsAsFactors = FALSE
  )
}))
rownames(resumen_muestra) <- NULL

oficial <- data.frame(
  encuesta = rep(c("EPE", "EPEN"), each = 12),
  indicador = rep(rep(c("actividad", "ocupacion"), each = 6), 2),
  dominio = rep(c(
    "total", "hombre", "mujer", "edad_14_24", "edad_25_44",
    "edad_45_mas"
  ), 4),
  estimado_oficial = c(
    66.1, 74.8, 58.3, 48.3, 83.3, 59.5,
    92.2, 93.4, 90.8, 85.3, 93.3, 94.4,
    65.6, 74.5, 57.5, 41.1, 84.6, 60.5,
    94.5, 95.0, 93.9, 87.2, 95.2, 96.0
  ),
  stringsAsFactors = FALSE
)

mascara_dominio <- function(x, dominio) {
  switch(dominio,
    total = rep(TRUE, length(x$age)),
    hombre = x$sex == 1,
    mujer = x$sex == 2,
    edad_14_24 = x$age >= 14 & x$age <= 24,
    edad_25_44 = x$age >= 25 & x$age <= 44,
    edad_45_mas = x$age >= 45
  )
}

media_ponderada <- function(valor, peso) {
  valido <- !is.na(valor) & is.finite(peso) & peso > 0
  sum(valor[valido] * peso[valido]) / sum(peso[valido])
}

calculados <- do.call(rbind, lapply(seq_len(nrow(oficial)), function(i) {
  objetivo <- oficial[i, ]
  x <- preparados[[objetivo$encuesta]]
  dominio <- mascara_dominio(x, objetivo$dominio)
  if (objetivo$indicador == "actividad") {
    usar <- x$pet & dominio
    valor <- x$active[usar]
  } else {
    usar <- x$pet & x$active & dominio
    valor <- x$occupied[usar]
  }
  estimado <- 100 * media_ponderada(valor, x$weight[usar])
  data.frame(
    encuesta = objetivo$encuesta,
    indicador = objetivo$indicador,
    dominio = objetivo$dominio,
    estimado = estimado,
    estimado_oficial = objetivo$estimado_oficial,
    diferencia = estimado - objetivo$estimado_oficial,
    coincide_redondeo = round(estimado, 1) == objetivo$estimado_oficial,
    stringsAsFactors = FALSE
  )
}))
rownames(calculados) <- NULL

normalizar_cobertura <- function(x, variable_year) {
  data.frame(
    encuesta = x$encuesta,
    year = x[[variable_year]],
    periodo = "Oct-Nov-Dic",
    prueba = "integracion_real",
    estado = x$estado,
    detalle = x$detalle,
    n = x$n,
    pct_n = x$pct_n,
    poblacion = x$poblacion,
    pct_poblacion = x$pct_poblacion,
    stringsAsFactors = FALSE
  )
}

cobertura <- rbind(
  normalizar_cobertura(resultado_flujo$epe$cobertura, "pano"),
  normalizar_cobertura(resultado_flujo$epen$cobertura, "ANIO")
)

resumir_homologacion <- function(resultado) {
  d <- resultado$datos
  peso <- numero(d[[resultado$variables[["peso"]]]])
  estado <- ifelse(
    is.na(d$homologacion_estado), "sin_estado", d$homologacion_estado
  )
  estados <- sort(unique(estado))
  do.call(rbind, lapply(estados, function(valor) {
    usar <- estado == valor
    data.frame(
      homologacion_estado = valor,
      n = sum(usar),
      pct_n = 100 * mean(usar),
      poblacion = sum(peso[usar], na.rm = TRUE),
      pct_poblacion = 100 * sum(peso[usar], na.rm = TRUE) /
        sum(peso, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
}

homologacion_epe <- resumir_homologacion(resultado_flujo$epe)

auditar_codigos_epe <- function(resultado) {
  d <- resultado$datos
  peso <- numero(d[[resultado$variables[["peso"]]]])
  base <- data.frame(
    co95_original = as.character(d[[resultado$variables[["ocupacion"]]]]),
    co95_normalizado = as.character(d$cno_cod),
    cno_homologado = as.character(d$cno_homologado),
    cno_candidatos = as.character(d$cno_candidatos),
    homologacion_estado = as.character(d$homologacion_estado),
    stringsAsFactors = FALSE
  )
  base[is.na(base)] <- ""
  claves <- unique(base)
  filas <- lapply(seq_len(nrow(claves)), function(i) {
    usar <- Reduce(`&`, Map(`==`, base, claves[i, ]))
    cbind(
      claves[i, , drop = FALSE],
      n = sum(usar),
      poblacion = sum(peso[usar], na.rm = TRUE)
    )
  })
  resultado <- do.call(rbind, filas)
  resultado[order(
    resultado$homologacion_estado,
    resultado$co95_normalizado
  ), ]
}

homologacion_codigos <- auditar_codigos_epe(resultado_flujo$epe)

expandir_pares <- function(auditoria) {
  filas <- lapply(seq_len(nrow(auditoria)), function(i) {
    candidatos <- strsplit(
      auditoria$cno_candidatos[i], "; ", fixed = TRUE
    )[[1]]
    candidatos <- candidatos[nzchar(candidatos)]
    if (length(candidatos) == 0L) candidatos <- NA_character_
    data.frame(
      co95_normalizado = auditoria$co95_normalizado[i],
      cno2015_candidato = candidatos,
      homologacion_estado = auditoria$homologacion_estado[i],
      n_origen = auditoria$n[i],
      poblacion_origen = auditoria$poblacion[i],
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, filas)
}

homologacion_pares <- expandir_pares(homologacion_codigos)

distribucion_gran_grupo <- function(resultado, encuesta) {
  d <- resultado$datos
  peso <- numero(d[[resultado$variables[["peso"]]]])
  grupo <- if ("cno_gran_grupo" %in% names(d)) {
    as.character(d$cno_gran_grupo)
  } else {
    substr(as.character(d$cno_cod), 1, 1)
  }
  grupo[is.na(grupo) | grupo == ""] <- "sin_asignar"
  grupos <- sort(unique(grupo))
  do.call(rbind, lapply(grupos, function(valor) {
    usar <- grupo == valor
    data.frame(
      encuesta = encuesta,
      gran_grupo = valor,
      n = sum(usar),
      poblacion = sum(peso[usar], na.rm = TRUE),
      pct_poblacion = 100 * sum(peso[usar], na.rm = TRUE) /
        sum(peso, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
}

gran_grupo <- rbind(
  distribucion_gran_grupo(resultado_flujo$epe, "EPE"),
  distribucion_gran_grupo(resultado_flujo$epen, "EPEN")
)

fuentes$archivo <- vapply(
  zip_paths,
  function(z) unzip(z, list = TRUE)$Name[[1]],
  character(1)
)
fuentes$sha256 <- vapply(
  zip_paths,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE
)
fuentes$comparabilidad_territorial_exacta <- FALSE
fuentes$nota_territorial <- paste0(
  "El modulo 76 no publica distrito; no se puede excluir Mi Peru de EPEN 2024."
)

# Invariantes de cierre. Una diferencia obliga a revisar los insumos o las
# definiciones antes de actualizar las salidas guardadas.
stopifnot(all(calculados$coincide_redondeo))
stopifnot(all(resumen_muestra$n_ocupados_sin_peso == 0L))
stopifnot(nrow(resultado_flujo$epe$datos) == resumen_muestra$n_ocupados[1])
stopifnot(nrow(resultado_flujo$epen$datos) == resumen_muestra$n_ocupados[2])

epe_procesada <- resultado_flujo$epe$datos
ambiguas <- epe_procesada$homologacion_estado != "unica"
stopifnot(all(is.na(epe_procesada$cno_homologado[ambiguas])))

salida <- "data-raw/validation"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
write.csv(
  fuentes,
  file.path(salida, "2026-11-12_epe_epen_fuentes.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  resumen_muestra,
  file.path(salida, "2026-11-12_epe_epen_muestra.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  calculados,
  file.path(salida, "2026-11-12_epe_epen_indicadores_oficiales.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  cobertura,
  file.path(salida, "2026-11-12_epe_epen_cobertura.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  homologacion_epe,
  file.path(salida, "2026-11-12_epe_homologacion.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  homologacion_codigos,
  file.path(salida, "2026-11-12_epe_homologacion_codigos.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  homologacion_pares,
  file.path(salida, "2026-11-12_epe_homologacion_pares.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  gran_grupo,
  file.path(salida, "2026-11-12_epe_epen_gran_grupo.csv"),
  row.names = FALSE,
  na = ""
)

cat("\nResumen de las muestras:\n")
print(resumen_muestra, row.names = FALSE)
cat("\nContraste oficial (24/24 deben coincidir al redondeo):\n")
print(calculados, row.names = FALSE, digits = 6)
cat("\nHomologacion EPE:\n")
print(homologacion_epe, row.names = FALSE, digits = 6)
