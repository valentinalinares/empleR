# Catalogo de fuentes de datos disponibles

Inventario de todas las encuestas, anos, variantes y periodos
disponibles para descargar con
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md).
Incluye EPEN (departamentos y Lima movil) y ENAHO anual.

## Usage

``` r
catalogo_fuentes
```

## Format

Un `data.frame` con columnas:

- fuente:

  Nombre de la encuesta: EPEN o ENAHO.

- variante:

  Variante: departamentos_anual, lima_movil, anual.

- year:

  Ano de referencia.

- periodo:

  Descripcion del periodo.

- filas:

  Numero de filas en la base.

- codigos_ocup:

  Numero de codigos ocupacionales distintos.

## Source

INEI / elaboracion propia.
