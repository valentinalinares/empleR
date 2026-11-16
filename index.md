# empleR

[![R-CMD-check](https://github.com/valentinalinares/empleR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/valentinalinares/empleR/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/valentinalinares/empleR/actions/workflows/lint.yaml/badge.svg)](https://github.com/valentinalinares/empleR/actions/workflows/lint.yaml)
[![test
coverage](https://codecov.io/gh/valentinalinares/empleR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/valentinalinares/empleR)
[![sitio
web](https://img.shields.io/badge/documentacion-pkgdown-2c7fb8)](https://valentinalinares.github.io/empleR/)

`empleR` reúne herramientas para trabajar en R con las encuestas de
empleo del Perú. Permite descargar datos de la EPEN, interpretar códigos
ocupacionales, calcular indicadores ponderados y explorar los resultados
en mapas. Está pensado para estudiantes de pregrado y posgrado,
docentes, investigadores y analistas que usan microdatos del INEI.

La primera versión cubre la **EPE** de Lima Metropolitana y la **EPEN**
nacional. Complementa la documentación del INEI, no la reemplaza, y por
ahora no busca abarcar encuestas de otros países.

## ¿Qué problema resuelve?

En 2022 no solo cambió el nombre de la encuesta. La EPE cubría Lima
Metropolitana y clasificaba las ocupaciones con el CO-95; la EPEN tiene
cobertura nacional y usa el CNO 2015. Por eso, si trabajas con años de
ambas encuestas, conviene revisar cómo se corresponden sus códigos.
`empleR` ayuda a documentar esas diferencias y a reconocer qué
correspondencias pueden establecerse y cuáles siguen siendo ambiguas.

La [documentación completa](https://valentinalinares.github.io/empleR/)
incluye ejemplos, resultados y una explicación de los cambios entre la
EPE y la EPEN.

## Instalación

``` r

pak::pak("valentinalinares/empleR")
```

## Un primer ejemplo

El paquete trae 2.000 registros completamente sintéticos con la
estructura de personas ocupadas de la EPEN 2024. Puedes correr los
ejemplos sin descargar archivos grandes y sin redistribuir registros de
personas reales.

``` r

library(empleR)

datos <- muestra_epen_2024 |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)

# Ingreso promedio por tipo de impacto de la IA
indicadores(datos, indicador = "ingreso_promedio", por = "ia_tipo")
```

### ¿Qué produce `mapa()`?

![Ejemplo de mapa departamental creado con
empleR](reference/figures/README-mapa.png)

Ejemplo de mapa departamental creado con empleR

La figura se construyó con datos sintéticos incluidos en el paquete; no
es una estimación oficial del INEI.

## Sobre el índice de exposición a IA

![Distribución del puntaje medio de exposición a IA entre ocupaciones
del CNO 2015](reference/figures/README-ia-distribucion.png)

Distribución del puntaje medio de exposición a IA entre ocupaciones del
CNO 2015

El índice asigna a cada ocupación del CNO 2015 un puntaje continuo entre
0 y 1. Mide la exposición potencial de sus tareas a la IA, no la
probabilidad de que ese empleo desaparezca. Con
[`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md)
puedes comprobar cuántos registros de tu base reciben un puntaje.

El índice fue desarrollado por Walter Omar Manky Bonilla, con asistencia
de investigación de Valentina Linares Herrera. Es una actualización del
estudio [*Doble desafío
tecnológico*](https://www.gob.pe/institucion/inei/informes-publicaciones/7453406-doble-desafio-tecnologico-analisis-de-la-exposicion-a-la-automatizacion-tradicional-y-a-la-inteligencia-artificial-generativa-en-el-empleo-peruano-utilizando-datos-de-la-enaho-2024),
publicado por el INEI en 2025. La corrida incluida en el paquete se hizo
en abril de 2026 con Claude Sonnet 4.6, y su paquete metodológico se
versionó el 15 de junio de 2026. Los nuevos puntajes no deben atribuirse
al INEI.

## Cómo citar

Si usas las funciones o los datos preparados por `empleR`, cita el
paquete con la referencia que devuelve:

``` r

citation("empleR")
```

Si además utilizas el índice de exposición a IA, cita también el estudio
de Walter Omar Manky Bonilla que aparece en esa salida e indica que
trabajaste con la actualización de abril de 2026 incluida en `empleR`.
Los microdatos y las cifras oficiales deben citarse por separado como
productos del INEI.

## Funciones principales

| Función | Para qué sirve |
|----|----|
| [`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md) | Consulta las fuentes, años, variantes y periodos procesados por el proyecto. |
| [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md) | Descarga el módulo de empleo e ingresos de la EPEN y permite guardarlo en caché. Por ahora solo funciona con la EPEN. |
| [`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md) | Añade categorías legibles a variables crudas o procesadas de la EPEN sin borrar sus códigos. |
| [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md) | Describe ocupaciones del CNO 2015 y homologa el CO-95 sin forzar los casos ambiguos. Conserva los candidatos y el estado de cada correspondencia. |
| [`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md) | Añade a cada ocupación su puntaje de exposición a IA. |
| [`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md) | Muestra cuántas observaciones, y cuánta población ponderada, tienen código, homologación y puntaje. |
| [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md) | Calcula ingreso y horas ponderados para la población ocupada y muestra los casos usados o excluidos. La inferencia es experimental y solo se calcula si se solicita. |
| [`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md) | Consulta indicadores nacionales precalculados y documentados. |
| [`mapa()`](https://valentinalinares.github.io/empleR/reference/mapa.md) | Muestra indicadores agregados para los 25 ámbitos departamentales oficiales de la EPEN. Distingue Lima Metropolitana y Callao de Región Lima. |

La función experimental `panel()` se retiró de esta versión: enlazar
viviendas u hogares entre periodos no basta para seguir a las mismas
personas, y esa validación sigue pendiente. El detalle está en
`NEWS.md`.

## Contexto y trabajo relacionado

`empleR` no es el primer paquete para microdatos del Perú.
[`enaho`](https://cran.r-project.org/package=enaho) descarga y combina
la ENAHO y otras encuestas del INEI. En Argentina,
[`eph`](https://packages.ropensci.org/eph) es un antecedente valioso
para trabajar con una encuesta continua de hogares de propósitos
múltiples, con un fuerte componente de mercado laboral.

Lo propio de `empleR` es su foco en la EPE y la EPEN, y en el paso del
CO-95 al CNO 2015. Mantiene visibles las correspondencias ambiguas y
permite vincular las ocupaciones con un índice peruano de exposición a
IA.

## Qué conviene tener en cuenta

- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
  trabaja solo con la EPEN. Para trabajar con la EPE, necesitas contar
  con los archivos históricos. La ENAHO aparece en
  [`catalogo()`](https://valentinalinares.github.io/empleR/reference/catalogo.md)
  como parte del inventario del proyecto, pero todavía no se puede
  descargar desde el paquete.
- [`etiquetar()`](https://valentinalinares.github.io/empleR/reference/etiquetar.md)
  cubre ocho conceptos documentados del módulo 76, entre ellos sexo,
  educación, condición de actividad, categoría ocupacional y área. Las
  demás variables crudas permanecen intactas hasta contar con un
  diccionario verificado.
- [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  usa el ingreso total proveniente del trabajo y las horas de todas las
  ocupaciones. Sus estimaciones puntuales se contrastaron con los
  microdatos y las cifras oficiales de 2022 a 2025. Los errores estándar
  se solicitan con `incluir_inferencia = TRUE`: la reconstrucción
  reproduce los CV publicados en los contrastes disponibles, pero sigue
  marcada como experimental porque no equivale a una especificación
  oficial completa.
- Antes de comparar EPE y EPEN, revisa `homologacion_estado` y
  [`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md).
  En la validación real de octubre-diciembre, solo 34,64 % de la
  población ocupada EPE tuvo una correspondencia única al CNO 2015.
  Además, la EPE 2021 y la EPEN 2024 difieren en un distrito del Callao
  y el módulo usado no permite igualar exactamente el territorio. El
  paquete no presenta esa diferencia como una tendencia temporal
  validada.
- La primera versión estable no incluye análisis longitudinales de
  personas ni encuestas de otros países.

## Desarrollo

El proyecto usa pruebas automatizadas, `R CMD check`, `lintr` y
`pkgdown`. Si quieres contribuir o reportar un problema, puedes abrir un
[issue en GitHub](https://github.com/valentinalinares/empleR/issues).
Antes de enviar código, consulta la [guía de
contribución](https://valentinalinares.github.io/empleR/CONTRIBUTING.md)
y el [código de
conducta](https://valentinalinares.github.io/empleR/CODE_OF_CONDUCT.md).

Durante el desarrollo se usaron asistentes de código para apoyar
revisiones, pruebas y redacción. Valentina revisó las propuestas, tomó
las decisiones y es responsable del contenido integrado. Estos
asistentes no son autores del paquete. Su uso es distinto de Claude
Sonnet 4.6 como instrumento metodológico en la corrida de 2026 del
índice de exposición a IA.
