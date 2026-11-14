# Fase 5: reconstrucción y procedencia de datasets

**Fecha:** 14 de noviembre de 2026  
**Rama:** `audit/procedencia-datasets`  
**Alcance:** once objetos distribuidos en `data/`

## Resultado

Los once datasets se reconstruyeron desde una copia limpia sin sobrescribir
los objetos publicados. Todos coincidieron por contenido, dimensiones,
nombres y orden de columnas. En los dos objetos `sf` se compararon además las
geometrías serializadas. `muestra_epen_2024` también coincidió byte por byte;
los otros diez cambiaron únicamente en la serialización `.rda` producida por
el entorno de ejecución.

La corrida verificó diez entradas mediante SHA-256 y fijó el repositorio
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
- La muestra conserva exactamente las mismas 2.000 filas y sus 36 variables.
- Los polígonos reconstruidos tienen las mismas geometrías que los
  distribuidos.

## Qué no demuestra

- No reproduce una nueva corrida del modelo de IA. Reconstruye la tabla final
  fijada; las respuestas originales y todos los intermedios no están
  archivados en el repositorio.
- Igualdad de contenido no implica por sí misma permiso de redistribución.
- No se encontró una licencia explícita del INEI que autorice empaquetar una
  muestra de microdatos reales. El acceso público al portal no basta para
  inferir ese permiso.
- El índice pertenece a Walter Omar Manky Bonilla; debe registrarse su
  autorización o una licencia aplicable antes de una distribución formal.

## Decisiones recomendadas antes del envío

1. Sustituir `muestra_epen_2024` por una muestra sintética estructural para
   ejemplos y pruebas, a menos que se documente un permiso explícito de
   redistribución.
2. Obtener de Omar una autorización breve y escrita o escoger una licencia
   explícita para redistribuir el índice en `empleR`.
3. Archivar, si existen, las respuestas originales y los intermedios de la
   corrida Sonnet en un depósito versionado con acceso y licencia definidos.
   Si no existen, mantener la limitación tal como está documentada.
4. Conservar la atribución y versión de `geoperu`, cuya fuente sí declara
   licencia MIT.

## Evidencia

- `2026-11-14_rebuild_inputs.csv`: diez huellas de entrada verificadas.
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

La reconstrucción técnica y el inventario quedan **cerrados con evidencia**.
Las condiciones de redistribución de la muestra real y del índice quedan
**abiertas como decisiones previas al envío**, no como fallos de los
generadores.
