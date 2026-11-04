# Corrige occupation_code_4d en data/muestra_epen_2024.rda.
# Ejecutar desde la raiz del paquete.
#
# En la base procesada de origen, los codigos CNO de 3 digitos (Fuerzas
# Armadas, gran grupo 0) se completaron con un cero a la derecha
# (211 -> "2110") en vez de a la izquierda (211 -> "0211"). Esos codigos no
# existen en el CNO 2015. Se recalcula occupation_code_4d desde
# occupation_code_raw; en la muestra solo cambian 20 filas (211, 220, 311 y
# 312). El mismo defecto afecta a la base procesada completa
# (epen_persona_departamentos_anual_2022_2025.csv.gz): 00_preparar_datasets.R
# ya aplica esta correccion al regenerar la muestra.

load(file.path("data", "muestra_epen_2024.rda"))

raw <- trimws(as.character(muestra_epen_2024$occupation_code_raw))
valido <- grepl("^[0-9]{1,4}$", raw)
nuevo <- ifelse(valido, formatC(suppressWarnings(as.integer(raw)), width = 4, flag = "0"), NA_character_)

cambian <- which(nuevo != muestra_epen_2024$occupation_code_4d)
cat("Filas corregidas:", length(cambian), "\n")
print(table(paste(muestra_epen_2024$occupation_code_4d[cambian], "->", nuevo[cambian])))
stopifnot(all(substr(nuevo[cambian], 1, 1) == "0"))

muestra_epen_2024$occupation_code_4d <- nuevo
save(muestra_epen_2024, file = file.path("data", "muestra_epen_2024.rda"), compress = "bzip2")
