# Descargar microdatos de la EPEN desde el portal del INEI

Descarga el modulo de Empleo e Ingresos de la Encuesta Permanente de
Empleo Nacional (EPEN) directamente desde el portal de microdatos del
INEI (<https://proyectos.inei.gob.pe/microdatos/>). Soporta cache local
para evitar descargas repetidas.

## Usage

``` r
descargar(
  year,
  variante = "departamentos_anual",
  periodo = NULL,
  destfile = NULL,
  quiet = TRUE
)
```

## Arguments

- year:

  Ano de la encuesta. EPEN disponible: 2022-2025. Ver
  [`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md)
  para la lista completa.

- variante:

  Variante de la encuesta:

  - `"departamentos_anual"` (por defecto): EPEN nacional anual.

  - `"lima_movil"`: EPEN Lima Metropolitana, trimestres moviles.

- periodo:

  Para `variante = "lima_movil"`, el periodo a descargar. Usar el label
  exacto del catalogo, e.g. `"Trimestre Movil -(Ene-Feb-Mar)"`. Ver
  [`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md)
  para la lista completa de periodos disponibles.

- destfile:

  Ruta local donde cachear el resultado como `.rds`. Si el archivo ya
  existe, se usa la version en cache sin descargar. Si es `NULL` (por
  defecto), descarga sin guardar cache permanente.

- quiet:

  Logico. Si `TRUE` (por defecto), suprime mensajes de progreso.

## Value

Un `data.frame` con los microdatos crudos del modulo de Empleo e
Ingresos de la EPEN. Las columnas siguen la nomenclatura original del
INEI (e.g. `C308_COD`, `FACTOR07`, `ESTRATO`, `CONGLOME`). Usar
[`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
para aplicar etiquetas de valor y
[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
para agregar descripciones de ocupaciones.

**A diferencia de
[muestra_epen_2024](https://valentinalinares.github.io/empleR/reference/muestra_epen_2024.md),
estos datos incluyen todos los estados laborales**: ocupados,
desocupados abiertos, desocupados ocultos e inactivos. La variable
`OCA500` (o equivalente) indica el estado laboral de cada persona, lo
que permite calcular tasas de desempleo y actividad.

## Examples

``` r
if (FALSE) { # \dontrun{
# Descargar EPEN 2024 departamentos (nivel nacional)
epen_2024 <- descargar(year = 2024)

# Con cache: si el archivo existe, no vuelve a descargar
epen_2024 <- descargar(
  year = 2024,
  destfile = "datos/epen_2024.rds"
)

# Ver que periodos estan disponibles para lima_movil 2024
catalogo(fuente = "EPEN", variante = "lima_movil", year = 2024)

# Descargar un trimestre movil de Lima
lima_ene <- descargar(
  year    = 2024,
  variante = "lima_movil",
  periodo  = "Trimestre Movil -(Ene-Feb-Mar)"
)
} # }
```
