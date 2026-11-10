# Fase 3: delimitar paneles y mapas

Fecha de ejecución: 10 de noviembre de 2026.
Rama: `refactor/alcance-v1`, creada desde `31dca788fa6685663f516b6ee5a9921eaf65c809`
(`main` tras fusionar la fase 2).
Hallazgos: H04 (`panel()`) y H05 (`mapa()`).

## Objetivo

Que ninguna función pública prometa seguir a personas en el tiempo ni asignar
valores a territorios cuando el paquete no puede sustentarlo.

## Decisión sobre `panel()`

Se aplicó la recomendación registrada en la fase 0: posponer la función y
conservar su desarrollo en el historial.

Motivos, según la auditoría:

- la clave predeterminada (`cluster_id`, `dwelling_id`, `household_id`) omitía
  muestra y región;
- no distinguía una entrevista repetida en trimestres móviles solapados de una
  visita nueva;
- enlazar vivienda u hogar no demuestra que se sigue a la misma persona;
- la función no tenía pruebas (cobertura 0 %).

Cambios:

- se eliminaron `R/panel.R`, `man/panel.Rd` y la viñeta `manual-panel.Rmd`;
- `NAMESPACE` se regeneró con roxygen y ya no exporta `panel`;
- se quitaron la sección «Experimental» de la referencia y la tarjeta del
  manual en `_pkgdown.yml` y `funciones.Rmd`;
- `_pkgdown.yml` añade redirecciones de `reference/panel.html` y
  `articles/manual-panel.html` hacia `news/index.html`, para que los enlaces ya
  publicados no terminen en una página inexistente;
- README, NEWS y el demo dejan de presentarla como disponible.

Recuperación: la última versión está en el commit
`31dca788fa6685663f516b6ee5a9921eaf65c809`
(`git show 31dca788fa6685663f516b6ee5a9921eaf65c809:R/panel.R`). NEWS lo indica.

Para volver a incorporarla habría que validar antes la unidad de seguimiento,
la clave completa (incluidas muestra, región y `LLAVE_PANEL` cuando exista),
los faltantes, las repeticiones entre entregas solapadas y las visitas
efectivas, con pruebas.

## Decisión sobre `mapa()`

Se limitó el soporte estable al nivel departamental.

### Evidencia de las bases reales

Se leyeron los cuatro ZIP anuales de la EPEN departamental (los mismos de la
fase 1; sus SHA-256 están en `2026-11-10_fases_0_1.md`) y se buscaron columnas
geográficas (`CCDD`, `CCPP`, `CCDI`, `UBIGEO`, `DEPARTAMENTO`, `PROVINCIA`,
`DISTRITO`, `DOMINIO`, `REGION`).

| Año | ZIP | Filas | Columnas geográficas | Códigos `CCDD` | Sin polígono | Filas asignadas | Sin dato | Polígonos correctos |
| ---: | --- | ---: | --- | ---: | ---: | ---: | --- | ---: |
| 2022 | `790-Modulo76.zip` | 439.523 | `CCDD` | 24 | 0 | 439.523 | Callao | 25/25 |
| 2023 | `874-Modulo76.zip` | 449.202 | `CCDD` | 24 | 0 | 449.202 | Callao | 25/25 |
| 2024 | `935-Modulo76.zip` | 465.598 | `CCDD` | 24 | 0 | 465.598 | Callao | 25/25 |
| 2025 | `1001-Modulo76.zip` | 471.438 | `CCDD` | 24 | 0 | 471.438 | Callao | 25/25 |

Conclusiones:

1. La única variable geográfica es `CCDD`. Las bases no identifican provincia
   ni distrito, así que esos niveles no tienen datos de origen en las encuestas
   soportadas.
2. `CCDD` usa los códigos de departamento del UBIGEO del INEI (`01` Amazonas a
   `25` Ucayali). El código `07` (Callao) no aparece en ningún año. No se
   pudo consultar el diccionario oficial desde este equipo (el sitio del INEI
   rechazó las conexiones), por lo que no se afirma aquí en qué código se
   registran los hogares de Callao. `mapa()` deja Callao sin dato y lo avisa;
   no copia el valor de Lima.
3. `region_code` en las bases procesadas es `CCDD`: el generador de
   `ia_empleo_peru` (`build_epen_persona_departamentos.py`) lo toma de esa
   columna, y `muestra_epen_2024` contiene los códigos 1 a 25 sin el 7.
4. Las entregas de Lima móvil revisadas (2022 y 2026) traen `REGION = 1` para
   todas las filas y no traen `CCDD`. Representan un solo ámbito, no un
   departamento; `mapa()` no las acepta como llave departamental.

Para cada año, el script pasa a `mapa()` el número de observaciones y la suma
del factor de expansión por `CCDD`, y comprueba que el polígono de cada
departamento reciba exactamente el valor de su código, tanto en el objeto
`ggplot` como en las etiquetas del objeto `leaflet`.

### Cambios

- `nivel = "provincia"` y `nivel = "distrito"` producen un error que explica
  por qué no están disponibles. Ya no se carga `geoperu::peru` (1.874
  distritos con nombres repetidos) y `geoperu` sale de `Imports`; `sf` se
  declara de forma explícita porque los polígonos y ambos tipos de salida lo
  necesitan.
