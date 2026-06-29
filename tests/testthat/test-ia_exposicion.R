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
