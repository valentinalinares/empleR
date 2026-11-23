# Visualizar un indicador por ámbito departamental de la EPEN

Une una tabla con una fila por ámbito departamental de la Encuesta
Permanente de Empleo Nacional (EPEN) a los polígonos incluidos en el
paquete y devuelve un mapa interactivo (`leaflet`) o estático
(`ggplot2`). La función recibe resultados ya agregados; no calcula
indicadores.

## Uso

``` r
mapa(
  data,
  var,
  nivel = "departamento",
  tipo = c("leaflet", "ggplot"),
  titulo = NULL,
  paleta = "YlOrRd",
  shapes = NULL
)
```

## Argumentos

- data:

  `data.frame` con una fila por ámbito departamental EPEN. Para
  resultados de
  [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md),
  usa `por = c("region_code", "division_lima")`.

- var:

  Nombre de la columna numérica que se representara con colores.

- nivel:

  Nivel geográfico. Solo se admite `"departamento"`; los niveles
  `"provincia"` y `"distrito"` producen un error informativo.

- tipo:

  Tipo de visualizacion: `"leaflet"` (por defecto, interactivo) o
  `"ggplot"` (estático).

- titulo:

  Título del mapa y de la leyenda. Si es `NULL`, usa `var`.

- paleta:

  Paleta de colores de `leaflet` o `ggplot2`.

- shapes:

  Objeto `sf` opcional con `geo_id`, `departamento` y una geometría por
  ámbito EPEN. Si es `NULL`, se construyen los polígonos oficiales a
  partir de
  [shapes_departamentos](https://valentinalinares.github.io/empleR/reference/shapes_departamentos.md)
  y
  [shapes_provincias](https://valentinalinares.github.io/empleR/reference/shapes_provincias.md).

## Valor

Un objeto `leaflet` o `ggplot`.

## Detalles

**Ámbitos de la EPEN.** El INEI no publica los resultados de Lima como
un único departamento. Distingue `DIVISION_LIMA = 1`, Lima Metropolitana
y la Provincia Constitucional del Callao, de `DIVISION_LIMA = 2`, Región
Lima (las otras nueve provincias del departamento). Por ello, cuando
`CCDD` o `region_code` vale 15, `mapa()` exige también `DIVISION_LIMA` o
`division_lima` para identificar el ámbito al que corresponde el
resultado.

Los otros 23 departamentos conservan su ámbito habitual. En total, el
mapa contiene 25 ámbitos departamentales EPEN. Los polígonos de los dos
ámbitos de Lima se construyen a partir de los polígonos provinciales
incluidos en el paquete.

**Clave de unión.** La función admite:

1.  `CCDD` o `region_code`, más `DIVISION_LIMA` o `division_lima` para
    el código 15; o

2.  un nombre oficial en `ambito_epen`, `departamento`, `DEPARTAMENTO`,
    `dep` o `region`.

Si hay varias columnas geográficas, todas las que tengan un valor deben
coincidir. Los códigos inválidos y las contradicciones producen un
error. Los nombres no reconocidos se informan y no se dibujan.

**Nivel geográfico.** Esta versión no admite provincias ni distritos. Un
mapa representa los valores que recibe, pero no demuestra
representatividad ni significancia estadística. Revisa el diseño
muestral, el número de observaciones y la precisión antes de comparar
territorios.

## Ejemplos

``` r
ingreso_dep <- indicadores(
  muestra_epen_2024,
  "ingreso_promedio",
  por = c("region_code", "division_lima")
)
#> Warning: 80 filas no participan por peso ausente o invalido.
#> Warning: 48 filas con peso valido no participan por el valor del indicador.
mapa(ingreso_dep, "estimado", tipo = "ggplot")
#> Warning: 23 ambitos sin dato para 'estimado': "AMAZONAS", "ANCASH", "APURIMAC",
#> "AREQUIPA", "AYACUCHO", "CAJAMARCA", "CUSCO", "HUANCAVELICA", "HUANUCO", "ICA",
#> "JUNIN", "LA LIBERTAD", "LAMBAYEQUE", "LORETO", "MADRE DE DIOS", "MOQUEGUA",
#> "PASCO", "PIURA", …, "TUMBES", and "UCAYALI".
```