- La llave puede ser un código UBIGEO (`CCDD` o `region_code`, con o sin cero
  a la izquierda) o un nombre (`departamento`, `DEPARTAMENTO`, `dep`, `region`)
  sin distinguir mayúsculas ni tildes. Antes había que construir el nombre
  indexando `shapes_departamentos` con `region_code`, un procedimiento correcto
  solo mientras ambos órdenes coincidieran.
- Si la tabla trae código y nombre, ambos deben indicar el mismo departamento.
- Se rechazan departamentos repetidos, por ejemplo un resultado agrupado por
  departamento y sexo.
- Se avisan filas sin polígono (por ejemplo, «Lima Metropolitana» o un código
  inexistente) y departamentos sin dato, con sus nombres.
- Se rechazan entradas sin ninguna correspondencia, una variable no numérica,
  una variable completamente vacía y polígonos propios que no sean `sf` o que
  repitan departamentos.
- Las columnas de `data` no reemplazan el nombre ni la geometría de los
  polígonos.
- Las etiquetas del mapa interactivo muestran `sin dato` en lugar de `NA` y
  usan cuatro cifras significativas; antes redondeaban a un decimal y una tasa
  como 0,0391 aparecía como 0.
- La documentación de la función y el manual explican que un mapa no
  demuestra representatividad estadística territorial ni diferencias
  significativas.
- `shapes_provincias` se conserva y su ayuda aclara que `mapa()` no la usa en
  esta versión. Retirarla o mantenerla es una decisión del inventario de
  datasets de la fase 5.

## Pruebas sintéticas y de integración

`tests/testthat/test-mapa.R` pasó de 2 bloques a 16. Cubre:

- correspondencia entre la tabla UBIGEO interna y los 25 polígonos;
- normalización de nombres con tildes, espacios y vacíos;
- asignación del valor correcto a cada polígono con filas desordenadas;
- unión por `region_code` numérico y por `CCDD` con ceros;
- código y nombre contradictorios;
- departamentos repetidos;
- filas sin polígono, departamentos sin dato y aviso específico de Callao;
- ninguna correspondencia y variable sin valores;
- niveles provincial y distrital;
- `REGION = 1` de Lima móvil;
- polígonos propios inválidos;
- salida `ggplot` (valores en `$data`, título y construcción completa);
- salida `leaflet` (etiqueta y color de cada departamento, gris para Callao y
  título de la leyenda).

Resultados para este commit:

| Comprobación | Resultado |
| --- | --- |
| `devtools::test()` | 96 bloques, 277 expectativas, 0 fallos, 0 omitidas |
| `lintr::lint_package()` | Sin observaciones |
| `data-raw/validar_mapa_epen.R` | 4 años, 100 polígonos comprobados, 0 diferencias |
| `R CMD check --as-cran --no-manual` | 0 errores, 0 warnings, 0 notas |
| `pkgdown::check_pkgdown()` y `build_site()` | Sin problemas; redirecciones de `panel` generadas |

## Comprobación del paquete

Entorno: Windows 11, R 4.5.1, pkgdown 2.2.0 y Pandoc 3.6.3. Se usó la copia de
Pandoc incluida con Quarto mediante `RSTUDIO_PANDOC`, porque no está en el
`PATH` del sistema. La comprobación remota de entrada a CRAN se desactivó con
`_R_CHECK_CRAN_INCOMING_REMOTE_=false`, igual que en las fases anteriores.

La primera ejecución detectó un warning real: caracteres no ASCII en
`R/mapa.R`, dentro de la tabla de tildes usada para normalizar nombres. Se
reemplazaron por escapes `\uXXXX` y la comprobación final terminó con estado
`OK`.

El sitio construido con `pkgdown` muestra el mapa del manual con el aviso
esperado sobre Callao. Las páginas antiguas `reference/panel.html` y
`articles/manual-panel.html` redirigen a `news/index.html`. Quedan dos avisos
anteriores a esta fase: los títulos de dos viñetas no coinciden con su
`VignetteIndexEntry`, que no lleva tildes.

## Reproducción

```sh
Rscript data-raw/validar_mapa_epen.R "ruta/a/inei_data_core/epen_departamentos"
```

El script escribe:

- `2026-11-10_mapa_epen_departamentos.csv`: valor esperado y valor asignado
  por departamento y año;
- `2026-11-10_mapa_epen_departamentos_resumen.csv`: columnas geográficas,
  filas, códigos, avisos y polígonos correctos por año.

Termina con error si algún polígono recibe un valor distinto del de su código
o si alguna fila queda sin asignar.

## Límites

- La validación prueba el cruce, no la calidad de una estimación
  departamental. La precisión y la representatividad por departamento
  pertenecen a la fase 4.
- No se verificó en el diccionario oficial dónde se registra Callao en la EPEN
  departamental.
- La EPE histórica y la variante Lima móvil no tienen un recorrido de mapas
  departamentales.
- Los polígonos provienen de `geoperu`; la revisión de sus condiciones de uso
  corresponde a la fase 5.
