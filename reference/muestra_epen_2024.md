# Muestra de microdatos EPEN 2024 (solo ocupados)

Submuestra aleatoria de 2.000 filas de la EPEN 2024 (variante
departamentos_anual) para uso en ejemplos y pruebas.

## Usage

``` r
muestra_epen_2024
```

## Format

Un `data.frame` con 2.000 filas y 33 columnas. Variables principales:

- year, month:

  Ano y mes de referencia.

- region_code:

  Codigo de departamento (1-25).

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

INEI - Encuesta Permanente de Empleo Nacional 2024. Pipeline de
procesamiento: Linares Herrera, V. (2025).

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
