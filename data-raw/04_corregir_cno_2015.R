# Corrige data/cno_2015.rda: agrega el grupo primario CNO 5321.
# Ejecutar desde la raiz del paquete, despues de 00_preparar_datasets.R.
#
# Problema: al extraer el clasificador, el titulo del grupo primario 5321
# ("Trabajadores en el cuidado de personas en instituciones", CNO 2015,
# p. 242) quedo pegado a la descripcion del subgrupo 532 y la fila 5321 no se
# creo. Resultado: 472 grupos primarios en vez de 473.
#
# Fuentes del codigo y el nombre:
# - Clasificador Nacional de Ocupaciones 2015 (INEI), p. 242.
# - Tablas de correspondencia del INEI (hojas CNO2015_CO95 y
#   CNO2015_CIUO2008), donde 5321 aparece con ese nombre.
#
# La descripcion extendida y las tareas de 5321 NO se incluyen: estan en la
# p. 242 del PDF oficial y deben copiarse desde ahi. No se completan con
# textos de otros clasificadores. Hasta entonces quedan en NA y la ocupacion
# no tiene score en indice_ia.

load(file.path("data", "cno_2015.rda"))
load(file.path("data", "equivalencia_co95.rda"))

nombre_5321 <- "Trabajadores en el cuidado de personas en instituciones"
nombre_532 <- "Trabajadores en el cuidado de personas en servicios de salud"

stopifnot(identical(
  unique(equivalencia_co95$nombre_cno2015[equivalencia_co95$cno2015 == "5321"]),
  nombre_5321
))

i532 <- which(cno_2015$codigo == "532")
stopifnot(length(i532) == 1)
if (cno_2015$descripcion[i532] == paste(nombre_532, nombre_5321)) {
  cno_2015$descripcion[i532] <- nombre_532
}

if (!"5321" %in% cno_2015$codigo) {
  fila <- cno_2015[i532, ]
  fila$codigo <- "5321"
  fila$descripcion <- nombre_5321
  fila$nivel <- 4L
  fila$descripcion_extendida <- NA_character_
  fila$tasks <- NA_character_
  fila$tasks_clean <- NA_character_
  cno_2015 <- rbind(cno_2015[seq_len(i532), ], fila, cno_2015[-seq_len(i532), ])
}

stopifnot(
  !anyDuplicated(cno_2015$codigo),
  sum(cno_2015$nivel == 4) == 473L,
  setequal(cno_2015$codigo[cno_2015$nivel == 4], unique(equivalencia_co95$cno2015))
)
rownames(cno_2015) <- NULL

save(cno_2015, file = file.path("data", "cno_2015.rda"), compress = "bzip2")
