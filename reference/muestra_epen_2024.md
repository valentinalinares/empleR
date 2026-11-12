# Muestra de microdatos EPEN 2024 (solo ocupados)

Submuestra aleatoria de 2.000 filas de la EPEN 2024 (variante
departamentos_anual) para uso en ejemplos y pruebas.

## Usage

``` r
muestra_epen_2024
```

## Format

Un `data.frame` con 2.000 filas y 35 columnas. Variables principales:

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

  Conglomerado, vivienda y hogar (character, con los ceros a la
  izquierda del original). La UPM es `sample_id` + `region_code` +
  `cluster_id`.

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

  Horas trabajadas por semana.

- weight:

  Factor de expansion (peso muestral).

- sex_code, age, education_code:

  Variables sociodemograficas.

## Source

INEI - Encuesta Permanente de Empleo Nacional 2024, modulo 76. Pipeline
de procesamiento: Linares Herrera, V. (2025),
<https://github.com/valentinalinares/ia_empleo_peru>.

## Details

**Importante:** este dataset contiene **unicamente personas ocupadas**
(`labor_status_code = 1`). Los desocupados e inactivos fueron excluidos
durante el procesamiento del pipeline porque no tienen codigo de
ocupacion (CNO) y no pueden cruzarse con el indice de IA.

Esto significa que **no es posible calcular tasas de desempleo o
actividad** directamente desde esta muestra. Para esos indicadores usa:

- [`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md):
  tasas pre-calculadas sobre la PEA completa.

- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md):
  microdatos crudos del INEI con todos los estados laborales.

81 filas no tienen factor de expansion (`weight`); se conservan sin
imputar. `ubigeo` y `domain_code` estan vacios porque el modulo 76 no
trae variables equivalentes.

La muestra se regenera con `data-raw/07_muestra_epen_2024.R` desde la
base corregida de `ia_empleo_peru` (codigos CNO completados a la
izquierda e identificadores reconstruidos desde los ZIP oficiales). Son
las mismas 2.000 personas que la version anterior.
