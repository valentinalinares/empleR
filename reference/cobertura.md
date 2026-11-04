# Cobertura de la homologacion ocupacional y del indice de IA

Resume, por encuesta y ano, cuantas observaciones y cuanta poblacion
ponderada tienen score de IA, y por que falta en el resto. Distingue la
falta de homologacion CO-95 -\> CNO 2015 (EPE) de la falta de score en
el indice. Revisar este resumen es un paso previo a comparar EPE y EPEN.

## Usage

``` r
cobertura(data, por = NULL, var_peso = NULL)
```

## Arguments

- data:

  `data.frame` procesado con
  [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  e
  [`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md).

- por:

  Variables de agrupacion. Por defecto, la encuesta (`source`, o la
  derivada de `clasificador`: CO-95 = EPE, CNO 2015 = EPEN) y el ano.

- var_peso:

  Factor de expansion. Si es `NULL` se detecta (`weight`,
  `FAC300_ANUAL`, `FACTOR07`, `FACTOR`, `fexp`); si no existe, solo se
  reportan observaciones. En la EPE (`fa_def19`, `fa_def21`) el factor
  depende del periodo y hay que indicarlo.

## Value

Un `data.frame` con una fila por grupo, estado y detalle:

- estado:

  `"con_score"`, `"sin_score"`, `"codigo_no_encontrado"`,
  `"sin_homologacion"` o `"sin_codigo"` (ver
  [`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)).

- detalle:

  En bases EPE, el motivo segun `homologacion_estado`: para
  `"sin_homologacion"`, `multiples_destinos`, `discrepancia_fuente`,
  `ocupacion_no_especificada` o `codigo_no_encontrado`; para
  `"sin_codigo"`, `sin_codigo` o `formato_invalido`. En los demas casos,
  `NA`.

- n, pct_n:

  Observaciones y porcentaje dentro del grupo.

- poblacion, pct_poblacion:

  Poblacion expandida y porcentaje dentro del grupo (`NA` si no hay
  factor de expansion).

## Examples

``` r
muestra <- suppressWarnings(ia_exposicion(cno(muestra_epen_2024)))
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
cobertura(muestra)
#> Warning: 81 fila(s) con weight NA no suman poblacion.
#>   source year    estado detalle    n pct_n  poblacion pct_poblacion
#> 1   EPEN 2024 con_score    <NA> 1961 98.05 165010.121         97.26
#> 2   EPEN 2024 sin_score    <NA>   39  1.95   4651.136          2.74
```
