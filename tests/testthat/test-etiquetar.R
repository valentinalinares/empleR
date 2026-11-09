test_that("etiquetar() convierte codigos procesados en etiquetas legibles", {
  datos <- data.frame(
    sex_code = c(1, 2),
    education_code = c(6, 10),
    valor = c(100, 200)
  )

  resultado <- suppressMessages(etiquetar(datos))

  expect_s3_class(resultado$sex_code, "factor")
  expect_equal(as.character(resultado$sex_code), c("Hombre", "Mujer"))
  expect_equal(
    as.character(resultado$education_code),
    c("Secundaria completa", "Sup. universitaria incompleta")
  )
  expect_identical(resultado$valor, datos$valor)
})

test_that("education_code sigue el diccionario C366 de la EPEN", {
  datos <- data.frame(education_code = 1:12)
  resultado <- suppressMessages(etiquetar(datos, as_factor = FALSE))

  expect_equal(resultado$education_code[7], "Basica especial")
  expect_equal(resultado$education_code[11], "Sup. universitaria completa")
  expect_equal(resultado$education_code[12], "Maestria / Doctorado")
})

test_that("etiquetar() permite devolver texto y omite variables desconocidas", {
  datos <- data.frame(sex_code = c(1, 2))

  resultado <- suppressMessages(
    etiquetar(datos, vars = "sex_code", as_factor = FALSE)
  )
  expect_type(resultado$sex_code, "character")

  expect_warning(
    sin_cambio <- etiquetar(datos, vars = "variable_inexistente"),
    "no tiene diccionario"
  )
  expect_identical(sin_cambio, datos)
})
