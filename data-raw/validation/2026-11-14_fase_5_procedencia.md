# Fase 5: reconstrucción y procedencia de datasets

**Fecha:** 14 de noviembre de 2026

**Rama:** `audit/procedencia-datasets`

**Alcance:** once objetos distribuidos en `data/`

## Resultado

Los once datasets se reconstruyeron desde una copia limpia sin sobrescribir
los objetos publicados. Todos coincidieron por contenido, dimensiones,
nombres y orden de columnas. En los dos objetos `sf` se compararon además las
geometrías serializadas. Después de esa comprobación, la muestra real fue
reemplazada por una muestra sintética de igual esquema para eliminar el riesgo
de redistribución de microdatos. La reconstrucción se repitió contra esa
versión final.

La corrida final verificó ocho entradas mediante SHA-256 y fijó el repositorio
`ia_empleo_peru` en el commit
`d7a179f143bb33a6fef23cd0394d8b3053eb89ec`. El coordinador no usa un
`main` cambiante y escribe en una carpeta temporal por defecto.

## Cambios realizados

- Se convirtió `00_preparar_datasets.R` en un generador efectivo de
  `catalogo_fuentes`, `indicadores_epen`, `cno_2015`, `equivalencia_cno` y
  `url_catalog_epen`.
- Se parametrizaron las entradas y salidas externas de los generadores.
- Se preservó el orden de correcciones del CNO: fila 5321 y, después, tareas
  5223/5321.
- Se eliminó del generador de tareas una copia lateral innecesaria hacia
  `inst/extdata`.
- Se añadió `rebuild_all.R` con verificación de commit, entradas, pasos,
  contenido, geometrías, huellas, entorno y semilla.
- Se documentaron los 11 objetos y se añadió un manifiesto legible por
  máquina.
- Se corrigió la documentación de `muestra_epen_2024`: contiene 36 columnas,
  no 35.
- El lector de la equivalencia CNO-CIUO quedó protegido contra diferencias de
  representación de tildes entre locales de Windows; la fuente está fijada
  por su huella antes de aplicar el mapeo posicional.

## Qué demuestra la validación

- Los once objetos actuales pueden recrearse desde las entradas identificadas.
- Las correcciones posteriores no se pierden al reconstruir desde cero.
- `indicadores_epen` y `url_catalog_epen` ya tienen generadores identificados.
- La muestra sintética conserva 2.000 filas, 36 variables, tipos, claves y
  dominios necesarios para ejemplos y pruebas, sin conservar personas reales.
- Los polígonos reconstruidos tienen las mismas geometrías que los
  distribuidos.

## Qué no demuestra

- No reproduce una nueva corrida del modelo de IA. Reconstruye la tabla final
  fijada; las respuestas originales y todos los intermedios no están
  archivados en el repositorio.
- Igualdad de contenido no implica por sí misma permiso de redistribución.
- No se encontró una licencia explícita del INEI para redistribuir microdatos;
  esa incertidumbre se resolvió retirando la muestra real del paquete.
- Walter Omar Manky Bonilla autorizó verbalmente a Valentina a usar el índice.
  Antes del envío formal conviene conservar una confirmación breve por escrito
  y definir la licencia aplicable.

## Decisiones recomendadas antes del envío

1. Obtener de Omar una autorización breve y escrita o escoger una licencia
   explícita para redistribuir el índice en `empleR`.
2. Archivar, si existen, las respuestas originales y los intermedios de la
   corrida Sonnet en un depósito versionado con acceso y licencia definidos.
   Si no existen, mantener la limitación tal como está documentada.
3. Conservar la atribución y versión de `geoperu`, cuya fuente sí declara
   licencia MIT.

## Evidencia

- `2026-11-14_rebuild_inputs.csv`: ocho huellas de entrada verificadas.
- `2026-11-14_rebuild_steps.csv`: siete pasos generados sin fallos.
- `2026-11-14_rebuild_datasets.csv`: once comparaciones de contenido.
- `2026-11-14_rebuild_environment.json`: R, plataforma, paquetes, commit y
  semilla.
- `data-raw/manifests/datasets.json`: procedencia por objeto.

## Comprobaciones del paquete

- Todas las pruebas unitarias pasaron.
- `lintr::lint_package()` no encontró observaciones.
- `R CMD check --no-manual` terminó con estado `OK` en Windows 11 y R 4.5.1.
- Las seis viñetas se reconstruyeron durante el check.
- El sitio `pkgdown` se construyó completo y verificó sus enlaces y metadatos.
- Ningún archivo del repositorio supera 100 MB.

## Estado de cierre

La reconstrucción técnica, el inventario y el retiro de microdatos reales
quedan **cerrados con evidencia**. Solo queda formalizar por escrito el permiso
del índice antes del envío; no es un fallo de los generadores.
