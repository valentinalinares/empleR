# Poligonos provinciales del Peru (sf)

Shapes a nivel provincia (196 unidades) pre-computados desde el dataset
[`geoperu::peru`](https://paulesantos.github.io/geoperu/reference/peru.html)
usando el motor GEOS (sin s2). Usados internamente por
[`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
cuando `nivel = "provincia"`.

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
