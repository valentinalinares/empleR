test_that("etiquetar() conserva codigos procesados y agrega etiquetas", {
  datos <- data.frame(
    sex_code = c(1, 2),
    education_code = c(6, 10),
    valor = c(100, 200)
  )

  resultado <- suppressMessages(etiquetar(datos))

  expect_identical(resultado$sex_code, datos$sex_code)
  expect_identical(resultado$education_code, datos$education_code)
  expect_s3_class(resultado$sex_label, "factor")
  expect_equal(as.character(resultado$sex_label), c("Hombre", "Mujer"))
  expect_equal(
    as.character(resultado$education_label),
    c("Secundaria completa", "Superior universitaria incompleta")
  )
  expect_identical(resultado$valor, datos$valor)
})

test_that("etiquetar() reconoce nombres originales del modulo 76", {
  datos <- data.frame(
    C207 = c("1", "2"),
    OCUP300 = c("1", "4"),
    C366 = c("7", "12"),
    C310 = c("3", "9"),
    C311 = c("1", "5"),
    C317 = c("1", "5"),
    C338 = c("4", "5"),
    AREA = c("1", "2")
  )

  resultado <- suppressMessages(etiquetar(datos, as_factor = FALSE))

  expect_equal(resultado$sex_label, c("Hombre", "Mujer"))
  expect_equal(resultado$labor_status_label, c("Ocupado", "Inactivo pleno"))
  expect_equal(
    resultado$education_label,
    c("B\u00e1sica especial", "Maestr\u00eda / Doctorado")
  )
  expect_equal(resultado$occupational_category_label, c(
    "Empleado u obrero",
    "Ayudante en un negocio de la familia de otro hogar"
  ))
  expect_equal(resultado$institutional_sector_label, c(
    "Fuerzas Armadas, Polic\u00eda Nacional del Per\u00fa (militares)",
    "Empresa o patrono privado"
  ))
  expect_equal(
    resultado$firm_size_label,
    c("Hasta 20 personas", "M\u00e1s de 500 personas")
  )
  expect_equal(
    resultado$income_periodicity_label,
    c("Mensual", "No recibi\u00f3 pago alguno")
  )
  expect_equal(resultado$area_label, c("Urbano", "Rural"))
})

test_that("diccionarios corregidos cubren las codificaciones oficiales", {
  datos <- data.frame(
    occupational_category_code = 1:10,
    institutional_sector_code = rep(1:6, length.out = 10),
    firm_size_code = rep(1:5, length.out = 10),
    income_periodicity_code = rep(1:5, length.out = 10)
  )

  resultado <- suppressMessages(etiquetar(datos, as_factor = FALSE))

  expect_equal(resultado$occupational_category_label[6], "Trabajador del hogar")
  expect_equal(
    resultado$occupational_category_label[10],
    "Ayudante en el empleo de un familiar de otro hogar"
  )
  expect_equal(
    resultado$institutional_sector_label[2],
    "Administraci\u00f3n p\u00fablica"
  )
  expect_equal(resultado$firm_size_label[5], "M\u00e1s de 500 personas")
  expect_equal(
    resultado$income_periodicity_label[5],
    "No recibi\u00f3 pago alguno"
  )
})

test_that("etiquetar() distingue ausentes, codigos desconocidos y variables ausentes", {
  datos <- data.frame(C207 = c("1", "", NA, "99"))

  expect_warning(
    resultado <- etiquetar(datos, as_factor = FALSE),
    "99"
  )
  expect_identical(resultado$C207, datos$C207)
  expect_equal(resultado$sex_label, c("Hombre", NA, NA, NA))

  expect_error(
    etiquetar(datos, vars = "C366"),
    "no existen en los datos"
  )
  expect_warning(
    sin_cambio <- etiquetar(datos, vars = "variable_inexistente"),
    "sin diccionario"
  )
  expect_identical(sin_cambio, datos)
})

test_that("etiquetar() es idempotente y detecta aliases discrepantes", {
  datos <- data.frame(C207 = c("1", "2"), sex_code = c(1, 2))
  una_vez <- suppressMessages(etiquetar(datos))
  dos_veces <- suppressMessages(etiquetar(una_vez))

  expect_identical(dos_veces, una_vez)

  discrepantes <- data.frame(C207 = c("1", "2"), sex_code = c(2, 2))
  expect_error(
    suppressWarnings(etiquetar(discrepantes)),
    "no producen la misma"
  )
})

test_that("reemplazar = TRUE conserva la compatibilidad y admite repeticion", {
  datos <- data.frame(sex_code = c(1, 2), valor = 1:2)
  una_vez <- suppressMessages(etiquetar(datos, reemplazar = TRUE))
  dos_veces <- suppressMessages(etiquetar(una_vez, reemplazar = TRUE))

  expect_s3_class(una_vez$sex_code, "factor")
  expect_equal(as.character(una_vez$sex_code), c("Hombre", "Mujer"))
  expect_equal(as.character(dos_veces$sex_code), c("Hombre", "Mujer"))
  expect_identical(una_vez$valor, datos$valor)
})

test_that("etiquetar() conserva el codigo ocupacional para el flujo con cno()", {
  datos <- data.frame(
    C207 = c("1", "2"),
    C308_COD = c("1111", "212"),
    year = c("2024", "2024")
  )

  etiquetados <- suppressMessages(etiquetar(datos, as_factor = FALSE))
  resultado <- suppressMessages(cno(etiquetados))

  expect_identical(etiquetados$C308_COD, datos$C308_COD)
  expect_equal(resultado$cno_cod, c("1111", "0212"))
  expect_equal(resultado$sex_label, c("Hombre", "Mujer"))
})
