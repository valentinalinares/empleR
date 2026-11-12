# Fase 3 corregida: alcance longitudinal y mapas EPEN

**Fecha:** 11 de noviembre de 2026
**Rama:** `refactor/alcance-v1-corregido`

## Decisión sobre `panel()`

La función experimental `panel()` se retira de la interfaz pública. La clave
anterior podía reconocer viviendas u hogares presentes en varias entregas,
pero no demostraba que se siguiera a las mismas personas. Además, no separaba
de forma suficiente muestra y región ni distinguía una visita nueva de la
repetición causada por trimestres móviles solapados.

No se presenta esa unión como longitudinal hasta verificar la unidad de
seguimiento, la rotación de la muestra y las llaves contra la documentación y
los microdatos originales. La última versión queda recuperable en el historial
de Git; no se borra la evidencia de su desarrollo.

## Corrección de los ámbitos geográficos

La primera propuesta de esta fase interpretaba `CCDD` como 25 departamentos
político-administrativos y dejaba Callao sin dato. Esa interpretación era
incorrecta para la EPEN anual.

La solución usa dos variables originales:

- `CCDD` identifica el departamento base;
- cuando `CCDD = 15`, `DIVISION_LIMA` distingue:
  - `1`: Lima Metropolitana y Provincia Constitucional del Callao;
  - `2`: Región Lima, formada por las otras nueve provincias del departamento.

Así se reproducen los 25 ámbitos departamentales que publica la encuesta: 23
departamentos ordinarios y dos ámbitos para el código 15. Callao no se trata
como código `07` separado.

### Fuentes oficiales

- INEI, *Perú: Comportamiento de los indicadores del mercado laboral a nivel
  nacional y en 26 ciudades, 2024*, p. 14. El cuadro departamental presenta por
  separado “Lima Metrop./Prov. Const. Callao” y “Región Lima”:
  <https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib2029/libro.pdf>.
- Diccionarios oficiales del módulo 76 de la EPEN anual 2022–2025. En particular,
  el diccionario 2024 define `DIVISION_LIMA = 1` como Provincia de Lima, incluida
  la Provincia Constitucional del Callao, y `DIVISION_LIMA = 2` como Región
  Lima. Los diccionarios se descargaron junto con cada encuesta desde el portal
  de microdatos del INEI.
- ZIP anuales oficiales usados en la prueba: encuestas 790 (2022), 874 (2023),
  935 (2024) y 1001 (2025), módulo 76.

El catálogo independiente de referencia está en
`data-raw/validation/epen_ambitos_departamentales_oficiales.csv`. El validador
no toma la lista esperada de las funciones internas del paquete.

## Cambios aplicados

1. `mapa()` exige `DIVISION_LIMA` o `division_lima` cuando el código es 15.
2. Los polígonos se construyen sin superposición:
   - Lima Metropolitana y Callao = provincia de Lima + Callao;
   - Región Lima = las otras nueve provincias de Lima.
3. Los nombres oficiales también son llaves válidas. Si se proporcionan
   código, división y nombre, deben coincidir.
4. Se rechazan el código 07, códigos desconocidos, divisiones fuera de Lima,
   códigos 15 sin división y ámbitos duplicados.
5. La muestra incluida incorpora `division_lima`, recuperada del ZIP original
   mediante la llave completa de persona.
6. Provincias y distritos permanecen fuera del alcance: los datos procesados no
   contienen una llave suficiente para ofrecer esos cruces con seguridad.

## Validación con bases reales

Se ejecutó:

```text
Rscript data-raw/validar_mapa_epen.R RUTA_EPEN_DEPARTAMENTOS
```

El script leyó directamente los cuatro ZIP originales, construyó la llave
`CCDD + DIVISION_LIMA`, comparó los ámbitos observados con el catálogo oficial
y comprobó tanto el objeto `ggplot` como las etiquetas de `leaflet`.

| Año | Filas originales | Ámbitos originales | Ámbitos del mapa | Filas asignadas | Polígonos correctos |
|---:|---:|---:|---:|---:|---:|
| 2022 | 439.523 | 25 | 25 | 439.523 | 25 |
| 2023 | 449.202 | 25 | 25 | 449.202 | 25 |
| 2024 | 465.598 | 25 | 25 | 465.598 | 25 |
| 2025 | 471.438 | 25 | 25 | 471.438 | 25 |

No quedó ninguna fila sin ámbito y no hubo avisos de geometrías o etiquetas
faltantes. El detalle reproducible está en
`2026-11-11_mapa_epen_ambitos.csv`; el resumen, en
`2026-11-11_mapa_epen_ambitos_resumen.csv`.

## Pruebas sintéticas complementarias

Las pruebas unitarias cubren los casos que una ejecución con datos válidos no
provoca: código 15 sin división, código 07, división inválida, contradicción
entre aliases, duplicados, nombres desconocidos, valores infinitos y niveles
provincial o distrital. También comprueban que los dos polígonos de Lima cubren
exactamente la superficie conjunta de Lima y Callao sin pérdidas.

## Alcance que queda explícitamente pendiente

- No se ofrece seguimiento longitudinal de personas.
- No se ofrecen mapas provinciales ni distritales.
- Un mapa describe el indicador recibido; no valida por sí solo la precisión ni
  la representatividad de la estimación.
- Los errores estándar de `indicadores()` siguen siendo provisionales hasta su
  contraste con resultados oficiales.
