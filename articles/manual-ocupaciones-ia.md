# Ocupaciones, homologación e índice de IA

``` r

library(empleR)
```

Esta parte del manual explica cómo describir ocupaciones, tratar el
cambio del CO-95 al CNO 2015 y añadir el índice de exposición a
inteligencia artificial.

## `cno()`: interpretar y armonizar códigos ocupacionales

### Para qué sirve

[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
reconoce el clasificador de una base, normaliza los códigos y añade la
descripción de cada ocupación. Para datos EPE también puede buscar sus
posibles correspondencias en el CNO 2015.

### Qué recibe

| Argumento      | Uso                                                       |
|----------------|-----------------------------------------------------------|
| `data`         | Microdatos EPE o EPEN.                                    |
| `var_ocup`     | Nombre de la variable ocupacional si no puede detectarse. |
| `homologar`    | Busca correspondencias CO-95–CNO 2015 cuando es `TRUE`.   |
| `agregar`      | Nivel ocupacional: cuatro, tres, dos o un dígito.         |
| `clasificador` | Permite declarar `CNO_2015` o `CO_95`.                    |

### Qué hace por dentro

1.  Determina si la base usa CNO 2015 o CO-95 a partir de la encuesta,
    el año o el argumento indicado.
2.  Localiza la variable ocupacional original.
3.  Conserva los ceros a la izquierda y normaliza la longitud del
    código.
4.  Añade su descripción y el nivel de agregación solicitado.
5.  Si se trata de CO-95 y `homologar = TRUE`, consulta la
    correspondencia oficial y distingue destinos únicos, múltiples y
    discrepancias.

### Qué devuelve con EPEN

``` r

ocupaciones <- cno(muestra_epen_2024[1:8, ])
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
ocupaciones[, c(
  "occupation_code_raw", "clasificador", "cno_cod", "cno_desc"
)]
#> # A tibble: 8 × 4
#>   occupation_code_raw clasificador cno_cod cno_desc                             
#>                 <dbl> <chr>        <chr>   <chr>                                
#> 1                1141 CNO_2015     1141    Directores generales del sector priv…
#> 2                1167 CNO_2015     1167    Directores generales del sector priv…
#> 3                1223 CNO_2015     1223    Directores de investigación y desarr…
#> 4                1342 CNO_2015     1342    Directores y gerentes de empresas qu…
#> 5                1499 CNO_2015     1499    Otros gerentes de servicios          
#> 6                2143 CNO_2015     2143    Ingenieros medioambientales          
#> 7                2164 CNO_2015     2164    Urbanistas e ingenieros de tránsito  
#> 8                2253 CNO_2015     2253    Profesionales de la salud y la higie…
```

La salida conserva las filas originales y añade `clasificador`,
`cno_cod` y `cno_desc`. Si la base trae un código original y otro ya
procesado, también puede marcar discrepancias entre ambos.

### Qué devuelve con EPE

Una correspondencia ocupacional no siempre es uno a uno. En un caso
ambiguo,
[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
conserva todos los candidatos y deja el código homologado sin asignar:

``` r

epe_ejemplo <- data.frame(
  source = "EPE",
  year = 2019,
  p204a = c("262", "014")
)

cno(epe_ejemplo, homologar = TRUE)[, c(
  "cno_cod", "cno_desc", "cno_homologado",
  "cno_candidatos", "homologacion_estado"
)]
#> ℹ Clasificador segun la encuesta de la base: CO_95
#> ✔ Columna cno_homologado agregada con equivalencias CNO 2015.
#> ℹ 0% de las filas tiene una equivalencia unica.
#> ℹ Los casos con varios destinos quedan en NA; ver cno_candidatos y
#>   homologacion_estado.
#>   cno_cod                     cno_desc cno_homologado
#> 1     262 Economistas y planificadores           <NA>
#> 2     014 Personal de servicio militar           <NA>
#>                                         cno_candidatos homologacion_estado
#> 1                                           2412; 2631  multiples_destinos
#> 2 0111; 0112; 0113; 0211; 0212; 0213; 0311; 0312; 0313  multiples_destinos
```

Antes de comparar encuestas, revisa la distribución de
`homologacion_estado`. La [guía de
contexto](https://valentinalinares.github.io/empleR/articles/contexto-encuestas.md)
explica por qué homologar el clasificador no resuelve por sí solo las
diferencias de ámbito, periodo y diseño.

## `ia_exposicion()`: añadir los puntajes de exposición

### Para qué sirve

[`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)
vincula las ocupaciones del CNO 2015 con el índice de exposición
potencial de sus tareas a IA generativa. El puntaje va de 0 a 1 y no
representa la probabilidad de perder el empleo.

### Qué recibe

| Argumento | Uso |
|----|----|
| `data` | Base procesada previamente con [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md). |
| `score` | Selecciona media, mediana o ambos puntajes. |
| `incluir_tipo` | Añade el tipo de impacto predominante cuando está disponible. |

### Qué hace y qué devuelve

La función elige el código CNO válido de cada fila, lo cruza con el
índice y añade las columnas solicitadas sin eliminar personas. Para EPE
usa únicamente los códigos que tienen una correspondencia válida; no
asigna puntajes a casos ambiguos.

``` r

con_ia <- muestra_epen_2024 |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
#> ℹ Filas con score de IA: 2000 (100%).
#> ℹ Resumen por encuesta y ano: `cobertura()`.

con_ia[1:8, c(
  "cno_cod", "cno_desc", "ia_score_mean",
  "ia_score_median", "ia_tipo"
)]
#> # A tibble: 8 × 5
#>   cno_cod cno_desc                         ia_score_mean ia_score_median ia_tipo
#>   <chr>   <chr>                                    <dbl>           <dbl> <chr>  
#> 1 1141    Directores generales del sector…         0.489           0.573 A      
#> 2 1167    Directores generales del sector…         0.501           0.61  A      
#> 3 1223    Directores de investigación y d…         0.518           0.518 A      
#> 4 1342    Directores y gerentes de empres…         0.433           0.4   A      
#> 5 1499    Otros gerentes de servicios              0.542           0.59  A      
#> 6 2143    Ingenieros medioambientales              0.494           0.5   A      
#> 7 2164    Urbanistas e ingenieros de trán…         0.575           0.58  A      
#> 8 2253    Profesionales de la salud y la …         0.473           0.483 A
```

La media resume los puntajes de las tareas de la ocupación; la mediana
ofrece una medida menos sensible a tareas extremas. `ia_tipo` describe
el patrón predominante cuando puede determinarse y queda ausente en
empates o casos sin información suficiente.

## `cobertura()`: comprobar a quiénes representa el cruce

### Para qué sirve

Un promedio del índice puede ser engañoso si muchas observaciones no
tienen un código válido, una homologación o un puntaje.
[`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md)
cuantifica esos casos antes de calcular resultados.

### Qué hace y qué devuelve

Clasifica las filas según su estado y resume tanto el número de
observaciones como la población representada por sus pesos. Así permite
distinguir un problema pequeño en la muestra de uno importante en
términos poblacionales.

``` r

cobertura(con_ia)
#> Warning: 80 fila(s) con weight NA no suman poblacion.
#>   source year    estado detalle    n pct_n poblacion pct_poblacion
#> 1   EPEN 2024 con_score    <NA> 2000   100  100496.5           100
```

### Cómo aplicar el resultado

Reporta la cobertura junto con cualquier indicador de exposición y
explica por qué faltan puntajes. En comparaciones EPE–EPEN conviene
calcularla por encuesta y año, porque la homologación puede modificar la
cobertura de forma desigual.

La validación real de octubre-diciembre de 2021 encontró puntaje para
33,37 % de la población ocupada EPE, frente a 97,72 % en la EPEN de
octubre-diciembre de 2024. La causa principal fue que 64,25 % de la
población EPE tenía varios destinos CNO posibles. No compares las medias
de ambas encuestas como si la cobertura fuera equivalente: informa estos
estados, recalcula la cobertura para tu periodo y, si corresponde,
presenta resultados por separado o una sensibilidad a los casos sin
homologación.

## Autoría del índice

El índice incluido en `empleR` fue desarrollado por Walter Omar Manky
Bonilla, con asistencia de investigación de Valentina Linares Herrera.
La corrida se realizó en abril de 2026 con Claude Sonnet 4.6 y el
paquete metodológico se versionó el 15 de junio de 2026. Actualiza el
estudio [*Doble desafío
tecnológico*](https://www.gob.pe/institucion/inei/informes-publicaciones/7453406-doble-desafio-tecnologico-analisis-de-la-exposicion-a-la-automatizacion-tradicional-y-a-la-inteligencia-artificial-generativa-en-el-empleo-peruano-utilizando-datos-de-la-enaho-2024),
publicado por el INEI en 2025. Los puntajes de esta actualización no
deben atribuirse al INEI.

## Siguiente paso

Continúa con [Indicadores ponderados y
mapas](https://valentinalinares.github.io/empleR/articles/manual-indicadores-mapas.md).
