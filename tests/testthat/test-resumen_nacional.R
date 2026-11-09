test_that("resumen_nacional() filtra fuente, variante y ano", {
  resultado <- resumen_nacional(
    fuente = "EPEN",
    year = 2024,
    variante = "departamentos_anual"
  )

  expect_gt(nrow(resultado), 0)
  expect_true(all(resultado$source == "EPEN"))
  expect_true(all(resultado$year == 2024))
  expect_true(all(resultado$survey_variant == "departamentos_anual"))
})

test_that("resumen_nacional() avisa cuando no hay resultados", {
  expect_warning(
    resultado <- resumen_nacional("EPEN", year = 1900),
    "No se encontraron"
  )
  expect_equal(nrow(resultado), 0)
})
