test_that("catalogo() devuelve un data.frame", {
  resultado <- catalogo()
  expect_s3_class(resultado, "data.frame")
  expect_true(nrow(resultado) > 0)
})

test_that("catalogo() filtra por fuente correctamente", {
  solo_epen <- catalogo(fuente = "EPEN")
  expect_true(all(solo_epen$fuente == "EPEN"))
})

test_that("catalogo() filtra por year correctamente", {
  solo_2024 <- catalogo(year = 2024)
  expect_true(all(solo_2024$year == 2024))
})

test_that("catalogo() avisa cuando no hay resultados", {
  expect_warning(catalogo(year = 1990))
})
