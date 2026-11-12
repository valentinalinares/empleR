datos_ambitos_epen <- function() {
  ids <- names(.ambitos_epen)
  data.frame(
    region_code = as.integer(sub("-.*", "", ids)),
    division_lima = ifelse(grepl("-", ids), as.integer(sub(".*-", "", ids)), NA),
    indicador = seq_along(ids)
  )
}

valor_en <- function(mapa_data, geo_id, var = "indicador") {
  mapa_data[[var]][mapa_data$geo_id == geo_id]
}

llamada_leaflet <- function(m, metodo) {
  llamadas <- Filter(function(x) identical(x$method, metodo), m$x$calls)
  llamadas[[1]]
}

test_that("los shapes representan los 25 ambitos oficiales de la EPEN", {
  shapes <- .shapes_ambitos_epen()

  expect_s3_class(shapes, "sf")
  expect_identical(shapes$geo_id, names(.ambitos_epen))
  expect_identical(shapes$departamento, unname(.ambitos_epen))
  expect_true(all(sf::st_is_valid(shapes)))
  expect_false("07" %in% shapes$geo_id)
  expect_true(all(c("15-1", "15-2") %in% shapes$geo_id))
})

test_that("los dos ambitos de Lima cubren Lima y Callao sin perder superficie", {
  shapes <- .shapes_ambitos_epen()
  original <- sf::st_union(shapes_departamentos[
    shapes_departamentos$departamento %in% c("LIMA", "CALLAO"),
  ])
  reconstruido <- sf::st_union(shapes[shapes$geo_id %in% c("15-1", "15-2"), ])

  diferencia <- abs(as.numeric(sf::st_area(original) - sf::st_area(reconstruido)))
  expect_lt(diferencia, 1)
})

test_that("se normalizan los nombres oficiales de los ambitos", {
  expect_identical(
    .nombre_a_geo_id(c(
      "Áncash",
      "Región Lima",
      "Lima Metropolitana y la Provincia Constitucional del Callao",
      "desconocido",
      NA
    )),
    c("02", "15-2", "15-1", NA, NA)
  )
})

test_that("CCDD 15 exige y utiliza DIVISION_LIMA", {
  datos <- data.frame(
    CCDD = c("08", "15", "15"),
    DIVISION_LIMA = c(NA, "1", "2"),
    indicador = c(8, 151, 152)
  )
  unido <- suppressWarnings(.unir_mapa(datos, "indicador", .shapes_ambitos_epen()))

  expect_identical(valor_en(unido, "08"), 8)
  expect_identical(valor_en(unido, "15-1"), 151)
  expect_identical(valor_en(unido, "15-2"), 152)
  expect_error(
    mapa(data.frame(CCDD = "15", indicador = 1), "indicador", tipo = "ggplot"),
    "requiere.*DIVISION_LIMA"
  )
})

test_that("se rechazan codigos ajenos a los ambitos EPEN", {
  expect_error(
    mapa(data.frame(CCDD = "07", indicador = 1), "indicador", tipo = "ggplot"),
    "integra Callao"
  )
  expect_error(
    mapa(data.frame(CCDD = "99", indicador = 1), "indicador", tipo = "ggplot"),
    "codigo departamental valido"
  )
  expect_error(
    mapa(data.frame(CCDD = "A", indicador = 1), "indicador", tipo = "ggplot"),
    "codigo invalido"
  )
})

test_that("la division de Lima solo se admite con CCDD 15", {
  expect_error(
    mapa(
      data.frame(CCDD = "08", DIVISION_LIMA = 1, indicador = 1),
      "indicador",
      tipo = "ggplot"
    ),
    "solo corresponde al codigo 15"
  )
  expect_error(
    mapa(
      data.frame(CCDD = "15", DIVISION_LIMA = 3, indicador = 1),
      "indicador",
      tipo = "ggplot"
    ),
    "solo puede valer 1 o 2"
  )
})

test_that("todas las columnas geograficas presentes deben coincidir", {
  expect_error(
    mapa(
      data.frame(
        CCDD = "15",
        region_code = 8,
        DIVISION_LIMA = 1,
        indicador = 1
      ),
      "indicador",
      tipo = "ggplot"
    ),
    "solo corresponde|no coinciden"
  )
  expect_error(
    mapa(
      data.frame(
        CCDD = "15",
        DIVISION_LIMA = 1,
        division_lima = 2,
        indicador = 1
      ),
      "indicador",
      tipo = "ggplot"
    ),
    "discrepan"
  )
  expect_error(
    mapa(
      data.frame(
        CCDD = "15",
        DIVISION_LIMA = 1,
        departamento = "REGION LIMA",
        indicador = 1
      ),
      "indicador",
      tipo = "ggplot"
    ),
    "no coinciden"
  )
})

