# Catálogo de fuentes de datos disponibles

Inventario de las encuestas, años, variantes y periodos procesados por
el proyecto. Incluye EPEN (departamentos y Lima móvil) y ENAHO anual. La
descarga automática con
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
está disponible solo para EPEN.

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

  Año de referencia.

- periodo:

  Descripción del periodo.

- filas:

  Número de filas en la base.

- codigos_ocup:

  Número de códigos ocupacionales distintos.

## Source

INEI / elaboración propia.
