# Fuente final del índice de exposición IA

El conjunto de datos interno `indice_ia` se reconstruye con
`data-raw/02_build_indice_ia.R` a partir de la corrida Sonnet de abril de 2026.
El paquete metodológico fue versionado el 15 de junio de 2026. La fuente
principal es `02_exposure_index_por_ocupacion.xlsx`.

La carpeta del paquete metodológico (`01_Indice_exposicion`) no se incluye en
el repositorio. Para reconstruir el índice, indica su ruta con la variable de
entorno `EMPLER_INDICE_IA_DIR` antes de ejecutar el script. Las huellas
SHA-256 de abajo permiten verificar que se usan los mismos archivos.

Archivos del paquete metodológico:

- `02_exposure_index_por_ocupacion.xlsx`: índice final por ocupación.
- `03_comparison_by_task_fused.xlsx`: comparación por tarea entre corridas.
- `04_agreement_summary.json`: resumen de acuerdo entre corridas.
- `05_strip_claude_por_sector.html`: visualización exploratoria por sector.
- `06_memo_paquete_sonnet_para_compartir.md`: memo metodológico.

Huellas SHA-256:

- `228DE84C663DBD5DC286DF5AB7930E22C2B66350FCC3C6C156E7773090C73D02`
  `02_exposure_index_por_ocupacion.xlsx`
- `1F677D9B63BFD2AC71F1B2CB8C8053CC3C2BD4B02CAB6D4379909366AA4F498E`
  `03_comparison_by_task_fused.xlsx`
- `490AD09F7F6726E1DBD427A9FC176C8FE5819D1CD10A4E873E2FFF3983222D2B`
  `04_agreement_summary.json`
- `DF82281513EF5FC618C5D16A3D569BDBF3709047FF14FC395D23C30C7B12525B`
  `05_strip_claude_por_sector.html`
- `CF521D99C0FCA668F14728BE116E4D3E893CA62F825EBD9551B9DCD559CA109B`
  `06_memo_paquete_sonnet_para_compartir.md`

Decisiones metodológicas:

- El puntaje final recomendado para análisis es `mean_exposure_score`.
- La escala del índice es 0-1.
- `median_exposure_score` y `std_score` se conservan para sensibilidad.
- El tipo de impacto por tarea usa `A` aumento, `S` sustitución y `N` nulo.

## Autoría y relación con el índice publicado

El índice y la corrida Sonnet fueron desarrollados por **Walter Omar Manky
Bonilla**, con la asistencia de investigación de **Valentina Linares
Herrera**. Es una actualización del enfoque basado en tareas del CNO-2015
publicado en el estudio citado a continuación.

> Manky, W. O. (2025). *Doble desafío tecnológico: análisis de la exposición a
> la automatización tradicional y a la inteligencia artificial generativa en
> el empleo peruano, utilizando datos de la ENAHO 2024*. Instituto Nacional de
> Estadística e Informática.

Publicación oficial:
<https://www.gob.pe/institucion/inei/informes-publicaciones/7453406-doble-desafio-tecnologico-analisis-de-la-exposicion-a-la-automatizacion-tradicional-y-a-la-inteligencia-artificial-generativa-en-el-empleo-peruano-utilizando-datos-de-la-enaho-2024>.

Omar autorizó verbalmente a Valentina a usar el índice en `empleR`. Valentina
dejó constancia de esa autorización el 14 de noviembre de 2026. Para una
publicación formal se solicitará una confirmación breve por escrito y se
registrará la licencia de redistribución acordada; mientras tanto no se
atribuye al índice una licencia que su autor no haya escogido.

Los puntajes actuales no reproducen los valores de esa publicación: fueron
recalculados con Claude Sonnet 4.6, conservan un puntaje continuo y aplican
reglas revisadas para empates, ambigüedades y tipo de exposición. La referencia
interna de esta versión es:

> Manky Bonilla, W. O. (2026). *Índice de exposición a inteligencia artificial
> generativa para ocupaciones peruanas: corrida Claude Sonnet 4.6*. Con
> asistencia de investigación de V. Linares Herrera. Material de trabajo no
> publicado.
