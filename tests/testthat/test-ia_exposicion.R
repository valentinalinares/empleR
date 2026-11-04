test_that("ia_exposicion() agrega columna ia_score_mean", {
  datos <- cno(muestra_epen_2024)
  resultado <- suppressWarnings(ia_exposicion(datos))
  expect_true("ia_score_mean" %in% names(resultado))
})

test_that("ia_exposicion() falla si no existe var_cno", {
  expect_error(
    ia_exposicion(muestra_epen_2024, var_cno = "columna_inexistente"),
    "no existe en los datos"
  )
})

test_that("ia_score_mean esta entre 0 y 1", {
  datos <- cno(muestra_epen_2024)
  resultado <- suppressWarnings(ia_exposicion(datos))
  scores <- resultado$ia_score_mean[!is.na(resultado$ia_score_mean)]
  expect_true(all(scores >= 0 & scores <= 1))
})

test_that("ia_exposicion(incluir_tipo = TRUE) marca empates sin elegir tipo", {
  datos <- suppressMessages(cno(muestra_epen_2024))
  resultado <- suppressWarnings(ia_exposicion(datos, incluir_tipo = TRUE))
  expect_true(all(c("ia_tipo", "ia_empate", "ia_tipo_estado") %in% names(resultado)))
  expect_true(all(resultado$ia_tipo %in% c("A", "S", "N", NA)))

  empate <- resultado$ia_tipo_estado == "empate"
  expect_true(all(is.na(resultado$ia_tipo[empate])))
  expect_true(all(resultado$ia_empate[empate]))
  # Los conteos se conservan en los empates
  expect_false(anyNA(resultado$tipo_S_sustitucion[empate]))

  pred <- resultado$ia_tipo_estado == "predominante"
  expect_false(anyNA(resultado$ia_tipo[pred]))
  expect_false(any(resultado$ia_empate[pred]))
})

test_that(".tipo_predominante() distingue predominante, empate, sin tareas e indice", {
  r <- .tipo_predominante(
    n_a = c(5, 2, 0, NA, 1),
    n_s = c(1, 2, 0, NA, 4),
    n_n = c(0, 1, 0, NA, 0),
    total = c(6, 5, 0, NA, 5)
  )
  expect_equal(r$tipo, c("A", NA, NA, NA, "S"))
  expect_equal(r$empate, c(FALSE, TRUE, NA, NA, FALSE))
  expect_equal(r$estado, c("predominante", "empate", "sin_tareas", "sin_indice", "predominante"))
})

test_that("empates del indice: tipo NA en todas las ocupaciones con maximo compartido", {
  m <- cbind(indice_ia$tipo_A_aumento, indice_ia$tipo_S_sustitucion, indice_ia$tipo_N_nulo)
  r <- .tipo_predominante(m[, 1], m[, 2], m[, 3], total = indice_ia$total_tasks)
  n_empates <- sum(rowSums(m == apply(m, 1, max)) > 1)
  expect_equal(sum(r$estado == "empate"), n_empates)
  expect_true(all(is.na(r$tipo[r$estado == "empate"])))
})

# Flujo EPE completo -----------------------------------------------------------

co95_con_score <- function() {
  unicos <- co_1995[co_1995$estado == "unica" & co_1995$cno2015_unico %in% indice_ia$code, ]
  unicos[1, ]
}

epe_para_ia <- function() {
  u <- co95_con_score()
  data.frame(
    year   = 2019L,
    P204A  = c(as.integer(u$co95), 262L, 999L, NA),
    weight = c(100, 200, 300, 400)
  )
}

test_that("flujo EPE: cno(homologar = TRUE) |> ia_exposicion() usa cno_homologado", {
  u <- co95_con_score()
  resultado <- suppressWarnings(suppressMessages(
    ia_exposicion(cno(epe_para_ia(), homologar = TRUE), incluir_tipo = TRUE)
  ))

  expect_equal(nrow(resultado), 4L)
  expect_equal(resultado$weight, c(100, 200, 300, 400))
  expect_equal(resultado$ia_cno, resultado$cno_homologado)
  expect_equal(resultado$ia_cno[1], u$cno2015_unico)
  expect_equal(
    resultado$ia_score_mean[1],
    indice_ia$mean_exposure_score[indice_ia$code == u$cno2015_unico]
  )
  expect_equal(
    resultado$ia_cobertura,
    c("con_score", "sin_homologacion", "sin_homologacion", "sin_codigo")
  )
  expect_true(all(is.na(resultado$ia_score_mean[2:4])))
})

test_that("ia_exposicion() no cruza codigos CO-95 con el indice", {
  sin_homologar <- suppressMessages(cno(epe_para_ia()))
  expect_error(ia_exposicion(sin_homologar), "homologar")

  homologada <- suppressMessages(cno(epe_para_ia(), homologar = TRUE))
  expect_error(ia_exposicion(homologada, var_cno = "cno_cod"), "CO-95")
})

test_that("ia_exposicion() no cruza codigos agregados con el indice", {
  agregada <- suppressMessages(cno(muestra_epen_2024, agregar = "2d"))
  expect_error(ia_exposicion(agregada), "4 digitos")
})

test_that("ia_exposicion() usa el codigo correcto en una base EPE + EPEN", {
  epe <- suppressMessages(cno(epe_para_ia(), homologar = TRUE))
  epen <- suppressMessages(cno(muestra_epen_2024[1:5, ]))
  unida <- dplyr::bind_rows(epe, epen)
  resultado <- suppressWarnings(suppressMessages(ia_exposicion(unida)))
  es_epe <- resultado$clasificador == "CO_95"
  expect_equal(resultado$ia_cno[es_epe], resultado$cno_homologado[es_epe])
  expect_equal(resultado$ia_cno[!es_epe], resultado$cno_cod[!es_epe])
})

test_that("ia_exposicion(score = 'median') agrega solo la mediana", {
  datos <- suppressMessages(cno(muestra_epen_2024))
  resultado <- suppressWarnings(ia_exposicion(datos, score = "median"))
  expect_true("ia_score_median" %in% names(resultado))
  expect_false("ia_score_mean" %in% names(resultado))
})

test_that("ia_exposicion() rechaza valores invalidos de score", {
  datos <- suppressMessages(cno(muestra_epen_2024))
  expect_error(ia_exposicion(datos, score = "promedio"))
})

test_that("codigos de 4 digitos inexistentes en el CNO no se cuentan como sin score", {
  datos <- data.frame(year = 2024L, C308_COD = c("2110", "0211", "5321"))
  expect_warning(procesada <- suppressMessages(cno(datos)), "cero a la derecha")
  r <- suppressWarnings(suppressMessages(ia_exposicion(procesada)))
  expect_equal(r$ia_cobertura[1], "codigo_no_encontrado")
  # 0211 (Fuerzas Armadas) y 5321 existen en el CNO pero no tienen score
  expect_equal(r$ia_cobertura[2:3], c("sin_score", "sin_score"))
})
