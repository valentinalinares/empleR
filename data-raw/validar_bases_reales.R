# Valida una base EPE (CO-95) y una EPEN (CNO 2015) reales antes de compararlas.
# Ejecutar desde la raiz del paquete con las bases descargadas del INEI:
#
#   devtools::load_all()
#   source("data-raw/validar_bases_reales.R")
#   epe  <- readRDS("epe_lima_2021.rds")
#   epen <- descargar(year = 2024, variante = "lima_movil", periodo = "45")
#   res  <- validar_bases(
#     epe, epen,
#     vars_epe = list(peso = "fa_ond21"),
#     vars_epen = list(peso = "fa_ond24")
#   )
#
# Comprueba, para cada base: variables del diccionario, pesos, diseno
# muestral, homologacion y cobertura del indice de IA (observaciones y
# poblacion), y compara la poblacion ocupada expandida entre ambas.
#
# Variables: se detectan con los alias por encuesta del paquete
# (empleR:::.alias_variables). EPE: pano, p204a, fa_def19/fa_def21, ocu200,
# p108 (edad solo en EPE). EPEN: ANIO, C308_COD, FAC300_ANUAL, OCUP300, C208.
# Ambas: ESTRATO, CONGLOMERADO. Con fa_def19 y fa_def21 a la vez hay que
# indicar el factor: vars_epe = list(peso = "fa_def19").
#
# El script no supone que dos bases tienen el mismo territorio. Esa decision
# debe quedar documentada por la validacion que lo invoque. Para el trimestre
# movil octubre-diciembre, la EPE 2021 cubre 43 distritos de Lima y 6 del
# Callao; la EPEN 2024 cubre 43 y 7, respectivamente. Sin distrito en el modulo
# 76 no se puede excluir Mi Peru de la EPEN.

validar_una <- function(d, nombre, vars = list(), ocupado = 1, edad_min = 14, filtro = NULL) {
  cat("\n==========", nombre, "==========\n")
  v <- empleR:::.detectar_variables(d, nombre, vars)
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
  # Las filas sin factor se reportan; no se imputan ni se excluyen (pendiente)
  cat(sprintf("Pesos: NA=%d, <=0=%d, min=%.1f, max=%.1f, suma=%.0f\n",
              sum(is.na(peso)), sum(peso <= 0, na.rm = TRUE),
              min(peso, na.rm = TRUE), max(peso, na.rm = TRUE), sum(peso, na.rm = TRUE)))

  if (!is.na(v["estrato"]) && !is.na(v["upm"])) {
    upm_por_estrato <- tapply(d[[v["upm"]]], d[[v["estrato"]]], function(z) length(unique(z)))
    cat(sprintf("Diseno: %d estratos, %d UPM, %d estratos con una sola UPM, NA en estrato/UPM: %d/%d\n",
                length(upm_por_estrato), length(unique(d[[v["upm"]]])), sum(upm_por_estrato == 1),
                sum(is.na(d[[v["estrato"]]])), sum(is.na(d[[v["upm"]]]))))
  } else {
    cat("AVISO: la base no trae estrato o UPM completos para describirlos.\n")
  }

  es_epe <- identical(nombre, "EPE")
  d <- cno(d, var_ocup = v[["ocupacion"]], homologar = es_epe,
           clasificador = if (es_epe) "CO_95" else "CNO_2015")
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

  gran_grupo <- function(d, variable_peso) {
    gg <- if ("cno_gran_grupo" %in% names(d)) d$cno_gran_grupo else substr(d$cno_cod, 1, 1)
    gg <- ifelse(is.na(gg), "sin_asignar", gg)
    w <- as.numeric(d[[variable_peso]])
    round(100 * tapply(w, gg, sum, na.rm = TRUE) / sum(w, na.rm = TRUE), 1)
  }
  cat("\nDistribucion por gran grupo CNO (% poblacion; EPE solo si los candidatos coinciden):\n")
  gg_epe <- gran_grupo(r_epe$datos, r_epe$variables[["peso"]])
  gg_epen <- gran_grupo(r_epen$datos, r_epen$variables[["peso"]])
  todos <- sort(union(names(gg_epe), names(gg_epen)))
  print(data.frame(gran_grupo = todos, EPE = as.numeric(gg_epe[todos]), EPEN = as.numeric(gg_epen[todos])),
        row.names = FALSE)
  invisible(list(epe = r_epe, epen = r_epen))
}
