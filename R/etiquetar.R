#' Aplicar etiquetas de valor a variables de la EPEN
#'
#' Interpreta variables codificadas de la EPEN siguiendo los diccionarios
#' oficiales del INEI. Reconoce tanto los nombres originales del modulo 76
#' (`C207`, `OCUP300`, `C366`, `C310`, `C311`, `C317`, `C338` y `AREA`) como
#' sus equivalentes en las bases procesadas de `{empleR}`.
#'
#' Por defecto conserva intacta cada columna de codigos y agrega una columna
#' terminada en `_label`. Esta separacion permite usar las etiquetas para
#' tablas y graficos sin perder los codigos necesarios para validar o procesar
#' los microdatos. Los valores ausentes siguen ausentes; un codigo no incluido
#' en el diccionario genera una advertencia y su etiqueta queda en `NA`.
#'
#' @param data `data.frame` con microdatos de la EPEN.
#' @param vars Vector de nombres de variables a etiquetar. Si es `NULL`
#'   (por defecto), usa todas las variables reconocidas presentes en `data`.
#' @param as_factor Logico. Si `TRUE` (por defecto), devuelve las etiquetas
#'   como factores. Si `FALSE`, las devuelve como texto.
#' @param reemplazar Logico. Si es `FALSE` (por defecto), conserva los codigos
#'   y agrega columnas de etiquetas. Usa `TRUE` solo para reproducir el
#'   comportamiento anterior, que reemplaza las columnas seleccionadas.
#'
#' @return El mismo `data.frame`. Por defecto agrega una columna de etiqueta
#'   por concepto reconocido y conserva las columnas originales. Los nombres
#'   posibles son `sex_label`, `labor_status_label`, `education_label`,
#'   `institutional_sector_label`, `occupational_category_label`,
#'   `firm_size_label`, `area_label` e `income_periodicity_label`.
#'
#' @references INEI. Diccionario de variables EPEN anual 2023.
#'   <https://www.inei.gob.pe/media/DATOS_ABIERTOS/EPEN_DEP/DICCIONARIO/2023/Anual-Ener-Dic/Diccionario.pdf>
#'
#' @export
#'
#' @examples
#' # Conserva sex_code y crea sex_label
#' muestra_etiquetada <- etiquetar(muestra_epen_2024)
#' table(muestra_etiquetada$sex_label)
#'
#' # Funciona tambien con nombres originales del modulo 76
#' crudos <- data.frame(C207 = c("1", "2"), C366 = c("6", "11"))
#' etiquetar(crudos, as_factor = FALSE)
#'
#' # Compatibilidad con el comportamiento anterior
#' etiquetar(
#'   muestra_epen_2024,
#'   vars = c("sex_code", "education_code"),
#'   reemplazar = TRUE
#' )
etiquetar <- function(data,
                      vars = NULL,
                      as_factor = TRUE,
                      reemplazar = FALSE) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} debe ser un data.frame.")
  }
  if (!is.logical(as_factor) || length(as_factor) != 1L || is.na(as_factor)) {
    cli::cli_abort("{.arg as_factor} debe ser TRUE o FALSE.")
  }
  if (!is.logical(reemplazar) || length(reemplazar) != 1L || is.na(reemplazar)) {
    cli::cli_abort("{.arg reemplazar} debe ser TRUE o FALSE.")
  }

  if (is.null(vars)) {
    vars <- intersect(names(data), names(.especificaciones_etiquetas))
  } else {
    vars <- unique(as.character(vars))
  }

  if (length(vars) == 0L) {
    cli::cli_warn("No se encontraron variables con diccionario disponible.")
    return(data)
  }

  desconocidas <- setdiff(vars, names(.especificaciones_etiquetas))
  if (length(desconocidas) > 0L) {
    cli::cli_warn(c(
      "Variable(s) sin diccionario disponible: {.field {desconocidas}}.",
      "i" = "Se omitieron y las demas variables se procesaron."
    ))
    vars <- setdiff(vars, desconocidas)
  }

  ausentes <- setdiff(vars, names(data))
  if (length(ausentes) > 0L) {
    cli::cli_abort(c(
      "Variable(s) solicitada(s) que no existen en los datos: {.field {ausentes}}.",
      "i" = "Revisa {.arg vars} o los nombres de las columnas."
    ))
  }

  if (length(vars) == 0L) return(data)

  destinos_asignados <- list()
  n_procesadas <- 0L

  for (v in vars) {
    especificacion <- .especificaciones_etiquetas[[v]]
    mapa <- .diccionarios_epen[[especificacion$diccionario]]
    aplicado <- .aplicar_etiqueta(data[[v]], mapa, as_factor = as_factor)

    if (length(aplicado$desconocidos) > 0L) {
      codigos <- utils::head(aplicado$desconocidos, 8L)
      cli::cli_warn(c(
        "{sum(aplicado$filas_desconocidas)} fila(s) de {.field {v}} tienen codigos sin etiqueta: {.val {codigos}}.",
        "i" = "Los codigos originales se conservan y sus etiquetas quedan en NA."
      ))
    }

    destino <- if (reemplazar) v else especificacion$destino
    if (!reemplazar && destino %in% names(destinos_asignados)) {
      anterior <- destinos_asignados[[destino]]
      iguales <- (is.na(anterior) & is.na(aplicado$valor)) |
        as.character(anterior) == as.character(aplicado$valor)
      iguales[is.na(iguales)] <- FALSE
      if (!all(iguales)) {
        cli::cli_abort(c(
          "Las variables seleccionadas no producen la misma {.field {destino}}.",
          "i" = "Revisa los codigos de {.field {v}} y de sus aliases antes de continuar."
        ))
      }
    }

    data[[destino]] <- aplicado$valor
    if (!reemplazar) destinos_asignados[[destino]] <- aplicado$valor
    n_procesadas <- n_procesadas + 1L
  }

  n_destinos <- if (reemplazar) n_procesadas else length(destinos_asignados)
  accion <- if (reemplazar) "reemplazada(s)" else "agregada(s)"
  cli::cli_inform(c("v" = "{n_destinos} columna(s) de etiquetas {accion}."))
  data
}


