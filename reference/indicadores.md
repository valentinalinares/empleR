# Calcular ingresos y horas de trabajo ponderados

Calcula el ingreso promedio o mediano y las horas semanales promedio de
la población ocupada usando factores de expansión. El error estándar se
solicita con `incluir_inferencia = TRUE` y sigue siendo experimental. Si
la base contiene `OCUP300` o `labor_status_code`, conserva de forma
explícita el código de ocupado. Si no contiene una variable de condición
de actividad, supone que las filas recibidas ya corresponden a personas
ocupadas.

## Usage

``` r
indicadores(
  data,
  indicador,
  por = NULL,
  var_strata = NULL,
  var_psu = NULL,
  var_peso = NULL,
  var_estado = NULL,
  codigo_ocupado = "1",
  var_indicador = NULL,
  incluir_inferencia = FALSE
)
```

## Arguments

- data:

  `data.frame` con microdatos de EPEN (resultado de
  [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)).

- indicador:

  Nombre del indicador a calcular:

  - `"ingreso_promedio"`: ingreso mensual medio proveniente del trabajo,
    sumando ocupaciones principal y secundaria e ingresos
    extraordinarios.

  - `"horas_promedio"`: total medio de horas trabajadas en la semana en
    todas las ocupaciones.

  - `"ingreso_mediano"`: mediana del mismo ingreso mensual.

- por:

  Variable(s) de agrupación: `"sex"`, `"region_code"`,
  `"education_code"`, `"institutional_sector_code"`, etc. `NULL` =
  nacional.

- var_strata:

  Nombre de la variable de estrato. Detecta automáticamente
  `strata_code` (datos procesados) o `ESTRATO` (datos crudos INEI).

- var_psu:

  Nombre de la unidad primaria de muestreo (UPM). Detecta
  automáticamente `cluster_id` (datos procesados) o
  `CONGLOMERADO`/`CONGLOME` (datos crudos INEI). Si se detecta y la base
  trae también la muestra (`sample_id` o `MUESTRA`) y la región
  (`region_code` o `CCDD`), la UPM se forma con las tres: los números de
  conglomerado se repiten entre departamentos y muestras, así que el
  conglomerado solo no identifica una UPM.

- var_peso:

  Nombre del factor de expansión. Si existe un solo candidato, lo
  detecta automáticamente. Si encuentra más de uno (por ejemplo,
  `FAC_T300` y `FAC300_ANUAL`), exige elegirlo de forma explícita.

- var_estado:

  Nombre de la variable de condición de actividad. Detecta
  `labor_status_code` o `OCUP300`. `NULL` permite la detección
  automática.

- codigo_ocupado:

  Código que identifica a las personas ocupadas en `var_estado`. En la
  EPEN es `"1"`.

- var_indicador:

  Nombre de la variable numérica que se desea resumir. Normalmente no
  hace falta indicarla: para ingreso se usan
  `labor_income_work_weighted` o `ingtrabw`, y para horas
  `hours_week_total` o `whoraT`. Sirve para solicitar expresamente otro
  concepto, como el ingreso o las horas de la ocupación principal.

- incluir_inferencia:

  Lógico. Si es `FALSE` (por defecto), devuelve solo la estimación
  puntual y la auditoría. Si es `TRUE`, agrega `error_std` usando la
  aproximación de diseño documentada abajo. La inferencia requiere
  identificadores completos de UPM y, cuando se usa, de estrato.

## Value

Un `data.frame` con el indicador calculado y columnas de auditoría:
`n_universo`, `n_estimacion`, `n_sin_peso`, `n_peso_invalido`,
`n_sin_indicador`, `n_indicador_invalido`, `n_fuera_definicion` y
`poblacion_representada`. Si `incluir_inferencia = TRUE`, agrega
`error_std`. Los conteos de problemas no son mutuamente excluyentes.

## Details

Para consultar tasas de desempleo, actividad y empleo, usa
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md),
que devuelve resultados ya calculados en el proyecto con las bases
completas del INEI.

## Definiciones y tratamiento de faltantes

Los indicadores de ingreso excluyen valores iguales o menores que cero.
Esta regla reproduce el ingreso medio oficial de la EPEN, que resume las
remuneraciones positivas de trabajadores dependientes e independientes.
Las horas incluyen ceros válidos. En todos los indicadores se excluyen
del cálculo los pesos ausentes, no numéricos, no finitos o no positivos,
y los valores del indicador ausentes, no numéricos o no finitos. La
salida informa cuántos casos se excluyeron por cada motivo.

