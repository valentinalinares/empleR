# Introduccion a empleR

``` r

library(empleR)
```

## Que es empleR

[empleR](https://valentinalinares.github.io/empleR/) es un paquete de R
para descargar, procesar y analizar los microdatos de las encuestas de
empleo del Peru publicadas por el INEI:

- **EPEN** (Encuesta Permanente de Empleo Nacional, 2022-presente):
  cobertura nacional por departamentos.
- **EPE** (Encuesta Permanente de Empleo, hasta 2021): cobertura solo
  Lima Metropolitana.

El paquete resuelve la principal dificultad tecnica de trabajar con
estas series: la **ruptura de clasificadores ocupacionales** entre EPE
(que usa CO-95, 3 digitos) y EPEN (que usa CNO 2015, 4 digitos).

## Ver que datos estan disponibles

``` r

# Ver todo el catalogo de fuentes disponibles
catalogo()

# Solo EPEN departamentos anuales
catalogo(fuente = "EPEN", variante = "departamentos_anual")
```

## Flujo basico de trabajo

``` r

# 1. Descargar microdatos
epen_2024 <- descargar(year = 2024)

# 2. Aplicar etiquetas de valor
epen_2024 <- etiquetar(epen_2024)

# 3. Armonizar codigos ocupacionales (CNO 2015 automatico para 2024)
epen_2024 <- cno(epen_2024)

# 4. Calcular indicadores con diseno muestral
ingreso_dep <- indicadores(epen_2024, "ingreso_promedio", por = "region_code")

# 5. Visualizar en mapa (region_code 1-25 sigue el orden alfabetico)
ingreso_dep$departamento <- shapes_departamentos$departamento[ingreso_dep$region_code]
mapa(ingreso_dep, var = "estimado",
     titulo = "Ingreso laboral promedio por departamento, EPEN 2024")
```

Las tasas de desempleo, actividad y empleo requieren la PEA completa y
se consultan pre-calculadas con
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md):

``` r

resumen_nacional("EPEN", variante = "departamentos_anual")
```

Con el operador pipe, el flujo se puede escribir de forma compacta:

``` r

descargar(year = 2024) |>
  cno() |>
  ia_exposicion(incluir_tipo = TRUE) |>
  indicadores("ingreso_promedio", por = "ia_tipo")
```

## La ruptura de clasificadores EPE/EPEN

