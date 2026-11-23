# Registro de cambios

## empleR 0.1.0

### Documentación

- Se revisó la redacción del README, el manual y las ayudas para
  explicar con el mismo criterio el alcance de las funciones, las
  correspondencias ocupacionales y la inferencia experimental. Se
  aclararon los denominadores de las tasas y el origen sintético de los
  datos de ejemplo.
- La introducción ahora ejecuta los ejemplos que usan datos incluidos en
  el paquete. El mapa de exposición utiliza la muestra sintética y
  considera solo registros con puntaje y factor de expansión válidos.

### Cambios de alcance

- Se retiró la función experimental `panel()`. Enlazar viviendas u
  hogares entre entregas de la EPEN no permite afirmar que se sigue a la
  misma persona: la clave omitía muestra y región, y no distinguía una
  entrevista repetida en trimestres móviles solapados de una visita
  nueva. La función volverá solo después de validar la unidad de
  seguimiento y sus claves. Su última versión puede consultarse en el
  historial del repositorio con
  `git show 31dca788fa6685663f516b6ee5a9921eaf65c809:R/panel.R`.
- [`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
  solo admite los 25 ámbitos departamentales que publica la EPEN.
  Conserva los 23 departamentos ordinarios y separa el código `15`
  mediante `DIVISION_LIMA`: `15-1` es Lima Metropolitana y Callao, y
  `15-2` es Región Lima. No inventa un código `07` para Callao ni lo
  deja como un polígono sin dato.
- Para el código `15`,
  [`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
  exige `DIVISION_LIMA` o `division_lima`. También acepta los nombres
  oficiales sin distinguir mayúsculas ni tildes. Rechaza claves
  contradictorias y ámbitos repetidos; avisa de filas sin polígono y de
  ámbitos sin dato. Las etiquetas interactivas muestran `sin dato` en
  lugar de `NA` y conservan tasas pequeñas.
- `nivel = "provincia"` y `nivel = "distrito"` producen un error: las
  bases procesadas no tienen una clave territorial suficiente para esos
  niveles. `geoperu` deja de ser una dependencia de ejecución y queda
  solo como dependencia sugerida para reconstruir los datos espaciales;
  `sf` pasa a declararse de forma explícita.

### Homologación EPE (CO-95) y EPEN (CNO 2015)

- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  homologa CO-95 -\> CNO 2015 con la tabla oficial del INEI (`co_1995`,
  `equivalencia_co95`). Solo asigna un código cuando la equivalencia es
  única; los casos ambiguos quedan en `NA` con `cno_candidatos`,
  `cno_gran_grupo` y `homologacion_estado`.
- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  detecta el clasificador por la encuesta (`source`) o por los años de
  todas las filas, rechaza bases que mezclan periodos, acepta el
  argumento `clasificador` y reconoce la variable año con distintos
  nombres y codificaciones (incluido `AÑO`).
- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  usa el código original (`C308_COD`, `P204A`, `occupation_code_raw`)
  completado con ceros a la izquierda; si `occupation_code_4d` no
  coincide, marca la fila en `cno_discrepancia_4d`.

### Exposición a IA y cobertura

- [`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)
  usa `cno_homologado` en las filas EPE y rechaza códigos CO-95 o
  agregados. Agrega `ia_cno` e `ia_cobertura`.
- `ia_tipo` queda en `NA` cuando hay empate (`ia_empate = TRUE`);
  `ia_tipo_estado` distingue predominante, empate, sin tareas y sin
  índice.
- Nueva función
  [`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md):
  cobertura de homologación y puntaje por encuesta y año, en
  observaciones y población ponderada.
- El flujo se válido con microdatos reales EPE 2021 y EPEN 2024 del
  mismo trimestre móvil. Reproduce al redondeo las 24 tasas oficiales de
  actividad y ocupación seleccionadas. La comparacion agregada del
  índice no se considera validada: solo 34,64 % de la población ocupada
  EPE tuvo una correspondencia CNO única y los ámbitos difieren en un
  distrito del Callao.

### Diseño muestral

- [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  explícita el universo ocupado, convierte de forma controlada los datos
  numéricos recibidos como texto y exige elegir `var_peso` cuando
  existen factores para más de un periodo. La salida informa casos
  usados, faltantes, valores inválidos y población representada.
- El ingreso usa las ocupaciones principal y secundaria con ingresos
  extraordinarios (`ingtrabw`) y excluye valores no positivos, en
  concordancia con el indicador publicado por el INEI. Las horas usan el
  total semanal en todas las ocupaciones (`whoraT`). Los estimadores
  puntuales se validaron con los ZIP oficiales EPEN 2022-2025 y
  reproducen el ingreso oficial dentro del redondeo publicado.
- [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  devuelve por defecto estimaciones puntuales. La inferencia se solicita
  con `incluir_inferencia = TRUE`, agrega `error_std` y queda marcada
  como experimental. Ya no reemplaza silenciosamente un diseño
  incompleto por uno basado solo en pesos: una UPM o un estrato faltante
  produce un error explicativo.
- La UPM combina muestra + región + conglomerado cuando esos
  identificadores están disponibles. La aproximación reproduce al
  redondeo publicado 24 CV trimestrales de 2024-2025 y ocho CV anuales
  de ingreso de 2024. No usa corrección por población finita porque
  faltan los totales del marco por etapa.

### Datos

- `muestra_epen_2024` ahora contiene 2.000 registros completamente
  sintéticos: conserva las 36 columnas necesarias para ejemplos y
  pruebas, pero ninguna fila corresponde a una persona, vivienda u hogar
  real. Se genera con semilla fija y reglas declaradas, sin remuestrear
  microdatos del INEI.
- `cno_2015` incluye el grupo primario 5321 con sus tareas oficiales y
  restaura las tareas de 5223.
- Nuevos conjuntos de datos `co_1995` y `equivalencia_co95`.
- Los once conjuntos de datos distribuidos tienen generadores
  coordinados, manifiestos, huellas y una validación de reconstrucción
  por contenido.

### Otros

- Se agregaron instrucciones de citación, una guía de contribución, un
  código de conducta y plantillas para reportar errores, proponer
  cambios y revisar pull requests.
- `DESCRIPTION` identifica al INEI y su Sistema de Microdatos como
  origen de las encuestas, y deja de declarar un ORCID vacío.
- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
  detecta si el CSV usa `;` o `,` y lee todas las columnas crudas como
  texto para conservar códigos, ceros iniciales y valores mixtos. Los
  archivos de caché nuevos registran año, variante, periodo y URL; los
  archivos de caché antiguos sin esos metadatos deben regenerarse.
- Ejemplos y viñeta corregidos; alias de variables reales EPE y EPEN
  para la validación de bases (`data-raw/validar_bases_reales.R`).
- Nuevo sitio de documentación con guías de funciones y de la transicion
  EPE-EPEN, ejemplos ejecutados e imágenes reproducibles en el README.
- [`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
  reconoce los nombres originales del módulo 76 y los nombres
  procesados. Conserva los códigos y crea columnas `_label` por defecto;
  `reemplazar = TRUE` mantiene el comportamiento anterior. Se
  corrigieron las etiquetas de `C310`, `C311`, `C317` y `C338` contra el
  diccionario oficial, ademas de conservar la codificación educativa de
  `C366`.

## empleR 0.0.0.9000

- Version inicial.
