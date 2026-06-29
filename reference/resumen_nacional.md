# Consultar indicadores nacionales pre-calculados (EPEN/ENAHO)

Devuelve indicadores del mercado laboral a nivel nacional ya calculados
para todos los periodos disponibles. Incluye tasas de desempleo,
actividad y empleo que requieren la PEA completa (no solo ocupados).

## Usage

``` r
resumen_nacional(fuente = "todas", year = NULL, variante = NULL)
```

## Arguments

- fuente:

  `"EPEN"`, `"ENAHO"` o `"todas"` (por defecto).

- year:

  Filtrar por ano. `NULL` devuelve todos los anos.

- variante:

  Filtrar por variante. `NULL` devuelve todas las variantes.

## Value

Un `data.frame` con columnas: `source`, `survey_variant`, `year`,
`period_label`, `activity_rate_pet`, `employment_rate_pet`,
`unemployment_rate_pea`, `income_monthly_weighted_mean`,
`hours_week_weighted_mean`, y mas.

## Examples

``` r
# Ver indicadores EPEN
resumen_nacional(fuente = "EPEN")
#> # A tibble: 45 × 18
#>    source survey_variant       year period_label   pet_population pea_population
#>    <chr>  <chr>               <dbl> <chr>                   <dbl>          <dbl>
#>  1 EPEN   departamentos_anual  2022 Anual - (Ene-…      25481684.      18184319.
#>  2 EPEN   departamentos_anual  2023 Anual - (Ene-…      25910035.      18157195.
#>  3 EPEN   departamentos_anual  2024 Anual - (Ene-…      26276644.      18344229.
#>  4 EPEN   departamentos_anual  2025 Anual - (Ene-…      26601316.      18477203.
#>  5 EPEN   lima_movil           2022 Trimestre Móv…       8223267.       5379730.
#>  6 EPEN   lima_movil           2022 Trimestre Móv…       8280581.       5473922.
#>  7 EPEN   lima_movil           2022 Trimestre Móv…       8252081.       5447447.
#>  8 EPEN   lima_movil           2023 Trimestre Móv…       8451270.       5581158.
#>  9 EPEN   lima_movil           2023 Trimestre Móv…       8566210.       5594204.
#> 10 EPEN   lima_movil           2023 Trimestre Móv…       8337582.       5506158.
#> # ℹ 35 more rows
#> # ℹ 12 more variables: occupied_population <dbl>,
#> #   unemployed_open_population <dbl>, hidden_unemployment_population <dbl>,
#> #   inactive_population <dbl>, activity_rate_pet <dbl>,
#> #   employment_rate_pet <dbl>, unemployment_rate_pea <dbl>,
#> #   income_monthly_weighted_mean <dbl>, hours_week_weighted_mean <dbl>,
#> #   women_share_weighted <dbl>, rural_share_weighted <dbl>, …

# Tasa de desempleo EPEN departamentos por ano
resumen_nacional("EPEN", variante = "departamentos_anual") |>
  subset(select = c(year, unemployment_rate_pea, activity_rate_pet))
#> # A tibble: 4 × 3
#>    year unemployment_rate_pea activity_rate_pet
#>   <dbl>                 <dbl>             <dbl>
#> 1  2022                0.0466             0.714
#> 2  2023                0.0538             0.701
#> 3  2024                0.0557             0.698
#> 4  2025                0.0488             0.695
```
