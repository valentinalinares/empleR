#' Muestra sintética con estructura EPEN 2024 (solo ocupados)
#'
#' Dataset completamente sintético de 2.000 filas con la estructura de la EPEN
#' 2024 (variante departamentos_anual) para uso en ejemplos y pruebas. Ninguna
#' fila corresponde a una persona, vivienda u hogar real.
#'
#' @format Un `data.frame` con 2.000 filas y 36 columnas. Variables principales:
#'   \describe{
#'     \item{year, month}{Año y mes de referencia.}
#'     \item{region_code}{Código CCDD de la EPEN. El código 15 incluye los dos
#'       ámbitos de Lima y Callao.}
#'     \item{division_lima}{División geográfica cuando `region_code = 15`:
#'       1 = Lima Metropolitana y Provincia Constitucional del Callao;
#'       2 = Región Lima. En los otros departamentos es `NA`.}
#'     \item{sample_id}{Identificador de muestra (`MUESTRA`, character).}
#'     \item{strata_code}{Estrato (`ESTRATO`, 1-8).}
#'     \item{cluster_id, dwelling_id, household_id}{Conglomerado, vivienda y
#'       hogar (character, con ceros a la izquierda). La UPM
#'       es `sample_id` + `region_code` + `cluster_id`.}
#'     \item{person_id, relationship_code}{Número de orden de la persona
#'       (`C201`) y parentesco (`C203`).}
#'     \item{occupational_category_code, firm_size_code,
#'       income_periodicity_code}{Categoría ocupacional (`C310`), tamaño de
#'       empresa (`C317`) y periodicidad del pago (`C338`, solo dependientes).}
#'     \item{labor_status_code}{Estado laboral: **siempre 1 (Ocupado)** en este conjunto de datos.}
#'     \item{occupation_code_4d}{Código CNO 2015 de 4 dígitos (character).}
#'     \item{labor_income_monthly}{Ingreso laboral mensual en soles.}
#'     \item{hours_week}{Horas trabajadas en la ocupación principal
#'       (`C318_T`).}
#'     \item{hours_week_total}{Horas trabajadas en todas las ocupaciones
#'       durante la semana (`whoraT`).}
#'     \item{weight}{Factor de expansión (peso muestral).}
#'     \item{sex_code, age, education_code}{Variables sociodemográficas.}
#'   }
#'
#' @details
#' Los registros se generaron para representar únicamente personas ocupadas
#' (`labor_status_code = 1`) y practicar con códigos ocupacionales e índices
#' de exposición a IA.
#'
#' Esto significa que **no es posible calcular tasas de desempleo o actividad**
#' directamente desde esta muestra. Para esos indicadores usa:
#' - [resumen_nacional()]: tasas ya calculadas con las bases completas.
#' - [descargar()]: microdatos crudos del INEI con todos los estados laborales.
#'
#' Algunas filas tienen `weight = NA` para probar el tratamiento explícito de
#' pesos faltantes. `ubigeo` y `domain_code` se conservan vacíos para reproducir
#' el esquema disponible del módulo 76.
#'
#' La muestra se genera con `data-raw/07_muestra_epen_2024.R`, semilla
#' `20261114` y reglas declaradas. No se remuestrean microdatos del INEI. Los
#' códigos ocupacionales se limitan a códigos CNO válidos presentes en el
#' índice incluido en el paquete.
#'
#' @source Datos sintéticos generados por `empleR`. El esquema y los nombres de
#'   variables se basan en la documentación pública de la Encuesta Permanente
#'   de Empleo Nacional 2024 del INEI.
"muestra_epen_2024"


