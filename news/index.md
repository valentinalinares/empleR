# Changelog

## empleR 0.1.0

### Homologacion EPE (CO-95) y EPEN (CNO 2015)

- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  homologa CO-95 -\> CNO 2015 con la tabla oficial del INEI (`co_1995`,
  `equivalencia_co95`). Solo asigna un codigo cuando la equivalencia es
  unica; los casos ambiguos quedan en `NA` con `cno_candidatos`,
  `cno_gran_grupo` y `homologacion_estado`.
- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  detecta el clasificador por la encuesta (`source`) o por los anos de
  todas las filas, rechaza bases que mezclan periodos, acepta el
  argumento `clasificador` y reconoce la variable ano con distintos
  nombres y codificaciones (incluido `AÑO`).
- [`cno()`](https://valentinalinares.github.io/empleR/reference/cno.md)
  usa el codigo original (`C308_COD`, `P204A`, `occupation_code_raw`)
  completado con ceros a la izquierda; si `occupation_code_4d` no
  coincide, marca la fila en `cno_discrepancia_4d`.

### Exposicion a IA y cobertura

- [`ia_exposicion()`](https://valentinalinares.github.io/empleR/reference/ia_exposicion.md)
  usa `cno_homologado` en las filas EPE y rechaza codigos CO-95 o
  agregados. Agrega `ia_cno` e `ia_cobertura`.
- `ia_tipo` queda en `NA` cuando hay empate (`ia_empate = TRUE`);
  `ia_tipo_estado` distingue predominante, empate, sin tareas y sin
  indice.
- Nueva funcion
  [`cobertura()`](https://valentinalinares.github.io/empleR/reference/cobertura.md):
  cobertura de homologacion y score por encuesta y ano, en observaciones
  y poblacion ponderada.

### Diseno muestral

- [`indicadores()`](https://valentinalinares.github.io/empleR/reference/indicadores.md)
  forma la UPM con muestra + region + conglomerado cuando la base trae
  `sample_id` y `region_code`. El diseno se documenta como provisional
  hasta contar con la especificacion oficial.

### Datos

- `muestra_epen_2024` se regenera desde la base corregida de
  `ia_empleo_peru` (mismas 2.000 personas): codigos CNO completados a la
  izquierda, `sample_id`, estrato e identificadores reconstruidos.
- `cno_2015` incluye el grupo primario 5321 con sus tareas oficiales y
  restaura las tareas de 5223.
- Nuevos datasets `co_1995` y `equivalencia_co95`.

### Otros

- [`descargar()`](https://valentinalinares.github.io/empleR/reference/descargar.md)
  detecta si el CSV usa `;` o `,`.
- Ejemplos y vineta corregidos; alias de variables reales EPE y EPEN
  para la validacion de bases (`data-raw/validar_bases_reales.R`).

## empleR 0.0.0.9000

- Version inicial.
