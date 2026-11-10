# Aplicar etiquetas de valor a variables de la EPEN

Interpreta variables codificadas de la EPEN siguiendo los diccionarios
oficiales del INEI. Reconoce tanto los nombres originales del modulo 76
(`C207`, `OCUP300`, `C366`, `C310`, `C311`, `C317`, `C338` y `AREA`)
como sus equivalentes en las bases procesadas de `{empleR}`.

## Usage

``` r
etiquetar(data, vars = NULL, as_factor = TRUE, reemplazar = FALSE)
```

## Arguments

- data:

  `data.frame` con microdatos de la EPEN.

- vars:

  Vector de nombres de variables a etiquetar. Si es `NULL` (por
  defecto), usa todas las variables reconocidas presentes en `data`.

- as_factor:

  Logico. Si `TRUE` (por defecto), devuelve las etiquetas como factores.
  Si `FALSE`, las devuelve como texto.

- reemplazar:

  Logico. Si es `FALSE` (por defecto), conserva los codigos y agrega
  columnas de etiquetas. Usa `TRUE` solo para reproducir el
  comportamiento anterior, que reemplaza las columnas seleccionadas.

## Value

El mismo `data.frame`. Por defecto agrega una columna de etiqueta por
concepto reconocido y conserva las columnas originales. Los nombres
posibles son `sex_label`, `labor_status_label`, `education_label`,
`institutional_sector_label`, `occupational_category_label`,
`firm_size_label`, `area_label` e `income_periodicity_label`.

## Details

Por defecto conserva intacta cada columna de codigos y agrega una
columna terminada en `_label`. Esta separacion permite usar las
etiquetas para tablas y graficos sin perder los codigos necesarios para
validar o procesar los microdatos. Los valores ausentes siguen ausentes;
un codigo no incluido en el diccionario genera una advertencia y su
etiqueta queda en `NA`.

## References

INEI. Diccionario de variables EPEN anual 2023.
<https://www.inei.gob.pe/media/DATOS_ABIERTOS/EPEN_DEP/DICCIONARIO/2023/Anual-Ener-Dic/Diccionario.pdf>

## Examples

``` r
# Conserva sex_code y crea sex_label
muestra_etiquetada <- etiquetar(muestra_epen_2024)
#> ✔ 8 columna(s) de etiquetas agregada(s).
table(muestra_etiquetada$sex_label)
#> 
#> Hombre  Mujer 
#>   1043    957 

# Funciona tambien con nombres originales del modulo 76
crudos <- data.frame(C207 = c("1", "2"), C366 = c("6", "11"))
etiquetar(crudos, as_factor = FALSE)
#> ✔ 2 columna(s) de etiquetas agregada(s).
#>   C207 C366 sex_label                 education_label
#> 1    1    6    Hombre             Secundaria completa
#> 2    2   11     Mujer Superior universitaria completa

# Compatibilidad con el comportamiento anterior
etiquetar(
  muestra_epen_2024,
  vars = c("sex_code", "education_code"),
  reemplazar = TRUE
)
#> ✔ 2 columna(s) de etiquetas reemplazada(s).
#> # A tibble: 2,000 × 34
#>    source survey_variant period_label  year month region_code ubigeo domain_code
#>    <chr>  <chr>          <chr>        <dbl> <dbl>       <dbl> <chr>  <chr>      
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
#> # ℹ 26 more variables: sample_id <chr>, strata_code <int>, cluster_id <chr>,
#> #   dwelling_id <chr>, household_id <chr>, person_id <int>,
#> #   relationship_code <int>, sex_code <fct>, sex <chr>, age <dbl>,
#> #   labor_status_code <dbl>, occupation_code_raw <dbl>,
#> #   occupation_code_4d <chr>, occupational_category_code <int>,
#> #   firm_size_code <int>, hours_week <dbl>, income_periodicity_code <int>, …
```
