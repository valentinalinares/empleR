# De la EPE a la EPEN: qué cambió y por qué importa

## Dos encuestas, no solo dos nombres

La Encuesta Permanente de Empleo (EPE) comenzó en 2001 para producir
indicadores frecuentes del mercado laboral de Lima Metropolitana y
Callao. Sus resultados se difundían principalmente mediante trimestres
móviles, una forma de reducir la variabilidad de estimaciones mensuales.

La Encuesta Permanente de Empleo Nacional (EPEN) amplió el estudio del
mercado laboral a todo el país. Su ficha técnica de 2022 define
cobertura nacional, departamental y de principales ciudades, además de
resultados mensuales, trimestrales y anuales según el indicador.

La transición implica al menos cuatro diferencias que una investigación
debe hacer explícitas:

1.  **Ámbito geográfico.** La EPE histórica representa Lima
    Metropolitana; la EPEN tiene cobertura nacional y dominios
    subnacionales.
2.  **Diseño y muestra.** Cambian la selección, el tamaño muestral, los
    factores de expansión y las variables necesarias para estimar la
    precisión.
3.  **Periodos de difusión.** Un trimestre móvil, un trimestre
    calendario y un promedio anual no son el mismo objeto estadístico.
4.  **Clasificador ocupacional.** La EPE usa CO-95 y la EPEN usa CNO
    2015.

Por estas razones, `empleR` no presenta EPE y EPEN como una única serie
lista para apilar. El paquete ayuda a identificar cada fuente y hace
visible la incertidumbre de las correspondencias ocupacionales.

## La ruptura CO-95–CNO 2015

El cambio relevante no ocurre todos los años. Es una ruptura estructural
entre el CO-95 de tres dígitos, utilizado por la EPE, y el CNO 2015 de
cuatro dígitos, utilizado por la EPEN desde 2022.

El INEI publica tablas de correspondencia, pero una correspondencia no
siempre es uno a uno. Un código antiguo puede dividirse entre varias
ocupaciones del nuevo clasificador. En esos casos, elegir un destino sin
información adicional crearía precisión falsa.

``` r

library(empleR)

table(co_1995$estado)
#> 
#>       discrepancia_fuente        multiples_destinos ocupacion_no_especificada 
#>                         8                       125                         1 
#>                     unica 
#>                       236
```

[`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
solo completa `cno_homologado` cuando el destino es único y consistente.
Para los demás casos conserva `cno_candidatos` y `homologacion_estado`.
Así la persona usuaria puede decidir si su análisis admite agregación a
gran grupo, exclusión documentada o una revisión caso por caso.

``` r

co_1995[
  co_1995$estado == "multiples_destinos",
  c("co95", "nombre_co95", "cno2015_candidatos")
][1:3, ]
#>   co95                    nombre_co95 cno2015_candidatos
#> 1  011     Oficiales(Fuerzas Armadas)   0111; 0112; 0113
#> 2  012      Técnicos(Fuerzas Armadas)   0311; 0312; 0313
#> 3  013 Sub-oficiales(Fuerzas Armadas)   0211; 0212; 0213
```

## Qué puede y qué no puede compararse

Una comparación entre años debe mantener constantes, o explicar, el
ámbito, el periodo, el universo, el factor y el nivel ocupacional.
Homologar el código es necesario, pero no resuelve por sí solo los demás
cambios de encuesta.

Antes de interpretar una tendencia se recomienda:

1.  separar EPE y EPEN y documentar sus ámbitos;
2.  revisar `homologacion_estado` y
    [`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md);
3.  comparar a un nivel ocupacional compatible;
4.  comprobar que el indicador y el periodo de referencia sean
    equivalentes;
5.  presentar por separado cualquier resultado sensible a casos sin
    factor o sin homologación.

## Fuentes oficiales

- INEI. [Ficha técnica de la EPE
  2001](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2001-31/Ficha-Tecnica-Epe-Oct.pdf).
- INEI. [Ficha técnica de la EPEN
  2022](https://www.inei.gob.pe/media/encuestas/documentos/epen/Ficha-Tecnica.pdf).
- INEI. [Clasificador Nacional de Ocupaciones
  2015](https://www.inei.gob.pe/media/Clasificador_Nacional_de_Ocupaciones_2015_publicado.pdf).
- INEI. [Tablas de correspondencia
  CNO–CIUO–CO](https://www.inei.gob.pe/media/Tablas_de_correspondencia_CNO_CIUO_CO.xlsx).

## Relación con otras herramientas

No corresponde presentar `empleR` como el primer paquete peruano de
microdatos. [`enaho`](https://cran.r-project.org/package=enaho) cubre
ENAHO y otras encuestas del INEI. La diferencia de `empleR` es su foco
en EPE/EPEN, la comparabilidad ocupacional y la auditoría de las
correspondencias CO-95–CNO 2015. Como antecedente internacional,
[`eph`](https://packages.ropensci.org/eph) organiza la Encuesta
Permanente de Hogares de Argentina.

Esta delimitación es intencional. Incorporar otro país requeriría
validar su encuesta, clasificadores, diseño y documentación como un
producto propio; por eso no forma parte del alcance de la primera
versión estable.
