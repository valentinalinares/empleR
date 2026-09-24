#' Visualizar indicadores laborales en un mapa regional del Peru
#'
#' Genera un mapa interactivo o estatico con indicadores del mercado laboral
#' agregados por departamento, provincia o distrito. Usa los shapes oficiales
#' del INEI via el paquete \pkg{geoperu}.
#'
#' @param data `data.frame` con un indicador agregado por unidad geografica
#'   (output de [indicadores()] con el argumento `por`).
#' @param var Nombre de la columna numerica a visualizar en el mapa.
#' @param nivel Nivel geografico. Opciones: `"departamento"` (por defecto),
#'   `"provincia"`, `"distrito"`.
#' @param tipo Tipo de visualizacion: `"leaflet"` (por defecto, interactivo)
#'   o `"ggplot"` (estatico, para exportar).
#' @param titulo Titulo del mapa y la leyenda. Si es `NULL`, usa el nombre
#'   de la variable.
#' @param paleta Paleta de colores para el gradiente. Por defecto `"YlOrRd"`.
#'   Acepta cualquier paleta de \pkg{RColorBrewer}.
#' @param shapes Objeto `sf` con los poligonos. Si es `NULL` (por defecto),
#'   se descarga automaticamente con \pkg{geoperu}.
#'
#' @return Un objeto `leaflet` (si `tipo = "leaflet"`) o `ggplot`
#'   (si `tipo = "ggplot"`).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Ingreso promedio por departamento. region_code (1-25) sigue el orden
#' # alfabetico de los departamentos, igual que shapes_departamentos.
#' ingreso_dep <- indicadores(muestra_epen_2024, "ingreso_promedio",
#'                            por = "region_code")
#' ingreso_dep$departamento <- shapes_departamentos$departamento[ingreso_dep$region_code]
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

  tipo  <- match.arg(tipo,  c("leaflet", "ggplot"))
  nivel <- match.arg(nivel, c("departamento", "provincia", "distrito"))

  if (!var %in% names(data)) {
    cli::cli_abort("La variable '{var}' no existe en los datos.")
  }

  # Obtener shapes si no se proporcionan
  if (is.null(shapes)) {
    cli::cli_inform(c("i" = "Preparando shapes ({nivel}) via geoperu..."))
    shapes <- .obtener_shapes(nivel)
  }

  # Detectar columna de union (ubigeo o nombre de departamento)
  col_join <- .detectar_col_join(data, shapes, nivel)

  # Join datos + shapes
  # Agregar columnas de data a shapes por indice (evita problemas de dispatch
  # de left_join/merge con objetos sf cuando sf no esta explicitamente adjuntado)
  by_shapes <- unname(col_join)   # columna en shapes
  by_data   <- names(col_join)    # columna en data
  idx <- match(shapes[[by_shapes]], data[[by_data]])
  cols_nuevas <- setdiff(names(data), by_data)
  mapa_data <- shapes
  for (col in cols_nuevas) {
    mapa_data[[col]] <- data[[col]][idx]
  }

  n_sin_dato <- sum(is.na(mapa_data[[var]]))
  if (n_sin_dato > 0) {
    cli::cli_warn(
      "{n_sin_dato} unidades geograficas sin dato para '{var}'."
    )
  }

  titulo <- titulo %||% var

  if (tipo == "leaflet") {
    .mapa_leaflet(mapa_data, var = var, titulo = titulo, paleta = paleta)
  } else {
    .mapa_ggplot(mapa_data, var = var, titulo = titulo, paleta = paleta)
  }
}


# Helpers internos --------------------------------------------------------

#' @noRd
.obtener_shapes <- function(nivel) {
  # Usar datasets pre-calculados incluidos en {empleR}
  # (generados en data-raw/01_preparar_shapes.R via GEOS sin s2)
  # Columna clave: "departamento" en MAYUSCULAS (e.g. "LIMA", "CUSCO")
  switch(nivel,
    departamento = shapes_departamentos,
    provincia    = shapes_provincias,
    distrito     = {
      # Nivel distrito: usar el dataset crudo de geoperu
      cli::cli_inform(c("i" = "Cargando shapes a nivel distrito desde geoperu..."))
      geoperu::peru
    }
  )
}

#' @noRd
.detectar_col_join <- function(data, shapes, nivel) {
  # geoperu usa nombres en mayuscula: "departamento", "provincia", "distrito"
  candidatos_data   <- switch(nivel,
    departamento = c("departamento", "DEPARTAMENTO", "dep", "region"),
    provincia    = c("provincia",    "PROVINCIA"),
    distrito     = c("distrito",     "DISTRITO")
  )
  candidatos_shapes <- switch(nivel,
    departamento = "departamento",
    provincia    = "provincia",
    distrito     = "distrito"
  )
  # Buscar en data
  col_data <- intersect(candidatos_data, names(data))
  if (length(col_data) == 0) {
    cli::cli_abort(c(
      "No se encontro columna de {nivel} en los datos.",
      "i" = "Los datos deben tener una de estas columnas: {.val {candidatos_data}}"
    ))
  }
  # Devolver como named vector: data_col = shapes_col
  stats::setNames(candidatos_shapes, col_data[1])
}

#' @noRd
.mapa_leaflet <- function(mapa_data, var, titulo, paleta) {
  pal <- leaflet::colorNumeric(paleta, domain = mapa_data[[var]], na.color = "#cccccc")

  leaflet::leaflet(mapa_data) |>
    leaflet::addTiles() |>
    leaflet::addPolygons(
      fillColor   = ~pal(mapa_data[[var]]),
      fillOpacity = 0.8,
      color       = "white",
      weight      = 1,
      label       = ~paste0(
        mapa_data[["departamento"]], ": ",
        round(mapa_data[[var]], 1)
      )
    ) |>
    leaflet::addLegend(
      "bottomright",
      pal    = pal,
      values = mapa_data[[var]],
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
      plot.title = ggplot2::element_text(hjust = 0.5, size = 12)
    )
}
