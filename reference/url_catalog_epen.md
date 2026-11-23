# Catálogo de URLs de descarga EPEN (INEI)

URLs reales para descargar los microdatos de la EPEN desde el servidor
del INEI. Extraídas del paquete Python `inei_microdatos`. Usadas
internamente por
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md).

## Uso

``` r
url_catalog_epen
```

## Formato

Un `data.frame` con columnas:

- source:

  Nombre de la encuesta: EPEN.

- survey_variant:

  Variante: `departamentos_anual`, `lima_movil`.

- year:

  Año de referencia (integer).

- period_label:

  Etiqueta del periodo (e.g. "Anual", "Trimestre Móvil...").

- survey_code:

  Código de encuesta INEI (entero).

- url:

  URL de descarga del ZIP con los módulos CSV.

## Fuente

INEI - Sistema de Recuperación de Información de Encuestas (SRIIE).