test_that("un codigo invalido no se sustituye por un nombre valido", {
  datos <- data.frame(CCDD = "99", departamento = "CUSCO", indicador = 1)
  expect_error(mapa(datos, "indicador", tipo = "ggplot"), "codigo departamental valido")
})

test_that("se rechazan ambitos repetidos", {
  datos <- data.frame(
    region_code = c(8, 8),
    indicador = c(1, 2)
  )
  expect_error(
    mapa(datos, "indicador", tipo = "ggplot"),
    "una fila por ambito"
  )
})

test_that("los nombres desconocidos se informan y no se asignan", {
  datos <- data.frame(
    departamento = c("CUSCO", "LIMA", NA),
    indicador = c(8, 1, 2)
  )
  expect_warning(
    expect_warning(
      unido <- .unir_mapa(datos, "indicador", .shapes_ambitos_epen()),
      "no corresponde"
    ),
    "24 ambitos sin dato"
  )
  expect_identical(valor_en(unido, "08"), 8)
  expect_identical(sum(!is.na(unido$indicador)), 1L)
})

test_that("se avisa cuando faltan ambitos completos", {
  datos <- datos_ambitos_epen()
  datos <- datos[datos$region_code != 24, ]
  expect_warning(
    .unir_mapa(datos, "indicador", .shapes_ambitos_epen()),
    "1 ambito sin dato.*TUMBES"
  )
})

test_that("mapa valida la variable y la llave geografica", {
  expect_error(mapa(data.frame(CCDD = "08"), "valor"), "no existe")
  expect_error(
    mapa(data.frame(CCDD = "08", valor = "alto"), "valor"),
    "numerica"
  )
  expect_error(
    mapa(data.frame(CCDD = "08", valor = Inf), "valor"),
    "infinitos"
  )
  expect_error(
    mapa(data.frame(valor = 1), "valor", tipo = "ggplot"),
    "llave geografica"
  )
  expect_error(mapa(list(CCDD = "08", valor = 1), "valor"), "data.frame")
})

test_that("Lima movil no se confunde con un ambito departamental", {
  expect_error(
    mapa(data.frame(REGION = "1", valor = 10), "valor", tipo = "ggplot"),
    "llave geografica"
  )
  expect_error(
    mapa(data.frame(region = "1", valor = 10), "valor", tipo = "ggplot"),
    "Ninguna fila"
  )
})

test_that("los niveles provincial y distrital no estan disponibles", {
  datos <- datos_ambitos_epen()
  expect_error(mapa(datos, "indicador", nivel = "provincia"), "no esta disponible")
  expect_error(mapa(datos, "indicador", nivel = "distrito"), "no esta disponible")
  expect_error(mapa(datos, "indicador", nivel = "region"), "departamento")
})

test_that("shapes propios requieren geo_id y nombres unicos", {
  datos <- datos_ambitos_epen()
  shapes <- .shapes_ambitos_epen()
  repetidos <- rbind(shapes, shapes[1, ])

  expect_error(
    mapa(datos, "indicador", tipo = "ggplot", shapes = repetidos),
    "una geometria por"
  )
  expect_error(
    mapa(
      datos,
      "indicador",
      tipo = "ggplot",
      shapes = shapes_departamentos
    ),
    "geo_id"
  )
})

test_that("mapa produce un ggplot con los valores asignados", {
  datos <- datos_ambitos_epen()
  resultado <- mapa(datos, "indicador", tipo = "ggplot", titulo = "Indicador")

  expect_s3_class(resultado, "ggplot")
  expect_identical(valor_en(resultado$data, "08"), 7L)
  expect_identical(valor_en(resultado$data, "15-1"), 14L)
  expect_identical(valor_en(resultado$data, "15-2"), 15L)
  expect_identical(resultado$labels$title, "Indicador")
  expect_no_error(ggplot2::ggplot_build(resultado))
})

test_that("mapa produce un leaflet con etiquetas por ambito", {
  datos <- data.frame(
    region_code = c(8, 15, 15),
    division_lima = c(NA, 1, 2),
    indicador = c(1234.56, 0.0391, 20)
  )
  resultado <- suppressWarnings(mapa(datos, "indicador"))

  expect_s3_class(resultado, "leaflet")
  poligonos <- llamada_leaflet(resultado, "addPolygons")
  etiquetas <- Find(
    function(a) is.character(a) && length(a) == length(.ambitos_epen),
    poligonos$args
  )
  ids <- names(.ambitos_epen)

  expect_identical(etiquetas[ids == "08"], "CUSCO: 1235")
  expect_identical(
    etiquetas[ids == "15-1"],
    "LIMA METROPOLITANA Y CALLAO: 0.0391"
  )
  expect_identical(etiquetas[ids == "15-2"], "REGION LIMA: 20")
})
