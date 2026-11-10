# Fase 2: conexión entre datos crudos, etiquetas y ocupaciones

Fecha de ejecución: 10 de noviembre de 2026.

## Objetivo

Comprobar que `etiquetar()` pueda aplicarse directamente al módulo 76 que
devuelve `descargar()`, sin perder los códigos originales, y que sus etiquetas
coincidan con la documentación oficial de la EPEN.

Esta fase no intenta etiquetar todas las variables del módulo. Incorpora solo
ocho conceptos para los cuales se verificaron el nombre, la codificación y su
equivalente en las bases procesadas.

## Fuentes oficiales

La fuente principal es el [Diccionario de variables de la EPEN anual
2023](https://www.inei.gob.pe/media/DATOS_ABIERTOS/EPEN_DEP/DICCIONARIO/2023/Anual-Ener-Dic/Diccionario.pdf):

| Variable | Contenido | Página numerada |
|---|---|---:|
| `AREA` | Área de residencia | 1 |
| `C207` | Sexo | 3 |
| `C310` | Categoría ocupacional | 4-5 |
| `C311` | Sector institucional | 5 |
| `C317` | Tamaño de empresa | 5 |
| `C338` | Periodicidad del pago | 6 |
| `C366` | Nivel educativo | 11 |
| `OCUP300` | Condición de actividad | 12 |

Se usó además el [diccionario de la EPEN Lima móvil de octubre-noviembre-
diciembre de 2023](https://www.inei.gob.pe/media/DATOS_ABIERTOS/EPEN/DICCIONARIO/2023/12-trim-movil-oct-nov-dic23/Diccionario.pdf)
para dos extensiones que no aparecen completas en el diccionario anual:

- página 7: `C310` incluye también los códigos 9 y 10;
- página 18: `OCUP300` documenta el código 0, “Sin información”.

El detalle reproducible por código, alias, página y fuente está en
`2026-11-10_diccionario_etiquetas_epen.csv`.

## Errores corregidos

La versión anterior solo acertaba plenamente en sexo, educación y el área
procesada. Se corrigieron estas correspondencias:

1. `C310` no separa “empleado” y “obrero” en códigos 3 y 4. El código 3 es
   “Empleado u obrero”; los códigos 4 a 10 distinguen distintas formas de
   ayuda familiar, trabajo del hogar y prácticas.
2. `C311` no representa sector público, privado, independiente y trabajo
   familiar. Distingue Fuerzas Armadas/PNP, administración pública, empresa
   pública, empresas especiales de servicios, empresa privada y otra.
3. `C317` usa cinco intervalos: hasta 20, 21-50, 51-100, 101-500 y más de 500
   personas. Los nueve intervalos anteriores no correspondían a esta variable.
4. En `C338`, el código 5 significa “No recibió pago alguno”, no “Anual”. No
   existen categorías 6 a 8 en el diccionario revisado.
5. En `OCUP300`, el código 4 se presenta como “Inactivo pleno”; el código 0
   se mantiene como “Sin información”.

## Comportamiento implementado

- Reconoce los nombres crudos `C207`, `OCUP300`, `C366`, `C310`, `C311`,
  `C317`, `C338` y `AREA`.
- Reconoce sus equivalentes procesados: `sex_code`, `labor_status_code`,
  `education_code`, `occupational_category_code`,
  `institutional_sector_code`, `firm_size_code`,
  `income_periodicity_code` e `is_rural`.
- Conserva los códigos y crea columnas terminadas en `_label` por defecto.
- `reemplazar = TRUE` conserva el comportamiento anterior para compatibilidad.
- Distingue un valor ausente de un código no documentado. El segundo produce
  una advertencia y conserva el código original.
- Una segunda ejecución produce el mismo resultado.
- Si aparecen a la vez un nombre crudo y su alias procesado, exige que ambos
  produzcan la misma etiqueta; una discrepancia detiene la operación.
- `C208` no se etiqueta: es una edad numérica, no una variable categórica.

## Pruebas con datos reales

Se revisaron 47 ZIP oficiales disponibles en el equipo, sin modificarlos:

| Variante | Años | ZIP revisados |
|---|---|---:|
| EPEN departamental anual | 2022-2025 | 4 |
| EPEN Lima móvil | 2022 | 3 |
| EPEN Lima móvil | 2023 | 12 |
| EPEN Lima móvil | 2024 | 12 |
| EPEN Lima móvil | 2025 | 12 |
| EPEN Lima móvil | 2026 | 4 |

Todos los códigos no ausentes observados pertenecen a los diccionarios
implementados:

| Variable | Códigos observados |
|---|---|
| `AREA` | 1, 2 |
| `C207` | 1, 2 |
| `C310` | 1, 2, 3, 4, 6, 7, 8, 9 |
| `C311` | 1, 2, 3, 4, 5 |
| `C317` | 1, 2, 3, 4, 5 |
| `C338` | 1, 2, 3, 4, 5 |
| `C366` | 1 a 12 |
| `OCUP300` | 0, 1, 2, 3, 4 |

Resultado: **cero códigos observados fuera del diccionario**. Que `C310 = 10`
o `C311 = 6` no aparezcan en estos ZIP no los vuelve inválidos: ambos están
documentados oficialmente.

El detalle por ZIP, año, entrega, variable, código y frecuencia está en
`2026-11-10_etiquetas_epen_codigos_observados.csv`.

Además se ejecutó el recorrido completo sobre la EPEN departamental anual
2024: 465.598 filas, ocho variables crudas reconocidas, ocho columnas de
etiquetas agregadas, **todas las columnas crudas preservadas sin cambios** y
207.057 filas con un CNO normalizado. El resumen está en
`2026-11-10_flujo_real_epen_2024.csv`.

Durante esta ejecución se detectó otro caso real: el ZIP anual 2022 tiene un
nombre interno con un acento cuya codificación cambia al extraerlo en Windows.
La lectura ahora abre el CSV directamente dentro del ZIP y tiene una prueba de
regresión con un nombre UTF-8.

## Pruebas sintéticas y de integración

Las pruebas automatizadas cubren, por separado:

- los ocho nombres crudos y los ocho nombres procesados;
- los diccionarios corregidos;
- valores ausentes, códigos desconocidos y variables solicitadas que no
  existen;
- repetición segura de `etiquetar()`;
- conflicto entre un nombre crudo y su alias procesado;
- compatibilidad con `reemplazar = TRUE`;
- el flujo `etiquetar()` -> `cno()`, comprobando que `C308_COD` no cambia y
  que un código como `212` se normaliza a `0212`.

Las pruebas sintéticas verifican la lógica. La tabla de 47 ZIP es la evidencia
contra microdatos reales.

## Reproducción

Desde la raíz del paquete:

```r
Rscript data-raw/validar_etiquetas_epen.R \
  "ruta/a/inei_data_core"
```

La ruta debe contener las carpetas `epen_departamentos` y `epen_lima`. El
script devuelve un estado distinto de cero si encuentra un código no ausente
fuera del diccionario.
