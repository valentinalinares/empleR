# Tabla de correspondencia CO-95 -\> CNO 2015 (todos los pares)

Contiene los 604 pares CO-95 / CNO 2015 del anexo 1 del INEI. Un código
CO-95 puede aparecer varias veces. Para añadir correspondencias a los
microdatos, usa
[co_1995](https://valentinalinares.github.io/empleR/reference/co_1995.md)
o [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
con `homologar = TRUE`: unir directamente esta tabla duplicaría
registros y factores de expansión en los casos con varios destinos.

## Uso

``` r
equivalencia_co95
```

## Formato

Un `data.frame` con 604 filas y columnas:

- co95, nombre_co95:

  Código (3 dígitos) y descripción CO-95.

- cno2015, nombre_cno2015:

  Código (4 dígitos) y descripción CNO 2015.

- acuerdo_anexos:

  `"si"` si el par aparece en los anexos 1 y 2; `"solo_anexo1"` si no.

- n_cno_por_co95:

  Número de destinos CNO 2015 del código CO-95.

- n_co95_por_cno:

  Número de orígenes CO-95 del código CNO 2015.

## Fuente

Ver
[co_1995](https://valentinalinares.github.io/empleR/reference/co_1995.md).
