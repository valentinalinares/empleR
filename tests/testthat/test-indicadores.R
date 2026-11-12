test_that("indicadores() calcula nacional y por grupo", {
  nacional <- suppressWarnings(indicadores(muestra_epen_2024, "ingreso_promedio"))
  expect_equal(nrow(nacional), 1)
  expect_true("estimado" %in% names(nacional))
  expect_false("error_std" %in% names(nacional))
  expect_equal(attr(nacional, "inferencia"), "no_calculada")

  por_sexo <- suppressWarnings(
    indicadores(muestra_epen_2024, "ingreso_mediano", por = "sex")
  )
  expect_equal(nrow(por_sexo), length(unique(muestra_epen_2024$sex)))
  expect_true(all(por_sexo$estimado > 0))
  expect_true(all(c(
    "n_universo", "n_estimacion", "n_sin_peso", "n_peso_invalido",
    "n_sin_indicador", "n_indicador_invalido", "n_fuera_definicion",
    "poblacion_representada"
  ) %in% names(nacional)))
})

test_that("indicadores() rechaza indicadores no soportados", {
  expect_error(indicadores(muestra_epen_2024, "tasa_desempleo"), "resumen_nacional")
})

test_that("la UPM combina muestra, region y conglomerado", {
  datos <- data.frame(
    sample_id = c("1", "1", "2"),
    region_code = c(16, 24, 16),
    cluster_id = c("07502", "07502", "07502")
  )
  r <- .upm_compuesta(datos, "cluster_id")
  # El mismo numero de conglomerado en otra region o muestra es otra UPM
  expect_equal(length(unique(r$.upm)), 3L)

  sin_muestra <- .upm_compuesta(datos[, c("region_code", "cluster_id")], "cluster_id")
  expect_false(".upm" %in% names(sin_muestra))
})

test_that("indicadores() usa estrato y UPM compuesta con la muestra", {
  expect_no_error(
    suppressWarnings(suppressMessages(
      r <- indicadores(
        muestra_epen_2024[!is.na(muestra_epen_2024$weight), ],
        "ingreso_promedio",
        incluir_inferencia = TRUE
      )
    ))
  )
  expect_true(r$error_std > 0)
  expect_equal(attr(r, "inferencia"), "experimental")
})

test_that("la inferencia no simplifica identificadores incompletos", {
  datos <- data.frame(
    sample_id = c("1", "1", "1", "1"),
    region_code = c("15", "15", "15", "15"),
    cluster_id = c("001", "001", "002", "002"),
    strata_code = c("1", "1", NA, NA),
    weight = rep(1, 4),
    labor_income_work_weighted = c(100, 200, 300, 400)
  )

  expect_error(
    indicadores(
      datos, "ingreso_promedio", incluir_inferencia = TRUE
    ),
    "estratos incompletos"
  )
  expect_no_error(suppressMessages(
    resultado <- indicadores(
      datos,
      "ingreso_promedio",
      var_strata = NA,
      incluir_inferencia = TRUE
    )
  ))
  expect_true(resultado$error_std > 0)
})

test_that("la inferencia exige una UPM", {
  datos <- data.frame(
    weight = c(1, 2),
    labor_income_work_weighted = c(100, 200)
  )
  expect_error(
    indicadores(datos, "ingreso_promedio", incluir_inferencia = TRUE),
    "UPM"
  )
})

test_that("la inferencia valida sus argumentos y el numero de UPM", {
  datos <- data.frame(
    cluster_id = c("001", "002"),
    weight = c(1, 2),
    labor_income_work_weighted = c(100, 200)
  )

  expect_error(
    indicadores(datos, "ingreso_promedio", incluir_inferencia = NA),
    "debe ser `TRUE` o `FALSE`"
  )
  datos$cluster_id <- "unica"
  expect_error(
    indicadores(datos, "ingreso_promedio", incluir_inferencia = TRUE),
    "por lo menos dos UPM"
  )
})

