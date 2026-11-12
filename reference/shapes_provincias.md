# Poligonos provinciales del Peru (sf)

Shapes a nivel provincia (196 unidades) pre-computados desde el dataset
[`geoperu::peru`](https://paulesantos.github.io/geoperu/reference/peru.html)
usando el motor GEOS (sin s2).
[`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
los usa internamente para construir los dos ambitos oficiales del codigo
15: Lima Metropolitana y Callao, y Region Lima. Si los unes a tus
propios datos, usa departamento y provincia juntos como llave.

## Usage

``` r
shapes_provincias
```

## Format

Un objeto `sf` con 196 filas y columnas:

- departamento:

  Nombre del departamento en mayusculas.

- provincia:

  Nombre de la provincia en mayusculas.

- geometry:

  Poligono en CRS EPSG:4326.

## Source

geoperu (CRAN) / INEI.