#' Clasificador Nacional de Ocupaciones 2015 (CNO 2015)
#'
#' Diccionario completo del CNO 2015, el clasificador ocupacional peruano
#' de 4 dígitos vigente desde 2022 en la EPEN. Basado en CIUO-08.
#'
#' @format Un `data.frame` con 666 filas (todos los niveles) y columnas:
#'   \describe{
#'     \item{codigo}{Código CNO de 1 a 4 dígitos según el nivel (character).}
#'     \item{descripcion}{Nombre del grupo.}
#'     \item{nivel}{Nivel jerárquico: 1 (gran grupo) a 4 (grupo primario;
#'       473 códigos).}
#'     \item{descripcion_extendida}{Descripción del grupo según el INEI.}
#'     \item{tasks, tasks_clean}{Tareas del grupo primario (texto original y
#'       limpio).}
#'   }
#'
#' @details El grupo primario 5321 ("Trabajadores en el cuidado de personas
#'   en instituciones", p. 242) se agregó con
#'   `data-raw/04_corregir_cno_2015.R`: faltaba porque su título quedó pegado
#'   al subgrupo 532. Sus cuatro tareas se transcribieron de esa página
#'   (`data-raw/cno_2015_tareas_5321.txt`); su descripción extendida sigue en
#'   `NA`. 5321 no tiene puntaje en [indice_ia].
#'
#' @source INEI - Clasificador Nacional de Ocupaciones 2015.
"cno_2015"


#' Tabla de equivalencias CIUO-2008 <-> CNO 2015
#'
#' Tabla de correspondencias entre los códigos CIUO-2008 y el Clasificador
#' Nacional de Ocupaciones 2015 (CNO 2015, 4 dígitos). Publicada por el INEI
#' para facilitar la homologación de series temporales entre clasificadores.
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{cod_ciuo_2008}{Código CIUO-2008 (4 dígitos).}
#'     \item{desc_ciuo_2008}{Descripción del grupo primario CIUO-2008.}
#'     \item{cod_cno_2015}{Código CNO 2015 equivalente (4 dígitos).}
#'     \item{desc_cno_2015}{Descripción del grupo primario CNO 2015.}
#'     \item{enlace_ciuo_cno}{Tipo de enlace de CIUO hacia CNO.}
#'     \item{enlace_cno_ciuo}{Tipo de enlace de CNO hacia CIUO.}
#'   }
#'
#' @source INEI - Tabla de equivalencias CIUO-2008 / CNO 2015.
"equivalencia_cno"


#' Índice de exposición a inteligencia artificial por ocupación
#'
#' Puntaje de exposición a IA generativa para cada ocupación del CNO 2015,
#' desarrollado por Walter Omar Manky Bonilla, con la asistencia de
#' investigación de Valentina Linares Herrera, usando Claude Sonnet 4.6
#' (Anthropic) mediante tres corridas independientes y consolidación por
#' consenso.
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{code}{Código CNO 2015 de 4 dígitos (character).}
#'     \item{occupation_group}{Nombre de la ocupación.}
#'     \item{mean_exposure_score}{Puntaje medio de exposición en una escala de 0 a 1.}
#'     \item{median_exposure_score}{Puntaje mediano de exposición (0 a 1).}
#'     \item{std_score}{Desviación estándar del puntaje entre tareas.}
#'     \item{total_tasks}{Número total de tareas evaluadas.}
#'     \item{tipo_A_aumento}{Número de tareas tipo A (aumento/augmentation).}
#'     \item{tipo_S_sustitucion}{Número de tareas tipo S (sustitución).}
#'     \item{tipo_N_nulo}{Número de tareas tipo N (impacto nulo).}
#'   }
#'
#' @details
#' El archivo fuente final recomendado es
#' `02_exposure_index_por_ocupacion.xlsx`. El puntaje principal por ocupación es
#' `mean_exposure_score`; `median_exposure_score` y `std_score` se conservan
#' para análisis de sensibilidad y heterogeneidad. Según el memo metodológico
#' de la corrida Sonnet de abril de 2026, cuyo paquete metodológico fue
#' versionado el 15 de junio de 2026:
#' - Correlación con índice OIT: r = 0.85.
#' - Correlación con índice anterior: r = 0.45.
#'
#' @source Manky Bonilla, W. O. (2026). Índice de exposición a inteligencia
#'   artificial generativa para ocupaciones peruanas: corrida Claude Sonnet
#'   4.6. Con asistencia de investigación de V. Linares Herrera. Material de
#'   trabajo no publicado.
#'
#'   Antecedente metodológico: Manky, W. O. (2025). Doble desafío tecnológico:
#'   análisis de la exposición a la automatización tradicional y a la
#'   inteligencia artificial generativa en el empleo peruano, utilizando datos
#'   de la ENAHO 2024. Instituto Nacional de Estadística e Informática.
"indice_ia"


