# Reconstrucción y procedencia de los datos

Esta carpeta contiene los generadores de los once objetos distribuidos en
`data/`. La reconstrucción fue verificada el 14 de noviembre de 2026 desde
una copia limpia: los once objetos coincidieron por contenido con la versión
distribuida. Las huellas binarias pueden cambiar cuando cambia la versión de
R o la serialización de un archivo `.rda`; por eso el coordinador informa por
separado igualdad de contenido e igualdad binaria.

## Reconstrucción completa

Se necesita:

- un checkout de `valentinalinares/ia_empleo_peru` exactamente en el commit
  `d7a179f143bb33a6fef23cd0394d8b3053eb89ec`;
- el ZIP oficial `935-Modulo76.zip` de EPEN 2024;
- R y los paquetes enumerados por `data-raw/rebuild_all.R`.

Desde la raíz del paquete:

```r
Sys.setenv(
  EMPLER_IA_EMPLEO_REPO = "ruta/al/checkout/fijado",
  EMPLER_EPEN_RAW_2024 = "ruta/a/935-Modulo76.zip"
)
source("data-raw/rebuild_all.R")
```

Por defecto se escribe en una carpeta temporal y no se sobrescribe `data/`.
Para conservar una reconstrucción en otra carpeta se puede definir
`EMPLER_DATA_OUTPUT_DIR`. El coordinador comprueba el commit, las huellas de
las entradas, el resultado de cada script, las dimensiones y el contenido de
cada objeto.

El orden de ejecución es importante:

1. `00_preparar_datasets.R` crea los catálogos, indicadores, CNO base y
   equivalencia CNO-CIUO.
2. `02_build_indice_ia.R` crea el índice de exposición.
3. `03_build_equivalencia_co95.R` crea CO-95 y su correspondencia.
4. `04_corregir_cno_2015.R` incorpora el código 5321 faltante.
5. `06_restaurar_tareas_cno_2015.R` restaura las tareas verificadas de 5223 y
   5321 sin inventar scores.
6. `07_muestra_epen_2024.R` reproduce la muestra real con semilla 42 y
   recupera `DIVISION_LIMA` del ZIP original.
7. `01_preparar_shapes.R` agrega los límites de `geoperu` a departamento y
   provincia.

## Inventario

| Objeto | Dimensión | Fuente principal | Generador |
| --- | ---: | --- | --- |
| `catalogo_fuentes` | 52 × 6 | disponibilidad procesada en `ia_empleo_peru` | `00_preparar_datasets.R` |
| `cno_2015` | 666 × 6 | CNO 2015 estructurado, PDF oficial y tareas verificadas | `00`, `04`, `06` |
| `co_1995` | 370 × 7 | tablas de correspondencia oficiales del INEI | `03_build_equivalencia_co95.R` |
| `equivalencia_cno` | 539 × 6 | tabla CNO 2015-CIUO 2008 | `00_preparar_datasets.R` |
| `equivalencia_co95` | 604 × 7 | tablas de correspondencia oficiales del INEI | `03_build_equivalencia_co95.R` |
| `indicadores_epen` | 52 × 18 | resultados agregados de `ia_empleo_peru` | `00_preparar_datasets.R` |
| `indice_ia` | 449 × 21 | corrida Sonnet de abril de 2026 | `02_build_indice_ia.R` |
| `muestra_epen_2024` | 2.000 × 36 | base procesada y ZIP oficial EPEN 2024 | `07_muestra_epen_2024.R` |
| `shapes_departamentos` | 25 × 2 | `geoperu` 0.0.0.2 | `01_preparar_shapes.R` |
| `shapes_provincias` | 196 × 3 | `geoperu` 0.0.0.2 | `01_preparar_shapes.R` |
| `url_catalog_epen` | 141 × 6 | catálogo versionado de enlaces del INEI | `00_preparar_datasets.R` |

El manifiesto legible por máquina está en
`data-raw/manifests/datasets.json`. Los resultados observados están en
`data-raw/validation/2026-11-14_rebuild_*.csv` y el entorno en el JSON de la
misma fecha.

## Límites de procedencia y distribución

### Índice de exposición a IA

El índice fue desarrollado por Walter Omar Manky Bonilla, con asistencia de
investigación de Valentina Linares Herrera. El archivo final fijado permite
reconstruir exactamente `indice_ia`, pero el repositorio no contiene las
respuestas originales del modelo ni todo el paquete intermedio. Por tanto,
esta verificación reproduce el dataset final, no una nueva ejecución del
modelo. Antes de distribuir el índice en una versión enviada a CRAN o a
rOpenSci debe quedar registrada la autorización o licencia de su autor.

### Datos y documentos del INEI

El INEI publica los microdatos y documentos usados en su portal. En esta
auditoría no se encontró una licencia explícita que autorice la
redistribución de microdatos dentro de otro paquete. Acceso público no se
interpreta automáticamente como permiso de redistribución. La opción más
segura para una candidatura es reemplazar `muestra_epen_2024` por una muestra
sintética que conserve la estructura necesaria para los ejemplos, salvo que
se documente antes un permiso o término aplicable. La misma revisión de
condiciones debe acompañar los extractos derivados de clasificadores y tablas
de correspondencia.

### Límites geográficos

Los objetos espaciales se derivan de `geoperu` 0.0.0.2, publicado bajo
licencia MIT. Se conserva la atribución al proyecto de origen y la versión
usada.