Este es el problema central que
[empleR](https://valentinalinares.github.io/empleR/) resuelve
automaticamente.

Antes de 2022, la EPE usaba el **CO-95** (3 digitos, basado en CIUO-88).
Desde 2022, la EPEN usa el **CNO 2015** (4 digitos, basado en CIUO-08).

La homologacion usa la tabla de correspondencia oficial del INEI
(`co_1995`). No todas las ocupaciones tienen un equivalente unico: de
370 codigos CO-95, 236 tienen un solo destino CNO 2015 y 125 tienen
varios. Por ejemplo, CO-95 262 (“Economistas y planificadores”)
corresponde a CNO 2412 (analistas financieros) y 2631 (economistas). En
esos casos
[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
**no elige un candidato**: deja `cno_homologado` en `NA` y guarda todas
las opciones en `cno_candidatos`.

``` r

# Con datos EPE 2019 (CO-95, detectado automaticamente; variable P204A)
epe_2019 <- readRDS("epe_2019.rds")
epe_2019 <- cno(epe_2019, homologar = TRUE)
# Agrega: cno_cod, cno_desc, cno_homologado, cno_candidatos,
#         cno_gran_grupo, homologacion_estado

# Revisar cobertura antes de comparar series
table(epe_2019$homologacion_estado)

# A nivel de gran grupo la cobertura es mayor
epen_2024 <- cno(descargar(year = 2024), agregar = "1d")
# epe_2019$cno_gran_grupo es comparable con epen_2024$cno_cod
```

La tabla completa de pares esta en `equivalencia_co95`. No la unas
directamente a los microdatos: un codigo CO-95 con varios destinos
replicaria personas y pesos.

### Deteccion del clasificador

[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
decide el clasificador con el argumento `clasificador`, la encuesta
declarada en `source` (EPE o EPEN) o los anos de **todas** las filas
(`year`, `anio`, `ANIO` o `AÑO`). Una base que mezcla anos anteriores y
posteriores a 2022, o ambas encuestas, produce un error: procesa cada
parte por separado y une despues.

### Exposicion a IA y cobertura en EPE y EPEN

[`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)
usa `cno_homologado` en las filas EPE y `cno_cod` en las EPEN, y rechaza
codigos CO-95 o agregados.
[`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md)
resume por encuesta y ano cuantas observaciones y cuanta poblacion
tienen score, y por que falta en el resto:

``` r

epe  <- cno(epe_2019, homologar = TRUE) |> ia_exposicion()
epen <- cno(descargar(year = 2024)) |> ia_exposicion()
cobertura(dplyr::bind_rows(epe, epen))
# estado: con_score, sin_score, sin_homologacion, sin_codigo
```

## Indice de exposicion a inteligencia artificial

[empleR](https://valentinalinares.github.io/empleR/) incluye un indice
de exposicion a IA generativa construido con Claude Sonnet 4.6
(Anthropic) para las ocupaciones del CNO 2015.

``` r

# Agregar score de IA a los microdatos
epen_ia <- descargar(year = 2024) |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)

# Ver distribucion del score
summary(epen_ia$ia_score_mean)

# Exposicion media por departamento en mapa (promedio ponderado por peso)
ia_dep <- do.call(rbind, lapply(split(epen_ia, epen_ia$region_code), function(d) {
  ok <- !is.na(d$ia_score_mean)
  data.frame(
    region_code   = d$region_code[1],
    ia_score_mean = stats::weighted.mean(d$ia_score_mean[ok], d$weight[ok])
  )
}))
ia_dep$departamento <- shapes_departamentos$departamento[ia_dep$region_code]
mapa(ia_dep, var = "ia_score_mean",
     titulo = "Exposicion a IA generativa por departamento, 2024")
```

## Datos de ejemplo

El paquete incluye `muestra_epen_2024`, una submuestra de 2.000 filas
para practicar sin necesidad de descargar datos:

``` r

# Ver estructura de la muestra
str(muestra_epen_2024)
#> tibble [2,000 × 34] (S3: tbl_df/tbl/data.frame)
#>  $ source                    : chr [1:2000] "EPEN" "EPEN" "EPEN" "EPEN" ...
#>  $ survey_variant            : chr [1:2000] "departamentos_anual" "departamentos_anual" "departamentos_anual" "departamentos_anual" ...
#>  $ period_label              : chr [1:2000] "Anual - (Ene-Dic)" "Anual - (Ene-Dic)" "Anual - (Ene-Dic)" "Anual - (Ene-Dic)" ...
#>  $ year                      : num [1:2000] 2024 2024 2024 2024 2024 ...
#>  $ month                     : num [1:2000] 4 4 7 5 3 11 9 4 5 7 ...
#>  $ region_code               : num [1:2000] 18 15 14 9 16 3 11 23 15 22 ...
#>  $ ubigeo                    : chr [1:2000] NA NA NA NA ...
#>  $ domain_code               : chr [1:2000] NA NA NA NA ...
#>  $ sample_id                 : chr [1:2000] "7" "1" "2" "1" ...
#>  $ strata_code               : int [1:2000] 3 6 1 8 8 3 2 7 1 2 ...
#>  $ cluster_id                : chr [1:2000] "43905" "16838" "03583" "33332" ...
#>  $ dwelling_id               : chr [1:2000] "0096" "0045" "0089" "0083" ...
#>  $ household_id              : chr [1:2000] "1" "1" "1" "1" ...
#>  $ person_id                 : int [1:2000] 1 1 3 2 1 1 1 1 1 1 ...
#>  $ relationship_code         : int [1:2000] 1 1 9 2 1 1 1 1 1 1 ...
#>  $ sex_code                  : num [1:2000] 2 1 2 2 1 1 2 1 1 1 ...
#>  $ sex                       : chr [1:2000] "Mujer" "Hombre" "Mujer" "Mujer" ...
#>  $ age                       : num [1:2000] 38 60 67 66 61 32 50 36 50 29 ...
#>  $ labor_status_code         : num [1:2000] 1 1 1 1 1 1 1 1 1 1 ...
#>  $ occupation_code_raw       : num [1:2000] 5212 6114 9111 9211 6114 ...
#>  $ occupation_code_4d        : chr [1:2000] "5212" "6114" "9111" "9211" ...
#>  $ occupational_category_code: int [1:2000] 2 2 6 4 2 2 3 3 3 3 ...
#>  $ firm_size_code            : int [1:2000] 1 1 1 1 1 1 5 1 2 4 ...
#>  $ hours_week                : num [1:2000] 62 49 48 45 53 20 36 18 40 17 ...
#>  $ income_periodicity_code   : int [1:2000] NA NA 2 NA NA NA 4 2 4 2 ...
#>  $ labor_income_raw          : num [1:2000] 1771 422 1689 0 504 ...
#>  $ labor_income_monthly      : num [1:2000] 1771 422 1689 0 104 ...
#>  $ weight                    : num [1:2000] 9.04 66.05 21.6 46.5 114.65 ...
#>  $ is_rural                  : num [1:2000] 0 1 0 1 1 0 0 1 0 0 ...
#>  $ is_urban                  : num [1:2000] 1 0 1 0 0 1 1 0 1 1 ...
#>  $ labor_income_work_weighted: num [1:2000] 1771 422 1723 0 504 ...
#>  $ education_code            : num [1:2000] 9 5 3 1 3 8 11 6 9 11 ...
#>  $ institutional_sector_code : num [1:2000] NA NA NA NA NA NA 2 5 5 5 ...
#>  $ area_raw                  : num [1:2000] 1 2 1 2 2 1 1 2 1 1 ...

# Aplicar cno() directamente
muestra_con_cno <- cno(muestra_epen_2024)
#> ℹ Clasificador segun la encuesta de la base: CNO_2015
head(muestra_con_cno[, c("cno_cod", "cno_desc", "clasificador")])
#> # A tibble: 6 × 3
#>   cno_cod cno_desc                                                  clasificador
#>   <chr>   <chr>                                                     <chr>       
#> 1 5212    Vendedores minoristas en tiendas y establecimientos (exc… CNO_2015    
#> 2 6114    Agricultores y trabajadores calificados de cultivos mixt… CNO_2015    
#> 3 9111    Limpiadores y asistentes domésticos                       CNO_2015    
#> 4 9211    Peones de explotaciones agrícolas y ganaderas             CNO_2015    
#> 5 6114    Agricultores y trabajadores calificados de cultivos mixt… CNO_2015    
#> 6 7231    Mecánicos y reparadores de vehículos de motor             CNO_2015
```
