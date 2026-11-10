#' Visualizar un indicador por departamento del Peru
#'
#' Une una tabla con una fila por departamento a los poligonos incluidos en el
#' paquete y devuelve un mapa interactivo (`leaflet`) o estatico (`ggplot2`).
#' La funcion no calcula indicadores: recibe resultados ya agregados, por
#' ejemplo la salida de [indicadores()] con `por = "region_code"`.
#'
#' @details
#' **Nivel geografico.** Esta version solo admite departamentos. Las bases de
#' la EPEN que descarga el paquete identifican el departamento (`CCDD`), pero no
#' la provincia ni el distrito, y los nombres de distritos se repiten entre
#' departamentos. Por eso `nivel = "provincia"` y `nivel = "distrito"` producen
#' un error en lugar de un cruce que podria asignar valores al territorio
#' equivocado.
#'
#' **Llave de union.** La funcion busca, en este orden:
#'
#' 1. un codigo de departamento del UBIGEO del INEI en `CCDD` o `region_code`
#'    (de 1 a 25, con o sin cero a la izquierda);
#' 2. un nombre de departamento en `departamento`, `DEPARTAMENTO`, `dep` o
#'    `region`, sin distinguir mayusculas ni tildes.
#'
#' Si la tabla trae codigo y nombre, ambos deben corresponder al mismo
#' departamento. Nombres como `"Lima Metropolitana"` no se asignan al
#' departamento de Lima: son otro ambito geografico.
#'
#' **Controles.** `mapa()` rechaza departamentos repetidos, por ejemplo cuando
#' el resultado de [indicadores()] se agrupo por departamento y sexo; filtra o
#' agrega antes de mapear. Tambien avisa cuando una fila no corresponde a
#' ningun poligono y cuando un departamento queda sin dato. Nunca copia ni
#' reparte valores entre departamentos. En las bases anuales de la EPEN
#' 2022-2025 el codigo `07` (Callao) no aparece, por lo que Callao se muestra
#' sin dato.
#'
#' **Interpretacion.** Un mapa representa los valores que recibe. No demuestra
#' que la encuesta sea representativa para cada departamento ni que las
#' diferencias de color sean estadisticamente significativas. Antes de
#' comparar territorios, revisa el diseno muestral, el numero de observaciones
#' y la precision de cada estimacion.
#'
#' @param data `data.frame` con una fila por departamento, por ejemplo la
#'   salida de [indicadores()] con `por = "region_code"`.
#' @param var Nombre de la columna numerica que se representara con colores.
#' @param nivel Nivel geografico. Solo se admite `"departamento"`; los niveles
#'   `"provincia"` y `"distrito"` producen un error informativo.
#' @param tipo Tipo de visualizacion: `"leaflet"` (por defecto, interactivo)
#'   o `"ggplot"` (estatico, para exportar).
#' @param titulo Titulo del mapa y la leyenda. Si es `NULL`, usa el nombre
#'   de la variable.
#' @param paleta Paleta de colores para el gradiente. Por defecto `"YlOrRd"`.
#'   Acepta cualquier paleta de \pkg{RColorBrewer}.
#' @param shapes Objeto `sf` con una columna `departamento` y un poligono por
#'   departamento. Si es `NULL` (por defecto), usa [shapes_departamentos].
#'
#' @return Un objeto `leaflet` (si `tipo = "leaflet"`) o `ggplot`
#'   (si `tipo = "ggplot"`). En ambos casos los datos del mapa conservan los
#'   poligonos de `shapes` y las columnas de `data` asignadas a cada
#'   departamento.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Ingreso promedio por departamento. region_code es el codigo UBIGEO
#' # del departamento (CCDD en las bases originales de la EPEN).
#' ingreso_dep <- indicadores(muestra_epen_2024, "ingreso_promedio",
#'                            por = "region_code")
#'
#' # Mapa interactivo (leaflet)
#' mapa(ingreso_dep, var = "estimado", titulo = "Ingreso promedio (S/)")
#'
#' # Mapa estatico (ggplot2)
#' mapa(ingreso_dep, var = "estimado", tipo = "ggplot",
#'      titulo = "Ingreso laboral promedio por departamento, EPEN 2024")
#' }
mapa <- function(data,
                 var,
                 nivel   = "departamento",
                 tipo    = "leaflet",
                 titulo  = NULL,
                 paleta  = "YlOrRd",
                 shapes  = NULL) {

  tipo <- match.arg(tipo, c("leaflet", "ggplot"))
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

  shapes <- shapes %||% shapes_departamentos
  mapa_data <- .unir_mapa(data, var = var, shapes = shapes)

  titulo <- titulo %||% var

  if (tipo == "leaflet") {
    .mapa_leaflet(mapa_data, var = var, titulo = titulo, paleta = paleta)
  } else {
    .mapa_ggplot(mapa_data, var = var, titulo = titulo, paleta = paleta)
  }
}


