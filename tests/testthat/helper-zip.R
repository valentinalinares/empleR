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
