# Cruzar ocupaciones con el indice de exposicion a inteligencia artificial

Agrega a los microdatos el indice de exposicion a IA generativa por
ocupacion, desarrollado por Walter Omar Manky Bonilla, con la asistencia
de investigacion de Valentina Linares Herrera, usando Claude Sonnet 4.6
(Anthropic). El indice mide el grado en que las tareas de cada ocupacion
pueden ser asistidas o sustituidas por IA generativa, usando un score
continuo de 0 a 1.

## Usage

``` r
ia_exposicion(data, var_cno = NULL, score = "mean", incluir_tipo = FALSE)
```

## Arguments

- data:

  `data.frame` con microdatos de EPEN/EPE procesados con
  [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md).

- var_cno:

  Variable con el codigo CNO 2015 de 4 digitos. Si es `NULL` (por
  defecto) se elige por fila segun la columna `clasificador`: `cno_cod`
  para CNO 2015 y `cno_homologado` para CO-95.

- score:

  Que score agregar. Opciones:

  - `"mean"` (por defecto): score medio de exposicion por ocupacion.

  - `"median"`: score mediano.

  - `"ambos"`: agrega tanto media como mediana.

- incluir_tipo:

  Logico. Si `TRUE`, agrega el tipo de impacto predominante y los
  conteos de tareas por tipo. Por defecto `FALSE`.

## Value

El mismo `data.frame` (mismas filas y orden) con columnas adicionales:

- ia_cno:

  Codigo CNO 2015 usado para el cruce.

- ia_score_mean:

  Score medio de exposicion a IA (0-1).

- ia_score_median:

  Score mediano (si `score` es `"median"` o `"ambos"`).

- ia_cobertura:

  `"con_score"`, `"sin_score"` (codigo CNO valido sin score en el
  indice), `"codigo_no_encontrado"` (4 digitos que no existen en el CNO
  2015), `"sin_homologacion"` (CO-95 sin equivalencia unica) o
  `"sin_codigo"`.

- ia_tipo:

  Tipo de impacto con mas tareas (`A`, `S` o `N`); `NA` si hay empate,
  si la ocupacion no tiene tareas o no esta en el indice.

- ia_empate:

  `TRUE` si dos o mas tipos empatan en el maximo; `NA` si no hay tareas
  o indice.

- ia_tipo_estado:

  `"predominante"`, `"empate"`, `"sin_tareas"` o `"sin_indice"`.

- ia_total_tareas, tipo_A_aumento, tipo_S_sustitucion, tipo_N_nulo:

  Conteos de tareas del indice.

Las ultimas cuatro filas solo se agregan con `incluir_tipo = TRUE`.

## Details

El indice fue construido evaluando las tareas de cada ocupacion del
Clasificador Nacional de Ocupaciones (CNO 2015) con tres corridas
independientes del modelo Claude Sonnet 4.6, consolidando el resultado
por consenso. Cada tarea recibe:

- Un **score continuo** (0-1) de exposicion.

- Un **tipo de impacto**: `A` (aumento/augmentation), `S` (sustitucion),
  `N` (impacto nulo).

El indice final por ocupacion es la media de los scores de sus tareas.
Correlacion con el indice de la OIT: r = 0.85.

Esta corrida actualiza el enfoque publicado por Manky (2025), pero sus
puntajes no son los publicados originalmente por el INEI: conserva
scores continuos y aplica reglas revisadas para empates, ambiguedades y
tipo de exposicion.

## Bases EPE (CO-95)

El indice esta definido en CNO 2015 a 4 digitos. En bases EPE se usa
`cno_homologado` (de `cno(homologar = TRUE)`): solo las ocupaciones con
equivalencia unica reciben score. Las ambiguas quedan en `NA` con
`ia_cobertura = "sin_homologacion"`; nunca se cruza un codigo CO-95 ni
un codigo agregado (1-3 digitos) con el indice. En una base que une EPE
y EPEN (con la columna `clasificador` de
[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md))
cada fila usa su codigo.

## See also

[`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md)
para resumir la cobertura por encuesta y ano.

## Examples

``` r
# Con la muestra incluida
muestra <- cno(muestra_epen_2024)
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
muestra <- ia_exposicion(muestra)
#> Warning: ℹ Filas con score de IA: 1961 (98%).
#> ! 39 (2%) con codigo CNO sin score en el indice.
#> ℹ Resumen por encuesta y ano: `cobertura()`.

# Ver distribucion de exposicion
hist(muestra$ia_score_mean, main = "Exposicion a IA", xlab = "Score (0-1)")


if (FALSE) { # \dontrun{
epen_2024 <- descargar(year = 2024) |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)

# Ingreso promedio segun tipo de impacto predominante (con diseno muestral)
indicadores(epen_2024, "ingreso_promedio", por = "ia_tipo")

# Base EPE: el cruce usa cno_homologado automaticamente
epe_2019 <- cno(readRDS("epe_2019.rds"), homologar = TRUE) |>
  ia_exposicion()
cobertura(epe_2019)
} # }
```
