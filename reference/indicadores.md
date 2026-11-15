# Calcular indicadores del mercado laboral con diseno muestral

Calcula indicadores laborales de la poblacion ocupada incorporando el
diseno muestral complejo de la EPEN mediante el paquete survey. Si la
base contiene `OCUP300` o `labor_status_code`, conserva de forma
explicita el codigo de ocupado. Si no contiene una variable de condicion
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

  `data.frame` con microdatos de EPEN (output de
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

  Variable(s) de agrupacion: `"sex"`, `"region_code"`,
  `"education_code"`, `"institutional_sector_code"`, etc. `NULL` =
  nacional.

- var_strata:

  Nombre de la variable de estrato. Detecta automaticamente
  `strata_code` (datos procesados) o `ESTRATO` (datos crudos INEI).

- var_psu:

  Nombre de la variable PSU. Detecta automaticamente `cluster_id` (datos
  procesados) o `CONGLOMERADO`/`CONGLOME` (datos crudos INEI). Si se
  detecta y la base trae tambien la muestra (`sample_id` o `MUESTRA`) y
  la region (`region_code` o `CCDD`), la UPM se forma con las tres: los
  numeros de conglomerado se repiten entre departamentos y muestras, asi
  que el conglomerado solo no identifica una UPM.

- var_peso:

  Nombre del factor de expansion. Si existe un solo candidato, lo
  detecta automaticamente. Si encuentra mas de uno (por ejemplo,
  `FAC_T300` y `FAC300_ANUAL`), exige elegirlo de forma explicita.

- var_estado:

  Nombre de la variable de condicion de actividad. Detecta
  `labor_status_code` o `OCUP300`. `NULL` permite la deteccion
  automatica.

- codigo_ocupado:

  Codigo que identifica a las personas ocupadas en `var_estado`. En la
  EPEN es `"1"`.

- var_indicador:

  Nombre de la variable numerica que se desea resumir. Normalmente no
  hace falta indicarla: para ingreso se usan
  `labor_income_work_weighted` o `ingtrabw`, y para horas
  `hours_week_total` o `whoraT`. Sirve para solicitar expresamente otro
  concepto, como el ingreso o las horas de la ocupacion principal.

- incluir_inferencia:

  Logico. Si es `FALSE` (por defecto), devuelve solo la estimacion
  puntual y la auditoria. Si es `TRUE`, agrega `error_std` usando la
  aproximacion de diseno documentada abajo. La inferencia requiere
  identificadores completos de UPM y, cuando se usa, de estrato.

## Value

Un `data.frame` con el indicador calculado y columnas de auditoria:
`n_universo`, `n_estimacion`, `n_sin_peso`, `n_peso_invalido`,
`n_sin_indicador`, `n_indicador_invalido`, `n_fuera_definicion` y
`poblacion_representada`. Si `incluir_inferencia = TRUE`, agrega
`error_std`. Los conteos de problemas no son mutuamente excluyentes.

## Details

Para obtener tasas de desempleo, actividad y empleo a nivel nacional o
regional, usa
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md),
que devuelve los indicadores pre-calculados del pipeline INEI con la
muestra completa de la PEA.

## Definiciones y tratamiento de faltantes

Los indicadores de ingreso excluyen valores iguales o menores que cero.
Esta regla reproduce el ingreso medio oficial de la EPEN, que resume las
remuneraciones positivas de trabajadores dependientes e independientes.
Las horas incluyen ceros validos. En todos los indicadores se excluyen
del calculo los pesos ausentes, no numericos, no finitos o no positivos,
y los valores del indicador ausentes, no numericos o no finitos. La
salida informa cuantos casos se excluyeron por cada motivo.

La mediana usa la regla matematica de
[`survey::svyquantile()`](https://rdrr.io/pkg/survey/man/svyquantile.html):
el extremo inferior del intervalo donde la funcion de distribucion
ponderada alcanza 0.5 (`qrule = "math"`).

## Inferencia experimental

Las fichas EPEN describen un diseno probabilistico, estratificado, de
areas y bietapico, independiente en cada departamento. La UPM
implementada combina muestra, region y conglomerado porque los numeros
de conglomerado se reutilizan entre departamentos. En la base anual
departamental validada se usa `ESTRATO` (`strata_code`). En la variante
trimestral movil de Lima validada no se usa un estrato explicito: se
debe indicar `var_strata = NA`.

Esta reconstruccion se contrasto con 24 estimaciones, errores estandar,
CV y DEFF oficiales de Lima Metropolitana para octubre-diciembre de 2024
y 2025, y con ocho estimaciones y CV de ingreso anual nacional de 2024.
Los estimados y CV se reproducen al redondeo publicado. El contraste
respalda el calculo como aproximacion, pero no demuestra que sea el
algoritmo interno del INEI.

No se aplica correccion por poblacion finita porque los microdatos
publicos no incluyen los totales del marco necesarios para cada etapa.
Tampoco se inventan estratos ni UPM faltantes: si se solicita inferencia
y esos identificadores estan incompletos, la funcion se detiene. Para
una variante documentada sin estrato explicito se puede usar
`var_strata = NA`.

## References

INEI. Ficha tecnica EPEN 2024.
<https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Ficha_Tecnica.pdf>

INEI. Diccionario EPEN 2024.
<https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Diccionario.pdf>

INEI. Errores muestrales EPEN, octubre-diciembre 2024.
<https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-45/Error_Muestral_por_Trimestre.pdf>

INEI. Peru: Indicadores del Mercado Laboral a nivel departamental,
2022-2024.
<https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib2029/libro.pdf>

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

# Ingreso por ambito departamental EPEN; Lima requiere su division
indicadores(
  epen_2024,
  "ingreso_promedio",
  por = c("region_code", "division_lima")
)

# Horas trabajadas por sector institucional
indicadores(epen_2024, "horas_promedio", por = "institutional_sector_code")
} # }
```
