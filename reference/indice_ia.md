# Índice de exposición a inteligencia artificial por ocupación

Puntaje de exposición a IA generativa para cada ocupación del CNO 2015,
desarrollado por Walter Omar Manky Bonilla, con la asistencia de
investigación de Valentina Linares Herrera, usando Claude Sonnet 4.6
(Anthropic) mediante tres corridas independientes y consolidación por
consenso.

## Uso

``` r
indice_ia
```

## Formato

Un `data.frame` con columnas:

- code:

  Código CNO 2015 de 4 dígitos (character).

- occupation_group:

  Nombre de la ocupación.

- mean_exposure_score:

  Puntaje medio de exposición en una escala de 0 a 1.

- median_exposure_score:

  Puntaje mediano de exposición (0 a 1).

- std_score:

  Desviación estándar del puntaje entre tareas.

- total_tasks:

  Número total de tareas evaluadas.

- tipo_A_aumento:

  Número de tareas tipo A (aumento/augmentation).

- tipo_S_sustitucion:

  Número de tareas tipo S (sustitución).

- tipo_N_nulo:

  Número de tareas tipo N (impacto nulo).

## Fuente

Manky Bonilla, W. O. (2026). Índice de exposición a inteligencia
artificial generativa para ocupaciones peruanas: corrida Claude Sonnet
4.6. Con asistencia de investigación de V. Linares Herrera. Material de
trabajo no publicado.

Antecedente metodológico: Manky, W. O. (2025). Doble desafío
tecnológico: análisis de la exposición a la automatización tradicional y
a la inteligencia artificial generativa en el empleo peruano, utilizando
datos de la ENAHO 2024. Instituto Nacional de Estadística e Informática.

## Detalles

El archivo fuente final recomendado es
`02_exposure_index_por_ocupacion.xlsx`. El puntaje principal por
ocupación es `mean_exposure_score`; `median_exposure_score` y
`std_score` se conservan para análisis de sensibilidad y heterogeneidad.
Según el memo metodológico de la corrida Sonnet de abril de 2026, cuyo
paquete metodológico fue versionado el 15 de junio de 2026:

- Correlación con índice OIT: r = 0.85.

- Correlación con índice anterior: r = 0.45.
