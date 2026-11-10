datos_departamentos <- function() {
  data.frame(
    departamento = shapes_departamentos$departamento,
    indicador = seq_len(nrow(shapes_departamentos))
  )
}

valor_en <- function(mapa_data, departamento, var = "indicador") {
  mapa_data[[var]][mapa_data$departamento == departamento]
}

llamada_leaflet <- function(m, metodo) {
  llamadas <- Filter(function(x) identical(x$method, metodo), m$x$calls)
  llamadas[[1]]
}

test_that("los codigos UBIGEO coinciden con los poligonos incluidos", {
  expect_setequal(unname(.departamentos_ubigeo), shapes_departamentos$departamento)
  expect_identical(
    .codigo_a_departamento(c(1, "07", "15", " 25 ", "26", "A", NA)),
    c("AMAZONAS", "CALLAO", "LIMA", "UCAYALI", NA, NA, NA)
  )
})

test_that("los nombres se comparan sin mayusculas ni tildes", {
  expect_identical(
    .normalizar_departamento(c("\u00c1ncash", " San  Mart\u00edn ", "jun\u00edn", "", NA)),
    c("ANCASH", "SAN MARTIN", "JUNIN", NA, NA)
  )
})

test_that("cada valor se asigna al poligono de su departamento", {
  datos <- datos_departamentos()
  datos <- datos[rev(seq_len(nrow(datos))), ]

  unido <- .unir_mapa(datos, "indicador", shapes_departamentos)

  expect_s3_class(unido, "sf")
  expect_identical(nrow(unido), nrow(shapes_departamentos))
  expect_identical(unido$departamento, shapes_departamentos$departamento)
  expect_identical(unido$indicador, seq_len(nrow(shapes_departamentos)))
  expect_identical(valor_en(unido, "CUSCO"), 8L)
})

test_that("se puede unir por region_code o CCDD sin columnas de nombres", {
  por_region <- data.frame(region_code = c(8, 15, 1), indicador = c(80, 150, 10))
  unido <- suppressWarnings(.unir_mapa(por_region, "indicador", shapes_departamentos))
  expect_identical(valor_en(unido, "CUSCO"), 80)
  expect_identical(valor_en(unido, "LIMA"), 150)
  expect_identical(valor_en(unido, "AMAZONAS"), 10)
  expect_true(is.na(valor_en(unido, "CALLAO")))

  por_ccdd <- data.frame(CCDD = c("08", "15"), indicador = c(80, 150))
  unido <- suppressWarnings(.unir_mapa(por_ccdd, "indicador", shapes_departamentos))
  expect_identical(valor_en(unido, "CUSCO"), 80)
  expect_identical(valor_en(unido, "LIMA"), 150)
})

test_that("las columnas de nombres de data no reemplazan las de shapes", {
  datos <- data.frame(
    region_code = 1:25,
    departamento = shapes_departamentos$departamento,
    indicador = 1:25
  )
  datos <- datos[datos$region_code != 7, ]

  unido <- suppressWarnings(.unir_mapa(datos, "indicador", shapes_departamentos))

  expect_identical(unido$departamento, shapes_departamentos$departamento)
  expect_true(is.na(valor_en(unido, "CALLAO")))
})

test_that("se rechaza un codigo que contradice el nombre", {
  datos <- data.frame(
    region_code = c(8, 15),
    departamento = c("CUSCO", "CALLAO"),
    indicador = c(1, 2)
  )
  expect_error(
    .unir_mapa(datos, "indicador", shapes_departamentos),
    "no coinciden"
  )
})

test_that("se rechazan departamentos repetidos", {
  datos <- data.frame(
    region_code = c(8, 8, 15, 15),
    sex = c("Hombre", "Mujer", "Hombre", "Mujer"),
    indicador = 1:4
  )
  expect_error(
    mapa(datos, "indicador", tipo = "ggplot"),
    "una fila por departamento"
  )

  nombres <- data.frame(departamento = c("Cusco", "CUSCO"), indicador = 1:2)
  expect_error(mapa(nombres, "indicador", tipo = "ggplot"), "CUSCO")
})

test_that("se avisa de filas sin poligono y de departamentos sin dato", {
  datos <- data.frame(
    departamento = c("CUSCO", "LIMA METROPOLITANA", NA),
    indicador = c(8, 1, 2)
  )

  expect_warning(
    expect_warning(
      unido <- .unir_mapa(datos, "indicador", shapes_departamentos),
      "no corresponden a ningun departamento"
    ),
    "24 departamentos sin dato"
  )
  expect_identical(valor_en(unido, "CUSCO"), 8)
  expect_true(is.na(valor_en(unido, "LIMA")))
  expect_identical(sum(!is.na(unido$indicador)), 1L)
})

