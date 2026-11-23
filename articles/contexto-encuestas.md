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

Antes de comparar resultados de ambas encuestas, conviene revisar cuatro
aspectos:

1.  **Ámbito geográfico.** La EPE histórica representa Lima
    Metropolitana; la EPEN tiene cobertura nacional y dominios
    subnacionales.
2.  **Diseño y muestra.** Cambian la selección, el tamaño muestral, los
    factores de expansión y las variables necesarias para estimar la
    precisión.
3.  **Periodos de difusión.** Comprueba qué meses abarca cada resultado
    y si corresponde a un trimestre móvil, un trimestre calendario o un
    promedio anual.
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
información adicional asignaría una ocupación que los datos no permiten
determinar.

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
Con esa información puedes evaluar si conviene agrupar ocupaciones,
revisar casos individuales o excluirlos del análisis y explicar el
criterio usado.

``` r

co_1995[
  co_1995$estado == "multiples_destinos",
  c("co95", "nombre_co95", "cno2015_candidatos")
][1:3, ]
#>   co95                      nombre_co95 cno2015_candidatos
#> 1  011       Oficiales(Fuerzas Armadas)   0111; 0112; 0113
#> 2  012 T<U+00E9>cnicos(Fuerzas Armadas)   0311; 0312; 0313
#> 3  013   Sub-oficiales(Fuerzas Armadas)   0211; 0212; 0213
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

Una validación con los microdatos reales de octubre-diciembre encontró
un límite concreto. La EPE 2021 cubría 43 distritos de Lima y 6 del
Callao; la EPEN 2024 cubría 43 y 7, y su módulo 76 no ofrece distrito
para retirar el ámbito adicional. En esa misma prueba, solo 34,64 % de
la población ocupada EPE tuvo una correspondencia única al CNO 2015;
64,25 % tuvo destinos múltiples. Por ello, un promedio de exposición a
IA calculado únicamente entre las ocupaciones homologadas no representa
la misma composición que el de la EPEN. Estos porcentajes describen esas
entregas concretas y deben recalcularse para otros periodos.

## Fuentes oficiales

- INEI. [Ficha técnica de la EPE
  2001](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2001-31/Ficha-Tecnica-Epe-Oct.pdf).
- INEI. [Ficha técnica de la EPEN
  2022](https://www.inei.gob.pe/media/encuestas/documentos/epen/Ficha-Tecnica.pdf).
- INEI. [Ficha técnica de la EPE, octubre-diciembre de
  2021](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2021-45/Ficha_Tecnica.pdf).
- INEI. [Ficha técnica de la EPEN, octubre-diciembre de
  2024](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-45/Ficha_Tecnica.pdf).
- INEI. [Clasificador Nacional de Ocupaciones
  2015](https://www.inei.gob.pe/media/Clasificador_Nacional_de_Ocupaciones_2015_publicado.pdf).
- INEI. [Tablas de correspondencia
  CNO–CIUO–CO](https://www.inei.gob.pe/media/Tablas_de_correspondencia_CNO_CIUO_CO.xlsx).

## Relación con otras herramientas

En R ya existen herramientas para trabajar con encuestas peruanas, como
[`enaho`](https://cran.r-project.org/package=enaho), que cubre la ENAHO
y otras encuestas del INEI. `empleR` se concentra en la EPE y la EPEN y
en las correspondencias entre sus clasificadores ocupacionales. Como
antecedente internacional, [`eph`](https://packages.ropensci.org/eph)
organiza la Encuesta Permanente de Hogares de Argentina.

Por ahora, el desarrollo se concentra en las encuestas peruanas.
Incorporar otro país requeriría estudiar sus fuentes, clasificadores y
diseño muestral, y preparar ejemplos y validaciones específicos.
