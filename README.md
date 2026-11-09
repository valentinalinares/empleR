# empleR

[![R-CMD-check](https://github.com/valentinalinares/empleR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/valentinalinares/empleR/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/valentinalinares/empleR/actions/workflows/lint.yaml/badge.svg)](https://github.com/valentinalinares/empleR/actions/workflows/lint.yaml)
[![sitio web](https://img.shields.io/badge/documentacion-pkgdown-2c7fb8)](https://valentinalinares.github.io/empleR/)

`empleR` facilita el trabajo reproducible con las encuestas de empleo del
Perú. Está pensado para estudiantes de pregrado y posgrado, docentes,
investigadores y analistas que usan R y necesitan pasar de los archivos del
INEI a ocupaciones comparables e indicadores documentados.

La primera versión se concentra en la **EPE** de Lima Metropolitana y la
**EPEN** nacional. No intenta reemplazar la documentación del INEI ni ofrecer
una infraestructura genérica para todos los países.

## ¿Qué problema resuelve?

En 2022 no solo cambió el nombre de la encuesta. La EPE estudiaba Lima
Metropolitana y empleaba el clasificador ocupacional CO-95; la EPEN amplió la
cobertura nacional y usa el CNO 2015. Por eso una serie no se vuelve comparable
simplemente uniendo años.

`empleR` documenta esa ruptura y permite:

- consultar y descargar entregas de la EPEN;
- aplicar etiquetas legibles a variables procesadas;
- describir ocupaciones del CNO 2015;
- homologar CO-95 a CNO 2015 sin asignar a la fuerza los casos ambiguos;
- incorporar el índice ocupacional de exposición a IA y auditar su cobertura;
- obtener resúmenes e indicadores ponderados;
- representar resultados departamentales en mapas estáticos o interactivos.

La [documentación completa](https://valentinalinares.github.io/empleR/)
incluye ejemplos, resultados y una explicación de los cambios entre EPE y
EPEN.

## Instalación

```r
pak::pak("valentinalinares/empleR")
```

## Un ejemplo completo

El paquete incluye una muestra de 2.000 personas ocupadas de la EPEN 2024 para
que los ejemplos puedan ejecutarse sin descargar archivos grandes.

```r
library(empleR)

datos <- muestra_epen_2024 |>
  cno() |>
  ia_exposicion(score = "ambos", incluir_tipo = TRUE)

# Ingreso promedio por tipo de impacto de la IA
indicadores(datos, indicador = "ingreso_promedio", por = "ia_tipo")
```

### ¿Qué puntajes contiene el índice?

![Distribución del puntaje medio de exposición a IA entre ocupaciones del CNO 2015](man/figures/README-ia-distribucion.png)

El puntaje es continuo y va de 0 a 1. Describe exposición potencial de las
tareas de una ocupación, no la probabilidad de que desaparezca el empleo.

### ¿Qué produce `mapa()`?

![Ejemplo de mapa departamental creado con empleR](man/figures/README-mapa.png)

La figura es un ejemplo construido con la muestra incluida en el paquete; no
es una estimación oficial del INEI.

## Funciones del núcleo

| Función | Para qué sirve |
|---|---|
| `catalogo()` | Consulta fuentes, años, variantes y periodos procesados por el proyecto. |
| `descargar()` | Descarga el módulo de empleo e ingresos de la EPEN y permite guardarlo en caché. |
| `etiquetar()` | Convierte códigos de bases procesadas en categorías legibles. |
| `cno()` | Describe CNO 2015 y homologa CO-95, conservando candidatos y estados de correspondencia. |
| `ia_exposicion()` | Añade puntajes continuos de exposición a IA por ocupación. |
| `cobertura()` | Mide cuántas observaciones y cuánto peso tienen código, homologación y puntaje. |
| `indicadores()` | Calcula ingreso y horas ponderados; los errores estándar deben tratarse como provisionales. |
| `resumen_nacional()` | Consulta indicadores nacionales precalculados y documentados. |
| `mapa()` | Visualiza indicadores agregados; el nivel departamental es el recorrido recomendado. |

`panel()` se conserva como una herramienta **experimental** para auditar
viviendas u hogares repetidos. No identifica por sí sola a la misma persona y
no forma parte del recorrido recomendado de la primera versión estable.

## Contexto y trabajo relacionado

`empleR` no es el primer paquete para microdatos del Perú. Por ejemplo,
[`enaho`](https://cran.r-project.org/package=enaho) descarga y combina ENAHO y
otras encuestas del INEI. En Argentina,
[`eph`](https://packages.ropensci.org/eph) ofrece un antecedente valioso para
trabajar con una encuesta laboral permanente.

El aporte específico de `empleR` es concentrarse en EPE/EPEN y en la ruptura
CO-95–CNO 2015, manteniendo visibles las correspondencias ambiguas y
permitiendo vincular ocupaciones con un índice peruano de exposición a IA.

El índice fue desarrollado por Walter Omar Manky Bonilla, con asistencia de
investigación de Valentina Linares Herrera. La corrida incluida en el paquete
se realizó en abril de 2026 con Claude Sonnet 4.6 y su paquete metodológico fue
versionado el 15 de junio de 2026. Es una actualización del estudio
[*Doble desafío tecnológico*](https://www.gob.pe/institucion/inei/informes-publicaciones/7453406-doble-desafio-tecnologico-analisis-de-la-exposicion-a-la-automatizacion-tradicional-y-a-la-inteligencia-artificial-generativa-en-el-empleo-peruano-utilizando-datos-de-la-enaho-2024),
publicado por el INEI en 2025; los nuevos puntajes no deben atribuirse al INEI.

## Alcance actual

- `descargar()` trabaja con entregas EPEN; una base EPE histórica debe ser
  aportada por la persona usuaria. Las entradas ENAHO de `catalogo()` describen
  el inventario del proyecto, pero aún no tienen descarga automática aquí.
- `etiquetar()` reconoce los nombres comunes de las bases procesadas. No
  renombra automáticamente todas las variables crudas del módulo 76.
- `indicadores()` produce estimaciones ponderadas. La reconstrucción del diseño
  permite errores estándar reproducibles, pero todavía no equivalentes a los
  errores oficiales del INEI.
- Los análisis longitudinales de personas y la ampliación a otros países se
  dejan fuera de la primera versión estable.

## Desarrollo

El proyecto usa pruebas automatizadas, `R CMD check`, `lintr` y `pkgdown`.
Para contribuir o reportar un problema, utiliza
[GitHub Issues](https://github.com/valentinalinares/empleR/issues).
