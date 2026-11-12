#' Visualizar un indicador por ambito departamental de la EPEN
#'
#' Une una tabla con una fila por ambito departamental de la Encuesta
#' Permanente de Empleo Nacional (EPEN) a los poligonos incluidos en el paquete
#' y devuelve un mapa interactivo (`leaflet`) o estatico (`ggplot2`). La funcion
#' recibe resultados ya agregados; no calcula indicadores.
#'
#' @details
#' **Ambitos de la EPEN.** El INEI no publica los resultados de Lima como un
#' unico departamento. Distingue `DIVISION_LIMA = 1`, Lima Metropolitana y la
#' Provincia Constitucional del Callao, de `DIVISION_LIMA = 2`, Region Lima
#' (las otras nueve provincias del departamento). Por ello, cuando `CCDD` o
#' `region_code` vale 15, [mapa()] exige tambien `DIVISION_LIMA` o
#' `division_lima`. Nunca asigna ese valor solo al poligono de Lima.
#'
#' Los otros 23 departamentos conservan su ambito habitual. En total, el mapa
#' contiene 25 ambitos departamentales EPEN. Los poligonos de los dos ambitos
#' de Lima se construyen a partir de los poligonos provinciales incluidos en el
#' paquete.
#'
#' **Llave de union.** La funcion admite:
#'
#' 1. `CCDD` o `region_code`, mas `DIVISION_LIMA` o `division_lima` para el
#'    codigo 15; o
#' 2. un nombre oficial en `ambito_epen`, `departamento`, `DEPARTAMENTO`, `dep`
#'    o `region`.
#'
#' Si hay varias columnas geograficas, todas las que tengan un valor deben
#' coincidir. Los codigos invalidos y las contradicciones producen un error.
#' Los nombres no reconocidos se informan y no se dibujan.
#'
#' **Nivel geografico.** Esta version no admite provincias ni distritos. Un
#' mapa representa los valores que recibe, pero no demuestra representatividad
#' ni significancia estadistica. Revisa el diseno muestral, el numero de
#' observaciones y la precision antes de comparar territorios.
#'
#' @param data `data.frame` con una fila por ambito departamental EPEN. Para
#'   resultados de [indicadores()], usa
#'   `por = c("region_code", "division_lima")`.
#' @param var Nombre de la columna numerica que se representara con colores.
#' @param nivel Nivel geografico. Solo se admite `"departamento"`; los niveles
#'   `"provincia"` y `"distrito"` producen un error informativo.
#' @param tipo Tipo de visualizacion: `"leaflet"` (por defecto, interactivo)
#'   o `"ggplot"` (estatico).
#' @param titulo Titulo del mapa y de la leyenda. Si es `NULL`, usa `var`.
#' @param paleta Paleta de colores de `leaflet` o `ggplot2`.
#' @param shapes Objeto `sf` opcional con `geo_id`, `departamento` y una
#'   geometria por ambito EPEN. Si es `NULL`, se construyen los poligonos
#'   oficiales a partir de [shapes_departamentos] y [shapes_provincias].
#'
#' @return Un objeto `leaflet` o `ggplot`.
#' @export
#'
#' @examples
#' ingreso_dep <- indicadores(
#'   muestra_epen_2024,
#'   "ingreso_promedio",
#'   por = c("region_code", "division_lima")
#' )
#' mapa(ingreso_dep, "estimado", tipo = "ggplot")
mapa <- function(data,
                 var,
                 nivel = "departamento",
                 tipo = c("leaflet", "ggplot"),
                 titulo = NULL,
                 paleta = "YlOrRd",
                 shapes = NULL) {
  tipo <- match.arg(tipo)
  .validar_nivel_mapa(nivel)

  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} debe ser un {.cls data.frame}.")
  }
  if (!is.character(var) || length(var) != 1L || is.na(var)) {
    cli::cli_abort("{.arg var} debe ser el nombre de una columna de {.arg data}.")
  }
  if (!var %in% names(data)) {
    cli::cli_abort("La variable '{var}' no existe en los datos.")
  }
  if (!is.numeric(data[[var]])) {
    cli::cli_abort(c(
      "La variable '{var}' debe ser numerica.",
      "i" = "Tiene clase {.cls {class(data[[var]])}}."
    ))
  }
  if (any(is.infinite(data[[var]]), na.rm = TRUE)) {
    cli::cli_abort("La variable '{var}' no puede contener valores infinitos.")
  }

  shapes <- shapes %||% .shapes_ambitos_epen()
  mapa_data <- .unir_mapa(data, var = var, shapes = shapes)
  titulo <- titulo %||% var

  if (tipo == "leaflet") {
    .mapa_leaflet(mapa_data, var = var, titulo = titulo, paleta = paleta)
  } else {
    .mapa_ggplot(mapa_data, var = var, titulo = titulo, paleta = paleta)
  }
}