# Diccionarios de etiquetas -----------------------------------------------
# Codificaciones verificadas contra el diccionario oficial EPEN 2023. Los
# nombres procesados documentan su variable original en
# .especificaciones_etiquetas.

#' @noRd
.diccionarios_epen <- list(
  sexo = c(
    "1" = "Hombre",
    "2" = "Mujer"
  ),
  condicion_actividad = c(
    "0" = "Sin informaci\u00f3n",
    "1" = "Ocupado",
    "2" = "Desocupado abierto",
    "3" = "Desocupado oculto",
    "4" = "Inactivo pleno"
  ),
  nivel_educativo = c(
    "1"  = "Sin nivel",
    "2"  = "Educaci\u00f3n inicial",
    "3"  = "Primaria incompleta",
    "4"  = "Primaria completa",
    "5"  = "Secundaria incompleta",
    "6"  = "Secundaria completa",
    "7"  = "B\u00e1sica especial",
    "8"  = "Superior no universitaria incompleta",
    "9"  = "Superior no universitaria completa",
    "10" = "Superior universitaria incompleta",
    "11" = "Superior universitaria completa",
    "12" = "Maestr\u00eda / Doctorado"
  ),
  sector_institucional = c(
    "1" = "Fuerzas Armadas, Polic\u00eda Nacional del Per\u00fa (militares)",
    "2" = "Administraci\u00f3n p\u00fablica",
    "3" = "Empresa p\u00fablica",
    "4" = "Empresas especiales de servicios (SERVICE)",
    "5" = "Empresa o patrono privado",
    "6" = "Otra"
  ),
  categoria_ocupacional = c(
    "1"  = "Empleador o patrono",
    "2"  = "Trabajador independiente",
    "3"  = "Empleado u obrero",
    "4"  = "Ayudante en un negocio de la familia",
    "5"  = "Ayudante en el empleo de un familiar",
    "6"  = "Trabajador del hogar",
    "7"  = "Aprendiz/practicante remunerado",
    "8"  = "Practicante sin remuneraci\u00f3n",
    "9"  = "Ayudante en un negocio de la familia de otro hogar",
    "10" = "Ayudante en el empleo de un familiar de otro hogar"
  ),
  tamano_empresa = c(
    "1" = "Hasta 20 personas",
    "2" = "De 21 a 50 personas",
    "3" = "De 51 a 100 personas",
    "4" = "De 101 a 500 personas",
    "5" = "M\u00e1s de 500 personas"
  ),
  area_procesada = c(
    "0" = "Urbano",
    "1" = "Rural"
  ),
  area_original = c(
    "1" = "Urbano",
    "2" = "Rural"
  ),
  periodicidad_ingreso = c(
    "1" = "Diario",
    "2" = "Semanal",
    "3" = "Quincenal",
    "4" = "Mensual",
    "5" = "No recibi\u00f3 pago alguno"
  )
)


# Relacion entre nombres originales/procesados y cada diccionario ---------

#' @noRd
.especificaciones_etiquetas <- list(
  C207 = list(diccionario = "sexo", destino = "sex_label"),
  sex_code = list(diccionario = "sexo", destino = "sex_label"),
  OCUP300 = list(
    diccionario = "condicion_actividad",
    destino = "labor_status_label"
  ),
  labor_status_code = list(
    diccionario = "condicion_actividad",
    destino = "labor_status_label"
  ),
  C366 = list(diccionario = "nivel_educativo", destino = "education_label"),
  education_code = list(
    diccionario = "nivel_educativo",
    destino = "education_label"
  ),
  C311 = list(
    diccionario = "sector_institucional",
    destino = "institutional_sector_label"
  ),
  institutional_sector_code = list(
    diccionario = "sector_institucional",
    destino = "institutional_sector_label"
  ),
  C310 = list(
    diccionario = "categoria_ocupacional",
    destino = "occupational_category_label"
  ),
  occupational_category_code = list(
    diccionario = "categoria_ocupacional",
    destino = "occupational_category_label"
  ),
  C317 = list(diccionario = "tamano_empresa", destino = "firm_size_label"),
  firm_size_code = list(
    diccionario = "tamano_empresa",
    destino = "firm_size_label"
  ),
  AREA = list(diccionario = "area_original", destino = "area_label"),
  is_rural = list(diccionario = "area_procesada", destino = "area_label"),
  C338 = list(
    diccionario = "periodicidad_ingreso",
    destino = "income_periodicity_label"
  ),
  income_periodicity_code = list(
    diccionario = "periodicidad_ingreso",
    destino = "income_periodicity_label"
  )
)


# Helpers internos --------------------------------------------------------

#' @noRd
.aplicar_etiqueta <- function(x, mapa, as_factor) {
  original <- as.character(x)
  ausente <- is.na(x) | trimws(original) == ""
  es_etiqueta <- !ausente & original %in% unname(mapa)

  resultado <- unname(mapa[original])
  resultado[es_etiqueta] <- original[es_etiqueta]
  resultado[ausente] <- NA_character_

  filas_desconocidas <- !ausente & is.na(resultado)
  desconocidos <- sort(unique(original[filas_desconocidas]))

  if (as_factor) {
    resultado <- factor(resultado, levels = unique(unname(mapa)))
  }

  list(
    valor = resultado,
    filas_desconocidas = filas_desconocidas,
    desconocidos = desconocidos
  )
}
