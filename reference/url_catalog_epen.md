# Catalogo de URLs de descarga EPEN (INEI)

URLs reales para descargar los microdatos de la EPEN desde el servidor
del INEI. Extraidas del paquete Python `inei_microdatos`. Usadas
internamente por
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md).

## Usage

``` r
url_catalog_epen
```

## Format

Un `data.frame` con columnas:

- source:

  Nombre de la encuesta: EPEN.

- survey_variant:

  Variante: `departamentos_anual`, `lima_movil`.

- year:

  Ano de referencia (integer).

- period_label:

  Etiqueta del periodo (e.g. "Anual", "Trimestre Movil...").

- survey_code:

  Codigo de encuesta INEI (entero).

- url:

  URL de descarga del ZIP con los modulos CSV.

## Source

INEI - Sistema de Recuperacion de Informacion de Encuestas (SRIIE).
