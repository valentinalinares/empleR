# Borrador de consulta de alcance para rOpenSci

**Fecha:** 15 de noviembre de 2026
**Estado:** borrador interno; no enviado

## Presentación breve

`empleR` es un paquete en R orientado a estudiantes, investigadoras e
investigadores y analistas que trabajan con las encuestas laborales del Perú.
Busca reducir el trabajo repetitivo y propenso a errores necesario para
localizar, descargar, leer, etiquetar y armonizar la Encuesta Permanente de
Empleo Nacional (EPEN) y su antecesora, la Encuesta Permanente de Empleo
(EPE).

El paquete está escrito y documentado principalmente en español. Su versión
actual se limita al Perú y no intenta ofrecer una interfaz común para otros
países.

## Núcleo propuesto para revisión

El núcleo estable comprende:

- consulta del catálogo y descarga reproducible de archivos públicos de EPEN;
- lectura que conserva códigos crudos, ceros iniciales y procedencia;
- etiquetado de variables mediante diccionarios documentados;
- armonización de clasificadores ocupacionales CO-95 y CNO 2015;
- cálculo de estimaciones puntuales ponderadas con universos explícitos;
- diagnóstico de cobertura del índice ocupacional;
- mapas para los ámbitos departamentales que la EPEN permite identificar.

Las pruebas habituales son sintéticas y no dependen de internet ni de
microdatos personales. Las validaciones con fuentes oficiales se registran
fuera del paquete instalado.

## Componentes que no definen el núcleo

La inferencia mediante diseño muestral se conserva como experimental porque
la documentación pública no permite reconstruir con certeza todos los
componentes necesarios para prometer errores estándar oficiales. No se
presenta como resultado estable ni es necesaria para usar el flujo principal.

El cruce con un índice peruano de exposición ocupacional a inteligencia
artificial es una integración opcional. El índice es de Walter Omar Manky
Bonilla y se cita por separado; no convierte al paquete en un producto del
INEI ni en un paquete dedicado exclusivamente a IA.

El seguimiento longitudinal de personas, la geografía distrital o provincial
y la ampliación a otros países quedaron fuera del alcance actual.

## Antecedentes y diferenciación

Existen paquetes valiosos para encuestas de hogares y laborales en otros
países, entre ellos `eph` para la Encuesta Permanente de Hogares de Argentina
y herramientas para ENAHO en el Perú. `empleR` se diferencia por concentrarse
en la transición EPE–EPEN, sus diccionarios y clasificadores ocupacionales,
con controles específicos para las fuentes públicas del INEI.

## Pregunta editorial propuesta

¿Un paquete cuyo núcleo es el acceso reproducible, etiquetado, armonización y
procesamiento de microdatos públicos de EPE y EPEN se encuentra dentro del
alcance de revisión de rOpenSci, aun cuando incluya como módulos opcionales un
índice ocupacional externo y una interfaz de inferencia claramente marcada
como experimental?

En caso afirmativo, ¿recomendarían excluir por completo la inferencia
experimental antes del envío, o basta con mantenerla fuera de la promesa
estable, con documentación explícita y pruebas de sus límites?

## Estado técnico para acompañar la consulta

- R 4.1 o posterior, comprobado en Linux, Windows y macOS;
- `R CMD check` sin errores ni advertencias;
- cobertura aproximada de 88 %;
- sitio de pkgdown con seis guías y referencia completa;
- guía de contribución, código de conducta, plantillas y citación;
- datos de ejemplo sintéticos; no se redistribuyen microdatos reales;
- procedencia y límites metodológicos documentados.

Este texto debe actualizarse con la URL del commit o versión candidata antes
de enviarse. La consulta solo se enviará después de una decisión explícita de
Valentina.
