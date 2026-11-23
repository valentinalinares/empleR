# Polígonos departamentales del Perú (sf)

Polígonos a nivel departamento (25 unidades) precalculados desde el
conjunto de datos
[`geoperu::peru`](https://paulesantos.github.io/geoperu/reference/peru.html)
usando el motor GEOS (sin s2).
[`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
los combina con
[shapes_provincias](https://valentinalinares.github.io/empleR/reference/shapes_provincias.md)
para representar los ámbitos departamentales de la EPEN. Incluyen la
Provincia Constitucional del Callao como unidad separada (código UBIGEO
`07`).

## Uso

``` r
shapes_departamentos
```

## Formato

Un objeto `sf` con 25 filas y columnas:

- departamento:

  Nombre del departamento en mayúsculas (e.g. `"LIMA"`).

- geometry:

  Polígono en CRS EPSG:4326.

## Fuente

geoperu (CRAN) / INEI.
