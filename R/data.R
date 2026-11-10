#' Muestra de microdatos EPEN 2024 (solo ocupados)
#'
#' Submuestra aleatoria de 2.000 filas de la EPEN 2024
#' (variante departamentos_anual) para uso en ejemplos y pruebas.
#'
#' @format Un `data.frame` con 2.000 filas y 34 columnas. Variables principales:
#'   \describe{
#'     \item{year, month}{Ano y mes de referencia.}
#'     \item{region_code}{Codigo de departamento (1-25).}
#'     \item{sample_id}{Identificador de muestra (`MUESTRA`, character).}
#'     \item{strata_code}{Estrato (`ESTRATO`, 1-8).}
#'     \item{cluster_id, dwelling_id, household_id}{Conglomerado, vivienda y
#'       hogar (character, con los ceros a la izquierda del original). La UPM
#'       es `sample_id` + `region_code` + `cluster_id`.}
#'     \item{person_id, relationship_code}{Numero de orden de la persona
#'       (`C201`) y parentesco (`C203`).}
#'     \item{occupational_category_code, firm_size_code,
#'       income_periodicity_code}{Categoria ocupacional (`C310`), tamano de
#'       empresa (`C317`) y periodicidad del pago (`C338`, solo dependientes).}
#'     \item{labor_status_code}{Estado laboral: **siempre 1 (Ocupado)** en este dataset.}
#'     \item{occupation_code_4d}{Codigo CNO 2015 de 4 digitos (character).}
#'     \item{labor_income_monthly}{Ingreso laboral mensual en soles.}
#'     \item{hours_week}{Horas trabajadas por semana.}
#'     \item{weight}{Factor de expansion (peso muestral).}
#'     \item{sex_code, age, education_code}{Variables sociodemograficas.}
#'   }
#'
#' @details
#' **Importante:** este dataset contiene **unicamente personas ocupadas**
#' (`labor_status_code = 1`). Los desocupados e inactivos fueron excluidos
#' durante el procesamiento del pipeline porque no tienen codigo de ocupacion
#' (CNO) y no pueden cruzarse con el indice de IA.
#'
#' Esto significa que **no es posible calcular tasas de desempleo o actividad**
#' directamente desde esta muestra. Para esos indicadores usa:
#' - [resumen_nacional()]: tasas pre-calculadas sobre la PEA completa.
#' - [descargar()]: microdatos crudos del INEI con todos los estados laborales.
#'
#' 81 filas no tienen factor de expansion (`weight`); se conservan sin
#' imputar. `ubigeo` y `domain_code` estan vacios porque el modulo 76 no trae
#' variables equivalentes.
#'
#' La muestra se regenera con `data-raw/07_muestra_epen_2024.R` desde la base
#' corregida de `ia_empleo_peru` (codigos CNO completados a la izquierda e
#' identificadores reconstruidos desde los ZIP oficiales). Son las mismas 2.000
#' personas que la version anterior.
#'
#' @source INEI - Encuesta Permanente de Empleo Nacional 2024, modulo 76.
#'   Pipeline de procesamiento: Linares Herrera, V. (2025),
#'   \url{https://github.com/valentinalinares/ia_empleo_peru}.
"muestra_epen_2024"


#' Clasificador Nacional de Ocupaciones 2015 (CNO 2015)
#'
#' Diccionario completo del CNO 2015, el clasificador ocupacional peruano
#' de 4 digitos vigente desde 2022 en la EPEN. Basado en CIUO-08.
#'
#' @format Un `data.frame` con 666 filas (todos los niveles) y columnas:
#'   \describe{
#'     \item{codigo}{Codigo CNO de 1 a 4 digitos segun el nivel (character).}
#'     \item{descripcion}{Nombre del grupo.}
#'     \item{nivel}{Nivel jerarquico: 1 (gran grupo) a 4 (grupo primario;
#'       473 codigos).}
#'     \item{descripcion_extendida}{Descripcion del grupo segun el INEI.}
#'     \item{tasks, tasks_clean}{Tareas del grupo primario (texto original y
#'       limpio).}
#'   }
#'
#' @details El grupo primario 5321 ("Trabajadores en el cuidado de personas
#'   en instituciones", p. 242) se agrego con
#'   `data-raw/04_corregir_cno_2015.R`: faltaba porque su titulo quedo pegado
#'   al subgrupo 532. Sus cuatro tareas se transcribieron de esa pagina
#'   (`data-raw/cno_2015_tareas_5321.txt`); su descripcion extendida sigue en
#'   `NA`. 5321 no tiene score en [indice_ia].
#'
#' @source INEI - Clasificador Nacional de Ocupaciones 2015.
"cno_2015"


