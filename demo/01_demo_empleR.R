# ============================================================
# Demo completo del paquete {empleR}
# Corre cada bloque con Ctrl+Enter (línea a línea)
# o todo junto con Ctrl+Shift+S (Source)
# ============================================================

library(empleR)


# ---- 1. CATALOGO: qué datos están disponibles ---------------

# Ver todas las fuentes disponibles
catalogo()

# Solo EPEN
catalogo(fuente = "EPEN")

# Solo un año
catalogo(fuente = "EPEN", year = 2024)


# ---- 2. DATOS DE MUESTRA (incluidos en el paquete) ----------

# 2,000 filas de la EPEN 2024, sin necesidad de descargar nada
muestra_epen_2024

# Ver todas las variables disponibles
names(muestra_epen_2024)

# IMPORTANTE: esta muestra contiene SOLO OCUPADOS (labor_status_code = 1)
# porque viene de un pipeline pre-procesado que filtró por código CNO.
# No es posible calcular tasas de desempleo desde aquí.
table(muestra_epen_2024$labor_status_code)  # siempre 1 = Ocupado

# Para tasas de desempleo/actividad usar:
resumen_nacional("EPEN", variante = "departamentos_anual")

# Para microdatos con todos los estados laborales (ocupados + desocupados + inactivos):
# epen_raw <- descargar(year = 2024)
# table(epen_raw$OCA500)  # ahí sí verás los 4 estados


# ---- 3. CNO: clasificador ocupacional -----------------------

# Detecta automáticamente CNO 2015 (para datos >= 2022)
dat <- cno(muestra_epen_2024)

# Qué clasificador detectó y descripción de la ocupación
dat[, c("occupation_code_4d", "clasificador", "cno_cod", "cno_desc")]

# Frecuencia de ocupaciones más comunes
sort(table(dat$cno_desc), decreasing = TRUE) |> head(10)


# ---- 4. ETIQUETAR: convertir códigos a etiquetas ------------

# Etiqueta todas las variables codificadas de una sola vez
dat_lab <- etiquetar(muestra_epen_2024)

# Ahora las variables tienen etiquetas legibles
table(dat_lab$sex_code)
table(dat_lab$labor_status_code)
table(dat_lab$education_code)
table(dat_lab$institutional_sector_code)


# ---- 5. INDICADORES: estadísticas con diseño muestral ------

# Ingreso promedio nacional (ponderado)
indicadores(muestra_epen_2024, "ingreso_promedio")

# Ingreso promedio por sexo
indicadores(muestra_epen_2024, "ingreso_promedio", por = "sex_code")

# Horas semanales por sector institucional
indicadores(muestra_epen_2024, "horas_promedio",
            por = "institutional_sector_code")

# Ingreso mediano nacional
indicadores(muestra_epen_2024, "ingreso_mediano")


# ---- 6. RESUMEN NACIONAL: tasas pre-calculadas --------------

# Tasas de desempleo, actividad y empleo (EPEN anual 2022-2025)
resumen_nacional("EPEN", variante = "departamentos_anual")

# Solo 2024
resumen_nacional("EPEN", year = 2024, variante = "departamentos_anual")


# ---- 7. INDICE IA: exposición a inteligencia artificial -----

# Cruzar datos con el índice de IA (requiere haber corrido cno() antes)
dat_ia <- dat |> ia_exposicion()

# Score promedio nacional (escala 0-1)
mean(dat_ia$ia_score_mean, na.rm = TRUE)

# Las 10 ocupaciones con MAYOR exposición a IA
dat_ia |>
  dplyr::select(cno_cod, cno_desc, ia_score_mean) |>
  dplyr::distinct() |>
  dplyr::arrange(dplyr::desc(ia_score_mean)) |>
  head(10)

# Las 10 ocupaciones con MENOR exposición a IA
dat_ia |>
  dplyr::select(cno_cod, cno_desc, ia_score_mean) |>
  dplyr::distinct() |>
  dplyr::arrange(ia_score_mean) |>
  head(10)

# Score IA promedio por sexo
dat_ia |>
  dplyr::group_by(sex_code) |>
  dplyr::summarise(
    ia_score = mean(ia_score_mean, na.rm = TRUE),
    n = dplyr::n()
  )

# También puedes pedir los tipos de impacto (A=aumento, S=sustitución, N=nulo)
dat_ia2 <- dat |> ia_exposicion(incluir_tipo = TRUE)
names(dat_ia2)  # ahora incluye tipo_A_aumento, tipo_S_sustitucion, tipo_N_nulo


# ---- 8. PANEL: seguimiento de viviendas en el tiempo --------

# Simular dos trimestres (en la práctica usar descargar() con lima_movil)
t1 <- muestra_epen_2024[1:500, ]
t2 <- muestra_epen_2024[300:800, ]

panel_df <- panel(
  list(t1, t2),
  labels_trimestre = c("T1-2024", "T2-2024")
)

# Tasa de apareamiento (% de viviendas seguidas entre trimestres)
attr(panel_df, "tasa_apareamiento")

# Viviendas en ambos trimestres
head(panel_df[, c("cluster_id", "dwelling_id", "trimestre", "labor_status_code")])


# ---- 9. MAPA: visualización regional ------------------------

library(dplyr)

# Preparar datos: score IA promedio por departamento
scores_dep <- dat_ia |>
  group_by(region_code) |>
  summarise(ia_score_mean = mean(ia_score_mean, na.rm = TRUE),
            .groups = "drop") |>
  filter(!is.na(ia_score_mean)) |>
  mutate(departamento = sort(shapes_departamentos$departamento)[region_code])

# Mapa estático (ggplot2) — se ve en el panel Plots de Positron
mapa(scores_dep,
     var    = "ia_score_mean",
     nivel  = "departamento",
     tipo   = "ggplot",
     titulo = "Exposición a IA por departamento (EPEN 2024)")

# Mapa interactivo (leaflet) — se ve en el panel Viewer de Positron
mapa(scores_dep,
     var    = "ia_score_mean",
     nivel  = "departamento",
     tipo   = "leaflet",
     titulo = "Exposición a IA por departamento (EPEN 2024)")
