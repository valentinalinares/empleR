# Armonizar codigos ocupacionales entre CNO 2015 y CO-95

Esta funcion resuelve la **ruptura de clasificadores** entre la EPE
(hasta 2021, usa CO-95 de 3 digitos, basado en CIUO-88) y la EPEN (desde
2022, usa CNO 2015 de 4 digitos, basado en CIUO-08). Detecta
automaticamente el clasificador correcto segun el ano de la base y,
opcionalmente, aplica la tabla de equivalencias para construir series
comparables.

## Usage

``` r
cno(data, var_ocup = NULL, homologar = FALSE, agregar = "4d")
```

## Arguments

- data:

  `data.frame` con microdatos de EPEN/EPE.

- var_ocup:

  Nombre de la variable de codigo ocupacional. Por defecto se detecta
  automaticamente (`C308_COD` para EPEN, segun el ano de la base).

- homologar:

  Logico. Si `TRUE`, aplica la tabla de equivalencias CO-95 \<-\> CNO
  2015 para bases EPE pre-2022 y devuelve la columna adicional
  `cno_homologado`. Por defecto `FALSE`.

- agregar:

  Nivel de agregacion del CNO al que reducir los codigos. Opciones:
  `"4d"` (4 digitos, por defecto), `"3d"`, `"2d"`, `"1d"`. Para bases
  EPE (CO-95), el maximo disponible es `"3d"`.

## Value

El mismo `data.frame` con columnas adicionales:

- clasificador:

  El clasificador detectado: `"CNO_2015"` o `"CO_95"`.

- cno_cod:

  Codigo ocupacional estandarizado al nivel solicitado.

- cno_desc:

  Descripcion de la ocupacion (del diccionario interno).

- cno_homologado:

  (Solo si `homologar = TRUE`) Codigo CNO 2015 equivalente para bases
  CO-95.

## Details

La variable ocupacional en EPEN es `C308_COD`; en ENAHO es `P505R4`. En
EPE (Lima historica) la variable puede diferir segun el ano.

## Examples

``` r
# Con la muestra incluida en el paquete
cno(muestra_epen_2024)
#> ℹ Ano detectado: 2024
#> ℹ Clasificador: CNO_2015
#> # A tibble: 2,000 × 36
#>    source survey_variant period_label  year month region_code ubigeo domain_code
#>    <chr>  <chr>          <chr>        <dbl> <dbl>       <dbl> <lgl>  <lgl>      
#>  1 EPEN   departamentos… Anual - (En…  2024     4          18 NA     NA         
#>  2 EPEN   departamentos… Anual - (En…  2024     4          15 NA     NA         
#>  3 EPEN   departamentos… Anual - (En…  2024     7          14 NA     NA         
#>  4 EPEN   departamentos… Anual - (En…  2024     5           9 NA     NA         
#>  5 EPEN   departamentos… Anual - (En…  2024     3          16 NA     NA         
#>  6 EPEN   departamentos… Anual - (En…  2024    11           3 NA     NA         
#>  7 EPEN   departamentos… Anual - (En…  2024     9          11 NA     NA         
#>  8 EPEN   departamentos… Anual - (En…  2024     4          23 NA     NA         
#>  9 EPEN   departamentos… Anual - (En…  2024     5          15 NA     NA         
#> 10 EPEN   departamentos… Anual - (En…  2024     7          22 NA     NA         
#> # ℹ 1,990 more rows
#> # ℹ 28 more variables: strata_code <lgl>, cluster_id <dbl>, dwelling_id <dbl>,
#> #   household_id <dbl>, person_id <lgl>, relationship_code <lgl>,
#> #   sex_code <dbl>, sex <chr>, age <dbl>, labor_status_code <dbl>,
#> #   occupation_code_raw <dbl>, occupation_code_4d <chr>,
#> #   occupational_category_code <lgl>, firm_size_code <lgl>, hours_week <dbl>,
#> #   income_periodicity_code <lgl>, labor_income_raw <dbl>, …

if (FALSE) { # \dontrun{
epen_2024 <- descargar(year = 2024)

# Agregar descripcion CNO al nivel de 4 digitos
epen_2024 <- cno(epen_2024)

# Agregar descripcion CNO al nivel de 2 digitos (subgrupos principales)
epen_2024 <- cno(epen_2024, agregar = "2d")

# Homologar base EPE 2019 a CNO 2015 para comparar con EPEN 2024
epe_2019  <- descargar(year = 2019)
epen_2024 <- descargar(year = 2024)

epe_2019  <- cno(epe_2019,  homologar = TRUE)
epen_2024 <- cno(epen_2024, homologar = TRUE)
# Ahora ambas bases tienen cno_homologado comparable
} # }
```
