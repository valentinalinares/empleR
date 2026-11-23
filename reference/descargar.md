# Descargar microdatos de la EPEN desde el portal del INEI

Descarga el módulo de Empleo e Ingresos de la Encuesta Permanente de
Empleo Nacional (EPEN) directamente desde el portal de microdatos del
INEI (<https://proyectos.inei.gob.pe/microdatos/>). Permite guardar una
copia local para evitar descargas repetidas.

## Uso

``` r
descargar(
  year,
  variante = "departamentos_anual",
  periodo = NULL,
  destfile = NULL,
  quiet = TRUE
)
```

## Argumentos

- year:

  Año de la encuesta. Los años disponibles dependen de la variante; ver
  [`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md)
  para la lista actual.

- variante:

  Variante de la encuesta:

  - `"departamentos_anual"` (por defecto): EPEN nacional anual.

  - `"lima_movil"`: EPEN Lima Metropolitana, trimestres móviles.

- periodo:

  Para `variante = "lima_movil"`, el periodo a descargar. Usar el label
  exacto del catálogo, e.g. `"Trimestre Movil -(Ene-Feb-Mar)"`. Ver
  [`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md)
  para la lista completa de periodos disponibles.

- destfile:

  Ruta local donde guardar el resultado como `.rds`. Si el archivo ya
  existe, se usa la versión en caché solamente cuando corresponde a la
  misma encuesta, variante, año, periodo y URL. Los archivos de caché
  creados por versiones anteriores, que no guardaban esta información,
  no se reutilizan automáticamente. Si es `NULL` (por defecto), descarga
  sin guardar caché permanente.

- quiet:

  Lógico. Si `TRUE` (por defecto), suprime mensajes de progreso.

## Valor

Un `data.frame` con los microdatos crudos del módulo de Empleo e
Ingresos de la EPEN. Las columnas siguen la nomenclatura original del
INEI (e.g. `C308_COD`, `FAC300_ANUAL`, `ESTRATO`, `CONGLOMERADO`). Para
conservar códigos y ceros iniciales, todas las columnas se leen como
texto; los campos vacios y el texto `NA` se devuelven como valores
faltantes. Usar
[`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
para aplicar etiquetas de valor y
[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
para agregar descripciones de ocupaciones.

**A diferencia de
[muestra_epen_2024](https://valentinalinares.github.io/empleR/reference/muestra_epen_2024.md),
estos datos incluyen todos los estados laborales**: ocupados,
desocupados abiertos, desocupados ocultos e inactivos. La variable
`OCUP300` (o equivalente) indica el estado laboral de cada persona, lo
que permite calcular tasas de desempleo y actividad.

## Ejemplos

``` r
if (FALSE) { # \dontrun{
# Descargar EPEN 2024 departamentos (nivel nacional)
epen_2024 <- descargar(year = 2024)

# Con caché: si el archivo existe, no vuelve a descargar
epen_2024 <- descargar(
  year = 2024,
  destfile = "datos/epen_2024.rds"
)

# Ver que periodos están disponibles para lima_movil 2024
catalogo(fuente = "EPEN", variante = "lima_movil", year = 2024)

# Descargar un trimestre móvil de Lima
lima_ene <- descargar(
  year    = 2024,
  variante = "lima_movil",
  periodo  = "Trimestre Movil -(Ene-Feb-Mar)"
)
} # }
```