# Helpers internos --------------------------------------------------------

# Codigos de departamento del UBIGEO del INEI. Coinciden con CCDD en las bases
# de la EPEN y con region_code en las bases procesadas.
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

#' @noRd
.validar_nivel_mapa <- function(nivel) {
  if (!is.character(nivel) || length(nivel) != 1L || is.na(nivel)) {
    cli::cli_abort("{.arg nivel} debe ser {.val departamento}.")
  }
  if (nivel %in% c("provincia", "distrito")) {
    cli::cli_abort(c(
      "El nivel {.val {nivel}} no esta disponible en esta version de {.fn mapa}.",
      "i" = paste(
        "Las bases de la EPEN identifican el departamento ({.field CCDD}),",
        "no la provincia ni el distrito."
      ),
      "i" = paste(
        "Los nombres de distritos se repiten entre departamentos y el paquete",
        "todavia no incluye una llave UBIGEO para cruzarlos sin ambiguedad."
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
.codigo_a_departamento <- function(x) {
  x <- trimws(as.character(x))
  es_codigo <- !is.na(x) & grepl("^[0-9]{1,2}$", x)
  codigo <- rep(NA_character_, length(x))
  codigo[es_codigo] <- sprintf("%02d", as.integer(x[es_codigo]))
  unname(.departamentos_ubigeo[codigo])
}

#' @noRd
.llave_departamento <- function(data) {
  col_codigo <- intersect(c("CCDD", "region_code"), names(data))[1]
  col_nombre <- intersect(
    c("departamento", "DEPARTAMENTO", "dep", "region"),
    names(data)
  )[1]

  if (is.na(col_codigo) && is.na(col_nombre)) {
    cli::cli_abort(c(
      "No se encontro columna de departamento en los datos.",
      "i" = paste(
        "Incluye un codigo UBIGEO ({.val CCDD} o {.val region_code}) o un",
        "nombre ({.val departamento})."
      )
    ))
  }

  codigo <- if (!is.na(col_codigo)) .codigo_a_departamento(data[[col_codigo]])
  nombre <- if (!is.na(col_nombre)) .normalizar_departamento(data[[col_nombre]])

  if (!is.null(codigo) && !is.null(nombre)) {
    discrepa <- !is.na(codigo) & !is.na(nombre) & codigo != nombre
    if (any(discrepa)) {
      i <- which(discrepa)[1]
      cli::cli_abort(c(
        "El codigo y el nombre de departamento no coinciden en {sum(discrepa)} fila{?s}.",
        "x" = paste0(
          "Por ejemplo, {.field {col_codigo}} = {.val {data[[col_codigo]][i]}} ",
          "corresponde a {.val {codigo[i]}}, pero {.field {col_nombre}} = ",
          "{.val {data[[col_nombre]][i]}}."
        ),
        "i" = "Revisa como se construyo la columna de nombres; {.fn mapa} no elige entre ambas."
      ))
    }
  }

  valores <- if (is.null(codigo)) nombre else codigo
  if (!is.null(codigo) && !is.null(nombre)) {
    valores <- ifelse(is.na(codigo), nombre, codigo)
  }

  columnas <- c(col_codigo, col_nombre)
  columnas <- columnas[!is.na(columnas)]
  original <- data[[columnas[1]]]

  list(valores = valores, columnas = columnas, original = original)
}

#' @noRd
.unir_mapa <- function(data, var, shapes) {
  if (!inherits(shapes, "sf") || !"departamento" %in% names(shapes)) {
    cli::cli_abort(
      "{.arg shapes} debe ser un objeto {.cls sf} con una columna {.field departamento}."
    )
  }

  nombres_shapes <- .normalizar_departamento(
    sf::st_drop_geometry(shapes)[["departamento"]]
  )
  repetidos_shapes <- unique(nombres_shapes[duplicated(nombres_shapes)])
  if (anyNA(nombres_shapes) || length(repetidos_shapes) > 0) {
    cli::cli_abort(c(
      "{.arg shapes} debe tener un poligono por departamento y ningun nombre vacio.",
      "x" = "Nombres repetidos: {.val {repetidos_shapes}}."
    ))
  }

  llave <- .llave_departamento(data)
  if (var %in% llave$columnas) {
    cli::cli_abort("{.arg var} no puede ser la columna geografica {.field {var}}.")
  }
  claves <- llave$valores

  repetidos <- unique(claves[!is.na(claves) & duplicated(claves)])
  if (length(repetidos) > 0) {
    cli::cli_abort(c(
      "{.fn mapa} necesita una fila por departamento.",
      "x" = "Departamentos repetidos: {.val {repetidos}}.",
      "i" = paste(
        "Si agrupaste por departamento y otra variable, filtra un grupo o",
        "calcula el indicador solo por departamento."
      )
    ))
  }

  sin_poligono <- is.na(claves) | !claves %in% nombres_shapes
  if (all(sin_poligono)) {
    cli::cli_abort(c(
      "Ninguna fila de {.arg data} corresponde a un departamento de {.arg shapes}.",
      "i" = "Valores recibidos en {.field {llave$columnas[1]}}: {.val {utils::head(llave$original, 5)}}."
    ))
  }
  if (any(sin_poligono)) {
    no_unidos <- as.character(llave$original[sin_poligono])
    no_unidos[is.na(no_unidos)] <- "NA"
    cli::cli_warn(c(
      "{sum(sin_poligono)} fila{?s} de {.arg data} no corresponde{?n} a ningun departamento y no se dibuja{?n}.",
      "i" = "{.field {llave$columnas[1]}}: {.val {no_unidos}}."
    ))
  }

  idx <- match(nombres_shapes, claves)
  columnas_shapes <- c("departamento", attr(shapes, "sf_column"))
  cols_nuevas <- setdiff(names(data), c(llave$columnas, columnas_shapes))

  mapa_data <- shapes
  for (col in cols_nuevas) {
    mapa_data[[col]] <- data[[col]][idx]
  }

  if (all(is.na(mapa_data[[var]]))) {
    cli::cli_abort("Ningun departamento tiene un valor no ausente para '{var}'.")
  }

  sin_dato <- is.na(mapa_data[[var]])
  if (any(sin_dato)) {
    nombres_sin_dato <- sf::st_drop_geometry(mapa_data)[["departamento"]][sin_dato]
    cli::cli_warn(
      "{sum(sin_dato)} departamento{?s} sin dato para '{var}': {.val {nombres_sin_dato}}."
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
      fillColor   = pal(valores),
      fillOpacity = 0.8,
      color       = "white",
      weight      = 1,
      label       = etiquetas
    ) |>
    leaflet::addLegend(
      "bottomright",
      pal    = pal,
      values = valores,
      title  = titulo
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
      palette  = paleta,
      direction = 1,
      name     = titulo,
      na.value = "#cccccc"
    ) +
    ggplot2::labs(title = titulo) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 12),
      plot.title.position = "plot"
    )
}
