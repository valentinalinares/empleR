#' Muestra de microdatos EPEN 2024 (solo ocupados)
#'
#' Submuestra aleatoria de 2.000 filas de la EPEN 2024
#' (variante departamentos_anual) para uso en ejemplos y pruebas.
#'
#' @format Un `data.frame` con 2.000 filas y 33 columnas. Variables principales:
#'   \describe{
#'     \item{year, month}{Ano y mes de referencia.}
#'     \item{region_code}{Codigo de departamento (1-25).}
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
#' @source INEI - Encuesta Permanente de Empleo Nacional 2024.
#'   Pipeline de procesamiento: Linares Herrera, V. (2025).
"muestra_epen_2024"


#' Clasificador Nacional de Ocupaciones 2015 (CNO 2015)
#'
#' Diccionario completo del CNO 2015, el clasificador ocupacional peruano
#' de 4 digitos vigente desde 2022 en la EPEN. Basado en CIUO-08.
#'
#' @format Un `data.frame` con columnas:
#'   \describe{
#'     \item{codigo}{Codigo CNO de 4 digitos (character).}
#'     \item{descripcion}{Descripcion de la ocupacion.}
#'     \item{grupo_primario}{Descripcion del grupo primario (4 digitos).}
#'     \item{subgrupo}{Descripcion del subgrupo (3 digitos).}
#'     \item{subgrupo_principal}{Descripcion del subgrupo principal (2 digitos).}
#'     \item{gran_grupo}{Descripcion del gran grupo (1 digito).}
#'   }
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
#' construido con Claude Sonnet 4.6 (Anthropic) mediante tres corridas
#' independientes y consolidacion por consenso.
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
#' del indice Sonnet 2026-06-15:
#' - Correlacion con indice OIT: r = 0.85.
#' - Correlacion con indice anterior: r = 0.45.
#'
#' @source Linares Herrera, V. (2025). Indice de exposicion a IA generativa
#'   para ocupaciones peruanas. Claude Sonnet 4.6, Anthropic.
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
#' `geoperu::peru` usando el motor GEOS (sin s2). Usados internamente por
#' [mapa()] cuando `nivel = "departamento"`.
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
#' `geoperu::peru` usando el motor GEOS (sin s2). Usados internamente por
#' [mapa()] cuando `nivel = "provincia"`.
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
