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
#> 1                5212 CNO_2015     5212    Vendedores minoristas en tiendas y e…
#> 2                6114 CNO_2015     6114    Agricultores y trabajadores califica…
#> 3                9111 CNO_2015     9111    Limpiadores y asistentes domésticos  
#> 4                9211 CNO_2015     9211    Peones de explotaciones agrícolas y …
#> 5                6114 CNO_2015     6114    Agricultores y trabajadores califica…
#> 6                7231 CNO_2015     7231    Mecánicos y reparadores de vehículos…
#> 7                2222 CNO_2015     2222    Profesionales de partería            
#> 8                9313 CNO_2015     9313    Peones de la construcción de edifici…
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
#> Warning: ℹ Filas con score de IA: 1961 (98%).
#> ! 39 (2%) con codigo CNO sin score en el indice.
#> ℹ Resumen por encuesta y ano: `cobertura()`.

con_ia[1:8, c(
  "cno_cod", "cno_desc", "ia_score_mean",
  "ia_score_median", "ia_tipo"
)]
#> # A tibble: 8 × 5
#>   cno_cod cno_desc                         ia_score_mean ia_score_median ia_tipo
#>   <chr>   <chr>                                    <dbl>           <dbl> <chr>  
#> 1 5212    Vendedores minoristas en tienda…        0.599            0.617 A      
#> 2 6114    Agricultores y trabajadores cal…        0.264            0.242 N      
#> 3 9111    Limpiadores y asistentes domést…        0.0625           0.05  N      
#> 4 9211    Peones de explotaciones agrícol…        0.05             0.05  N      
#> 5 6114    Agricultores y trabajadores cal…        0.264            0.242 N      
#> 6 7231    Mecánicos y reparadores de vehí…        0.238            0.15  N      
#> 7 2222    Profesionales de partería               0.325            0.333 NA     
#> 8 9313    Peones de la construcción de ed…        0.05             0.05  N
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
#> Warning: 81 fila(s) con weight NA no suman poblacion.
#>   source year    estado detalle    n pct_n  poblacion pct_poblacion
#> 1   EPEN 2024 con_score    <NA> 1961 98.05 165010.121         97.26
#> 2   EPEN 2024 sin_score    <NA>   39  1.95   4651.136          2.74
```

### Cómo aplicar el resultado

Reporta la cobertura junto con cualquier indicador de exposición y
explica por qué faltan puntajes. En comparaciones EPE–EPEN conviene
calcularla por encuesta y año, porque la homologación puede modificar la
cobertura de forma desigual.

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
