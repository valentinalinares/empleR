test_that(".leer_zip_inei() lee CSV separados por coma", {
  dir_csv <- nuevo_dir_temporal()
  writeLines(c("A,B,C", "1,2.5,3"), file.path(dir_csv, "modulo.csv"))
  zip_path <- zip_dir(dir_csv)
  datos <- .leer_zip_inei(zip_path)
  expect_equal(dim(datos), c(1L, 3L))
  expect_equal(datos$B, "2.5")
})

test_that(".leer_zip_inei() lee CSV separados por punto y coma", {
  dir_csv <- nuevo_dir_temporal()
  writeLines(c("A;B;C", "1;2,5;3"), file.path(dir_csv, "modulo.csv"))
  zip_path <- zip_dir(dir_csv)
  datos <- .leer_zip_inei(zip_path)
  expect_equal(dim(datos), c(1L, 3L))
  expect_equal(datos$B, "2,5")
})

test_that(".leer_zip_inei() conserva tipos mixtos y ceros iniciales", {
  dir_csv <- nuevo_dir_temporal()
  valores <- c(rep("1", 1000), "2", "texto")
  lineas <- c(
    "ID;MIXTA;VACIA",
    paste0(sprintf("%04d", seq_along(valores)), ";", valores, ";")
  )
  writeLines(lineas, file.path(dir_csv, "modulo.csv"))

  datos <- .leer_zip_inei(zip_dir(dir_csv))

  expect_type(datos$ID, "character")
  expect_equal(datos$ID[c(1, 1001)], c("0001", "1001"))
  expect_equal(datos$MIXTA[c(1, 1001, 1002)], c("1", "2", "texto"))
  expect_true(all(is.na(datos$VACIA)))
  expect_equal(nrow(readr::problems(datos)), 0L)
})

test_that(".leer_zip_inei() admite nombres internos con acentos", {
  datos <- .leer_zip_inei(zip_con_nombre_utf8())

  expect_equal(datos$CODIGO, "001")
  expect_equal(datos$VALOR, "si")
})

test_that(".leer_zip_inei() rechaza ZIP sin CSV o con varios CSV", {
  dir_sin_csv <- nuevo_dir_temporal()
  writeLines("contenido", file.path(dir_sin_csv, "notas.txt"))
  expect_error(
    .leer_zip_inei(zip_dir(dir_sin_csv)),
    "No se encontro archivo CSV"
  )

  dir_varios <- nuevo_dir_temporal()
  writeLines(c("A", "1"), file.path(dir_varios, "uno.csv"))
  writeLines(c("B", "2"), file.path(dir_varios, "dos.csv"))
  expect_error(
    .leer_zip_inei(zip_dir(dir_varios)),
    "mas de un archivo CSV"
  )
})

test_that(".leer_zip_inei() informa un ZIP invalido", {
  archivo <- tempfile(fileext = ".zip")
  writeLines("esto no es un zip", archivo)
  expect_error(.leer_zip_inei(archivo), "no es un ZIP valido")
})

test_that("el cache conserva y valida la solicitud", {
  path <- tempfile(fileext = ".rds")
  solicitud <- .solicitud_cache(
    year = 2024,
    variante = "departamentos_anual",
    periodo = NULL,
    url = "https://example.org/2024.zip"
  )
  datos <- data.frame(id = "001", stringsAsFactors = FALSE)

  .guardar_cache(datos, path, solicitud)

  expect_equal(.leer_cache(path, solicitud), datos)

  otra_solicitud <- solicitud
  otra_solicitud$year <- 2023L
  expect_error(
    .leer_cache(path, otra_solicitud),
    "corresponde a otra descarga"
  )
})

test_that("descargar() reutiliza solo el cache de la solicitud actual", {
  path <- tempfile(fileext = ".rds")
  url <- .buscar_url(2024, "departamentos_anual", NULL)
  solicitud <- .solicitud_cache(
    year = 2024,
    variante = "departamentos_anual",
    periodo = NULL,
    url = url
  )
  datos <- data.frame(id = "001", stringsAsFactors = FALSE)
  .guardar_cache(datos, path, solicitud)

  expect_silent(resultado <- descargar(2024, destfile = path))
  expect_equal(resultado, datos)
  expect_error(
    descargar(2023, destfile = path),
    "corresponde a otra descarga"
  )
})

test_that("un cache antiguo no se reutiliza silenciosamente", {
  path <- tempfile(fileext = ".rds")
  saveRDS(data.frame(id = 1), path)
  solicitud <- .solicitud_cache(
    year = 2024,
    variante = "departamentos_anual",
    periodo = NULL,
    url = "https://example.org/2024.zip"
  )

  expect_error(
    .leer_cache(path, solicitud),
    "no contiene metadatos de cache compatibles"
  )
})

test_that(".guardar_cache() crea la carpeta de destino", {
  raiz <- tempfile("cache_")
  path <- file.path(raiz, "subcarpeta", "epen.rds")
  solicitud <- .solicitud_cache(
    year = 2024,
    variante = "departamentos_anual",
    periodo = NULL,
    url = "https://example.org/2024.zip"
  )

  .guardar_cache(data.frame(id = "001"), path, solicitud)

  expect_true(file.exists(path))
})

test_that(".buscar_url() identifica una unica publicacion anual", {
  url <- .buscar_url(2024, "departamentos_anual", NULL)
  expect_length(url, 1L)
  expect_match(url, "935-Modulo76[.]zip$")
  expect_error(
    .buscar_url(2024, "departamentos_anual", "Ene-Feb-Mar"),
    "solo se usa con.*lima_movil"
  )
})
