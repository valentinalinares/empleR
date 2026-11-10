# Helpers para crear ZIP de prueba sin dependencias adicionales

nuevo_dir_temporal <- function() {
  dir <- tempfile("csv_")
  dir.create(dir)
  dir
}

zip_dir <- function(dir) {
  skip_if(Sys.which("zip") == "", "zip no esta disponible")
  zip_path <- tempfile(fileext = ".zip")
  old <- setwd(dir)
  on.exit(setwd(old))
  utils::zip(zip_path, files = list.files(dir), flags = "-q")
  zip_path
}

zip_con_nombre_utf8 <- function() {
  skip_if_not_installed("jsonlite")
  contenido <- paste0(
    "UEsDBBQAAAgIANxral1Qkd3WFgAAABQAAAAVAAAAUHVibGljYWNpw7NuIEVQRU4u",
    "Y3N2c/Z38XT3tw5z9PEP4jIwMLQuzuQCAFBLAQIUABQAAAgIANxral1Qkd3WFg",
    "AAABQAAAAVAAAAAAAAAAAAAAAAAAAAAABQdWJsaWNhY2nDs24gRVBFTi5jc3ZQ",
    "SwUGAAAAAAEAAQBDAAAASQAAAAAA"
  )
  path <- tempfile(fileext = ".zip")
  writeBin(jsonlite::base64_dec(contenido), path)
  path
}
