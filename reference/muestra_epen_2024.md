# Muestra sintética con estructura EPEN 2024 (solo ocupados)

Dataset completamente sintético de 2.000 filas con la estructura de la
EPEN 2024 (variante departamentos_anual) para uso en ejemplos y pruebas.
Ninguna fila corresponde a una persona, vivienda u hogar real.

## Uso

``` r
muestra_epen_2024
```

## Formato

Un `data.frame` con 2.000 filas y 36 columnas. Variables principales:

- year, month:

  Año y mes de referencia.

- region_code:

  Código CCDD de la EPEN. El código 15 incluye los dos ámbitos de Lima y
  Callao.

- division_lima:

  División geográfica cuando `region_code = 15`: 1 = Lima Metropolitana
  y Provincia Constitucional del Callao; 2 = Región Lima. En los otros
  departamentos es `NA`.

- sample_id:

  Identificador de muestra (`MUESTRA`, character).

- strata_code:

  Estrato (`ESTRATO`, 1-8).

- cluster_id, dwelling_id, household_id:

  Conglomerado, vivienda y hogar (character, con ceros a la izquierda).
  La UPM es `sample_id` + `region_code` + `cluster_id`.

- person_id, relationship_code:

  Número de orden de la persona (`C201`) y parentesco (`C203`).

- occupational_category_code, firm_size_code, income_periodicity_code:

  Categoría ocupacional (`C310`), tamaño de empresa (`C317`) y
  periodicidad del pago (`C338`, solo dependientes).

- labor_status_code:

  Estado laboral: **siempre 1 (Ocupado)** en este conjunto de datos.

- occupation_code_4d:

  Código CNO 2015 de 4 dígitos (character).

- labor_income_monthly:

  Ingreso laboral mensual en soles.

- hours_week:

  Horas trabajadas en la ocupación principal (`C318_T`).

- hours_week_total:

  Horas trabajadas en todas las ocupaciones durante la semana
  (`whoraT`).

- weight:

  Factor de expansión (peso muestral).

- sex_code, age, education_code:

  Variables sociodemográficas.

## Fuente

Datos sintéticos generados por `empleR`. El esquema y los nombres de
variables se basan en la documentación pública de la Encuesta Permanente
de Empleo Nacional 2024 del INEI.

## Detalles

Los registros se generaron para representar únicamente personas ocupadas
(`labor_status_code = 1`) y practicar con códigos ocupacionales e
índices de exposición a IA.

Esto significa que **no es posible calcular tasas de desempleo o
actividad** directamente desde esta muestra. Para esos indicadores usa:

- [`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md):
  tasas ya calculadas con las bases completas.

- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md):
  microdatos crudos del INEI con todos los estados laborales.

Algunas filas tienen `weight = NA` para probar el tratamiento explícito
de pesos faltantes. `ubigeo` y `domain_code` se conservan vacíos para
reproducir el esquema disponible del módulo 76.

La muestra se genera con `data-raw/07_muestra_epen_2024.R`, semilla
`20261114` y reglas declaradas. No se remuestrean microdatos del INEI.
Los códigos ocupacionales se limitan a códigos CNO válidos presentes en
el índice incluido en el paquete.