La mediana usa la regla matemática de
[`survey::svyquantile()`](https://rdrr.io/pkg/survey/man/svyquantile.html):
el extremo inferior del intervalo donde la función de distribución
ponderada alcanza 0.5 (`qrule = "math"`).

## Inferencia experimental

Las fichas EPEN describen un diseño probabilístico, estratificado, de
áreas y bietápico, independiente en cada departamento. La UPM
implementada combina muestra, región y conglomerado porque los números
de conglomerado se reutilizan entre departamentos. En la base anual
departamental validada se usa `ESTRATO` (`strata_code`). En la variante
trimestral móvil de Lima validada no se usa un estrato explícito: se
debe indicar `var_strata = NA`.

El coeficiente de variación (CV) relaciona el error estándar con la
estimación; el efecto de diseño (DEFF) compara la varianza con la de un
muestreo aleatorio simple. Esta reconstrucción se contrastó con 24
estimaciones, errores estándar, CV y DEFF oficiales de Lima
Metropolitana para octubre-diciembre de 2024 y 2025, y con ocho
estimaciones y CV de ingreso anual nacional de 2024. Los estimados y CV
se reproducen al redondeo publicado. El contraste respalda el cálculo
como aproximación, pero no demuestra que sea el algoritmo interno del
INEI.

No se aplica corrección por población finita porque los microdatos
públicos no incluyen los totales del marco necesarios para cada etapa.
Si solicitas inferencia y faltan identificadores requeridos de estrato o
UPM, la función se detiene e indica qué información necesitas completar.
Para una variante documentada sin estrato explícito se puede usar
`var_strata = NA`.

## References

INEI. Ficha técnica EPEN 2024.
<https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Ficha_Tecnica.pdf>

INEI. Diccionario EPEN 2024.
<https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Diccionario.pdf>

INEI. Errores muestrales EPEN, octubre-diciembre 2024.
<https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-45/Error_Muestral_por_Trimestre.pdf>

INEI. Perú: Indicadores del Mercado Laboral a nivel departamental,
2022-2024.
<https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib2029/libro.pdf>

## See also

[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md)
para indicadores precalculados (incluyendo tasas de desempleo y
actividad).
[indicadores_epen](https://valentinalinares.github.io/empleR/reference/indicadores_epen.md)
para el conjunto de datos interno con indicadores nacionales
precalculados.

## Examples

``` r
# Ingreso promedio nacional con la muestra interna
indicadores(muestra_epen_2024, "ingreso_promedio")
#> Warning: 80 filas no participan por peso ausente o invalido.
#> Warning: 48 filas con peso valido no participan por el valor del indicador.
#>          indicador estimado n_universo n_estimacion n_sin_peso n_peso_invalido
#> 1 ingreso_promedio 1901.751       2000         1872         80               0
#>   n_sin_indicador n_indicador_invalido n_fuera_definicion
#> 1               0                    0                 51
#>   poblacion_representada
#> 1               98084.87

# Ingreso promedio por sexo
indicadores(muestra_epen_2024, "ingreso_promedio", por = "sex")
#> Warning: 80 filas no participan por peso ausente o invalido.
#> Warning: 48 filas con peso valido no participan por el valor del indicador.
#>      sex        indicador estimado n_universo n_estimacion n_sin_peso
#> 1 Hombre ingreso_promedio 1847.812       1000          933         40
#> 2  Mujer ingreso_promedio 1954.854       1000          939         40
#>   n_peso_invalido n_sin_indicador n_indicador_invalido n_fuera_definicion
#> 1               0               0                    0                 28
#> 2               0               0                    0                 23
#>   poblacion_representada
#> 1               48658.90
#> 2               49425.97

if (FALSE) { # \dontrun{
epen_2024 <- descargar(year = 2024)

# Ingreso por ámbito departamental EPEN; Lima requiere su división
indicadores(
  epen_2024,
  "ingreso_promedio",
  por = c("CCDD", "DIVISION_LIMA")
)

# Horas trabajadas por sector institucional
indicadores(epen_2024, "horas_promedio", por = "C311")
} # }
```
