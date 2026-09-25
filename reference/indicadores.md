# Calcular indicadores del mercado laboral con diseno muestral

Calcula indicadores laborales incorporando el diseno muestral complejo
de la EPEN mediante el paquete survey. Los datos deben ser microdatos
procesados (output de
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md))
con al menos ocupados en la muestra.

## Usage

``` r
indicadores(
  data,
  indicador,
  por = NULL,
  var_strata = NULL,
  var_psu = NULL,
  var_peso = NULL
)
```

## Arguments

- data:

  `data.frame` con microdatos de EPEN (output de
  [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)).

- indicador:

  Nombre del indicador a calcular:

  - `"ingreso_promedio"`: Ingreso laboral mensual medio (ocupados).

  - `"horas_promedio"`: Horas trabajadas promedio semanales (ocupados).

  - `"ingreso_mediano"`: Mediana del ingreso mensual (ocupados).

- por:

  Variable(s) de agrupacion: `"sex"`, `"region_code"`,
  `"education_code"`, `"institutional_sector_code"`, etc. `NULL` =
  nacional.

- var_strata:

  Nombre de la variable de estrato. Detecta automaticamente
  `strata_code` (datos procesados) o `ESTRATO` (datos crudos INEI).

- var_psu:

  Nombre de la variable PSU. Detecta automaticamente `cluster_id` (datos
  procesados) o `CONGLOME` (datos crudos INEI).

- var_peso:

  Nombre del factor de expansion. Detecta automaticamente `weight`
  (procesados) o `FACTOR07` (datos crudos INEI).

## Value

Un `data.frame` con el indicador calculado y error estandar, agrupado
segun `por`.

## Details

Para obtener tasas de desempleo, actividad y empleo a nivel nacional o
regional, usa
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md),
que devuelve los indicadores pre-calculados del pipeline INEI con la
muestra completa de la PEA.

## See also

[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md)
para indicadores pre-calculados (incluyendo tasas de desempleo y
actividad).
[indicadores_epen](https://valentinalinares.github.io/empleR/reference/indicadores_epen.md)
para el dataset interno con indicadores nacionales precalculados.

## Examples

``` r
# Ingreso promedio nacional con la muestra interna
indicadores(muestra_epen_2024, "ingreso_promedio")
#> Warning: 81 filas eliminadas por peso NA o cero.
#> Warning: Diseno muestral simplificado: no se encontraron strata/PSU.
#>          indicador estimado error_std
#> 1 ingreso_promedio 1423.681  51.84008

# Ingreso promedio por sexo
indicadores(muestra_epen_2024, "ingreso_promedio", por = "sex")
#> Warning: 81 filas eliminadas por peso NA o cero.
#> Warning: Diseno muestral simplificado: no se encontraron strata/PSU.
#>           sex        indicador estimado error_std
#> Hombre Hombre ingreso_promedio 1606.021  72.06051
#> Mujer   Mujer ingreso_promedio 1209.925  72.57662

if (FALSE) { # \dontrun{
epen_2024 <- descargar(year = 2024)

# Ingreso promedio por departamento (codigo de region 1-25)
indicadores(epen_2024, "ingreso_promedio", por = "region_code")

# Horas trabajadas por sector institucional
indicadores(epen_2024, "horas_promedio", por = "institutional_sector_code")
} # }
```
