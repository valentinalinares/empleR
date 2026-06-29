# Indice de exposicion a inteligencia artificial por ocupacion

Score de exposicion a IA generativa para cada ocupacion del CNO 2015,
construido con Claude Sonnet 4.6 (Anthropic) mediante tres corridas
independientes y consolidacion por consenso.

## Usage

``` r
indice_ia
```

## Format

Un `data.frame` con columnas:

- code:

  Codigo CNO 2015 de 4 digitos (character).

- occupation_group:

  Nombre de la ocupacion.

- mean_exposure_score:

  Score medio de exposicion en escala 0-1 (p.ej. 0.37 equivale al 37 por
  ciento).

- median_exposure_score:

  Score mediano de exposicion (0 a 1).

- std_score:

  Desviacion estandar del score entre tareas.

- total_tasks:

  Numero total de tareas evaluadas.

- tipo_A_aumento:

  Numero de tareas tipo A (aumento/augmentation).

- tipo_S_sustitucion:

  Numero de tareas tipo S (sustitucion).

- tipo_N_nulo:

  Numero de tareas tipo N (impacto nulo).

## Source

Linares Herrera, V. (2025). Indice de exposicion a IA generativa para
ocupaciones peruanas. Claude Sonnet 4.6, Anthropic.

## Details

El archivo fuente final recomendado es
`02_exposure_index_por_ocupacion.xlsx`. El score sintetico principal es
`mean_exposure_score`; `median_exposure_score` y `std_score` se
conservan para analisis de sensibilidad y heterogeneidad. Segun el memo
metodologico del indice Sonnet 2026-06-15:

- Correlacion con indice OIT: r = 0.85.

- Correlacion con indice anterior: r = 0.45.
