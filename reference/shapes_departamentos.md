# Poligonos departamentales del Peru (sf)

Shapes a nivel departamento (25 unidades) pre-computados desde el
dataset
[`geoperu::peru`](https://paulesantos.github.io/geoperu/reference/peru.html)
usando el motor GEOS (sin s2).
[`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
los combina con
[shapes_provincias](https://valentinalinares.github.io/empleR/reference/shapes_provincias.md)
para representar los ambitos departamentales de la EPEN. Incluyen Callao
como departamento politico propio (codigo UBIGEO `07`).

## Usage

``` r
shapes_departamentos
```

## Format

Un objeto `sf` con 25 filas y columnas:

- departamento:

  Nombre del departamento en mayusculas (e.g. `"LIMA"`).

- geometry:

  Poligono en CRS EPSG:4326.

## Source

geoperu (CRAN) / INEI.
