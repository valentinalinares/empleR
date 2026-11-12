# Manual de empleR

Este manual explica cómo pasar de los archivos del INEI a resultados que
se puedan interpretar y reproducir. Está organizado por tareas para que
puedas seguir un flujo completo o ir directamente a la función que
necesitas.

[1 **Encontrar y preparar datos** `catalogo()`, `descargar()` y
`etiquetar()`](https://valentinalinares.github.io/empleR/articles/manual-datos.md)
[2 **Trabajar con ocupaciones e IA** `cno()`, `ia_exposicion()` y
`cobertura()`](https://valentinalinares.github.io/empleR/articles/manual-ocupaciones-ia.md)
[3 **Calcular y visualizar resultados** `indicadores()`,
`resumen_nacional()` y
`mapa()`](https://valentinalinares.github.io/empleR/articles/manual-indicadores-mapas.md)

## El recorrido general

Un análisis típico combina las funciones en este orden:

``` text
catalogo() → descargar() → etiquetar() → cno()
                                      ↓
                           ia_exposicion() → cobertura()
                                      ↓
                              indicadores() → mapa()
```

No todos los análisis necesitan cada paso. Por ejemplo, puedes consultar
los indicadores nacionales incluidos en el paquete con
[`resumen_nacional()`](https://valentinalinares.github.io/empleR/reference/resumen_nacional.md)
sin descargar una base completa.

## Qué encontrarás en cada ficha

Cada función se presenta con la misma estructura:

1.  **Para qué sirve:** el problema que resuelve.
2.  **Qué recibe:** los datos y argumentos principales.
3.  **Qué hace:** las transformaciones que aplica, explicadas sin entrar
    en el código interno.
4.  **Qué devuelve:** las columnas u objetos que produce.
5.  **Ejemplo reproducible:** código que puedes adaptar a tu análisis.
6.  **Cómo leer el resultado:** qué significa la salida y qué límites
    debes considerar.

La sección **Referencia** del sitio contiene la documentación técnica
completa de cada función. Allí puedes consultar todos sus argumentos,
valores posibles y mensajes de error.

## Antes de comparar EPE y EPEN

La EPE y la EPEN difieren en cobertura territorial, diseño, periodos de
difusión y clasificador ocupacional. El manual muestra cómo procesar
cada una, pero ninguna función convierte automáticamente ambas encuestas
en una única serie comparable. La guía [De la EPE a la
EPEN](https://valentinalinares.github.io/empleR/articles/contexto-encuestas.md)
explica qué cambió y qué decisiones debes documentar.
