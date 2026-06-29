# Visualizar indicadores laborales en un mapa regional del Peru

Genera un mapa interactivo o estatico con indicadores del mercado
laboral agregados por departamento, provincia o distrito. Usa los shapes
oficiales del INEI via el paquete geoperu.

## Usage

``` r
mapa(
  data,
  var,
  nivel = "departamento",
  tipo = "leaflet",
  titulo = NULL,
  paleta = "YlOrRd",
  shapes = NULL
)
```

## Arguments

- data:

  `data.frame` con un indicador agregado por unidad geografica (output
  de
  [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  con el argumento `por`).

- var:

  Nombre de la columna numerica a visualizar en el mapa.

- nivel:

  Nivel geografico. Opciones: `"departamento"` (por defecto),
  `"provincia"`, `"distrito"`.

- tipo:

  Tipo de visualizacion: `"leaflet"` (por defecto, interactivo) o
  `"ggplot"` (estatico, para exportar).

- titulo:

  Titulo del mapa y la leyenda. Si es `NULL`, usa el nombre de la
  variable.

- paleta:

  Paleta de colores para el gradiente. Por defecto `"YlOrRd"`. Acepta
  cualquier paleta de RColorBrewer.

- shapes:

  Objeto `sf` con los poligonos. Si es `NULL` (por defecto), se descarga
  automaticamente con geoperu.

## Value

Un objeto `leaflet` (si `tipo = "leaflet"`) o `ggplot` (si
`tipo = "ggplot"`).

## Examples

``` r
if (FALSE) { # \dontrun{
epen_2024 <- descargar(year = 2024)

# Calcular tasa de desempleo por departamento
desempleo <- indicadores(epen_2024, "tasa_desempleo", por = "departamento")

# Mapa interactivo (leaflet)
mapa(desempleo, var = "tasa_desempleo")

# Mapa estatico (ggplot2)
mapa(desempleo, var = "tasa_desempleo", tipo = "ggplot",
     titulo = "Tasa de desempleo por departamento, EPEN 2024")

# Mapa de exposicion a IA
ia_dep <- descargar(year = 2024) |>
  cno() |>
  ia_exposicion() |>
  indicadores("ingreso_promedio", por = "departamento")

mapa(ia_dep, var = "ia_score_mean",
     titulo = "Exposicion a IA por departamento (score medio)")
} # }
```
