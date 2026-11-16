# Fase 7: documentación, comunidad y preparación editorial

**Fecha:** 15 de noviembre de 2026
**Rama:** `docs/preparacion-ropensci`
**Punto de partida:** `2f00aca687650ab55a24d47a8b46c0a25c07d653`

## Alcance

Esta fase alinea la presentación pública de `empleR` con el alcance que quedó
implementado y comprobado en las fases anteriores. No modifica funciones,
datos empaquetados ni resultados estadísticos. Agrega documentos de comunidad,
metadatos de citación, procedencia institucional y plantillas para colaborar.

La revisión se hizo sobre las seis viñetas que existen actualmente. El plan
anterior hablaba de siete porque todavía contaba una guía de panel; esa
funcionalidad fue retirada del alcance estable y no corresponde recrear una
séptima viñeta solo para satisfacer un conteo desactualizado.

## Cambios editoriales y de comunidad

- `README.md` conserva la voz, los créditos y el ejemplo inicial elegidos por
  Valentina. Añade instrucciones de citación y enlaces a la guía de
  contribución y al código de conducta.
- `.github/CONTRIBUTING.md` delimita el alcance, explica cómo preparar cambios,
  exige pruebas y prohíbe adjuntar microdatos reales, rutas personales o
  información identificable.
- Se agregan plantillas para errores, propuestas y *pull requests*, además de
  un canal privado para asuntos de conducta o seguridad.
- `CODE_OF_CONDUCT.md` adopta los principios de Contributor Covenant 2.1 y del
  código de conducta de rOpenSci.
- El control de `pkgcheck` deja de tolerar fallos: al existir ya la guía de
  contribución, el flujo pasa a ser bloqueante.
- El sitio de pkgdown incorpora un acceso visible a la guía para contribuir.

## Autoría, fuentes y citación

`DESCRIPTION` conserva a Valentina Linares Herrera como autora y mantenedora
del paquete (`aut`, `cre`) y a Walter Omar Manky Bonilla como colaborador
(`ctb`) y autor del índice incorporado. No se agregó ningún ORCID porque no se
dispone de uno verificado; un identificador inventado o vacío sería peor que
su ausencia.

La descripción identifica al Instituto Nacional de Estadística e Informática
(INEI) como productor de la EPE y la EPEN y enlaza su Sistema de Microdatos.
La citación distingue tres productos:

1. `empleR`, cuya referencia corresponde a Valentina como autora del paquete;
2. el estudio y el índice de exposición a IA de Walter Omar Manky Bonilla;
3. los microdatos y documentos oficiales del INEI que use cada análisis.

`inst/CITATION` contiene las dos primeras referencias y explica cuándo usar
ambas. `CITATION.cff` permite a GitHub mostrar la referencia del software. El
archivo CFF se excluye del tarball de R mediante `.Rbuildignore`, porque R lo
considera un archivo en ubicación no estándar; permanece visible en GitHub y
`inst/CITATION` sigue incluido en el paquete.

El README declara de forma factual que se usaron asistentes de código para
apoyar revisión, pruebas y redacción, y que Valentina revisó y decidió el
contenido integrado. Esto se diferencia explícitamente del uso de Claude
Sonnet 4.6 como instrumento metodológico en la corrida de 2026 del índice.
Los asistentes no se presentan como autores y no se enlazan conversaciones
privadas.

## Coherencia del manual

Se revisaron y construyeron las seis viñetas actuales:

- introducción y recorrido general;
- manual de datos;
- manual de ocupaciones e índice de IA;
- manual de indicadores y mapas;
- referencia de funciones;
- nota metodológica sobre diseño muestral.

En conjunto cubren las nueve funciones exportadas: `catalogo()`,
`descargar()`, `etiquetar()`, `cno()`, `ia_exposicion()`, `cobertura()`,
`indicadores()`, `resumen_nacional()` y `mapa()`. Las referencias a panel se
mantienen solo donde se explica que fue retirado; provincia y distrito se
describen como niveles no admitidos; la descarga pública se presenta para
EPEN, mientras que los ejemplos de EPE requieren que la persona usuaria
aporte su base. La inferencia muestral se mantiene marcada como experimental.

## Revisión de ejemplos protegidos

`pkgcheck` informa cuatro funciones con `\\dontrun{}`: `descargar()`, `cno()`,
`ia_exposicion()` e `indicadores()`. No se retiró esa protección de forma
mecánica:

- `descargar()` realiza una operación de red contra una fuente externa;
- los bloques protegidos de las otras tres funciones usan una base EPE real
  que no se redistribuye con el paquete.

Cada función incluye antes un ejemplo sintético ejecutable. Por tanto, la
documentación comprueba la interfaz sin depender de internet ni de archivos
personales, y reserva `\\dontrun{}` para operaciones que no pueden ejecutarse
de manera autónoma durante `R CMD check`.

## Comprobaciones locales

Las comprobaciones se ejecutaron en Windows 11 con R 4.5.1.

| Comprobación | Resultado |
| --- | --- |
| Lectura de `DESCRIPTION` y archivos YAML | Correcta |
| Lectura de `inst/CITATION` | Dos referencias válidas |
| Pruebas unitarias de `testthat` | Aprobadas |
| `lintr::lint_package()` | Sin observaciones |
| Construcción completa de pkgdown | Aprobada; seis viñetas |
| `R CMD build` | Aprobada |
| `R CMD check --no-manual` | `Status: OK` |
| `pkgcheck` 0.3.4 | Sin errores ni advertencias de `R CMD check`; cobertura 87,9 % |

`pkgcheck` reconoce ahora `CONTRIBUTING`, el sitio, las viñetas, los ejemplos
y la cobertura. Su resumen local marca la comprobación de integración continua
porque la rama todavía no se había publicado al ejecutar el control; el
resultado remoto se registrará en el PR. También muestra recomendaciones no
bloqueantes: ORCID ausentes, coincidencia del nombre `mapa()` con otro paquete,
complejidad de algunas funciones, líneas extensas y uso justificado de
`\\dontrun{}`. La fase no inventa ORCID ni aplica refactorizaciones mecánicas
sin un defecto funcional demostrado.

Algunas señales de `goodpractice` ya se habían interpretado en la fase 6. En
particular, los supuestos argumentos duplicados son claves repetidas de
vectores de mensajes y no argumentos duplicados de llamadas; algunos helpers
se usan desde otros archivos o desde pruebas. Estas recomendaciones quedan
como insumo de mantenimiento, no como fallos de esta versión.

## Resultado y límites

La documentación pública, la interfaz y el alcance cuentan ahora la misma
historia. Quedan separados el paquete, el índice y las fuentes oficiales. La
fase no concede una licencia sobre microdatos, no convierte la inferencia
experimental en estable y no equivale a aceptación por rOpenSci.

Se preparó, por separado, un borrador de consulta editorial de alcance. No se
enviará ni publicará sin una decisión explícita de Valentina. Una versión o
DOI tampoco debe crearse antes de integrar esta rama y decidir que existe una
versión candidata.

## Fuentes de criterio

- [rOpenSci Packages: Development, Maintenance, and Peer Review — Packaging Guide](https://devguide.ropensci.org/pkg_building.html)
- [rOpenSci Packages — Collaboration Guide](https://devguide.ropensci.org/maintenance_collaboration.html)
- [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/)
- [Sistema de Microdatos del INEI](https://proyectos.inei.gob.pe/microdatos/)
- [Preguntas frecuentes del INEI](https://www.inei.gob.pe/preguntas-frecuentes/)
