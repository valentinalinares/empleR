# Encontrar, descargar y etiquetar datos

``` r

library(empleR)
```

Esta parte del manual cubre el inicio del flujo: saber qué información
existe, descargar los microdatos de la EPEN y convertir códigos
numéricos en categorías legibles.

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

1.  Si `destfile` ya existe, lee esa copia.
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
categorías. Por ejemplo, `sex_code = 1` significa “Hombre” y
`sex_code = 2` significa “Mujer”.
[`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
reemplaza esos códigos por etiquetas comprensibles.

### Qué recibe

| Argumento | Uso |
|----|----|
| `data` | Base procesada que contiene variables reconocidas por el paquete. |
| `vars` | Variables que quieres etiquetar; `NULL` usa todas las disponibles. |
| `as_factor` | Devuelve factores si es `TRUE` o texto si es `FALSE`. |

### Qué hace y qué devuelve

La función identifica las variables que tienen un diccionario interno,
busca la etiqueta de cada código y devuelve la misma base con esas
columnas convertidas. No cambia el número de filas ni crea una base
resumida.

``` r

ejemplo <- muestra_epen_2024[1:8, c(
  "sex_code", "education_code", "is_rural"
)]

antes <- ejemplo
despues <- etiquetar(ejemplo)
#> ✔ 3 variable(s) etiquetadas.

antes
#> # A tibble: 8 × 3
#>   sex_code education_code is_rural
#>      <dbl>          <dbl>    <dbl>
#> 1        2              9        0
#> 2        1              5        1
#> 3        2              3        0
#> 4        2              1        1
#> 5        1              3        1
#> 6        1              8        0
#> 7        2             11        0
#> 8        1              6        1
despues
#> # A tibble: 8 × 3
#>   sex_code education_code                   is_rural
#>   <fct>    <fct>                            <fct>   
#> 1 Mujer    Sup. no universitaria completa   Urbano  
#> 2 Hombre   Secundaria incompleta            Rural   
#> 3 Mujer    Primaria incompleta              Urbano  
#> 4 Mujer    Sin nivel                        Rural   
#> 5 Hombre   Primaria incompleta              Rural   
#> 6 Hombre   Sup. no universitaria incompleta Urbano  
#> 7 Mujer    Sup. universitaria completa      Urbano  
#> 8 Hombre   Secundaria completa              Rural
```

### Cómo interpretar el resultado

Las etiquetas facilitan tablas y gráficos. Si necesitas conservar los
códigos para una operación posterior, guarda una copia o etiqueta solo
las variables que usarás para presentar resultados.

``` r

etiquetar(
  muestra_epen_2024[1:8, ],
  vars = c("sex_code", "education_code"),
  as_factor = FALSE
)[, c("sex_code", "education_code")]
#> ✔ 2 variable(s) etiquetadas.
#> # A tibble: 8 × 2
#>   sex_code education_code                  
#>   <chr>    <chr>                           
#> 1 Mujer    Sup. no universitaria completa  
#> 2 Hombre   Secundaria incompleta           
#> 3 Mujer    Primaria incompleta             
#> 4 Mujer    Sin nivel                       
#> 5 Hombre   Primaria incompleta             
#> 6 Hombre   Sup. no universitaria incompleta
#> 7 Mujer    Sup. universitaria completa     
#> 8 Hombre   Secundaria completa
```

[`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
reconoce los nombres de las bases procesadas por el proyecto. No
renombra ni interpreta automáticamente todas las columnas originales del
módulo 76.

## Siguiente paso

Con una base preparada, continúa con [Ocupaciones, homologación e índice
de
IA](https://valentinalinares.github.io/empleR/articles/manual-ocupaciones-ia.md).