#' Tabla de equivalencias CIUO-2008 <-> CNO 2015
#'
#' Tabla de correspondencias entre los codigos CIUO-2008 y el Clasificador
#' Nacional de Ocupaciones 2015 (CNO 2015, 4 digitos). Publicada por el INEI
#' para facilitar la homologacion de series temporales entre clasificadores.
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{cod_ciuo_2008}{Codigo CIUO-2008 (4 digitos).}
#'     \item{desc_ciuo_2008}{Descripcion del grupo primario CIUO-2008.}
#'     \item{cod_cno_2015}{Codigo CNO 2015 equivalente (4 digitos).}
#'     \item{desc_cno_2015}{Descripcion del grupo primario CNO 2015.}
#'     \item{enlace_ciuo_cno}{Tipo de enlace de CIUO hacia CNO.}
#'     \item{enlace_cno_ciuo}{Tipo de enlace de CNO hacia CIUO.}
#'   }
#'
#' @source INEI - Tabla de equivalencias CIUO-2008 / CNO 2015.
"equivalencia_cno"


#' Indice de exposicion a inteligencia artificial por ocupacion
#'
#' Score de exposicion a IA generativa para cada ocupacion del CNO 2015,
#' desarrollado por Walter Omar Manky Bonilla, con la asistencia de
#' investigacion de Valentina Linares Herrera, usando Claude Sonnet 4.6
#' (Anthropic) mediante tres corridas independientes y consolidacion por
#' consenso.
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{code}{Codigo CNO 2015 de 4 digitos (character).}
#'     \item{occupation_group}{Nombre de la ocupacion.}
#'     \item{mean_exposure_score}{Score medio de exposicion en escala 0-1 (p.ej. 0.37 equivale al 37 por ciento).}
#'     \item{median_exposure_score}{Score mediano de exposicion (0 a 1).}
#'     \item{std_score}{Desviacion estandar del score entre tareas.}
#'     \item{total_tasks}{Numero total de tareas evaluadas.}
#'     \item{tipo_A_aumento}{Numero de tareas tipo A (aumento/augmentation).}
#'     \item{tipo_S_sustitucion}{Numero de tareas tipo S (sustitucion).}
#'     \item{tipo_N_nulo}{Numero de tareas tipo N (impacto nulo).}
#'   }
#'
#' @details
#' El archivo fuente final recomendado es
#' `02_exposure_index_por_ocupacion.xlsx`. El score sintetico principal es
#' `mean_exposure_score`; `median_exposure_score` y `std_score` se conservan
#' para analisis de sensibilidad y heterogeneidad. Segun el memo metodologico
#' de la corrida Sonnet de abril de 2026, cuyo paquete metodologico fue
#' versionado el 15 de junio de 2026:
#' - Correlacion con indice OIT: r = 0.85.
#' - Correlacion con indice anterior: r = 0.45.
#'
#' @source Manky Bonilla, W. O. (2026). Indice de exposicion a inteligencia
#'   artificial generativa para ocupaciones peruanas: corrida Claude Sonnet
#'   4.6. Con asistencia de investigacion de V. Linares Herrera. Material de
#'   trabajo no publicado.
#'
#'   Antecedente metodologico: Manky, W. O. (2025). Doble desafio tecnologico:
#'   analisis de la exposicion a la automatizacion tradicional y a la
#'   inteligencia artificial generativa en el empleo peruano, utilizando datos
#'   de la ENAHO 2024. Instituto Nacional de Estadistica e Informatica.
"indice_ia"


#' Catalogo de fuentes de datos disponibles
#'
#' Inventario de todas las encuestas, anos, variantes y periodos disponibles
#' para descargar con [descargar()]. Incluye EPEN (departamentos y Lima movil)
#' y ENAHO anual.
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{fuente}{Nombre de la encuesta: EPEN o ENAHO.}
#'     \item{variante}{Variante: departamentos_anual, lima_movil, anual.}
#'     \item{year}{Ano de referencia.}
#'     \item{periodo}{Descripcion del periodo.}
#'     \item{filas}{Numero de filas en la base.}
#'     \item{codigos_ocup}{Numero de codigos ocupacionales distintos.}
#'   }
#'
#' @source INEI / elaboracion propia.
"catalogo_fuentes"


#' Catalogo de URLs de descarga EPEN (INEI)
#'
#' URLs reales para descargar los microdatos de la EPEN desde el servidor del
#' INEI. Extraidas del paquete Python `inei_microdatos`. Usadas internamente
#' por [descargar()].
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{source}{Nombre de la encuesta: EPEN.}
#'     \item{survey_variant}{Variante: `departamentos_anual`, `lima_movil`.}
#'     \item{year}{Ano de referencia (integer).}
#'     \item{period_label}{Etiqueta del periodo (e.g. "Anual", "Trimestre Movil...").}
#'     \item{survey_code}{Codigo de encuesta INEI (entero).}
#'     \item{url}{URL de descarga del ZIP con los modulos CSV.}
#'   }
#'
#' @source INEI - Sistema de Recuperacion de Informacion de Encuestas (SRIIE).
"url_catalog_epen"


