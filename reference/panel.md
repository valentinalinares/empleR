# Construir panel de viviendas entre trimestres moviles de la EPEN

La EPEN Lima Metropolitana tiene un diseno de panel rotante a nivel de
vivienda: cada vivienda es encuestada durante varios trimestres
consecutivos antes de salir del panel. Esta funcion identifica y enlaza
las mismas viviendas entre dos o mas trimestres, permitiendo analisis de
transiciones laborales.

## Usage

``` r
panel(
  data_lista,
  vars_id = c("cluster_id", "dwelling_id", "household_id"),
  incluir_no_apareados = FALSE,
  labels_trimestre = NULL
)
```

## Arguments

- data_lista:

  Lista de `data.frame` con microdatos de trimestres consecutivos. Cada
  elemento debe ser el resultado de
  [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
  con `variante = "lima_movil"`. El orden de la lista es el orden
  temporal.

- vars_id:

  Variables que identifican unicamente a una vivienda entre trimestres.
  Por defecto: `c("cluster_id", "dwelling_id", "household_id")`. Para
  datos crudos INEI usar: `c("CONGLOME", "VIVIENDA", "HOGAR")`.

- incluir_no_apareados:

  Logico. Si `FALSE` (por defecto), solo incluye viviendas presentes en
  TODOS los trimestres. Si `TRUE`, incluye todas las viviendas con datos
  en al menos un trimestre.

- labels_trimestre:

  Vector de etiquetas para identificar cada trimestre en la columna
  `trimestre`. Si es `NULL`, usa "T1", "T2", etc.

## Value

Un `data.frame` en formato long (una fila por vivienda-trimestre) con
columna `trimestre` indicando el periodo. Atributo `tasa_apareamiento`
con el porcentaje de viviendas apareadas.

## Details

La unidad de seguimiento en la EPEN es la **vivienda** (no el
individuo), identificada por la combinacion
`cluster_id + dwelling_id + household_id`. El `person_id` no siempre
esta disponible en los datos procesados.

El panel es aplicable principalmente a la variante `lima_movil`, donde
los trimestres se solapan (Ene-Feb-Mar, Feb-Mar-Abr, etc.) permitiendo
seguir las mismas viviendas mes a mes.

## Examples

``` r
if (FALSE) { # \dontrun{
# Descargar tres trimestres consecutivos de Lima 2024
t1 <- descargar(2024, "lima_movil", "Trimestre Movil -(Ene-Feb-Mar)")
t2 <- descargar(2024, "lima_movil", "Trimestre Movil -(Feb-Mar-Abr)")
t3 <- descargar(2024, "lima_movil", "Trimestre Movil -(Mar-Abr-May)")

# Construir panel de viviendas
panel_q1 <- panel(
  list(t1, t2, t3),
  labels_trimestre = c("Ene-Feb-Mar", "Feb-Mar-Abr", "Mar-Abr-May")
)

# Ver tasa de apareamiento
attr(panel_q1, "tasa_apareamiento")

# Analizar transiciones: personas que cambiaron de estado laboral
library(dplyr)
panel_q1 |>
  select(cluster_id, dwelling_id, household_id, trimestre, labor_status_code) |>
  tidyr::pivot_wider(names_from = trimestre, values_from = labor_status_code)
} # }
```