test_that("la muestra trae identificadores del muestreo completos", {
  m <- muestra_epen_2024
  expect_equal(ncol(m), 36L)
  expect_false(anyNA(m$strata_code))
  expect_false(anyNA(m$sample_id))
  expect_type(m$cluster_id, "character")
  expect_true(any(startsWith(m$cluster_id, "0")))
  expect_false(anyNA(m$hours_week_total))
  expect_true(any(m$hours_week_total != m$hours_week))
  clave <- m[c("month", "sample_id", "region_code", "cluster_id", "dwelling_id",
               "household_id", "person_id")]
  expect_false(anyDuplicated(clave) > 0)
})

test_that("indicadores() reconoce nombres crudos del modulo 76", {
  crudos <- data.frame(
    MUESTRA = rep(1:2, each = 4),
    CCDD = rep(c("15", "24"), each = 4),
    CONGLOMERADO = rep(c("0001", "0002"), 4),
    ESTRATO = rep(c(1, 1, 2, 2), 2),
    FAC300_ANUAL = rep(100, 8),
    ingtrabw = as.character(seq(1000, 1700, by = 100)),
    whoraT = rep(c(40, 48), 4)
  )

  ingreso <- suppressMessages(
    indicadores(crudos, "ingreso_promedio")
  )
  horas <- suppressMessages(
    indicadores(crudos, "horas_promedio")
  )

  expect_equal(ingreso$estimado, mean(as.numeric(crudos$ingtrabw)))
  expect_equal(horas$estimado, mean(crudos$whoraT))
})

test_that("indicadores() filtra ocupados y convierte columnas de texto", {
  crudos <- data.frame(
    OCUP300 = c("1", "1", "2", "4"),
    FAC300_ANUAL = c("1", "3", "100", "100"),
    ingtrabw = c("100", "300", "9999", "9999"),
    whoraT = c("20", "40", "99", "99")
  )

  ingreso <- suppressWarnings(indicadores(crudos, "ingreso_promedio"))
  horas <- suppressWarnings(indicadores(crudos, "horas_promedio"))

  expect_equal(ingreso$estimado, 250)
  expect_equal(horas$estimado, 35)
  expect_equal(ingreso$n_universo, 2L)
  expect_equal(ingreso$n_estimacion, 2L)
})

test_that("indicadores() exige elegir entre varios factores", {
  datos <- data.frame(
    FAC300_ANUAL = c(1, 1),
    FAC_T300 = c(2, 2),
    ingtrabw = c(100, 200)
  )
  expect_error(
    indicadores(datos, "ingreso_promedio"),
    "varios factores"
  )
  expect_no_error(suppressWarnings(
    indicadores(datos, "ingreso_promedio", var_peso = "FAC300_ANUAL")
  ))
})

test_that("indicadores() audita pesos y valores excluidos", {
  datos <- data.frame(
    weight = c("1", "", "0", "Inf", "2", "3", "4"),
    labor_income_work_weighted = c("100", "200", "300", "400", "", "x", "0")
  )
  r <- suppressWarnings(indicadores(datos, "ingreso_promedio"))

  expect_equal(r$n_universo, 7L)
  expect_equal(r$n_estimacion, 1L)
  expect_equal(r$n_sin_peso, 1L)
  expect_equal(r$n_peso_invalido, 2L)
  expect_equal(r$n_sin_indicador, 1L)
  expect_equal(r$n_indicador_invalido, 1L)
  expect_equal(r$n_fuera_definicion, 1L)
  expect_equal(r$poblacion_representada, 1)
  expect_equal(r$estimado, 100)
})

test_that("la mediana ponderada usa la regla matematica", {
  datos <- data.frame(
    weight = c(1, 1, 1, 1),
    labor_income_work_weighted = c(10, 20, 30, 40)
  )
  r <- suppressWarnings(indicadores(datos, "ingreso_mediano"))
  expect_equal(r$estimado, 20)
})

test_that("horas totales no se sustituyen por horas de ocupacion principal", {
  datos <- data.frame(weight = 1:2, hours_week = c(40, 45))
  expect_error(
    indicadores(datos, "horas_promedio"),
    "var_indicador"
  )
  expect_no_error(suppressWarnings(
    indicadores(datos, "horas_promedio", var_indicador = "hours_week")
  ))
})
