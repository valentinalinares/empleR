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
  2015 para bases EPE pre-2022 y devuelve la columna adicionales
  `cno_homologado`, `cno_candidatos`, `cno_gran_grupo` y
  `homologacion_estado`. Por defecto `FALSE`.

- agregar:

  Nivel de agregacion del CNO al que reducir los codigos. Opciones:
  `"4d"` (4 digitos, por defecto), `"3d"`, `"2d"`, `"1d"`. Para bases
  EPE (CO-95), el maximo disponible y el valor por defecto es `"3d"`. La
  homologacion siempre usa el codigo CO-95 completo.

## Value

El mismo `data.frame` con columnas adicionales:

- clasificador:

  El clasificador detectado: `"CNO_2015"` o `"CO_95"`.

- cno_cod:

  Codigo ocupacional estandarizado al nivel solicitado.

- cno_desc:

  Descripcion de la ocupacion (del diccionario interno).

- cno_homologado:

  (Solo si `homologar = TRUE`, bases CO-95) Codigo CNO 2015 de 4 digitos
  cuando la equivalencia es unica; `NA` si no.

- cno_candidatos:

  Todos los codigos CNO 2015 posibles, separados por `"; "`.

- cno_gran_grupo:

  Gran grupo CNO 2015 (1 digito) cuando todos los candidatos lo
  comparten; permite comparar a nivel agregado.

- homologacion_estado:

  `"unica"`, `"multiples_destinos"`, `"discrepancia_fuente"`,
  `"ocupacion_no_especificada"`, `"codigo_no_encontrado"` o
  `"sin_codigo"`.

## Details

La variable ocupacional en EPEN es `C308_COD`; en EPE es `P204A`
(`p204a`); en ENAHO es `P505R4`.

La homologacion CO-95 -\> CNO 2015 usa la tabla de correspondencia
oficial del INEI (ver
[co_1995](https://valentinalinares.github.io/empleR/reference/co_1995.md)).
Solo se asigna un codigo CNO 2015 cuando la equivalencia es **unica**:
125 codigos CO-95 tienen varios destinos (por ejemplo, 262 "Economistas
y planificadores" corresponde a CNO 2412 y 2631) y en esos casos
`cno_homologado` queda en `NA`. Elegir un candidato o repartir los pesos
requiere una decision metodologica explicita del analista. Revisa
siempre la cobertura con `table(datos$homologacion_estado)` antes de
comparar series.

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
# (descargar() aun no cubre EPE; leer la base EPE obtenida del INEI)
epe_2019 <- readRDS("epe_2019.rds")
epe_2019 <- cno(epe_2019, homologar = TRUE)
table(epe_2019$homologacion_estado)

# Comparacion a nivel de gran grupo (mayor cobertura que 4 digitos)
epen_2024 <- cno(epen_2024, agregar = "1d")
# epe_2019$cno_gran_grupo es comparable con epen_2024$cno_cod
} # }
```
