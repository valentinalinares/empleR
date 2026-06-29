# Aplicar etiquetas de valor a variables de la EPEN/EPE

Convierte variables codificadas numericamente a factores con etiquetas
legibles, siguiendo el diccionario oficial del INEI. Funciona tanto con
datos crudos descargados con
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
como con datos ya procesados.

## Usage

``` r
etiquetar(data, vars = NULL, as_factor = TRUE)
```

## Arguments

- data:

  `data.frame` con microdatos de EPEN/EPE.

- vars:

  Vector de nombres de variables a etiquetar. Si es `NULL` (por
  defecto), etiqueta todas las variables con diccionario disponible.

- as_factor:

  Logico. Si `TRUE` (por defecto), devuelve las variables etiquetadas
  como `factor`. Si `FALSE`, devuelve como `character`.

## Value

El mismo `data.frame` con las variables seleccionadas convertidas.

## Examples

``` r
# Etiquetar todas las variables con diccionario en la muestra
muestra_etiquetada <- etiquetar(muestra_epen_2024)
#> ✔ 8 variable(s) etiquetadas.

# Verificar resultado
table(muestra_etiquetada$sex_code)
#> 
#> Hombre  Mujer 
#>   1043    957 

# Solo etiquetar variables especificas
muestra_etiquetada <- etiquetar(
  muestra_epen_2024,
  vars = c("sex_code", "education_code", "institutional_sector_code")
)
#> ✔ 3 variable(s) etiquetadas.
```
