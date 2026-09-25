# Tabla de correspondencia CO-95 -\> CNO 2015 (todos los pares)

Los 604 pares CO-95 / CNO 2015 del anexo 1 del INEI. Un codigo CO-95
puede aparecer varias veces: **no unir microdatos directamente con esta
tabla**, porque se replicarian personas y factores de expansion. Para
eso usar
[co_1995](https://valentinalinares.github.io/empleR/reference/co_1995.md)
o [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
con `homologar = TRUE`.

## Usage

``` r
equivalencia_co95
```

## Format

Un `data.frame` con 604 filas y columnas:

- co95, nombre_co95:

  Codigo (3 digitos) y descripcion CO-95.

- cno2015, nombre_cno2015:

  Codigo (4 digitos) y descripcion CNO 2015.

- acuerdo_anexos:

  `"si"` si el par aparece en los anexos 1 y 2; `"solo_anexo1"` si no.

- n_cno_por_co95:

  Numero de destinos CNO 2015 del codigo CO-95.

- n_co95_por_cno:

  Numero de origenes CO-95 del codigo CNO 2015.

## Source

Ver
[co_1995](https://valentinalinares.github.io/empleR/reference/co_1995.md).
