# Changelog

## empleR 0.1.0

### Cambios de alcance

- Se retiro la funcion experimental `panel()`. Enlazar viviendas u
  hogares entre entregas de la EPEN no permite afirmar que se sigue a la
  misma persona: la clave omitia muestra y region, y no distinguia una
  entrevista repetida en trimestres moviles solapados de una visita
  nueva. La funcion volvera solo despues de validar la unidad de
  seguimiento y sus claves. Su ultima version puede consultarse en el
  historial del repositorio con
  `git show 31dca788fa6685663f516b6ee5a9921eaf65c809:R/panel.R`.
- [`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
  solo admite los 25 ambitos departamentales que publica la EPEN.
  Conserva los 23 departamentos ordinarios y separa el codigo `15`
  mediante `DIVISION_LIMA`: `15-1` es Lima Metropolitana y Callao, y
  `15-2` es Region Lima. No inventa un codigo `07` para Callao ni lo
  deja como un poligono sin dato.
- Para el codigo `15`,
  [`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md)
  exige `DIVISION_LIMA` o `division_lima`. Tambien acepta los nombres
  oficiales sin distinguir mayusculas ni tildes. Rechaza llaves
  contradictorias y ambitos repetidos; avisa de filas sin poligono y de
  ambitos sin dato. Las etiquetas interactivas muestran `sin dato` en
  lugar de `NA` y conservan tasas pequenas.
- `nivel = "provincia"` y `nivel = "distrito"` producen un error: las
  bases procesadas no tienen una llave territorial suficiente para esos
  niveles. `geoperu` deja de ser una dependencia de ejecucion y queda
  solo como dependencia sugerida para reconstruir los datos espaciales;
  `sf` pasa a declararse de forma explicita.

### Homologacion EPE (CO-95) y EPEN (CNO 2015)

- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  homologa CO-95 -\> CNO 2015 con la tabla oficial del INEI (`co_1995`,
  `equivalencia_co95`). Solo asigna un codigo cuando la equivalencia es
  unica; los casos ambiguos quedan en `NA` con `cno_candidatos`,
  `cno_gran_grupo` y `homologacion_estado`.
- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  detecta el clasificador por la encuesta (`source`) o por los anos de
  todas las filas, rechaza bases que mezclan periodos, acepta el
  argumento `clasificador` y reconoce la variable ano con distintos
  nombres y codificaciones (incluido `AÑO`).
- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  usa el codigo original (`C308_COD`, `P204A`, `occupation_code_raw`)
  completado con ceros a la izquierda; si `occupation_code_4d` no
  coincide, marca la fila en `cno_discrepancia_4d`.

### Exposicion a IA y cobertura

- [`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)
  usa `cno_homologado` en las filas EPE y rechaza codigos CO-95 o
  agregados. Agrega `ia_cno` e `ia_cobertura`.
- `ia_tipo` queda en `NA` cuando hay empate (`ia_empate = TRUE`);
  `ia_tipo_estado` distingue predominante, empate, sin tareas y sin
  indice.
- Nueva funcion
  [`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md):
  cobertura de homologacion y score por encuesta y ano, en observaciones
  y poblacion ponderada.
- El flujo se valido con microdatos reales EPE 2021 y EPEN 2024 del
  mismo trimestre movil. Reproduce al redondeo las 24 tasas oficiales de
  actividad y ocupacion seleccionadas. La comparacion agregada del
  indice no se considera validada: solo 34,64 % de la poblacion ocupada
  EPE tuvo una correspondencia CNO unica y los ambitos difieren en un
  distrito del Callao.

### Diseno muestral

- [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  explicita el universo ocupado, convierte de forma controlada los datos
  numericos recibidos como texto y exige elegir `var_peso` cuando
  existen factores para mas de un periodo. La salida informa casos
  usados, faltantes, valores invalidos y poblacion representada.
- El ingreso usa las ocupaciones principal y secundaria con ingresos
  extraordinarios (`ingtrabw`) y excluye valores no positivos, en
  concordancia con el indicador publicado por el INEI. Las horas usan el
  total semanal en todas las ocupaciones (`whoraT`). Los estimadores
  puntuales se validaron con los ZIP oficiales EPEN 2022-2025 y
  reproducen el ingreso oficial dentro del redondeo publicado.
- [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  devuelve por defecto estimaciones puntuales. La inferencia se solicita
  con `incluir_inferencia = TRUE`, agrega `error_std` y queda marcada
  como experimental. Ya no reemplaza silenciosamente un diseno
  incompleto por uno basado solo en pesos: una UPM o un estrato faltante
  produce un error explicativo.
- La UPM combina muestra + region + conglomerado cuando esos
  identificadores estan disponibles. La aproximacion reproduce al
  redondeo publicado 24 CV trimestrales de 2024-2025 y ocho CV anuales
  de ingreso de 2024. No usa correccion por poblacion finita porque
  faltan los totales del marco por etapa.

### Datos

- `muestra_epen_2024` ahora contiene 2.000 registros completamente
  sinteticos: conserva las 36 columnas necesarias para ejemplos y
  pruebas, pero ninguna fila corresponde a una persona, vivienda u hogar
  real. Se genera con semilla fija y reglas declaradas, sin remuestrear
  microdatos del INEI.
- `cno_2015` incluye el grupo primario 5321 con sus tareas oficiales y
  restaura las tareas de 5223.
- Nuevos datasets `co_1995` y `equivalencia_co95`.
- Los once datasets distribuidos tienen generadores coordinados,
  manifiestos, huellas y una validacion de reconstruccion por contenido.

### Otros

- Se agregaron instrucciones de citación, una guía de contribución, un
  código de conducta y plantillas para reportar errores, proponer
  cambios y revisar pull requests.
- `DESCRIPTION` identifica al INEI y su Sistema de Microdatos como
  origen de las encuestas, y deja de declarar un ORCID vacío.
- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
  detecta si el CSV usa `;` o `,` y lee todas las columnas crudas como
  texto para conservar codigos, ceros iniciales y valores mixtos. Los
  caches nuevos registran ano, variante, periodo y URL; los caches
  antiguos sin esos metadatos deben regenerarse.
- Ejemplos y vineta corregidos; alias de variables reales EPE y EPEN
  para la validacion de bases (`data-raw/validar_bases_reales.R`).
- Nuevo sitio de documentacion con guias de funciones y de la transicion
  EPE-EPEN, ejemplos ejecutados e imagenes reproducibles en el README.
- [`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
  reconoce los nombres originales del modulo 76 y los nombres
  procesados. Conserva los codigos y crea columnas `_label` por defecto;
  `reemplazar = TRUE` mantiene el comportamiento anterior. Se
  corrigieron las etiquetas de `C310`, `C311`, `C317` y `C338` contra el
  diccionario oficial, ademas de conservar la codificacion educativa de
  `C366`.

## empleR 0.0.0.9000

- Version inicial.
