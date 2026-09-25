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

epe_sintetica <- function() {
  data.frame(
    year  = 2019L,
    P204A = c(262, 11, 999, 123, NA, 4567),
    weight = c(10, 20, 30, 40, 50, 60)
  )
}

test_that("cno() procesa bases CO-95 con descripcion", {
  resultado <- suppressMessages(cno(epe_sintetica()))
  expect_equal(unique(resultado$clasificador), "CO_95")
  expect_equal(resultado$cno_cod, c("262", "011", "999", "123", NA, NA))
  expect_false(is.na(resultado$cno_desc[1]))
})

test_that("homologar = TRUE solo asigna equivalencias unicas y conserva filas", {
  datos <- epe_sintetica()
  resultado <- suppressMessages(cno(datos, homologar = TRUE))

  expect_equal(nrow(resultado), nrow(datos))
  expect_equal(resultado$weight, datos$weight)

  # 262 tiene dos destinos (2412 y 2631): no se asigna automaticamente
  expect_true(is.na(resultado$cno_homologado[1]))
  expect_equal(resultado$cno_candidatos[1], "2412; 2631")
  expect_equal(resultado$homologacion_estado[1], "multiples_destinos")

  # 999 (no especificada) nunca se recodifica
  expect_true(is.na(resultado$cno_homologado[3]))
  expect_equal(resultado$homologacion_estado[3], "ocupacion_no_especificada")

  expect_equal(resultado$homologacion_estado[5:6], c("sin_codigo", "sin_codigo"))
})

test_that("cno_homologado coincide con el unico destino de la tabla larga", {
  unicos <- co_1995[co_1995$estado == "unica", ]
  datos <- data.frame(year = 2019L, P204A = unicos$co95)
  resultado <- suppressMessages(cno(datos, homologar = TRUE))
  esperado <- equivalencia_co95$cno2015[match(unicos$co95, equivalencia_co95$co95)]
  expect_equal(resultado$cno_homologado, esperado)
  expect_true(all(resultado$homologacion_estado == "unica"))
})

test_that("cno() rechaza niveles de agregacion invalidos", {
  expect_error(suppressMessages(cno(muestra_epen_2024, agregar = "5d")))
})