# Helpers internos --------------------------------------------------------

# Codigos politicos usados para identificar los 23 departamentos que no
# requieren una division especial de Lima.
.departamentos_ubigeo <- c(
  "01" = "AMAZONAS",      "02" = "ANCASH",        "03" = "APURIMAC",
  "04" = "AREQUIPA",      "05" = "AYACUCHO",      "06" = "CAJAMARCA",
  "07" = "CALLAO",        "08" = "CUSCO",         "09" = "HUANCAVELICA",
  "10" = "HUANUCO",       "11" = "ICA",           "12" = "JUNIN",
  "13" = "LA LIBERTAD",   "14" = "LAMBAYEQUE",    "15" = "LIMA",
  "16" = "LORETO",        "17" = "MADRE DE DIOS", "18" = "MOQUEGUA",
  "19" = "PASCO",         "20" = "PIURA",         "21" = "PUNO",
  "22" = "SAN MARTIN",    "23" = "TACNA",         "24" = "TUMBES",
  "25" = "UCAYALI"
)

# Ambitos que aparecen en los cuadros departamentales oficiales de la EPEN.
.ambitos_epen <- c(
  .departamentos_ubigeo[!names(.departamentos_ubigeo) %in% c("07", "15")],
  "15-1" = "LIMA METROPOLITANA Y CALLAO",
  "15-2" = "REGION LIMA"
)
.ambitos_epen <- .ambitos_epen[c(
  "01", "02", "03", "04", "05", "06", "08", "09", "10", "11", "12",
  "13", "14", "15-1", "15-2", "16", "17", "18", "19", "20", "21",
  "22", "23", "24", "25"
)]

#' @noRd
.validar_nivel_mapa <- function(nivel) {
  if (!is.character(nivel) || length(nivel) != 1L || is.na(nivel)) {
    cli::cli_abort("{.arg nivel} debe ser {.val departamento}.")
  }
  if (nivel %in% c("provincia", "distrito")) {
    cli::cli_abort(c(
      "El nivel {.val {nivel}} no esta disponible en esta version de {.fn mapa}.",
      "i" = paste(
        "La interfaz estable representa los ambitos departamentales que publica",
        "la EPEN."
      ),
      ">" = "Usa {.code nivel = \"departamento\"}."
    ))
  }
  if (!identical(nivel, "departamento")) {
    cli::cli_abort("{.arg nivel} debe ser {.val departamento}, no {.val {nivel}}.")
  }
  invisible(nivel)
}

#' @noRd
.normalizar_departamento <- function(x) {
  x <- as.character(x)
  x <- chartr(
    "\u00e1\u00e9\u00ed\u00f3\u00fa\u00fc\u00c1\u00c9\u00cd\u00d3\u00da\u00dc",
    "aeiouuAEIOUU",
    x
  )
  x <- toupper(gsub("\\s+", " ", trimws(x)))
  x[!is.na(x) & x == ""] <- NA_character_
  x
}

#' @noRd
.aliases_ambitos_epen <- function() {
  aliases <- stats::setNames(names(.ambitos_epen), unname(.ambitos_epen))
  c(
    aliases,
    "LIMA METROPOLITANA Y LA PROVINCIA CONSTITUCIONAL DEL CALLAO" = "15-1",
    "LIMA METROP./PROV. CONST. CALLAO" = "15-1",
    "LIMA METROPOLITANA Y PROVINCIA CONSTITUCIONAL DEL CALLAO" = "15-1"
  )
}