#' Catálogo de fuentes de datos disponibles
#'
#' Inventario de las encuestas, años, variantes y periodos procesados por el
#' proyecto. Incluye EPEN (departamentos y Lima móvil) y ENAHO anual.
#' La descarga automática con [descargar()] está disponible solo para EPEN.
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{fuente}{Nombre de la encuesta: EPEN o ENAHO.}
#'     \item{variante}{Variante: departamentos_anual, lima_movil, anual.}
#'     \item{year}{Año de referencia.}
#'     \item{periodo}{Descripción del periodo.}
#'     \item{filas}{Número de filas en la base.}
#'     \item{codigos_ocup}{Número de códigos ocupacionales distintos.}
#'   }
#'
#' @source INEI / elaboración propia.
"catalogo_fuentes"


#' Catálogo de URLs de descarga EPEN (INEI)
#'
#' URLs reales para descargar los microdatos de la EPEN desde el servidor del
#' INEI. Extraídas del paquete Python `inei_microdatos`. Usadas internamente
#' por [descargar()].
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{source}{Nombre de la encuesta: EPEN.}
#'     \item{survey_variant}{Variante: `departamentos_anual`, `lima_movil`.}
#'     \item{year}{Año de referencia (integer).}
#'     \item{period_label}{Etiqueta del periodo (e.g. "Anual", "Trimestre Móvil...").}
#'     \item{survey_code}{Código de encuesta INEI (entero).}
#'     \item{url}{URL de descarga del ZIP con los módulos CSV.}
#'   }
#'
#' @source INEI - Sistema de Recuperación de Información de Encuestas (SRIIE).
"url_catalog_epen"


#' Indicadores nacionales precalculados del mercado laboral (EPEN/ENAHO)
#'
#' Tasas e indicadores laborales calculados en el proyecto a partir de las
#' bases completas del INEI. La actividad y el empleo se expresan sobre la
#' población en edad de trabajar (PET); el desempleo, sobre la población
#' económicamente activa (PEA). Se consultan con [resumen_nacional()].
#'
#' @format Un `data.frame` con columnas principales:
#'   \describe{
#'     \item{source}{Fuente: EPEN o ENAHO.}
#'     \item{survey_variant}{Variante de la encuesta.}
#'     \item{year}{Año de referencia.}
#'     \item{period_label}{Etiqueta del periodo.}
#'     \item{activity_rate_pet}{Tasa de actividad sobre la PET (0-1).}
#'     \item{employment_rate_pet}{Tasa de empleo sobre la PET (0-1).}
#'     \item{unemployment_rate_pea}{Tasa de desempleo sobre la PEA (0-1).}
#'     \item{income_monthly_weighted_mean}{Ingreso mensual promedio ponderado (soles).}
#'     \item{hours_week_weighted_mean}{Horas semanales promedio ponderadas.}
#'   }
#'
#' @seealso [resumen_nacional()]
#' @source Elaboración del proyecto a partir de microdatos del INEI.
"indicadores_epen"


#' Polígonos departamentales del Perú (sf)
#'
#' Polígonos a nivel departamento (25 unidades) precalculados desde el conjunto de datos
#' `geoperu::peru` usando el motor GEOS (sin s2). [mapa()] los combina con
#' [shapes_provincias] para representar los ámbitos departamentales de la EPEN.
#' Incluyen la Provincia Constitucional del Callao como unidad separada
#' (código UBIGEO `07`).
#'
#' @format Un objeto `sf` con 25 filas y columnas:
#'   \describe{
#'     \item{departamento}{Nombre del departamento en mayúsculas (e.g. `"LIMA"`).}
#'     \item{geometry}{Polígono en CRS EPSG:4326.}
#'   }
#'
#' @source \pkg{geoperu} (CRAN) / INEI.
"shapes_departamentos"


