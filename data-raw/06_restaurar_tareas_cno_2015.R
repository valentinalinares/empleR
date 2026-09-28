# Restaura tareas faltantes en data/cno_2015.rda.
# Ejecutar desde la raiz del paquete, despues de 04_corregir_cno_2015.R.
#
# 5223 (Asistentes de venta de tiendas y almacenes): sus tres tareas estaban
# vacias en cno_2015, pero figuran en indice_ia$tasks_and_classifications y
# coinciden con el PDF oficial del CNO 2015 (verificado con el PDF). Se copian
# solo los textos; indice_ia y sus scores no se modifican.
#
# 5321 (Trabajadores en el cuidado de personas en instituciones): sus cuatro
# tareas estan en la p. 242 impresa del PDF oficial del CNO 2015 del INEI.
# Se incorporan desde data-raw/cno_2015_tareas_5321.txt (una tarea por linea,
# transcrita del PDF) si ese archivo existe. 5321 no esta en indice_ia: no
# tiene score ni tipo de impacto, y no se toman de 5322 ni 5329.

load(file.path("data", "cno_2015.rda"))
load(file.path("data", "indice_ia.rda"))

.asignar_tareas <- function(cno, codigo, tareas) {
  i <- which(cno$codigo == codigo)
  stopifnot(length(i) == 1, length(tareas) > 0, !anyNA(tareas), all(nzchar(tareas)))
  cno$tasks[i] <- paste(tareas, collapse = "\r\n")
  cno$tasks_clean[i] <- paste(tareas, collapse = " ")
  cno
}

# 5223: textos de indice_ia sin el sufijo " -> score: ..., tipo: ..."
lineas <- strsplit(indice_ia$tasks_and_classifications[indice_ia$code == "5223"], "\n", fixed = TRUE)[[1]]
tareas_5223 <- trimws(sub(" -> score: .*$", "", lineas))
stopifnot(length(tareas_5223) == indice_ia$total_tasks[indice_ia$code == "5223"])
cno_2015 <- .asignar_tareas(cno_2015, "5223", tareas_5223)

# 5321: solo desde la transcripcion del PDF oficial
archivo_5321 <- file.path("data-raw", "cno_2015_tareas_5321.txt")
if (file.exists(archivo_5321)) {
  tareas_5321 <- trimws(readLines(archivo_5321, encoding = "UTF-8"))
  tareas_5321 <- tareas_5321[nzchar(tareas_5321) & !startsWith(tareas_5321, "#")]
  stopifnot(length(tareas_5321) == 4L)
  cno_2015 <- .asignar_tareas(cno_2015, "5321", tareas_5321)
} else {
  message("Sin ", archivo_5321, ": las tareas de 5321 siguen en NA.")
}

stopifnot(!"5321" %in% indice_ia$code)
save(cno_2015, file = file.path("data", "cno_2015.rda"), compress = "bzip2")