#' @noRd
.nombre_a_geo_id <- function(x) {
  normalizado <- .normalizar_departamento(x)
  unname(.aliases_ambitos_epen()[normalizado])
}

#' @noRd
.resolver_division_lima <- function(data, columnas) {
  n <- nrow(data)
  if (length(columnas) == 0L) {
    return(list(valor = rep(NA_integer_, n), presente = rep(FALSE, n)))
  }

  valores <- lapply(columnas, function(col) {
    x <- trimws(as.character(data[[col]]))
    presente <- !is.na(x) & x != ""
    invalido <- presente & !x %in% c("1", "2")
    if (any(invalido)) {
      i <- which(invalido)[1]
      cli::cli_abort(c(
        "{.field {col}} solo puede valer 1 o 2.",
        "x" = "Fila {i}: {.val {data[[col]][i]}}."
      ))
    }
    as.integer(ifelse(presente, x, NA_character_))
  })

  resultado <- rep(NA_integer_, n)
  for (i in seq_len(n)) {
    fila <- unique(stats::na.omit(vapply(valores, `[`, integer(1), i)))
    if (length(fila) > 1L) {
      cli::cli_abort(
        "Las columnas {.field {columnas}} discrepan sobre la division de Lima en la fila {i}."
      )
    }
    if (length(fila) == 1L) {
      resultado[i] <- fila
    }
  }

  list(
    valor = resultado,
    presente = Reduce(`|`, lapply(columnas, function(col) {
      x <- trimws(as.character(data[[col]]))
      !is.na(x) & x != ""
    }))
  )
}

#' @noRd
.codigo_a_geo_id <- function(x, division, columna) {
  x_chr <- trimws(as.character(x))
  presente <- !is.na(x_chr) & x_chr != ""
  formato_valido <- !presente | grepl("^[0-9]{1,2}$", x_chr)
  if (any(!formato_valido)) {
    i <- which(!formato_valido)[1]
    cli::cli_abort(c(
      "{.field {columna}} contiene un codigo invalido.",
      "x" = "Fila {i}: {.val {x[i]}}."
    ))
  }

  codigo <- rep(NA_character_, length(x_chr))
  codigo[presente] <- sprintf("%02d", as.integer(x_chr[presente]))
  permitidos <- c(names(.departamentos_ubigeo)[
    !names(.departamentos_ubigeo) %in% c("07", "15")
  ], "15")
  invalido <- presente & !codigo %in% permitidos
  if (any(invalido)) {
    i <- which(invalido)[1]
    cli::cli_abort(c(
      "{.field {columna}} no es un codigo departamental valido de la EPEN.",
      "x" = "Fila {i}: {.val {x[i]}}.",
      "i" = "La EPEN integra Callao en el codigo 15; no utiliza el codigo 07."
    ))
  }

  falta_division <- codigo == "15" & is.na(division)
  falta_division[is.na(falta_division)] <- FALSE
  if (any(falta_division)) {
    cli::cli_abort(c(
      "El codigo 15 requiere {.field DIVISION_LIMA} o {.field division_lima}.",
      "i" = paste(
        "Usa 1 para Lima Metropolitana y Callao, o 2 para Region Lima.",
        "Agrupa el indicador por ambas variables antes de mapear."
      )
    ))
  }

  sobra_division <- presente & codigo != "15" & !is.na(division)
  sobra_division[is.na(sobra_division)] <- FALSE
  if (any(sobra_division)) {
    i <- which(sobra_division)[1]
    cli::cli_abort(
      "La division de Lima solo corresponde al codigo 15; revisa la fila {i}."
    )
  }

  ifelse(codigo == "15", paste0("15-", division), codigo)
}

#' @noRd
.combinar_llaves <- function(ids, presentes, columnas) {
  n <- length(ids[[1]])
  resultado <- rep(NA_character_, n)

  for (i in seq_len(n)) {
    reconocidos <- unique(stats::na.omit(vapply(ids, `[`, character(1), i)))
    desconocidos <- vapply(seq_along(ids), function(j) {
      presentes[[j]][i] && is.na(ids[[j]][i])
    }, logical(1))

    if (length(reconocidos) > 1L ||
          (length(reconocidos) == 1L && any(desconocidos))) {
      usados <- columnas[vapply(presentes, `[`, logical(1), i)]
      cli::cli_abort(c(
        "Las columnas geograficas no coinciden en la fila {i}.",
        "x" = "Columnas con valor: {.field {usados}}."
      ))
    }
    if (length(reconocidos) == 1L) {
      resultado[i] <- reconocidos
    }
  }
  resultado
}

