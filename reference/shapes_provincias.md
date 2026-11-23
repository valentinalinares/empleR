# Polígonos provinciales del Perú (sf)

Polígonos a nivel provincia (196 unidades) precalculados desde el
conjunto de datos
[`geoperu::peru`](https://paulesantos.github.io/geoperu/reference/peru.html)
usando el motor GEOS (sin s2).
[`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
los usa internamente para construir los dos ámbitos oficiales del código
15: Lima Metropolitana y Callao, y Región Lima. Si los unes a tus
propios datos, usa departamento y provincia juntos como clave.

## Uso

``` r
shapes_provincias
```

## Formato

Un objeto `sf` con 196 filas y columnas:

- departamento:

  Nombre del departamento en mayúsculas.

- provincia:

  Nombre de la provincia en mayúsculas.

- geometry:

  Polígono en CRS EPSG:4326.

## Fuente

geoperu (CRAN) / INEI.
