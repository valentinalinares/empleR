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

  expect_equal(resultado$homologacion_estado[5:6], c("sin_codigo", "formato_invalido"))
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

# Deteccion del clasificador --------------------------------------------------

base_min <- function(year, codigo = 111L, nombre_year = "year") {
  df <- data.frame(year = year, P204A = codigo, C308_COD = codigo)
  names(df)[1] <- nombre_year
  df
}

test_that("cno() usa todos los anos, no solo el de la primera fila", {
  expect_error(suppressMessages(cno(base_min(c(2024L, 2019L)))), "mezcla")
  expect_error(suppressMessages(cno(base_min(c(2021L, 2022L)))), "mezcla")
})

test_that("cno() acepta varios anos del mismo periodo", {
  r <- suppressMessages(cno(base_min(c(2017L, 2019L, 2021L))))
  expect_equal(unique(r$clasificador), "CO_95")
  r <- suppressMessages(cno(base_min(c(2022L, 2023L, 2025L))))
  expect_equal(unique(r$clasificador), "CNO_2015")
})

test_that("transicion 2022: 2021 es CO-95 y 2022 es CNO 2015", {
  expect_equal(suppressMessages(cno(base_min(2021L)))$clasificador, "CO_95")
  expect_equal(suppressMessages(cno(base_min(2022L)))$clasificador, "CNO_2015")
})

test_that("cno() detecta la variable ano con distintos nombres, incluido AÑO", {
  for (nombre in c("year", "anio", "ANIO", "ANO", "AÑO", "año", "AÃ‘O")) {
    r <- suppressMessages(cno(base_min(2019L, nombre_year = nombre)))
    expect_equal(r$clasificador, "CO_95", info = nombre)
  }
})

test_that("cno() ignora filas sin ano y avisa", {
  expect_warning(
    r <- suppressMessages(cno(base_min(c(NA, 2019L, 2019L)))),
    "sin ano"
  )
  expect_equal(unique(r$clasificador), "CO_95")
})

test_that("cno() falla si no puede determinar el clasificador", {
  sin_year <- data.frame(P204A = 111L)
  expect_error(suppressMessages(cno(sin_year)), "clasificador")
  expect_equal(
    suppressMessages(cno(sin_year, clasificador = "CO_95"))$clasificador,
    "CO_95"
  )
})

test_that("el argumento clasificador tiene prioridad y avisa si contradice el ano", {
  expect_warning(
    r <- suppressMessages(cno(base_min(2022L), clasificador = "CO_95")),
    "no coincide"
  )
  expect_equal(r$clasificador, "CO_95")
  expect_error(suppressMessages(cno(base_min(2022L), clasificador = "CIUO")))
})

test_that("la encuesta declarada en source tiene prioridad sobre el ano", {
  epe_2022 <- cbind(base_min(2022L), source = "EPE")
  expect_equal(suppressMessages(cno(epe_2022))$clasificador, "CO_95")
  mezcla <- rbind(cbind(base_min(2021L), source = "EPE"), cbind(base_min(2023L), source = "EPEN"))
  expect_error(suppressMessages(cno(mezcla)), "EPE y EPEN")
})

# Gran grupo --------------------------------------------------------------------

test_that("el gran grupo solo se asigna cuando todos los candidatos coinciden", {
  candidatos <- strsplit(co_1995$cno2015_candidatos, "; ", fixed = TRUE)
  un_digito <- vapply(candidatos, function(z) length(unique(substr(z, 1, 1))) == 1, logical(1))
  asignable <- un_digito & co_1995$estado %in% c("unica", "multiples_destinos")
  expect_equal(!is.na(co_1995$gran_grupo_cno), asignable)
  ok <- !is.na(co_1995$gran_grupo_cno)
  expect_equal(co_1995$gran_grupo_cno[ok], substr(vapply(candidatos[ok], `[`, "", 1), 1, 1))
})

# Catalogo CNO 2015 ---------------------------------------------------------------

test_that("cno_2015 incluye el grupo primario 5321 y los 473 codigos del INEI", {
  expect_true("5321" %in% cno_2015$codigo)
  expect_equal(sum(cno_2015$nivel == 4), 473L)
  expect_setequal(cno_2015$codigo[cno_2015$nivel == 4], unique(equivalencia_co95$cno2015))
  expect_equal(
    cno_2015$descripcion[cno_2015$codigo == "532"],
    "Trabajadores en el cuidado de personas en servicios de salud"
  )
})

