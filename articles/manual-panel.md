# Explorar hogares repetidos con panel()

``` r

library(empleR)
```

[`panel()`](https://valentinalinares.github.io/empleR/reference/panel.md)
se mantiene como una función experimental. Su propósito es reconocer
viviendas u hogares que comparten identificadores entre varios periodos.
Esto permite auditar la estructura de panel de la encuesta, pero no
demuestra que una persona sea la misma en todas las visitas.

## Para qué sirve

La función recibe dos o más bases y busca las claves de vivienda u hogar
que aparecen en todos los periodos. Después reúne las filas en formato
largo y añade una etiqueta de periodo.

## Qué recibe

| Argumento              | Uso                                                |
|------------------------|----------------------------------------------------|
| `data_lista`           | Lista de bases ordenadas en el tiempo.             |
| `vars_id`              | Columnas que forman la clave de vivienda u hogar.  |
| `incluir_no_apareados` | Conserva todas las viviendas o solo las repetidas. |
| `labels_trimestre`     | Nombres que identificarán cada periodo.            |

En datos procesados, la clave predeterminada usa `cluster_id`,
`dwelling_id` y `household_id`. En archivos originales del INEI, los
nombres pueden ser `CONGLOME`, `VIVIENDA` y `HOGAR`.

## Qué hace por dentro

1.  Comprueba que todas las bases contengan las columnas de
    identificación.
2.  Construye una clave combinada dentro de cada periodo.
3.  Identifica las claves presentes en todos los periodos.
4.  Calcula una tasa de apareamiento.
5.  Une las bases y añade la columna `trimestre`.

## Ejemplo reproducible

``` r

t1 <- data.frame(
  cluster_id = c("001", "001", "002"),
  dwelling_id = c("01", "01", "03"),
  household_id = c("1", "1", "1"),
  person_id = c("01", "02", "01"),
  labor_status = c("Ocupado", "Inactivo", "Ocupado")
)

t2 <- data.frame(
  cluster_id = c("001", "001", "004"),
  dwelling_id = c("01", "01", "02"),
  household_id = c("1", "1", "1"),
  person_id = c("01", "03", "01"),
  labor_status = c("Ocupado", "Ocupado", "Inactivo")
)

hogares_repetidos <- panel(
  list(t1, t2),
  labels_trimestre = c("Periodo 1", "Periodo 2")
)
#> ℹ Trimestres: 2
#> ℹ Viviendas unicas: 3
#> ✔ Viviendas apareadas en todos los trimestres: 1 (33.3%)

hogares_repetidos
#>   cluster_id dwelling_id household_id person_id labor_status trimestre
#> 1        001          01            1        01      Ocupado Periodo 1
#> 2        001          01            1        02     Inactivo Periodo 1
#> 3        001          01            1        01      Ocupado Periodo 2
#> 4        001          01            1        03      Ocupado Periodo 2
attr(hogares_repetidos, "tasa_apareamiento")
#> [1] 33.3
```

El hogar `001|01|1` aparece en ambos periodos y por eso se conserva. Sin
embargo, el segundo integrante cambia de `person_id = "02"` a `"03"`. La
coincidencia del hogar no autoriza a interpretar ambas filas como una
trayectoria individual.

## Qué devuelve

El resultado conserva las filas de los periodos seleccionados y añade
`trimestre`. También guarda como atributos la tasa de apareamiento, el
número de viviendas apareadas y las variables utilizadas para formar la
clave.

Si `incluir_no_apareados = TRUE`, la salida incluye todas las viviendas
y la tasa sigue describiendo cuántas estuvieron presentes en todos los
periodos.

## Precauciones

- Comprueba si `sample_id` y `region_code` deben formar parte de la
  clave en la entrega que utilizas.
- Conserva los identificadores como texto para no perder ceros a la
  izquierda.
- Revisa si el diseño sigue viviendas, hogares o personas.
- No construyas transiciones individuales únicamente con el número de
  orden de la persona.

Por estas razones,
[`panel()`](https://valentinalinares.github.io/empleR/reference/panel.md)
no forma parte del flujo estable recomendado. La función sirve para
explorar y auditar identificadores mientras se documenta la estructura
longitudinal de las entregas.
