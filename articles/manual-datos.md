# Encontrar, descargar y etiquetar datos

``` r

library(empleR)
```

Antes de empezar, puedes consultar qué años y periodos contiene el
catálogo. En esta sección aprenderás a descargar una base de la EPEN y
añadir etiquetas para interpretar sus códigos.

## `catalogo()`: saber qué está disponible

### Para qué sirve

[`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md)
consulta el inventario de bases que el proyecto ha procesado. Es útil
para revisar fuentes, años, variantes, periodos, número de filas y
cantidad de códigos ocupacionales antes de comenzar un análisis.

### Qué recibe

| Argumento | Uso |
|----|----|
| `fuente` | Filtra `EPEN`, `ENAHO` o muestra `todas`. |
| `year` | Selecciona uno o varios años. |
| `variante` | Filtra bases departamentales anuales, Lima móvil o ENAHO anual. |

### Qué hace y qué devuelve

La función filtra el catálogo incluido en el paquete y devuelve un
`data.frame`. No descarga datos. Una fila en el catálogo documenta que
el proyecto procesó esa fuente; solo las entregas EPEN tienen descarga
automática en la versión actual.

``` r

disponibles <- catalogo(
  fuente = "EPEN",
  variante = "departamentos_anual"
)
disponibles
#> # A tibble: 4 × 6
#>   fuente variante             year periodo            filas codigos_ocup
#>   <chr>  <chr>               <dbl> <chr>              <dbl>        <dbl>
#> 1 EPEN   departamentos_anual  2022 Anual - (Ene-Dic) 192416          439
#> 2 EPEN   departamentos_anual  2023 Anual - (Ene-Dic) 196595          449
#> 3 EPEN   departamentos_anual  2024 Anual - (Ene-Dic) 200630          434
#> 4 EPEN   departamentos_anual  2025 Anual - (Ene-Dic) 207407          438
```

### Cómo aplicar el resultado

Después de identificar el año y la variante, usa esos mismos valores en
[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md).
Para consultar los trimestres móviles de Lima de un año:

``` r

catalogo(
  fuente = "EPEN",
  year = 2024,
  variante = "lima_movil"
)
#> # A tibble: 12 × 6
#>    fuente variante    year periodo                        filas codigos_ocup
#>    <chr>  <chr>      <dbl> <chr>                          <dbl>        <dbl>
#>  1 EPEN   lima_movil  2024 Trimestre Móvil -(Abr-May-Jun)  6169          318
#>  2 EPEN   lima_movil  2024 Trimestre Móvil -(Ago-Set-Oct)  6034          309
#>  3 EPEN   lima_movil  2024 Trimestre Móvil -(Dic-Ene-Feb)  6179          315
#>  4 EPEN   lima_movil  2024 Trimestre Móvil -(Ene-Feb-Mar)  6173          327
#>  5 EPEN   lima_movil  2024 Trimestre Móvil -(Feb-Mar-Abr)  6140          322
#>  6 EPEN   lima_movil  2024 Trimestre Móvil -(Jul-Ago-Set)  5992          311
#>  7 EPEN   lima_movil  2024 Trimestre Móvil -(Jun-Jul-Ago)  6056          319
#>  8 EPEN   lima_movil  2024 Trimestre Móvil -(Mar-Abr-May)  6160          324
#>  9 EPEN   lima_movil  2024 Trimestre Móvil -(May-Jun-Jul)  6072          319
#> 10 EPEN   lima_movil  2024 Trimestre Móvil -(Nov-Dic-Ene)  6337          328
#> 11 EPEN   lima_movil  2024 Trimestre Móvil -(Oct-Nov-Dic)  5720          326
#> 12 EPEN   lima_movil  2024 Trimestre Móvil -(Set-Oct-Nov)  5887          314
```

## `descargar()`: obtener microdatos de la EPEN

### Para qué sirve

[`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
obtiene el módulo de empleo e ingresos de la EPEN desde el portal de
microdatos del INEI. Puede guardar el resultado como archivo RDS para no
repetir la descarga.

### Qué recibe

| Argumento  | Uso                                                       |
|------------|-----------------------------------------------------------|
| `year`     | Año de la EPEN, entre los disponibles en el catálogo.     |
| `variante` | `departamentos_anual` o `lima_movil`.                     |
| `periodo`  | Nombre del trimestre móvil; solo se usa con `lima_movil`. |
| `destfile` | Ruta opcional para guardar y reutilizar una copia local.  |
| `quiet`    | Controla los mensajes de progreso de la descarga.         |

### Qué hace por dentro

1.  Si `destfile` ya existe, comprueba que la copia corresponda a la
    solicitud antes de reutilizarla. Las copias antiguas sin metadatos
    deben regenerarse.
2.  Busca la URL que corresponde al año, variante y periodo.
3.  Descarga el ZIP del INEI a una ubicación temporal.
4.  Detecta el CSV y su separador.
5.  Lee las columnas con sus nombres originales y, si se solicitó,
    guarda el RDS.

### Qué devuelve

Devuelve un `data.frame` con el módulo original de empleo e ingresos.
Incluye ocupados, desocupados e inactivos; por eso sirve para construir
indicadores que requieren la población completa. Los nombres de las
variables siguen la nomenclatura del INEI.

``` r

epen_2024 <- descargar(
  year = 2024,
  variante = "departamentos_anual",
  destfile = "datos/epen_2024.rds"
)
```

La función todavía no descarga archivos históricos de la EPE. Para esa
encuesta debes partir de los archivos que hayas obtenido del INEI.

## `etiquetar()`: convertir códigos en categorías legibles

### Para qué sirve

En los microdatos, muchas variables usan números para representar
categorías. Por ejemplo, `C207 = 1` significa “Hombre” y `C207 = 2`
significa “Mujer”.
[`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
agrega una versión legible sin borrar el código original.

### Qué recibe

| Argumento | Uso |
|----|----|
| `data` | Base cruda o procesada que contiene variables reconocidas por el paquete. |
| `vars` | Variables que quieres etiquetar; `NULL` usa todas las disponibles. |
| `as_factor` | Devuelve factores si es `TRUE` o texto si es `FALSE`. |
| `reemplazar` | Conserva los códigos si es `FALSE`; `TRUE` reproduce el comportamiento anterior. |

### Qué hace y qué devuelve

La función identifica las variables que tienen un diccionario interno,
busca la etiqueta de cada código y devuelve la misma base con columnas
nuevas terminadas en `_label`. No cambia el número de filas ni los
códigos de origen. Si encuentra un código fuera del diccionario, lo
advierte y deja su etiqueta en `NA`.

``` r

ejemplo <- muestra_epen_2024[1:8, c(
  "sex_code", "education_code", "is_rural"
)]

antes <- ejemplo
despues <- etiquetar(ejemplo)
#> ✔ 3 columna(s) de etiquetas agregada(s).

antes
#> # A tibble: 8 × 3
#>   sex_code education_code is_rural
#>      <dbl>          <dbl>    <dbl>
#> 1        2              9        0
#> 2        1              4        0
#> 3        2             11        0
#> 4        1              6        0
#> 5        2              2        1
#> 6        1              9        1
#> 7        2              4        1
#> 8        1             11        1
despues[, c(
  "sex_code", "sex_label",
  "education_code", "education_label",
  "is_rural", "area_label"
)]
#> # A tibble: 8 × 6
#>   sex_code sex_label education_code education_label          is_rural area_label
#>      <dbl> <fct>              <dbl> <fct>                       <dbl> <fct>     
#> 1        2 Mujer                  9 Superior no universitar…        0 Urbano    
#> 2        1 Hombre                 4 Primaria completa               0 Urbano    
#> 3        2 Mujer                 11 Superior universitaria …        0 Urbano    
#> 4        1 Hombre                 6 Secundaria completa             0 Urbano    
#> 5        2 Mujer                  2 Educación inicial               1 Rural     
#> 6        1 Hombre                 9 Superior no universitar…        1 Rural     
#> 7        2 Mujer                  4 Primaria completa               1 Rural     
#> 8        1 Hombre                11 Superior universitaria …        1 Rural
```

### Cómo interpretar el resultado

Las etiquetas facilitan tablas y gráficos, mientras que los códigos se
mantienen disponibles para comprobaciones o transformaciones
posteriores.

``` r

etiquetar(
  muestra_epen_2024[1:8, ],
  vars = c("sex_code", "education_code"),
  as_factor = FALSE
)[, c("sex_code", "sex_label", "education_code", "education_label")]
#> ✔ 2 columna(s) de etiquetas agregada(s).
#> # A tibble: 8 × 4
#>   sex_code sex_label education_code education_label                   
#>      <dbl> <chr>              <dbl> <chr>                             
#> 1        2 Mujer                  9 Superior no universitaria completa
#> 2        1 Hombre                 4 Primaria completa                 
#> 3        2 Mujer                 11 Superior universitaria completa   
#> 4        1 Hombre                 6 Secundaria completa               
#> 5        2 Mujer                  2 Educación inicial                 
#> 6        1 Hombre                 9 Superior no universitaria completa
#> 7        2 Mujer                  4 Primaria completa                 
#> 8        1 Hombre                11 Superior universitaria completa
```

También puedes etiquetar una base recién descargada:

``` r

epen_2024 <- descargar(year = 2024)
epen_2024 <- etiquetar(epen_2024)

# C207 permanece intacta; sex_label contiene Hombre/Mujer
table(epen_2024$C207, epen_2024$sex_label, useNA = "ifany")

# El código ocupacional sigue disponible para el paso siguiente
epen_2024 <- cno(epen_2024)
```

Los nombres originales y procesados reconocidos son:

| Concepto | Variable original | Variable procesada | Etiqueta creada |
|----|----|----|----|
| Sexo | `C207` | `sex_code` | `sex_label` |
| Condición de actividad | `OCUP300` | `labor_status_code` | `labor_status_label` |
| Nivel educativo | `C366` | `education_code` | `education_label` |
| Categoría ocupacional | `C310` | `occupational_category_code` | `occupational_category_label` |
| Sector institucional | `C311` | `institutional_sector_code` | `institutional_sector_label` |
| Tamaño de empresa | `C317` | `firm_size_code` | `firm_size_label` |
| Periodicidad del ingreso | `C338` | `income_periodicity_code` | `income_periodicity_label` |
| Área | `AREA` | `is_rural` | `area_label` |

La codificación de `AREA` no es la misma en ambas versiones: el dato
original usa 1/2 y `is_rural` usa 0/1.
[`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
aplica el diccionario que corresponde a cada nombre. No interpreta
automáticamente las demás columnas del módulo 76.

## Siguiente paso

Con una base preparada, continúa con [Ocupaciones, homologación e índice
de
IA](https://valentinalinares.github.io/empleR/articles/manual-ocupaciones-ia.md).
