# Muestra sintética con estructura EPEN 2024 (solo ocupados)

Dataset completamente sintético de 2.000 filas con la estructura de la
EPEN 2024 (variante departamentos_anual) para uso en ejemplos y pruebas.
Ninguna fila corresponde a una persona, vivienda u hogar real.

## Usage

``` r
muestra_epen_2024
```

## Format

Un `data.frame` con 2.000 filas y 36 columnas. Variables principales:

- year, month:

  Ano y mes de referencia.

- region_code:

  Codigo CCDD de la EPEN. El codigo 15 incluye los dos ambitos de Lima y
  Callao.

- division_lima:

  Division geografica cuando `region_code = 15`: 1 = Lima Metropolitana
  y Provincia Constitucional del Callao; 2 = Region Lima. En los otros
  departamentos es `NA`.

- sample_id:

  Identificador de muestra (`MUESTRA`, character).

- strata_code:

  Estrato (`ESTRATO`, 1-8).

- cluster_id, dwelling_id, household_id:

  Conglomerado, vivienda y hogar (character, con ceros a la izquierda).
  La UPM es `sample_id` + `region_code` + `cluster_id`.

- person_id, relationship_code:

  Numero de orden de la persona (`C201`) y parentesco (`C203`).

- occupational_category_code, firm_size_code, income_periodicity_code:

  Categoria ocupacional (`C310`), tamano de empresa (`C317`) y
  periodicidad del pago (`C338`, solo dependientes).

- labor_status_code:

  Estado laboral: **siempre 1 (Ocupado)** en este dataset.

- occupation_code_4d:

  Codigo CNO 2015 de 4 digitos (character).

- labor_income_monthly:

  Ingreso laboral mensual en soles.

- hours_week:

  Horas trabajadas en la ocupacion principal (`C318_T`).

- hours_week_total:

  Horas trabajadas en todas las ocupaciones durante la semana
  (`whoraT`).

- weight:

  Factor de expansion (peso muestral).

- sex_code, age, education_code:

  Variables sociodemograficas.

## Source

Datos sintéticos generados por `empleR`. El esquema y los nombres de
variables se basan en la documentación pública de la Encuesta Permanente
de Empleo Nacional 2024 del INEI.

## Details

**Importante:** este dataset representa **unicamente personas ocupadas**
(`labor_status_code = 1`). Los desocupados e inactivos fueron excluidos
porque el objetivo de los ejemplos es trabajar con codigos de ocupacion
(CNO) y cruzarlos con el indice de IA.

Esto significa que **no es posible calcular tasas de desempleo o
actividad** directamente desde esta muestra. Para esos indicadores usa:

- [`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md):
  tasas pre-calculadas sobre la PEA completa.

- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md):
  microdatos crudos del INEI con todos los estados laborales.

Algunas filas tienen `weight = NA` para probar el tratamiento explícito
de pesos faltantes. `ubigeo` y `domain_code` se conservan vacíos para
reproducir el esquema disponible del módulo 76.

La muestra se genera con `data-raw/07_muestra_epen_2024.R`, semilla
`20261114` y reglas declaradas. No se remuestrean microdatos del INEI.
Los codigos ocupacionales se limitan a codigos CNO validos presentes en
el indice incluido en el paquete.
