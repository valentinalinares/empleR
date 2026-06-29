# Ver el catalogo de fuentes disponibles

Muestra un inventario de todas las encuestas, anos y variantes
disponibles para descargar con
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md).
Incluye EPEN (departamentos y Lima movil) y ENAHO anual, con el numero
de filas y codigos ocupacionales por periodo.

## Usage

``` r
catalogo(fuente = "todas", year = NULL, variante = "todas")
```

## Arguments

- fuente:

  Filtrar por fuente: `"EPEN"`, `"ENAHO"` o `"todas"` (por defecto).

- year:

  Filtrar por ano. Si es `NULL` (por defecto), devuelve todos los anos.

- variante:

  Filtrar por variante: `"departamentos_anual"`, `"lima_movil"`,
  `"anual"` o `"todas"` (por defecto).

## Value

Un `data.frame` con columnas:

- fuente:

  Nombre de la encuesta (EPEN, ENAHO).

- variante:

  Variante de la encuesta.

- year:

  Ano de referencia.

- periodo:

  Descripcion del periodo (trimestre o anual).

- filas:

  Numero de filas en la base procesada.

- codigos_ocup:

  Numero de codigos ocupacionales distintos.

## Examples

``` r
# Ver todo el catalogo
catalogo()
#> # A tibble: 52 × 6
#>    fuente variante             year periodo                   filas codigos_ocup
#>    <chr>  <chr>               <dbl> <chr>                     <dbl>        <dbl>
#>  1 ENAHO  anual                2019 Anual - (Ene-Dic)         64954          421
#>  2 ENAHO  anual                2020 Anual - (Ene-Dic)         56615          390
#>  3 ENAHO  anual                2021 Anual - (Ene-Dic)         59935          397
#>  4 ENAHO  anual                2022 Anual - (Ene-Dic)         61181          414
#>  5 ENAHO  anual                2023 Anual - (Ene-Dic)         59447          400
#>  6 ENAHO  anual                2024 Anual - (Ene-Dic)         58579          401
#>  7 ENAHO  anual                2025 Anual - (Ene-Dic)         57716          397
#>  8 EPEN   departamentos_anual  2022 Anual - (Ene-Dic)        192416          439
#>  9 EPEN   lima_movil           2022 Trimestre Móvil -(Ago-S…   6166          318
#> 10 EPEN   lima_movil           2022 Trimestre Móvil -(Oct-N…   6561          333
#> # ℹ 42 more rows

# Solo EPEN
catalogo(fuente = "EPEN")
#> # A tibble: 45 × 6
#>    fuente variante             year periodo                   filas codigos_ocup
#>    <chr>  <chr>               <dbl> <chr>                     <dbl>        <dbl>
#>  1 EPEN   departamentos_anual  2022 Anual - (Ene-Dic)        192416          439
#>  2 EPEN   lima_movil           2022 Trimestre Móvil -(Ago-S…   6166          318
#>  3 EPEN   lima_movil           2022 Trimestre Móvil -(Oct-N…   6561          333
#>  4 EPEN   lima_movil           2022 Trimestre Móvil -(Set-O…   6520          323
#>  5 EPEN   departamentos_anual  2023 Anual - (Ene-Dic)        196595          449
#>  6 EPEN   lima_movil           2023 Trimestre Móvil -(Abr-M…   6589          326
#>  7 EPEN   lima_movil           2023 Trimestre Móvil -(Ago-S…   6622          330
#>  8 EPEN   lima_movil           2023 Trimestre Móvil -(Dic-E…   6397          323
#>  9 EPEN   lima_movil           2023 Trimestre Móvil -(Ene-F…   6443          315
#> 10 EPEN   lima_movil           2023 Trimestre Móvil -(Feb-M…   6625          325
#> # ℹ 35 more rows

# EPEN departamentos anuales
catalogo(fuente = "EPEN", variante = "departamentos_anual")
#> # A tibble: 4 × 6
#>   fuente variante             year periodo            filas codigos_ocup
#>   <chr>  <chr>               <dbl> <chr>              <dbl>        <dbl>
#> 1 EPEN   departamentos_anual  2022 Anual - (Ene-Dic) 192416          439
#> 2 EPEN   departamentos_anual  2023 Anual - (Ene-Dic) 196595          449
#> 3 EPEN   departamentos_anual  2024 Anual - (Ene-Dic) 200630          434
#> 4 EPEN   departamentos_anual  2025 Anual - (Ene-Dic) 207407          438

# Un ano especifico
catalogo(year = 2024)
#> # A tibble: 14 × 6
#>    fuente variante             year periodo                   filas codigos_ocup
#>    <chr>  <chr>               <dbl> <chr>                     <dbl>        <dbl>
#>  1 ENAHO  anual                2024 Anual - (Ene-Dic)         58579          401
#>  2 EPEN   departamentos_anual  2024 Anual - (Ene-Dic)        200630          434
#>  3 EPEN   lima_movil           2024 Trimestre Móvil -(Abr-M…   6169          318
#>  4 EPEN   lima_movil           2024 Trimestre Móvil -(Ago-S…   6034          309
#>  5 EPEN   lima_movil           2024 Trimestre Móvil -(Dic-E…   6179          315
#>  6 EPEN   lima_movil           2024 Trimestre Móvil -(Ene-F…   6173          327
#>  7 EPEN   lima_movil           2024 Trimestre Móvil -(Feb-M…   6140          322
#>  8 EPEN   lima_movil           2024 Trimestre Móvil -(Jul-A…   5992          311
#>  9 EPEN   lima_movil           2024 Trimestre Móvil -(Jun-J…   6056          319
#> 10 EPEN   lima_movil           2024 Trimestre Móvil -(Mar-A…   6160          324
#> 11 EPEN   lima_movil           2024 Trimestre Móvil -(May-J…   6072          319
#> 12 EPEN   lima_movil           2024 Trimestre Móvil -(Nov-D…   6337          328
#> 13 EPEN   lima_movil           2024 Trimestre Móvil -(Oct-N…   5720          326
#> 14 EPEN   lima_movil           2024 Trimestre Móvil -(Set-O…   5887          314
```
