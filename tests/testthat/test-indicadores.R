test_that("indicadores() calcula nacional y por grupo", {
  nacional <- suppressWarnings(indicadores(muestra_epen_2024, "ingreso_promedio"))
  expect_equal(nrow(nacional), 1)
  expect_true(all(c("estimado", "error_std") %in% names(nacional)))

  por_sexo <- suppressWarnings(
    indicadores(muestra_epen_2024, "ingreso_mediano", por = "sex")
  )
  expect_equal(nrow(por_sexo), length(unique(muestra_epen_2024$sex)))
  expect_true(all(por_sexo$estimado > 0))
})

test_that("indicadores() rechaza indicadores no soportados", {
  expect_error(indicadores(muestra_epen_2024, "tasa_desempleo"), "resumen_nacional")
})
