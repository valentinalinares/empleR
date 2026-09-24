# empleR

`empleR` reune herramientas para trabajar con encuestas laborales peruanas,
ocupaciones y exposicion tecnologica. El paquete permite descargar y leer
microdatos EPEN/EPE, armonizar codigos ocupacionales, calcular indicadores
laborales y cruzar ocupaciones con un indice de exposicion a inteligencia
artificial generativa.

## Instalacion

```r
pak::pak("valentinalinares/empleR")
```

## Flujo basico

```r
library(empleR)

datos <- muestra_epen_2024 |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)

# Ingreso promedio por tipo de impacto de la IA
indicadores(datos, indicador = "ingreso_promedio", por = "ia_tipo")
```

## Que ofrece

- `catalogo()` lista fuentes, anos y variantes disponibles.
- `descargar()` obtiene microdatos de encuestas laborales.
- `etiquetar()` aplica etiquetas legibles a variables codificadas.
- `cno()` armoniza codigos ocupacionales hacia CNO 2015 (CO-95 de la EPE
  via la tabla de correspondencia del INEI, sin forzar casos ambiguos).
- `indicadores()` calcula indicadores laborales con diseno muestral.
- `resumen_nacional()` devuelve indicadores nacionales pre-calculados.
- `ia_exposicion()` agrega scores de exposicion a IA por ocupacion.
- `panel()` y `mapa()` ayudan a explorar resultados y visualizarlos.

## Indice de exposicion IA

El dataset `indice_ia` usa el indice Sonnet 2026-06-15. La unidad base es la
tarea ocupacional; el score final por ocupacion es `mean_exposure_score` en
escala 0-1. Los archivos fuente y validaciones estan documentados en
`data-raw/02_build_indice_ia.R` y `data-raw/indice_exposicion/README.md`.

## Desarrollo

El paquete usa:

- GitHub Actions para `R CMD check`.
- `pkgdown` para publicar documentacion web.
- `lintr` y `styler` como convencion de calidad y formato.

Comandos locales recomendados:

```r
devtools::document()
devtools::test()
devtools::check()
lintr::lint_package()
pkgdown::build_site()
```
