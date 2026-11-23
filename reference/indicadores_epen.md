# Indicadores nacionales precalculados del mercado laboral (EPEN/ENAHO)

Tasas e indicadores laborales calculados en el proyecto a partir de las
bases completas del INEI. La actividad y el empleo se expresan sobre la
población en edad de trabajar (PET); el desempleo, sobre la población
económicamente activa (PEA). Se consultan con
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md).

## Uso

``` r
indicadores_epen
```

## Formato

Un `data.frame` con columnas principales:

- source:

  Fuente: EPEN o ENAHO.

- survey_variant:

  Variante de la encuesta.

- year:

  Año de referencia.

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

## Fuente

Elaboración del proyecto a partir de microdatos del INEI.

## Ver también

[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md)
