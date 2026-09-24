test_that("ia_exposicion() agrega columna ia_score_mean", {
  datos <- cno(muestra_epen_2024)
  resultado <- suppressWarnings(ia_exposicion(datos))
  expect_true("ia_score_mean" %in% names(resultado))
})

test_that("ia_exposicion() falla si no existe var_cno", {
  expect_error(
    ia_exposicion(muestra_epen_2024, var_cno = "columna_inexistente"),
    "no existe en los datos"
  )
})

test_that("ia_score_mean esta entre 0 y 1", {
  datos <- cno(muestra_epen_2024)
  resultado <- suppressWarnings(ia_exposicion(datos))
  scores <- resultado$ia_score_mean[!is.na(resultado$ia_score_mean)]
  expect_true(all(scores >= 0 & scores <= 1))
})

test_that("ia_exposicion(incluir_tipo = TRUE) agrega ia_tipo", {
  datos <- suppressMessages(cno(muestra_epen_2024))
  resultado <- suppressWarnings(ia_exposicion(datos, incluir_tipo = TRUE))
  expect_true("ia_tipo" %in% names(resultado))
  expect_true(all(resultado$ia_tipo %in% c("A", "S", "N", NA)))
  expect_equal(is.na(resultado$ia_tipo), is.na(resultado$tipo_A_aumento))
})

test_that(".tipo_predominante() elige el tipo con mas tareas", {
  expect_equal(
    .tipo_predominante(c(5, 1, 2, NA), c(1, 4, 2, 1), c(0, 0, 3, 1)),
    c("A", "S", "N", NA)
  )
  # Empate: S antes que A
  expect_equal(.tipo_predominante(2, 2, 0), "S")
})

test_that("ia_exposicion(score = 'median') agrega solo la mediana", {
  datos <- suppressMessages(cno(muestra_epen_2024))
  resultado <- suppressWarnings(ia_exposicion(datos, score = "median"))
  expect_true("ia_score_median" %in% names(resultado))
  expect_false("ia_score_mean" %in% names(resultado))
})

test_that("ia_exposicion() rechaza valores invalidos de score", {
  datos <- suppressMessages(cno(muestra_epen_2024))
  expect_error(ia_exposicion(datos, score = "promedio"))
})