#' Indicadores nacionales pre-calculados del mercado laboral (EPEN/ENAHO)
#'
#' Tasas e indicadores laborales ya calculados con la muestra completa de la
#' PEA, incluyendo desocupados e inactivos que no estan en los microdatos
#' procesados de [descargar()]. Devueltos por [resumen_nacional()].
#'
#' @format Un `data.frame` con columnas principales:
#'   \describe{
#'     \item{source}{Fuente: EPEN o ENAHO.}
#'     \item{survey_variant}{Variante de la encuesta.}
#'     \item{year}{Ano de referencia.}
#'     \item{period_label}{Etiqueta del periodo.}
#'     \item{activity_rate_pet}{Tasa de actividad sobre la PET (0-1).}
#'     \item{employment_rate_pet}{Tasa de empleo sobre la PET (0-1).}
#'     \item{unemployment_rate_pea}{Tasa de desempleo sobre la PEA (0-1).}
#'     \item{income_monthly_weighted_mean}{Ingreso mensual promedio ponderado (soles).}
#'     \item{hours_week_weighted_mean}{Horas semanales promedio ponderadas.}
#'   }
#'
#' @seealso [resumen_nacional()]
#' @source INEI / elaboracion propia con pipeline Python.
"indicadores_epen"


#' Poligonos departamentales del Peru (sf)
#'
#' Shapes a nivel departamento (25 unidades) pre-computados desde el dataset
#' `geoperu::peru` usando el motor GEOS (sin s2). Son los poligonos que usa
#' [mapa()] por defecto. Incluyen Callao como departamento propio (codigo
#' UBIGEO `07`).
#'
#' @format Un objeto `sf` con 25 filas y columnas:
#'   \describe{
#'     \item{departamento}{Nombre del departamento en mayusculas (e.g. `"LIMA"`).}
#'     \item{geometry}{Poligono en CRS EPSG:4326.}
#'   }
#'
#' @source \pkg{geoperu} (CRAN) / INEI.
"shapes_departamentos"


#' Poligonos provinciales del Peru (sf)
#'
#' Shapes a nivel provincia (196 unidades) pre-computados desde el dataset
#' `geoperu::peru` usando el motor GEOS (sin s2). [mapa()] no los usa en esta
#' version: las bases de la EPEN no identifican la provincia. Se conservan
#' como referencia; si los unes a tus propios datos, usa departamento y
#' provincia juntos como llave.
#'
#' @format Un objeto `sf` con 196 filas y columnas:
#'   \describe{
#'     \item{departamento}{Nombre del departamento en mayusculas.}
#'     \item{provincia}{Nombre de la provincia en mayusculas.}
#'     \item{geometry}{Poligono en CRS EPSG:4326.}
#'   }
#'
#' @source \pkg{geoperu} (CRAN) / INEI.
"shapes_provincias"


#' Catalogo CO-95 con su equivalencia al CNO 2015
#'
#' Una fila por codigo del Codigo de Ocupaciones 1995 (CO-95), usado por la
#' EPE hasta 2021, con sus equivalentes en el CNO 2015. Es el diccionario que
#' usa [cno()] con `homologar = TRUE`.
#'
#' Construido con el anexo 1 (hoja `CNO2015_CO95`) de las tablas de
#' correspondencia del INEI, invertido. `cno2015_unico` solo se completa
#' cuando hay un unico destino, sin discrepancias entre los anexos 1 y 2, y el
#' codigo no es 999 (ocupacion no especificada).
#'
#' @format Un `data.frame` con 370 filas y 7 columnas:
#'   \describe{
#'     \item{co95}{Codigo CO-95 de 3 digitos (character).}
#'     \item{nombre_co95}{Descripcion de la ocupacion CO-95.}
#'     \item{n_cno2015}{Numero de codigos CNO 2015 equivalentes.}
#'     \item{cno2015_candidatos}{Codigos CNO 2015 equivalentes, separados por `"; "`.}
#'     \item{cno2015_unico}{Codigo CNO 2015 si la equivalencia es unica; `NA` si no.}
#'     \item{estado}{`"unica"` (236), `"multiples_destinos"` (125),
#'       `"discrepancia_fuente"` (8) u `"ocupacion_no_especificada"` (1).}
#'     \item{gran_grupo_cno}{Gran grupo CNO 2015 (1 digito) si todos los
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
#' Los 604 pares CO-95 / CNO 2015 del anexo 1 del INEI. Un codigo CO-95 puede
#' aparecer varias veces: **no unir microdatos directamente con esta tabla**,
#' porque se replicarian personas y factores de expansion. Para eso usar
#' [co_1995] o [cno()] con `homologar = TRUE`.
#'
#' @format Un `data.frame` con 604 filas y columnas:
#'   \describe{
#'     \item{co95, nombre_co95}{Codigo (3 digitos) y descripcion CO-95.}
#'     \item{cno2015, nombre_cno2015}{Codigo (4 digitos) y descripcion CNO 2015.}
#'     \item{acuerdo_anexos}{`"si"` si el par aparece en los anexos 1 y 2;
#'       `"solo_anexo1"` si no.}
#'     \item{n_cno_por_co95}{Numero de destinos CNO 2015 del codigo CO-95.}
#'     \item{n_co95_por_cno}{Numero de origenes CO-95 del codigo CNO 2015.}
#'   }
#' @source Ver [co_1995].
"equivalencia_co95"