#' @noRd
.llave_ambito_epen <- function(data) {
  columnas_codigo <- intersect(c("CCDD", "region_code"), names(data))
  columnas_division <- intersect(c("DIVISION_LIMA", "division_lima"), names(data))
  columnas_nombre <- intersect(
    c("ambito_epen", "departamento", "DEPARTAMENTO", "dep", "region"),
    names(data)
  )

  if (length(columnas_codigo) == 0L && length(columnas_nombre) == 0L) {
    cli::cli_abort(c(
      "No se encontro una llave geografica en los datos.",
      "i" = paste(
        "Incluye {.field CCDD} o {.field region_code}; para el codigo 15",
        "incluye tambien la division de Lima."
      )
    ))
  }

  division <- .resolver_division_lima(data, columnas_division)
  ids <- list()
  presentes <- list()
  etiquetas <- character()

  for (col in columnas_codigo) {
    x <- data[[col]]
    x_chr <- trimws(as.character(x))
    ids[[length(ids) + 1L]] <- .codigo_a_geo_id(x, division$valor, col)
    presentes[[length(presentes) + 1L]] <- !is.na(x_chr) & x_chr != ""
    etiquetas <- c(etiquetas, col)
  }

  for (col in columnas_nombre) {
    x <- data[[col]]
    x_chr <- trimws(as.character(x))
    ids[[length(ids) + 1L]] <- .nombre_a_geo_id(x)
    presentes[[length(presentes) + 1L]] <- !is.na(x_chr) & x_chr != ""
    etiquetas <- c(etiquetas, col)
  }

  if (length(columnas_codigo) == 0L && any(division$presente)) {
    cli::cli_abort("La division de Lima requiere tambien {.field CCDD} o {.field region_code}.")
  }

  valores <- .combinar_llaves(ids, presentes, etiquetas)
  columnas <- unique(c(columnas_codigo, columnas_division, columnas_nombre))
  original <- data[[c(columnas_codigo, columnas_nombre)[1]]]

  list(valores = valores, columnas = columnas, original = original)
}

#' @noRd
.shapes_ambitos_epen <- function() {
  # Los objetos pueden recuperar la clase tibble al cargarse desde LazyData.
  # Convertirlos explicitamente evita que `[.tbl_df` intente tratar la columna
  # sfc como un escalar durante la construccion de las vinetas instaladas.
  departamentos <- sf::st_as_sf(as.data.frame(shapes_departamentos))
  provincias <- sf::st_as_sf(as.data.frame(shapes_provincias))

  otros <- departamentos[
    !departamentos$departamento %in% c("LIMA", "CALLAO"),
  ]
  inversa <- stats::setNames(
    names(.departamentos_ubigeo),
    .normalizar_departamento(unname(.departamentos_ubigeo))
  )
  otros$geo_id <- unname(inversa[.normalizar_departamento(otros$departamento)])

  es_lima_metropolitana <- (
    provincias$departamento == "LIMA" & provincias$provincia == "LIMA"
  ) | provincias$departamento == "CALLAO"
  es_region_lima <- provincias$departamento == "LIMA" &
    provincias$provincia != "LIMA"

  lima_metropolitana <- sf::st_sf(
    departamento = unname(.ambitos_epen["15-1"]),
    geo_id = "15-1",
    geometry = sf::st_union(provincias[es_lima_metropolitana, ])
  )
  region_lima <- sf::st_sf(
    departamento = unname(.ambitos_epen["15-2"]),
    geo_id = "15-2",
    geometry = sf::st_union(provincias[es_region_lima, ])
  )

  otros <- otros[, c("departamento", "geo_id", attr(otros, "sf_column"))]
  resultado <- rbind(otros, lima_metropolitana, region_lima)
  resultado$departamento <- unname(.ambitos_epen[resultado$geo_id])
  resultado <- resultado[match(names(.ambitos_epen), resultado$geo_id), ]
  rownames(resultado) <- NULL
  resultado
}

