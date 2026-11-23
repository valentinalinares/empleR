# Cobertura de la homologación ocupacional y del índice de IA

Resume, por encuesta y año, cuántas observaciones y cuánta población
ponderada tienen puntaje de IA, y por qué falta en el resto. Distingue
la falta de homologación CO-95 -\> CNO 2015 (EPE) de la falta de puntaje
en el índice. Revisar este resumen es un paso previo a comparar EPE y
EPEN.

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

  Variables de agrupación. Por defecto, la encuesta (`source`, o la
  derivada de `clasificador`: CO-95 = EPE, CNO 2015 = EPEN) y el año.

- var_peso:

  Factor de expansión. Si es `NULL` se detecta (`weight`,
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

  En bases EPE, el motivo según `homologacion_estado`: para
  `"sin_homologacion"`, `multiples_destinos`, `discrepancia_fuente`,
  `ocupacion_no_especificada` o `codigo_no_encontrado`; para
  `"sin_codigo"`, `sin_codigo` o `formato_invalido`. En los demás casos,
  `NA`.

- n, pct_n:

  Observaciones y porcentaje dentro del grupo.

- poblacion, pct_poblacion:

  Población expandida y porcentaje dentro del grupo (`NA` si no hay
  factor de expansión).

## Examples

``` r
muestra <- suppressWarnings(ia_exposicion(cno(muestra_epen_2024)))
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
#> ℹ Filas con score de IA: 2000 (100%).
#> ℹ Resumen por encuesta y ano: `cobertura()`.
cobertura(muestra)
#> Warning: 80 fila(s) con weight NA no suman poblacion.
#>   source year    estado detalle    n pct_n poblacion pct_poblacion
#> 1   EPEN 2024 con_score    <NA> 2000   100  100496.5           100
```
