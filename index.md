# empleR

`empleR` reune herramientas para trabajar con encuestas laborales
peruanas, ocupaciones y exposicion tecnologica. El paquete permite
descargar y leer microdatos EPEN/EPE, armonizar codigos ocupacionales,
calcular indicadores laborales y cruzar ocupaciones con un indice de
exposicion a inteligencia artificial generativa.

## Instalacion

``` r

pak::pak("valentinalinares/empleR")
```

## Flujo basico

``` r

library(empleR)

datos <- muestra_epen_2024 |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)

indicadores(datos, indicador = "ingreso_promedio", por = "departamento")
```

## Que ofrece

- [`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md)
  lista fuentes, anos y variantes disponibles.
- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
  obtiene microdatos de encuestas laborales.
- [`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
  aplica etiquetas legibles a variables codificadas.
- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  armoniza codigos ocupacionales hacia CNO 2015.
- [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  calcula indicadores laborales con diseno muestral.
- [`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md)
  devuelve indicadores nacionales pre-calculados.
- [`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)
  agrega scores de exposicion a IA por ocupacion.
- [`panel()`](https://valentinalinares.github.io/empleR/reference/panel.md)
  y
  [`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
  ayudan a explorar resultados y visualizarlos.

## Indice de exposicion IA

El dataset `indice_ia` usa el indice Sonnet 2026-06-15. La unidad base
es la tarea ocupacional; el score final por ocupacion es
`mean_exposure_score` en escala 0-1. Los archivos fuente y validaciones
estan documentados en `data-raw/02_build_indice_ia.R` y
`data-raw/indice_exposicion/README.md`.

## Desarrollo

El paquete usa:

- GitHub Actions para `R CMD check`.
- `pkgdown` para publicar documentacion web.
- `lintr` y `styler` como convencion de calidad y formato.

Comandos locales recomendados:

``` r

devtools::document()
devtools::test()
devtools::check()
lintr::lint_package()
pkgdown::build_site()
```
