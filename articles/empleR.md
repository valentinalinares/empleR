# Introducción a empleR

``` r

library(empleR)
```

## Qué es empleR

[empleR](https://valentinalinares.github.io/empleR/) es un paquete de R
para descargar EPEN y procesar y analizar microdatos de las encuestas de
empleo del Perú publicadas por el INEI:

- **EPEN** (Encuesta Permanente de Empleo Nacional, 2022-presente):
  cobertura nacional y resultados en ámbitos departamentales.
- **EPE** (Encuesta Permanente de Empleo, hasta 2021): cobertura solo
  Lima Metropolitana.

Al trabajar con ambas encuestas encontrarás códigos de dos
clasificadores ocupacionales: CO-95 en la EPE y CNO 2015 en la EPEN.
[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
consulta sus correspondencias y muestra qué ocupaciones tienen una
equivalencia única y cuáles requieren una revisión adicional.

Para una explicación histórica y metodológica, consulta [De la EPE a la
EPEN](https://valentinalinares.github.io/empleR/articles/contexto-encuestas.md).
Para ver entradas, resultados y límites de cada función, consulta el
[Manual de
empleR](https://valentinalinares.github.io/empleR/articles/funciones.md).

## Ver qué datos están disponibles

``` r

# Ver todo el catálogo de fuentes disponibles
catalogo()
#> # A tibble: 52 × 6
#>    fuente variante             year periodo                   filas codigos_ocup
#>    <chr>  <chr>               <dbl> <chr>                     <dbl>        <dbl>
#>  1 ENAHO  anual                2019 Anual - (Ene-Dic)         64954          421
#>  2 ENAHO  anual                2020 Anual - (Ene-Dic)         56615          390
#>  3 ENAHO  anual                2021 Anual - (Ene-Dic)         59935          397
#>  4 ENAHO  anual                2022 Anual - (Ene-Dic)         61181          414
#>  5 ENAHO  anual                2023 Anual - (Ene-Dic)         59447          400
#>  6 ENAHO  anual                2024 Anual - (Ene-Dic)         58579          401
#>  7 ENAHO  anual                2025 Anual - (Ene-Dic)         57716          397
#>  8 EPEN   departamentos_anual  2022 Anual - (Ene-Dic)        192416          439
#>  9 EPEN   lima_movil           2022 Trimestre Móvil -(Ago-S…   6166          318
#> 10 EPEN   lima_movil           2022 Trimestre Móvil -(Oct-N…   6561          333
#> # ℹ 42 more rows

# Solo EPEN departamentos anuales
catalogo(fuente = "EPEN", variante = "departamentos_anual")
#> # A tibble: 4 × 6
#>   fuente variante             year periodo            filas codigos_ocup
#>   <chr>  <chr>               <dbl> <chr>              <dbl>        <dbl>
#> 1 EPEN   departamentos_anual  2022 Anual - (Ene-Dic) 192416          439
#> 2 EPEN   departamentos_anual  2023 Anual - (Ene-Dic) 196595          449
#> 3 EPEN   departamentos_anual  2024 Anual - (Ene-Dic) 200630          434
#> 4 EPEN   departamentos_anual  2025 Anual - (Ene-Dic) 207407          438
```

## Flujo básico de trabajo

``` r

# 1. Practicar con la muestra sintética incluida en el paquete
epen_2024 <- etiquetar(muestra_epen_2024)
#> ✔ 8 columna(s) de etiquetas agregada(s).

# 2. Armonizar códigos ocupacionales (CNO 2015 automático para 2024)
epen_2024 <- cno(epen_2024)
#> ℹ Clasificador segun la encuesta de la base: CNO_2015

# 3. Calcular indicadores ponderados
ingreso_dep <- indicadores(
  epen_2024,
  "ingreso_promedio",
  por = c("region_code", "division_lima")
)
#> Warning: 80 filas no participan por peso ausente o invalido.
#> Warning: 48 filas con peso valido no participan por el valor del
#> indicador.

# 4. Visualizar los 25 ámbitos departamentales oficiales de la EPEN
mapa(ingreso_dep, var = "estimado",
     titulo = "Ingreso laboral promedio: ejemplo con datos sintéticos")
#> Warning: 23 ambitos sin dato para 'estimado': "AMAZONAS", "ANCASH", "APURIMAC",
#> "AREQUIPA", "AYACUCHO", "CAJAMARCA", "CUSCO", "HUANCAVELICA", "HUANUCO", "ICA",
#> "JUNIN", "LA LIBERTAD", "LAMBAYEQUE", "LORETO", "MADRE DE DIOS", "MOQUEGUA",
#> "PASCO", "PIURA", …, "TUMBES", and "UCAYALI".
```

`descargar(year = 2024)` devuelve el módulo 76 con los nombres
originales del INEI.
[`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
reconoce ocho variables crudas del módulo y sus equivalentes procesados.
Conserva los códigos y agrega columnas terminadas en `_label`; no
intenta interpretar automáticamente las demás columnas sin un
diccionario verificado.

Las tasas de actividad y empleo usan como referencia la población en
edad de trabajar (PET); la tasa de desempleo usa la población
económicamente activa (PEA), formada por ocupados y desocupados. La
muestra de ejemplo contiene solo ocupados. Para consultar tasas ya
calculadas con las bases completas, usa
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md):

``` r

resumen_nacional("EPEN", variante = "departamentos_anual")
#> # A tibble: 4 × 18
#>   source survey_variant       year period_label    pet_population pea_population
#>   <chr>  <chr>               <dbl> <chr>                    <dbl>          <dbl>
#> 1 EPEN   departamentos_anual  2022 Anual - (Ene-D…      25481684.      18184319.
#> 2 EPEN   departamentos_anual  2023 Anual - (Ene-D…      25910035.      18157195.
#> 3 EPEN   departamentos_anual  2024 Anual - (Ene-D…      26276644.      18344229.
#> 4 EPEN   departamentos_anual  2025 Anual - (Ene-D…      26601316.      18477203.
#> # ℹ 12 more variables: occupied_population <dbl>,
#> #   unemployed_open_population <dbl>, hidden_unemployment_population <dbl>,
#> #   inactive_population <dbl>, activity_rate_pet <dbl>,
#> #   employment_rate_pet <dbl>, unemployment_rate_pea <dbl>,
#> #   income_monthly_weighted_mean <dbl>, hours_week_weighted_mean <dbl>,
#> #   women_share_weighted <dbl>, rural_share_weighted <dbl>,
#> #   occupation_count <dbl>
```

Con el operador pipe, el flujo reproducible sobre la muestra incluida se
puede escribir de forma compacta:

``` r

muestra_epen_2024 |>
  cno() |>
  ia_exposicion(incluir_tipo = TRUE) |>
  indicadores("ingreso_promedio", por = "ia_tipo")
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
#> ℹ Filas con score de IA: 2000 (100%).
#> ℹ Resumen por encuesta y ano: `cobertura()`.
#> Warning: 80 filas no participan por peso ausente o invalido.
#> Warning: 48 filas con peso valido no participan por el valor del
#> indicador.
#>   ia_tipo        indicador estimado n_universo n_estimacion n_sin_peso
#> 1       A ingreso_promedio 1901.539        849          791         37
#> 2       N ingreso_promedio 1883.667       1004          938         40
#> 3       S ingreso_promedio 2128.156          5            5          0
#>   n_peso_invalido n_sin_indicador n_indicador_invalido n_fuera_definicion
#> 1               0               0                    0                 23
#> 2               0               0                    0                 27
#> 3               0               0                    0                  0
#>   poblacion_representada
#> 1             42029.1207
#> 2             48515.3103
#> 3               199.5049
```

## La ruptura de clasificadores EPE/EPEN

Las tablas del INEI permiten buscar correspondencias entre los dos
clasificadores. Algunas ocupaciones tienen un destino único; otras se
reparten entre varias categorías del nuevo clasificador.

Antes de 2022, la EPE usaba el **CO-95** (3 dígitos, basado en CIUO-88).
Desde 2022, la EPEN usa el **CNO 2015** (4 dígitos, basado en CIUO-08).

La homologación usa la tabla de correspondencia oficial del INEI
(`co_1995`). No todas las ocupaciones tienen un equivalente único: de
370 códigos CO-95, 236 tienen un solo destino CNO 2015 y 125 tienen
varios. Por ejemplo, CO-95 262 (“Economistas y planificadores”)
corresponde a CNO 2412 (analistas financieros) y 2631 (economistas). En
esos casos
[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
**no elige un candidato**: deja `cno_homologado` en `NA` y guarda todas
las opciones en `cno_candidatos`.

``` r

# Con datos EPE 2019 (CO-95, detectado automáticamente; variable P204A)
epe_2019 <- readRDS("epe_2019.rds")
epe_2019 <- cno(epe_2019, homologar = TRUE)
# Agrega: cno_cod, cno_desc, cno_homologado, cno_candidatos,
#         cno_gran_grupo, homologacion_estado

# Revisar cobertura antes de comparar series
table(epe_2019$homologacion_estado)

# A nivel de gran grupo la cobertura es mayor
epen_2024 <- cno(descargar(year = 2024), agregar = "1d")
# Ambas columnas expresan el gran grupo ocupacional.
# Antes de compararlas, revisa cobertura, territorio y periodo.
```

La tabla completa de pares está en `equivalencia_co95`. No la unas
directamente a los microdatos: un código CO-95 con varios destinos
replicaría personas y pesos.

### Detección del clasificador

[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
decide el clasificador con el argumento `clasificador`, la encuesta
declarada en `source` (EPE o EPEN) o los años de **todas** las filas
(`year`, `anio`, `ANIO` o `AÑO`). Una base que mezcla años anteriores y
posteriores a 2022, o ambas encuestas, produce un error: procesa cada
parte por separado y une después.

### Exposición a IA y cobertura en EPE y EPEN

[`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)
usa `cno_homologado` en las filas EPE y `cno_cod` en las EPEN, y rechaza
códigos CO-95 o agregados.
[`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md)
resume por encuesta y año cuántas observaciones y cuánta población
tienen puntaje, y por qué falta en el resto:

``` r

epe  <- cno(epe_2019, homologar = TRUE) |> ia_exposicion()
epen <- cno(descargar(year = 2024)) |> ia_exposicion()
cobertura(dplyr::bind_rows(epe, epen))
# estado: con_score, sin_score, sin_homologacion, sin_codigo
```

## Índice de exposición a inteligencia artificial

[empleR](https://valentinalinares.github.io/empleR/) incluye una nueva
corrida del índice de exposición a IA generativa, desarrollada por
Walter Omar Manky Bonilla, con la asistencia de investigación de
Valentina Linares Herrera, usando Claude Sonnet 4.6 (Anthropic) para las
ocupaciones del CNO 2015. La corrida se realizó en abril de 2026 y su
paquete metodológico fue versionado el 15 de junio de 2026. Actualiza el
enfoque publicado por Manky (2025), conserva un puntaje continuo y
aplica reglas revisadas para empates, ambigüedades y tipo de exposición;
por ello sus valores no son los puntajes publicados originalmente por el
INEI.

Referencia del antecedente: Manky, W. O. (2025). *Doble desafío
tecnológico: análisis de la exposición a la automatización tradicional y
a la inteligencia artificial generativa en el empleo peruano, utilizando
datos de la ENAHO 2024*. Instituto Nacional de Estadística e
Informática.

``` r

# Agregar puntaje de IA a los microdatos
epen_ia <- muestra_epen_2024 |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
#> ℹ Filas con score de IA: 2000 (100%).
#> ℹ Resumen por encuesta y ano: `cobertura()`.

# Ver distribución del puntaje
summary(epen_ia$ia_score_mean)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>  0.0500  0.1800  0.3718  0.3522  0.5000  0.8033

# Exposición media por ámbito EPEN en los datos sintéticos
llave <- interaction(
  epen_ia$region_code,
  ifelse(is.na(epen_ia$division_lima), 0L, epen_ia$division_lima),
  drop = TRUE
)
ia_dep <- do.call(rbind, lapply(split(epen_ia, llave), function(d) {
  ok <- is.finite(d$ia_score_mean) & is.finite(d$weight) & d$weight > 0
  data.frame(
    region_code   = d$region_code[1],
    division_lima = d$division_lima[1],
    ia_score_mean = stats::weighted.mean(d$ia_score_mean[ok], d$weight[ok])
  )
}))
mapa(ia_dep, var = "ia_score_mean",
     titulo = "Exposición a IA: ejemplo con datos sintéticos")
```

El mapa anterior sirve para practicar el procedimiento. Sus valores
proceden de datos sintéticos y no describen la exposición de la
población peruana.

## Datos de ejemplo

El paquete incluye `muestra_epen_2024`, un conjunto de datos
completamente sintético de 2.000 filas para practicar sin descargar ni
redistribuir microdatos reales:

``` r

# Ver estructura de la muestra
str(muestra_epen_2024)
#> tibble [2,000 × 36] (S3: tbl_df/tbl/data.frame)
#>  $ source                    : chr [1:2000] "EPEN" "EPEN" "EPEN" "EPEN" ...
#>  $ survey_variant            : chr [1:2000] "departamentos_anual" "departamentos_anual" "departamentos_anual" "departamentos_anual" ...
#>  $ period_label              : chr [1:2000] "Anual - (Ene-Dic)" "Anual - (Ene-Dic)" "Anual - (Ene-Dic)" "Anual - (Ene-Dic)" ...
#>  $ year                      : num [1:2000] 2024 2024 2024 2024 2024 ...
#>  $ month                     : num [1:2000] 1 1 1 1 2 2 2 2 3 3 ...
#>  $ region_code               : num [1:2000] 1 1 1 1 2 2 2 2 3 3 ...
#>  $ ubigeo                    : chr [1:2000] NA NA NA NA ...
#>  $ domain_code               : chr [1:2000] NA NA NA NA ...
#>  $ sample_id                 : chr [1:2000] "1" "1" "1" "1" ...
#>  $ strata_code               : int [1:2000] 4 4 4 4 7 7 7 7 6 6 ...
#>  $ cluster_id                : chr [1:2000] "00000" "00000" "00000" "00000" ...
#>  $ dwelling_id               : chr [1:2000] "0001" "0001" "0001" "0001" ...
#>  $ household_id              : chr [1:2000] "1" "1" "1" "1" ...
#>  $ person_id                 : int [1:2000] 1 2 3 4 1 2 3 4 1 2 ...
#>  $ relationship_code         : int [1:2000] 1 2 3 4 5 6 7 8 9 10 ...
#>  $ sex_code                  : num [1:2000] 2 1 2 1 2 1 2 1 2 1 ...
#>  $ sex                       : chr [1:2000] "Mujer" "Hombre" "Mujer" "Hombre" ...
#>  $ age                       : num [1:2000] 31 44 57 70 26 39 52 65 21 34 ...
#>  $ labor_status_code         : num [1:2000] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ occupation_code_raw       : num [1:2000] 1141 1167 1223 1342 1499 ...
#>  $ occupation_code_4d        : chr [1:2000] "1141" "1167" "1223" "1342" ...
#>  $ occupational_category_code: int [1:2000] 4 7 2 5 8 3 6 1 4 7 ...
#>  $ firm_size_code            : int [1:2000] 2 3 4 5 2 3 4 5 2 3 ...
#>  $ hours_week                : num [1:2000] 45 16 57 42 38 31 42 24 30 43 ...
#>  $ income_periodicity_code   : int [1:2000] NA NA NA 5 NA NA NA 5 NA NA ...
#>  $ labor_income_raw          : num [1:2000] 3370 1024 2342 2078 1460 ...
#>  $ labor_income_monthly      : num [1:2000] 3370 1024 2342 2078 1460 ...
#>  $ weight                    : num [1:2000] 130.3 38.7 41.3 198.4 59.4 ...
#>  $ is_rural                  : num [1:2000] 0 0 0 0 1 1 1 1 0 0 ...
#>  $ is_urban                  : num [1:2000] 1 1 1 1 0 0 0 0 1 1 ...
#>  $ labor_income_work_weighted: num [1:2000] 3370 1024 2342 2078 1460 ...
#>  $ education_code            : num [1:2000] 9 4 11 6 2 9 4 11 7 2 ...
#>  $ institutional_sector_code : num [1:2000] 3 NA 5 NA 3 NA 5 NA 3 NA ...
#>  $ area_raw                  : num [1:2000] 1 1 1 1 2 2 2 2 1 1 ...
#>  $ hours_week_total          : num [1:2000] 45 16 57 42 45 31 42 24 30 55 ...
#>  $ division_lima             : int [1:2000] NA NA NA NA NA NA NA NA NA NA ...

# Aplicar cno() directamente
muestra_con_cno <- cno(muestra_epen_2024)
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
head(muestra_con_cno[, c("cno_cod", "cno_desc", "clasificador")])
#> # A tibble: 6 × 3
#>   cno_cod cno_desc                                                  clasificador
#>   <chr>   <chr>                                                     <chr>       
#> 1 1141    Directores generales del sector privado del servicio de … CNO_2015    
#> 2 1167    Directores generales del sector privado que prestan serv… CNO_2015    
#> 3 1223    Directores de investigación y desarrollo                  CNO_2015    
#> 4 1342    Directores y gerentes de empresas que prestan servicios … CNO_2015    
#> 5 1499    Otros gerentes de servicios                               CNO_2015    
#> 6 2143    Ingenieros medioambientales                               CNO_2015
```

## Citación y contribuciones

Para citar el paquete y, si corresponde, el índice de exposición a IA,
consulta:

``` r

citation("empleR")
```

Los microdatos y las cifras oficiales deben citarse por separado como
productos del INEI. Si encuentras un error o quieres proponer una
mejora, revisa la [guía de
contribución](https://valentinalinares.github.io/empleR/CONTRIBUTING.html)
y el [código de
conducta](https://valentinalinares.github.io/empleR/CODE_OF_CONDUCT.html).
