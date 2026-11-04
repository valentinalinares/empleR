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
  expect_no_warning(
    suppressMessages(r <- indicadores(muestra_epen_2024[!is.na(muestra_epen_2024$weight), ], "ingreso_promedio"))
  )
  expect_true(r$error_std > 0)
})

test_that("la muestra trae identificadores del muestreo completos", {
  m <- muestra_epen_2024
  expect_equal(ncol(m), 34L)
  expect_false(anyNA(m$strata_code))
  expect_false(anyNA(m$sample_id))
  expect_type(m$cluster_id, "character")
  expect_true(any(startsWith(m$cluster_id, "0")))
  clave <- m[c("month", "sample_id", "region_code", "cluster_id", "dwelling_id",
               "household_id", "person_id")]
  expect_false(anyDuplicated(clave) > 0)
})
