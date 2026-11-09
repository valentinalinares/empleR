test_that("mapa() produce un ggplot departamental", {
  datos <- data.frame(
    departamento = shapes_departamentos$departamento,
    indicador = seq_len(nrow(shapes_departamentos))
  )

  resultado <- suppressMessages(
    mapa(datos, var = "indicador", tipo = "ggplot")
  )

  expect_s3_class(resultado, "ggplot")
})

test_that("mapa() exige la variable y una llave geografica", {
  expect_error(mapa(data.frame(departamento = "LIMA"), "valor"), "no existe")
  expect_error(
    mapa(data.frame(valor = 1), "valor", tipo = "ggplot"),
    "No se encontro columna"
  )
})
