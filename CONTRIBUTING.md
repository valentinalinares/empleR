# Contribuir a empleR

Gracias por considerar una contribución. Son bienvenidos los reportes de
errores, mejoras de documentación, pruebas, ejemplos y propuestas de
código. `empleR` busca que el trabajo con la EPE y la EPEN sea
comprensible y reproducible, por lo que una buena explicación de una
fuente o de un caso límite también es una contribución valiosa.

## Antes de empezar

- Para un error o una idea nueva, abre un *issue* y describe el problema
  que quieres resolver. Las correcciones pequeñas de redacción pueden
  enviarse directamente como *pull request*.
- Revisa si ya existe un *issue* relacionado.
- No adjuntes microdatos reales, credenciales, rutas personales ni
  información que permita identificar personas u hogares. Para
  reproducir un problema, prepara el ejemplo sintético mínimo posible.
- Las propuestas deben respetar el [código de
  conducta](https://valentinalinares.github.io/CODE_OF_CONDUCT.md).

## Alcance actual

La versión 0.1.0 se concentra en la EPE y la EPEN del Perú. El núcleo
estable abarca descarga de EPEN, etiquetado, ocupaciones, homologación,
exposición a IA, cobertura, estimaciones puntuales y mapas de ámbitos
departamentales. La inferencia muestral continúa marcada como
experimental. El seguimiento longitudinal de personas y la ampliación a
otros países no forman parte del alcance actual.

Esta delimitación no impide proponer ideas. Sirve para que una
contribución no se presente como funcionalidad estable antes de contar
con fuentes, pruebas y una validación suficiente.

## Preparar el entorno

1.  Crea un *fork*, clona el repositorio y abre una rama con un nombre
    que describa el cambio.
2.  Usa R 4.1 o posterior. Instala las dependencias declaradas en
    `DESCRIPTION`.
3.  Instala el paquete localmente y ejecuta primero el ejemplo o la
    prueba que reproduce el problema.

Para cambios de código o documentación se usan, según corresponda:

``` r

testthat::test_local()
lintr::lint_package()
pkgdown::build_site()
```

Antes de enviar el *pull request*, construye el paquete y ejecuta
`R CMD check` o una comprobación equivalente con `rcmdcheck`. Si
modificaste comentarios de roxygen, regenera los archivos de `man/` y
`NAMESPACE`; no edites esos archivos generados a mano.

## Pruebas y datos

- Cada corrección funcional debe incluir una prueba que falle antes del
  cambio y pase después.
- Las pruebas habituales no deben depender de internet ni de archivos
  que solo existan en una computadora. Usa ZIP, CSV o data frames
  sintéticos mínimos.
- Las comprobaciones con microdatos oficiales pertenecen a `data-raw/` y
  deben registrar fuente, periodo, variables, procedimiento, resultado y
  límites.
- No incorpores bases reales al paquete. Los datos de ejemplo deben
  tener una licencia compatible o ser completamente sintéticos.
- Si cambias un dataset incluido, actualiza su generador, manifiesto,
  documentación y validación de reconstrucción. No edites solo el
  `.rda`.

## Pull requests

Procura que cada *pull request* tenga un objetivo definido. En la
descripción:

- explica qué problema resuelve y qué queda fuera;
- enlaza el *issue* correspondiente, si existe;
- indica qué pruebas y comprobaciones ejecutaste;
- distingue resultados sintéticos de validaciones con fuentes reales;
- documenta cambios de interfaz, resultados o supuestos metodológicos;
- declara cualquier uso sustantivo de asistentes de código y verifica
  personalmente el contenido propuesto.

La persona que envía la contribución es responsable de revisar su
exactitud, procedencia y licencia. Los asistentes automáticos no se
consideran autores.

## Reportar problemas de seguridad o conducta

No publiques información sensible en un *issue*. Los problemas de
conducta o seguridad que requieran reserva pueden enviarse a
<durgavalentinalinaresherrera@gmail.com>. Para los demás errores, usa
las plantillas públicas del repositorio.

## Reconocimiento

Las contribuciones se reconocerán según su naturaleza y magnitud. Antes
de agregar a una persona a `Authors@R` se solicitará su consentimiento y
se registrará el rol correspondiente.
