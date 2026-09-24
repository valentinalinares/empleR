test_that("cno() detecta CNO_2015 para anios >= 2022", {
  # Crear datos de prueba minimos con variable de anio
  datos_prueba <- muestra_epen_2024
  resultado <- cno(datos_prueba)
  expect_true("clasificador" %in% names(resultado))
  expect_equal(unique(resultado$clasificador), "CNO_2015")
})

test_that("cno() agrega columnas cno_cod y cno_desc", {
  resultado <- cno(muestra_epen_2024)
  expect_true("cno_cod" %in% names(resultado))
  expect_true("cno_desc" %in% names(resultado))
})

test_that("cno() respeta el nivel de agregacion", {
  resultado <- cno(muestra_epen_2024, agregar = "2d")
  # Con 2 digitos, todos los codigos deben tener 2 caracteres
  codigos_validos <- nchar(resultado$cno_cod) <= 2
  expect_true(all(codigos_validos | is.na(resultado$cno_cod)))
})

test_that("cno() da un error claro para bases CO-95 sin tabla de equivalencias", {
  skip_if(
    "equivalencia_co95" %in% utils::data(package = "empleR")$results[, "Item"],
    "equivalencia_co95 ya esta incluida en el paquete"
  )
  epe <- muestra_epen_2024
  epe$year <- 2019L
  expect_error(suppressMessages(cno(epe)), "CO-95")
})

test_that("cno() rechaza niveles de agregacion invalidos", {
  expect_error(suppressMessages(cno(muestra_epen_2024, agregar = "5d")))
})