#' Polígonos provinciales del Perú (sf)
#'
#' Polígonos a nivel provincia (196 unidades) precalculados desde el conjunto de datos
#' `geoperu::peru` usando el motor GEOS (sin s2). [mapa()] los usa internamente
#' para construir los dos ámbitos oficiales del código 15: Lima Metropolitana
#' y Callao, y Región Lima. Si los unes a tus propios datos, usa departamento y
#' provincia juntos como clave.
#'
#' @format Un objeto `sf` con 196 filas y columnas:
#'   \describe{
#'     \item{departamento}{Nombre del departamento en mayúsculas.}
#'     \item{provincia}{Nombre de la provincia en mayúsculas.}
#'     \item{geometry}{Polígono en CRS EPSG:4326.}
#'   }
#'
#' @source \pkg{geoperu} (CRAN) / INEI.
"shapes_provincias"


#' Catálogo CO-95 con su equivalencia al CNO 2015
#'
#' Una fila por código del Código de Ocupaciones 1995 (CO-95), usado por la
#' EPE hasta 2021, con sus equivalentes en el CNO 2015. Es el diccionario que
#' usa [cno()] con `homologar = TRUE`.
#'
#' Construido con el anexo 1 (hoja `CNO2015_CO95`) de las tablas de
#' correspondencia del INEI, invertido. `cno2015_unico` solo se completa
#' cuando hay un único destino, sin discrepancias entre los anexos 1 y 2, y el
#' código no es 999 (ocupación no especificada).
#'
#' @format Un `data.frame` con 370 filas y 7 columnas:
#'   \describe{
#'     \item{co95}{Código CO-95 de 3 dígitos (character).}
#'     \item{nombre_co95}{Descripción de la ocupación CO-95.}
#'     \item{n_cno2015}{Número de códigos CNO 2015 equivalentes.}
#'     \item{cno2015_candidatos}{Códigos CNO 2015 equivalentes, separados por `"; "`.}
#'     \item{cno2015_unico}{Código CNO 2015 si la equivalencia es única; `NA` si no.}
#'     \item{estado}{`"unica"` (236), `"multiples_destinos"` (125),
#'       `"discrepancia_fuente"` (8) u `"ocupacion_no_especificada"` (1).}
#'     \item{gran_grupo_cno}{Gran grupo CNO 2015 (1 dígito) si todos los
#'       candidatos lo comparten.}
#'   }
#' @source INEI, Tablas de correspondencia CNO - CIUO - CO
#'   (\url{https://www.inei.gob.pe/media/Tablas_de_correspondencia_CNO_CIUO_CO.xlsx})
#'   y Clasificador Nacional de Ocupaciones 2015, anexos 1 y 2. Ver
#'   `data-raw/03_build_equivalencia_co95.R`.
#' @seealso [equivalencia_co95] para la tabla completa de pares.
"co_1995"


#' Tabla de correspondencia CO-95 -> CNO 2015 (todos los pares)
#'
#' Contiene los 604 pares CO-95 / CNO 2015 del anexo 1 del INEI. Un código
#' CO-95 puede aparecer varias veces. Para añadir correspondencias a los
#' microdatos, usa [co_1995] o [cno()] con `homologar = TRUE`: unir directamente
#' esta tabla duplicaría registros y factores de expansión en los casos con
#' varios destinos.
#'
#' @format Un `data.frame` con 604 filas y columnas:
#'   \describe{
#'     \item{co95, nombre_co95}{Código (3 dígitos) y descripción CO-95.}
#'     \item{cno2015, nombre_cno2015}{Código (4 dígitos) y descripción CNO 2015.}
#'     \item{acuerdo_anexos}{`"si"` si el par aparece en los anexos 1 y 2;
#'       `"solo_anexo1"` si no.}
#'     \item{n_cno_por_co95}{Número de destinos CNO 2015 del código CO-95.}
#'     \item{n_co95_por_cno}{Número de orígenes CO-95 del código CNO 2015.}
#'   }
#' @source Ver [co_1995].
"equivalencia_co95"
