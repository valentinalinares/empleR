test_that(".leer_zip_inei() lee CSV separados por coma", {
  dir_csv <- nuevo_dir_temporal()
  writeLines(c("A,B,C", "1,2.5,3"), file.path(dir_csv, "modulo.csv"))
  zip_path <- zip_dir(dir_csv)
  datos <- .leer_zip_inei(zip_path)
  expect_equal(dim(datos), c(1L, 3L))
  expect_equal(datos$B, 2.5)
})

test_that(".leer_zip_inei() lee CSV separados por punto y coma", {
  dir_csv <- nuevo_dir_temporal()
  writeLines(c("A;B;C", "1;2,5;3"), file.path(dir_csv, "modulo.csv"))
  zip_path <- zip_dir(dir_csv)
  datos <- .leer_zip_inei(zip_path)
  expect_equal(dim(datos), c(1L, 3L))
  expect_equal(datos$B, 2.5)
})
