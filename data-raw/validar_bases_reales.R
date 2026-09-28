# Valida una base EPE (CO-95) y una EPEN (CNO 2015) reales antes de compararlas.
# Ejecutar desde la raiz del paquete con las bases descargadas del INEI:
#
#   devtools::load_all()
#   source("data-raw/validar_bases_reales.R")
#   epe  <- readRDS("epe_lima_2019.rds")      # o readr::read_csv(...)
#   epen <- descargar(year = 2024)
#   res  <- validar_bases(epe, epen,
#                         filtro_epen = function(d) d$region_code == 15)  # territorio comparable
#
# Comprueba, para cada base: variables del diccionario, pesos, diseno
# muestral, homologacion y cobertura del indice de IA (observaciones y
# poblacion), y compara la poblacion ocupada expandida entre ambas.

.candidatos <- list(
  year      = c("year", "YEAR", "anio", "ANIO", "ANO", "AÑO", "año"),
  ocupacion = c("C308_COD", "P204A", "p204a", "occupation_code_4d", "occupation_code_raw"),
  peso      = c("weight", "FACTOR07", "FACTOR", "fexp", "fac500a", "FAC500A"),
  estrato   = c("strata_code", "ESTRATO", "estrato"),
  upm       = c("cluster_id", "CONGLOME", "conglome"),
  condicion = c("labor_status_code", "OCU500", "ocu500", "OCA500"),
  edad      = c("age", "P208A", "p208a", "EDAD")
)

.buscar <- function(d, rol, forzada = NULL) {
  if (!is.null(forzada)) return(if (forzada %in% names(d)) forzada else NA_character_)
  empleR:::.buscar_nombre(names(d), .candidatos[[rol]])
}

validar_una <- function(d, nombre, vars = list(), ocupado = 1, edad_min = 14, filtro = NULL) {
  cat("\n==========", nombre, "==========\n")
  v <- vapply(names(.candidatos), function(r) .buscar(d, r, vars[[r]]), character(1))
  print(data.frame(rol = names(v), variable = unname(v)), row.names = FALSE)
  faltan <- names(v)[is.na(v) & names(v) %in% c("year", "ocupacion", "peso")]
  if (length(faltan) > 0) stop(nombre, ": faltan variables obligatorias: ", paste(faltan, collapse = ", "))

  n0 <- nrow(d)
  if (!is.null(filtro)) {
    d <- d[filtro(d) %in% TRUE, , drop = FALSE]
    cat("Filtro territorial/periodo:", n0, "->", nrow(d), "filas\n")
  } else {
    cat("AVISO: sin filtro territorial; revisa que la poblacion sea comparable.\n")
  }
  if (!is.na(v["condicion"])) d <- d[d[[v["condicion"]]] %in% ocupado, , drop = FALSE]
  if (!is.na(v["edad"])) d <- d[as.numeric(d[[v["edad"]]]) >= edad_min, , drop = FALSE]
  cat("Ocupados", if (!is.na(v["edad"])) paste0("de ", edad_min, "+ anos"), ":", nrow(d), "filas\n")

  peso <- as.numeric(d[[v["peso"]]])
  cat(sprintf("Pesos: NA=%d, <=0=%d, min=%.1f, max=%.1f, suma=%.0f\n",
              sum(is.na(peso)), sum(peso <= 0, na.rm = TRUE),
              min(peso, na.rm = TRUE), max(peso, na.rm = TRUE), sum(peso, na.rm = TRUE)))

  if (!is.na(v["estrato"]) && !is.na(v["upm"])) {
    upm_por_estrato <- tapply(d[[v["upm"]]], d[[v["estrato"]]], function(z) length(unique(z)))
    cat(sprintf("Diseno: %d estratos, %d UPM, %d estratos con una sola UPM, NA en estrato/UPM: %d/%d\n",
                length(upm_por_estrato), length(unique(d[[v["upm"]]])), sum(upm_por_estrato == 1),
                sum(is.na(d[[v["estrato"]]])), sum(is.na(d[[v["upm"]]]))))
  } else {
    cat("AVISO: sin estrato o UPM; los errores estandar seran aproximados.\n")
  }

  d <- cno(d, var_ocup = v[["ocupacion"]], homologar = identical(nombre, "EPE"))
  d <- suppressWarnings(ia_exposicion(d, incluir_tipo = TRUE))
  cob <- cobertura(d, var_peso = v[["peso"]])
  print(cob, row.names = FALSE)
  if ("homologacion_estado" %in% names(d)) print(table(d$homologacion_estado, useNA = "ifany"))
  invisible(list(datos = d, cobertura = cob, variables = v))
}

validar_bases <- function(epe, epen, vars_epe = list(), vars_epen = list(),
                          filtro_epe = NULL, filtro_epen = NULL) {
  r_epe  <- validar_una(epe, "EPE", vars_epe, filtro = filtro_epe)
  r_epen <- validar_una(epen, "EPEN", vars_epen, filtro = filtro_epen)

  pob <- function(r) sum(as.numeric(r$datos[[r$variables[["peso"]]]]), na.rm = TRUE)
  cat("\n========== Comparacion ==========\n")
  cat(sprintf("Poblacion ocupada expandida: EPE=%.0f, EPEN=%.0f (ratio %.3f)\n",
              pob(r_epe), pob(r_epen), pob(r_epen) / pob(r_epe)))

  # EPEN: contrastar con los indicadores oficiales precalculados del paquete
  years <- unique(suppressWarnings(as.integer(r_epen$datos[[r_epen$variables[["year"]]]])))
  ref <- indicadores_epen[indicadores_epen$year %in% years &
                            indicadores_epen$survey_variant == "departamentos_anual", ]
  if (nrow(ref) > 0 && is.null(filtro_epen)) {
    cat(sprintf("EPEN ocupados oficiales (indicadores_epen, %s): %.0f\n",
                paste(years, collapse = ","), sum(ref$occupied_population)))
  }

  gran_grupo <- function(d) {
    gg <- if ("cno_gran_grupo" %in% names(d)) d$cno_gran_grupo else substr(d$cno_cod, 1, 1)
    gg <- ifelse(is.na(gg), "sin_asignar", gg)
    w <- as.numeric(d[[r_epe$variables[["peso"]]]])
    round(100 * tapply(w, gg, sum, na.rm = TRUE) / sum(w, na.rm = TRUE), 1)
  }
  cat("\nDistribucion por gran grupo CNO (% poblacion; EPE solo si los candidatos coinciden):\n")
  gg_epe <- gran_grupo(r_epe$datos)
  gg_epen <- {
    w <- as.numeric(r_epen$datos[[r_epen$variables[["peso"]]]])
    g <- substr(r_epen$datos$cno_cod, 1, 1)
    g <- ifelse(is.na(g), "sin_asignar", g)
    round(100 * tapply(w, g, sum, na.rm = TRUE) / sum(w, na.rm = TRUE), 1)
  }
  todos <- sort(union(names(gg_epe), names(gg_epen)))
  print(data.frame(gran_grupo = todos, EPE = as.numeric(gg_epe[todos]), EPEN = as.numeric(gg_epen[todos])),
        row.names = FALSE)
  invisible(list(epe = r_epe, epen = r_epen))
}
