test_that("alias EPE: pano, p204a, fa_def, ocu200, p108, ESTRATO, CONGLOMERADO", {
  epe <- data.frame(
    pano = 2019L, p204a = 262L, fa_def19 = 10, ocu200 = 1, p108 = 40,
    ESTRATO = 1L, CONGLOMERADO = 5L
  )
  v <- .detectar_variables(epe, "EPE")
  expect_equal(
    v,
    c(year = "pano", ocupacion = "p204a", peso = "fa_def19", estrato = "ESTRATO",
      upm = "CONGLOMERADO", condicion = "ocu200", edad = "p108")
  )
})

test_that("alias EPEN: ANIO, C308_COD, FAC300_ANUAL, OCUP300, C208, ESTRATO, CONGLOMERADO", {
  epen <- data.frame(
    ANIO = 2024L, C308_COD = "5212", FAC300_ANUAL = 100, OCUP300 = 1, C208 = 35,
    ESTRATO = 2L, CONGLOMERADO = 9L
  )
  v <- .detectar_variables(epen, "EPEN")
  expect_equal(
    v,
    c(year = "ANIO", ocupacion = "C308_COD", peso = "FAC300_ANUAL", estrato = "ESTRATO",
      upm = "CONGLOMERADO", condicion = "OCUP300", edad = "C208")
  )
})

test_that("p108 solo es edad en la EPE", {
  epen <- data.frame(ANIO = 2024L, C308_COD = "5212", FAC300_ANUAL = 1, p108 = 3)
  expect_true(is.na(.detectar_variables(epen, "EPEN")[["edad"]]))
  epen$C208 <- 30
  expect_equal(.detectar_variables(epen, "EPEN")[["edad"]], "C208")
})

test_that("alias de una encuesta no se usan en la otra", {
  epe <- data.frame(pano = 2019L, p204a = 262L, FAC300_ANUAL = 1, OCUP300 = 1)
  v <- .detectar_variables(epe, "EPE")
  expect_true(is.na(v[["peso"]]))
  expect_true(is.na(v[["condicion"]]))
})

test_that("con fa_def19 y fa_def21 hay que indicar el factor", {
  epe <- data.frame(pano = 2019L, p204a = 262L, fa_def19 = 1, fa_def21 = 2)
  expect_error(.detectar_variables(epe, "EPE"), "depende del periodo")
  v <- .detectar_variables(epe, "EPE", forzadas = list(peso = "fa_def21"))
  expect_equal(v[["peso"]], "fa_def21")
  expect_error(.detectar_variables(epe, "EPE", forzadas = list(peso = "fa_def99")), "no existe")
})

test_that("las bases procesadas usan los nombres comunes", {
  v <- .detectar_variables(muestra_epen_2024, "EPEN")
  expect_equal(v[["year"]], "year")
  expect_equal(v[["ocupacion"]], "occupation_code_raw")
  expect_equal(v[["peso"]], "weight")
  expect_equal(v[["upm"]], "cluster_id")
})
