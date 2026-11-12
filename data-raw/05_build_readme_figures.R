# Figuras reproducibles para el README de empleR.

dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

load("data/indice_ia.rda")
load("data/muestra_epen_2024.rda")
pkgload::load_all(".", quiet = TRUE)

fig_ia <- ggplot2::ggplot(
  indice_ia[!is.na(indice_ia$mean_exposure_score), ],
  ggplot2::aes(x = mean_exposure_score)
) +
  ggplot2::geom_histogram(
    binwidth = 0.05,
    boundary = 0,
    color = "white",
    fill = "#2C7FB8"
  ) +
  ggplot2::scale_x_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2)
  ) +
  ggplot2::labs(
    title = "Exposici\u00f3n a IA generativa por ocupaci\u00f3n",
    subtitle = "Puntaje medio entre tareas del CNO 2015",
    x = "Puntaje medio (0 a 1)",
    y = "N\u00famero de ocupaciones",
    caption = paste(
      "\u00cdndice: Walter Omar Manky Bonilla;",
      "asistencia: Valentina Linares Herrera"
    )
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  "man/figures/README-ia-distribucion.png",
  fig_ia,
  width = 8,
  height = 4.8,
  dpi = 144
)

validos <- muestra_epen_2024[
  !is.na(muestra_epen_2024$labor_income_monthly) &
    !is.na(muestra_epen_2024$weight) &
    muestra_epen_2024$weight > 0,
]

llave <- interaction(
  validos$region_code,
  ifelse(is.na(validos$division_lima), 0L, validos$division_lima),
  drop = TRUE
)
ingreso_dep <- do.call(
  rbind,
  lapply(split(validos, llave), function(datos) {
    data.frame(
      region_code = datos$region_code[1],
      division_lima = datos$division_lima[1],
      ingreso = stats::weighted.mean(
        datos$labor_income_monthly,
        datos$weight,
        na.rm = TRUE
      )
    )
  })
)

fig_mapa <- mapa(
  ingreso_dep,
  var = "ingreso",
  tipo = "ggplot",
  titulo = "S/ mensuales"
) +
  ggplot2::labs(
    title = "Ingreso laboral promedio por \u00e1mbito departamental EPEN",
    subtitle = "Ejemplo con la muestra incluida; no es una estimaci\u00f3n oficial",
    caption = "Fuente: muestra_epen_2024 incluida en empleR"
  ) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", color = NA),
    plot.subtitle = ggplot2::element_text(color = "#333333"),
    plot.caption = ggplot2::element_text(color = "#555555")
  )

ggplot2::ggsave(
  "man/figures/README-mapa.png",
  fig_mapa,
  width = 7,
  height = 6.5,
  dpi = 144
)