test_that("se avisa cuando falta un departamento completo", {
  datos <- datos_departamentos()
  datos <- datos[datos$departamento != "CALLAO", ]

  expect_warning(
    .unir_mapa(datos, "indicador", shapes_departamentos),
    "1 departamento sin dato.*CALLAO"
  )
})

test_that("se rechazan entradas sin ninguna correspondencia o sin valores", {
  expect_error(
    mapa(data.frame(region_code = 99, indicador = 1), "indicador", tipo = "ggplot"),
    "Ninguna fila"
  )

  sin_valores <- data.frame(departamento = c("CUSCO", "LIMA"), indicador = NA_real_)
  expect_error(
    suppressWarnings(mapa(sin_valores, "indicador", tipo = "ggplot")),
    "Ningun departamento"
  )
})

test_that("mapa() exige la variable, que sea numerica y una llave geografica", {
  expect_error(mapa(data.frame(departamento = "LIMA"), "valor"), "no existe")
  expect_error(
    mapa(data.frame(departamento = "LIMA", valor = "alto"), "valor"),
    "numerica"
  )
  expect_error(
    mapa(data.frame(valor = 1), "valor", tipo = "ggplot"),
    "No se encontro columna"
  )
  expect_error(mapa(list(departamento = "LIMA", valor = 1), "valor"), "data.frame")
})

test_that("la region unica de Lima movil no se confunde con un departamento", {
  # Las entregas de Lima movil traen REGION = 1 y no traen CCDD.
  expect_error(
    mapa(data.frame(REGION = "1", valor = 10), "valor", tipo = "ggplot"),
    "No se encontro columna"
  )
  expect_error(
    mapa(data.frame(region = "1", valor = 10), "valor", tipo = "ggplot"),
    "Ninguna fila"
  )
})

test_that("los niveles provincial y distrital no estan disponibles", {
  datos <- datos_departamentos()
  expect_error(mapa(datos, "indicador", nivel = "provincia"), "no esta disponible")
  expect_error(mapa(datos, "indicador", nivel = "distrito"), "no esta disponible")
  expect_error(mapa(datos, "indicador", nivel = "region"), "departamento")
})

test_that("shapes propios deben tener un poligono por departamento", {
  datos <- datos_departamentos()
  repetidos <- rbind(shapes_departamentos, shapes_departamentos[8, ])
  expect_error(
    mapa(datos, "indicador", tipo = "ggplot", shapes = repetidos),
    "un poligono por departamento"
  )
  expect_error(
    mapa(datos, "indicador", tipo = "ggplot", shapes = data.frame(departamento = "LIMA")),
    "sf"
  )
})

test_that("mapa() produce un ggplot con los valores asignados", {
  datos <- datos_departamentos()
  datos <- datos[datos$departamento != "CALLAO", ]

  resultado <- suppressWarnings(
    mapa(datos, var = "indicador", tipo = "ggplot", titulo = "Indicador")
  )

  expect_s3_class(resultado, "ggplot")
  expect_identical(valor_en(resultado$data, "CUSCO"), 8L)
  expect_true(is.na(valor_en(resultado$data, "CALLAO")))
  expect_identical(resultado$labels$title, "Indicador")
  expect_no_error(ggplot2::ggplot_build(resultado))
})

test_that("mapa() produce un leaflet con colores y etiquetas por departamento", {
  datos <- data.frame(
    region_code = c(8, 15),
    indicador = c(1234.56, 0.0391)
  )

  resultado <- suppressWarnings(mapa(datos, var = "indicador"))

  expect_s3_class(resultado, "leaflet")
  poligonos <- llamada_leaflet(resultado, "addPolygons")
  opciones <- Find(function(a) is.list(a) && "fillColor" %in% names(a), poligonos$args)
  etiquetas <- Find(
    function(a) is.character(a) && length(a) == nrow(shapes_departamentos),
    poligonos$args
  )

  orden <- shapes_departamentos$departamento
  expect_identical(etiquetas[orden == "CUSCO"], "CUSCO: 1235")
  expect_identical(etiquetas[orden == "LIMA"], "LIMA: 0.0391")
  expect_identical(etiquetas[orden == "CALLAO"], "CALLAO: sin dato")
  expect_identical(opciones$fillColor[orden == "CALLAO"], "#cccccc")
  expect_false(identical(
    opciones$fillColor[orden == "CUSCO"],
    opciones$fillColor[orden == "LIMA"]
  ))

  leyenda <- llamada_leaflet(resultado, "addLegend")
  expect_identical(leyenda$args[[1]]$title, "indicador")
})
