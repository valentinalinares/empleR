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
# Ingreso promedio por departamento. region_code (1-25) sigue el orden
# alfabetico de los departamentos, igual que shapes_departamentos.
ingreso_dep <- indicadores(muestra_epen_2024, "ingreso_promedio",
                           por = "region_code")
ingreso_dep$departamento <- shapes_departamentos$departamento[ingreso_dep$region_code]

# Mapa interactivo (leaflet)
mapa(ingreso_dep, var = "estimado", titulo = "Ingreso promedio (S/)")

# Mapa estatico (ggplot2)
mapa(ingreso_dep, var = "estimado", tipo = "ggplot",
     titulo = "Ingreso laboral promedio por departamento, EPEN 2024")
} # }
```
