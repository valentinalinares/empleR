# empleR 0.1.0

## Homologacion EPE (CO-95) y EPEN (CNO 2015)

* `cno()` homologa CO-95 -> CNO 2015 con la tabla oficial del INEI
  (`co_1995`, `equivalencia_co95`). Solo asigna un codigo cuando la
  equivalencia es unica; los casos ambiguos quedan en `NA` con
  `cno_candidatos`, `cno_gran_grupo` y `homologacion_estado`.
* `cno()` detecta el clasificador por la encuesta (`source`) o por los anos de
  todas las filas, rechaza bases que mezclan periodos, acepta el argumento
  `clasificador` y reconoce la variable ano con distintos nombres y
  codificaciones (incluido `AÑO`).
* `cno()` usa el codigo original (`C308_COD`, `P204A`, `occupation_code_raw`)
  completado con ceros a la izquierda; si `occupation_code_4d` no coincide,
  marca la fila en `cno_discrepancia_4d`.

## Exposicion a IA y cobertura

* `ia_exposicion()` usa `cno_homologado` en las filas EPE y rechaza codigos
  CO-95 o agregados. Agrega `ia_cno` e `ia_cobertura`.
* `ia_tipo` queda en `NA` cuando hay empate (`ia_empate = TRUE`);
  `ia_tipo_estado` distingue predominante, empate, sin tareas y sin indice.
* Nueva funcion `cobertura()`: cobertura de homologacion y score por encuesta
  y ano, en observaciones y poblacion ponderada.

## Diseno muestral

* `indicadores()` forma la UPM con muestra + region + conglomerado cuando la
  base trae `sample_id` y `region_code`. El diseno se documenta como
  provisional hasta contar con la especificacion oficial.

## Datos

* `muestra_epen_2024` se regenera desde la base corregida de
  `ia_empleo_peru` (mismas 2.000 personas): codigos CNO completados a la
  izquierda, `sample_id`, estrato e identificadores reconstruidos.
* `cno_2015` incluye el grupo primario 5321 con sus tareas oficiales y
  restaura las tareas de 5223.
* Nuevos datasets `co_1995` y `equivalencia_co95`.

## Otros

* `descargar()` detecta si el CSV usa `;` o `,` y lee todas las columnas
  crudas como texto para conservar codigos, ceros iniciales y valores mixtos.
  Los caches nuevos registran ano, variante, periodo y URL; los caches antiguos
  sin esos metadatos deben regenerarse.
* Ejemplos y vineta corregidos; alias de variables reales EPE y EPEN para la
  validacion de bases (`data-raw/validar_bases_reales.R`).
* Nuevo sitio de documentacion con guias de funciones y de la transicion
  EPE-EPEN, ejemplos ejecutados e imagenes reproducibles en el README.
* `etiquetar()` reconoce los nombres originales del modulo 76 y los nombres
  procesados. Conserva los codigos y crea columnas `_label` por defecto;
  `reemplazar = TRUE` mantiene el comportamiento anterior. Se corrigieron las
  etiquetas de `C310`, `C311`, `C317` y `C338` contra el diccionario oficial,
  ademas de conservar la codificacion educativa de `C366`.
* `panel()` se documenta como experimental y no se interpreta como un panel de
  personas sin validacion adicional.

# empleR 0.0.0.9000

* Version inicial.
