epe_cobertura <- function() {
  unicos <- co_1995[co_1995$estado == "unica" & co_1995$cno2015_unico %in% indice_ia$code, ]
  data.frame(
    year   = 2019L,
    P204A  = c(as.integer(unicos$co95[1:2]), 262L, 999L, NA),
    weight = c(10, 20, 30, 40, 50)
  )
}

test_that("cobertura() separa falta de homologacion, de score y de codigo", {
  epe <- suppressWarnings(suppressMessages(
    ia_exposicion(cno(epe_cobertura(), homologar = TRUE))
  ))
  r <- suppressMessages(cobertura(epe))

  expect_equal(unique(r$encuesta), "EPE")
  expect_equal(sum(r$n), 5L)
  expect_equal(sum(r$poblacion), 150)
  expect_equal(sum(r$pct_n), 100)
  expect_equal(sum(r$pct_poblacion), 100)

  con <- r[r$estado == "con_score", ]
  expect_equal(con$n, 2L)
  expect_equal(con$poblacion, 30)
  expect_equal(con$pct_poblacion, 20)

  sin_hom <- r[r$estado == "sin_homologacion", ]
  expect_setequal(sin_hom$detalle, c("multiples_destinos", "ocupacion_no_especificada"))
  expect_equal(r$poblacion[r$estado == "sin_codigo"], 50)
})

test_that("cobertura() resume por encuesta y ano una base EPE + EPEN", {
  epe <- suppressWarnings(suppressMessages(
    ia_exposicion(cno(epe_cobertura(), homologar = TRUE))
  ))
  epen <- suppressWarnings(suppressMessages(ia_exposicion(cno(muestra_epen_2024))))
  epen$source <- NULL
  unida <- dplyr::bind_rows(epe, epen)
  r <- suppressWarnings(suppressMessages(cobertura(unida)))

  expect_setequal(unique(paste(r$encuesta, r$year)), c("EPE 2019", "EPEN 2024"))
  por_grupo <- as.numeric(tapply(r$pct_n, paste(r$encuesta, r$year), sum))
  expect_equal(por_grupo, c(100, 100), tolerance = 1e-3)
  expect_false("sin_homologacion" %in% r$estado[r$encuesta == "EPEN"])
})

test_that("cobertura() exige ia_exposicion() previo", {
  expect_error(cobertura(muestra_epen_2024), "ia_cobertura")
})

test_that("cobertura() conserva nombres de variables con enie (AÑO)", {
  base <- epe_cobertura()
  names(base)[1] <- "AÑO"
  epe <- suppressWarnings(suppressMessages(ia_exposicion(cno(base, homologar = TRUE))))
  r <- suppressMessages(cobertura(epe))
  expect_true("AÑO" %in% names(r))
  expect_equal(sum(r$n), 5L)
})