test_that("la variable AÑO se detecta aunque venga sin marca de codificacion o en latin1", {
  sin_marca <- "AÑO"
  Encoding(sin_marca) <- "unknown"
  latin1 <- iconv("AÑO", "UTF-8", "latin1")
  latin1_sin_marca <- rawToChar(as.raw(c(0x41, 0xd1, 0x4f)))
  for (nombre in list(sin_marca, latin1, latin1_sin_marca)) {
    df <- data.frame(x = 2019L, P204A = 111L)
    names(df)[1] <- nombre
    expect_equal(suppressMessages(cno(df))$clasificador, "CO_95")
  }
})

# Codigo original frente a occupation_code_4d -----------------------------------

test_that("raw 212 produce 0212 aunque el procesado sea 2120 y ambos existan", {
  cod4 <- cno_2015$codigo[cno_2015$nivel == 4]
  expect_true(all(c("0212", "2120") %in% cod4))

  datos <- data.frame(
    year = 2024L,
    occupation_code_raw = c(212, 5212),
    occupation_code_4d = c("2120", "5212")
  )
  expect_warning(r <- suppressMessages(cno(datos)), "no coincide")
  expect_equal(r$cno_cod, c("0212", "5212"))
  expect_equal(r$cno_discrepancia_4d, c(TRUE, FALSE))
})

test_that("C308_COD tiene prioridad sobre occupation_code_4d", {
  datos <- data.frame(year = 2024L, C308_COD = 212L, occupation_code_4d = "2120")
  r <- suppressWarnings(suppressMessages(cno(datos)))
  expect_equal(r$cno_cod, "0212")
  expect_true(r$cno_discrepancia_4d)
})

test_that("con var_ocup = occupation_code_4d la discrepancia sigue detectable", {
  datos <- data.frame(year = 2024L, occupation_code_raw = 212, occupation_code_4d = "2120")
  expect_warning(
    r <- suppressMessages(cno(datos, var_ocup = "occupation_code_4d")),
    "no coincide"
  )
  expect_equal(r$cno_cod, "2120")
  expect_true(r$cno_discrepancia_4d)
})

test_that("sin codigo original no se agrega la columna de discrepancia", {
  r <- suppressMessages(cno(data.frame(year = 2024L, occupation_code_4d = "5212")))
  expect_false("cno_discrepancia_4d" %in% names(r))
})

test_that("la muestra no tiene discrepancias entre codigo original y procesado", {
  r <- suppressMessages(cno(muestra_epen_2024))
  expect_false(any(r$cno_discrepancia_4d, na.rm = TRUE))
})

test_that("cno() reconoce pano como ano de la EPE", {
  r <- suppressMessages(cno(data.frame(pano = 2019L, p204a = 262L)))
  expect_equal(r$clasificador, "CO_95")
  expect_equal(r$cno_cod, "262")
})

# Tareas del catalogo --------------------------------------------------------------

test_that("5223 tiene sus tres tareas del indice y los scores no cambian", {
  i <- indice_ia$code == "5223"
  tareas_indice <- trimws(sub(
    " -> score: .*$", "",
    strsplit(indice_ia$tasks_and_classifications[i], "\n", fixed = TRUE)[[1]]
  ))
  tareas_cno <- strsplit(cno_2015$tasks[cno_2015$codigo == "5223"], "\r\n", fixed = TRUE)[[1]]
  expect_equal(tareas_cno, tareas_indice)
  expect_length(tareas_cno, 3)
  expect_equal(indice_ia$mean_exposure_score[i], 0.45)
  expect_equal(indice_ia$median_exposure_score[i], 0.45)
  expect_equal(
    c(indice_ia$tipo_A_aumento[i], indice_ia$tipo_S_sustitucion[i], indice_ia$tipo_N_nulo[i]),
    c(2, 0, 1)
  )
})

test_that("5321 no tiene score ni tipo de impacto (no se toman de 5322 ni 5329)", {
  expect_false("5321" %in% indice_ia$code)
  datos <- data.frame(year = 2024L, C308_COD = c("5321", "5322"))
  r <- suppressWarnings(suppressMessages(ia_exposicion(cno(datos), incluir_tipo = TRUE)))
  expect_true(is.na(r$ia_score_mean[1]))
  expect_true(is.na(r$ia_tipo[1]))
  expect_equal(r$ia_tipo_estado[1], "sin_indice")
  expect_equal(r$ia_cobertura[1], "sin_score")
  expect_false(is.na(r$ia_score_mean[2]))
})
