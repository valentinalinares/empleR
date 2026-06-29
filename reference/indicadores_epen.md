# Indicadores nacionales pre-calculados del mercado laboral (EPEN/ENAHO)

Tasas e indicadores laborales ya calculados con la muestra completa de
la PEA, incluyendo desocupados e inactivos que no estan en los
microdatos procesados de
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md).
Devueltos por
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md).

## Usage

``` r
indicadores_epen
```

## Format

Un `data.frame` con columnas principales:

- source:

  Fuente: EPEN o ENAHO.

- survey_variant:

  Variante de la encuesta.

- year:

  Ano de referencia.

- period_label:

  Etiqueta del periodo.

- activity_rate_pet:

  Tasa de actividad sobre la PET (0-1).

- employment_rate_pet:

  Tasa de empleo sobre la PET (0-1).

- unemployment_rate_pea:

  Tasa de desempleo sobre la PEA (0-1).

- income_monthly_weighted_mean:

  Ingreso mensual promedio ponderado (soles).

- hours_week_weighted_mean:

  Horas semanales promedio ponderadas.

## Source

INEI / elaboracion propia con pipeline Python.

## See also

[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md)