#' @noRd
.unir_mapa <- function(data, var, shapes) {
  requeridas <- c("geo_id", "departamento")
  if (!inherits(shapes, "sf") || !all(requeridas %in% names(shapes))) {
    cli::cli_abort(
      "{.arg shapes} debe ser un objeto {.cls sf} con {.field geo_id} y {.field departamento}."
    )
  }
  if (anyNA(shapes$geo_id) || anyDuplicated(shapes$geo_id)) {
    cli::cli_abort("{.arg shapes} debe tener una geometria por {.field geo_id}, sin vacios.")
  }

  llave <- .llave_ambito_epen(data)
  if (var %in% llave$columnas) {
    cli::cli_abort("{.arg var} no puede ser una columna geografica.")
  }
  claves <- llave$valores

  repetidos <- unique(claves[!is.na(claves) & duplicated(claves)])
  if (length(repetidos) > 0L) {
    cli::cli_abort(c(
      "{.fn mapa} necesita una fila por ambito departamental EPEN.",
      "x" = "Ambitos repetidos: {.val {repetidos}}.",
      "i" = "Filtra los otros grupos o agrega el indicador antes de mapear."
    ))
  }

  sin_poligono <- is.na(claves) | !claves %in% shapes$geo_id
  if (all(sin_poligono)) {
    cli::cli_abort("Ninguna fila corresponde a un ambito departamental EPEN.")
  }
  if (any(sin_poligono)) {
    no_unidos <- as.character(llave$original[sin_poligono])
    no_unidos[is.na(no_unidos)] <- "NA"
    cli::cli_warn(c(
      "{sum(sin_poligono)} fila{?s} no corresponde{?n} a ningun ambito y no se dibuja{?n}.",
      "i" = "Valores: {.val {no_unidos}}."
    ))
  }

  idx <- match(shapes$geo_id, claves)
  columnas_shapes <- c("geo_id", "departamento", attr(shapes, "sf_column"))
  cols_nuevas <- setdiff(names(data), c(llave$columnas, columnas_shapes))
  mapa_data <- shapes
  for (col in cols_nuevas) {
    mapa_data[[col]] <- data[[col]][idx]
  }

  if (all(is.na(mapa_data[[var]]))) {
    cli::cli_abort("Ningun ambito tiene un valor no ausente para '{var}'.")
  }
  sin_dato <- is.na(mapa_data[[var]])
  if (any(sin_dato)) {
    cli::cli_warn(
      "{sum(sin_dato)} ambito{?s} sin dato para '{var}': {.val {mapa_data$departamento[sin_dato]}}."
    )
  }

  mapa_data
}

#' @noRd
.formatear_valor_mapa <- function(x) {
  texto <- trimws(formatC(x, digits = 4, format = "fg"))
  texto[is.na(x)] <- "sin dato"
  texto
}

#' @noRd
.mapa_leaflet <- function(mapa_data, var, titulo, paleta) {
  valores <- mapa_data[[var]]
  pal <- leaflet::colorNumeric(paleta, domain = valores, na.color = "#cccccc")
  etiquetas <- paste0(
    mapa_data[["departamento"]], ": ",
    .formatear_valor_mapa(valores)
  )

  leaflet::leaflet(mapa_data) |>
    leaflet::addTiles() |>
    leaflet::addPolygons(
      fillColor = pal(valores),
      fillOpacity = 0.8,
      color = "white",
      weight = 1,
      label = etiquetas
    ) |>
    leaflet::addLegend(
      "bottomright",
      pal = pal,
      values = valores,
      title = titulo
    )
}

#' @noRd
.mapa_ggplot <- function(mapa_data, var, titulo, paleta) {
  ggplot2::ggplot(mapa_data) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = .data[[var]]),
      color = "white",
      linewidth = 0.3
    ) +
    ggplot2::scale_fill_distiller(
      palette = paleta,
      direction = 1,
      name = titulo,
      na.value = "#cccccc"
    ) +
    ggplot2::labs(title = titulo) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 12),
      plot.title.position = "plot"
    )
}
