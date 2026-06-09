# =============================================================================
# Preparacion de shapes pre-computados para mapa()
# =============================================================================
# Genera shapes_departamentos y shapes_provincias usando GEOS (sf_use_s2(FALSE))
# para evitar errores de geometrias invalidas en geoperu::peru.
#
# Ejecutar con: source("data-raw/01_preparar_shapes.R")
# desde el directorio raiz del paquete empleR/
# =============================================================================

library(sf)
library(dplyr)

# Usar motor GEOS (no s2) para evitar errores con geometrias invalidas
sf::sf_use_s2(FALSE)

cat("Cargando geoperu::peru (1874 distritos)...\n")
peru_raw <- geoperu::peru
cat("Columnas:", names(peru_raw), "\n")
cat("CRS:", sf::st_crs(peru_raw)$input, "\n")

# Reparar geometrias invalidas antes de agregar
cat("Reparando geometrias invalidas...\n")
peru_valido <- sf::st_make_valid(peru_raw)

# ---- Nivel departamento (25) ------------------------------------------------
cat("\nAgregando a nivel departamento...\n")
shapes_departamentos <- peru_valido |>
  group_by(departamento) |>
  summarise(geometry = sf::st_union(geometry), .groups = "drop") |>
  # Nombres en mayusculas (como en geoperu)
  mutate(departamento = toupper(departamento)) |>
  arrange(departamento)

cat("shapes_departamentos:", nrow(shapes_departamentos), "departamentos\n")
cat("Validas:", all(sf::st_is_valid(shapes_departamentos)), "\n")

save(shapes_departamentos,
     file = "data/shapes_departamentos.rda",
     compress = "bzip2")
cat("Guardado: data/shapes_departamentos.rda (",
    round(file.size("data/shapes_departamentos.rda") / 1024, 1), "KB)\n")


# ---- Nivel provincia (196) --------------------------------------------------
cat("\nAgregando a nivel provincia...\n")
shapes_provincias <- peru_valido |>
  group_by(departamento, provincia) |>
  summarise(geometry = sf::st_union(geometry), .groups = "drop") |>
  mutate(
    departamento = toupper(departamento),
    provincia    = toupper(provincia)
  ) |>
  arrange(departamento, provincia)

cat("shapes_provincias:", nrow(shapes_provincias), "provincias\n")
cat("Validas:", all(sf::st_is_valid(shapes_provincias)), "\n")

save(shapes_provincias,
     file = "data/shapes_provincias.rda",
     compress = "bzip2")
cat("Guardado: data/shapes_provincias.rda (",
    round(file.size("data/shapes_provincias.rda") / 1024, 1), "KB)\n")

# Restaurar s2 si se desea
# sf::sf_use_s2(TRUE)

cat("\nListo! Shapes pre-computados disponibles en data/\n")
