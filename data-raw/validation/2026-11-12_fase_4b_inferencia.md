# Fase 4B: validación de la inferencia de `indicadores()`

Fecha: 12 de noviembre de 2026

## Decisión

`indicadores()` conserva como comportamiento predeterminado las estimaciones
ponderadas y su auditoría de observaciones. Los errores estándar se calculan
solo con `incluir_inferencia = TRUE` y se identifican como experimentales.

La reconstrucción reproduce los errores publicados por el INEI, pero la
documentación pública no describe todos los ajustes internos con suficiente
detalle para presentar la inferencia como una réplica oficial. No se aplica una
corrección por población finita ni un tratamiento automático de estratos con una
sola UPM.

## Fuentes y archivos usados

- EPEN Lima Metropolitana, octubre-noviembre-diciembre de 2024 y 2025:
  cuadro 1.13 de los archivos oficiales de errores muestrales
  ([2024](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-45/Error_Muestral_por_Trimestre.pdf),
  [2025](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2025-45/Error_Muestral_por_Trimestre.pdf)).
- EPEN anual 2024: *Perú: Comportamiento de los indicadores del mercado
  laboral a nivel nacional y en 27 ciudades*, cuadros 7.1 y 7.2, páginas
  impresas 98 y 99
  ([publicación](https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib2029/libro.pdf)).
- Ficha técnica EPEN 2024: diseño probabilístico, estratificado de manera
  implícita, bietápico e independiente; conglomerado como UPM.
- Diccionario EPEN 2024: identificadores y variables usadas para reconstruir
  UPM, estrato, dominios e indicadores.

Huellas SHA-256 de los insumos:

| Insumo | SHA-256 |
|---|---|
| Módulo 76 trimestral 2024 | `B6328AF0265738DCF0621BEB26042EC373AB4870E60F44DB960CCB1EC7B43FB2` |
| Módulo 76 trimestral 2025 | `F45C96EBC07D7C605D8D98B8BB4E5E726990F10AFD03BC9235922744D90B0337` |
| Módulo 76 anual 2024 | `A33D062BC3F7BDFE86B91F89BEADF13B32AD590F384DD79F1D24B79AE25C86E2` |
| Ficha técnica anual 2024 | `98E30C679CF2499DDE26B671708B1D61B2C4F45191C694BC267E335985238913` |
| Diccionario anual 2024 | `896010FABA8E29E84E08000DCD48F006F6246383511403FA546F4AF0423FD157` |

## Contraste trimestral: Lima Metropolitana

Se compararon seis especificaciones plausibles con 24 celdas oficiales: tasas
de actividad y ocupación, para el total, sexo y tres grupos de edad, en 2024 y
2025. La especificación seleccionada usa una UPM compuesta por muestra, región
y conglomerado, sin un estrato explícito.

| Comprobación | Resultado |
|---|---:|
| Estimaciones que coinciden al redondeo publicado | 24 de 24 |
| Errores estándar que coinciden al redondeo publicado | 24 de 24 |
| CV que coinciden al redondeo publicado | 24 de 24 |
| Diferencia absoluta media del CV | 0,0025 puntos porcentuales |

El campo `ESTRATO` no mejora el ajuste en esta variante. Además, presenta 755
valores ausentes en 2024 y 321 en 2025, y solo un valor publicado entre los no
ausentes. Esto es coherente con la estratificación implícita descrita en la
ficha, pero no demuestra por sí solo el algoritmo interno del INEI.

## Contraste anual: departamentos, 2024

Se compararon siete especificaciones con ocho celdas oficiales de ingreso
promedio: total, hombres, mujeres, tres grupos de edad, área urbana y área
rural. La mejor especificación usa UPM compuesta por muestra, departamento y
conglomerado, y `ESTRATO` como estrato.

| Comprobación | Resultado |
|---|---:|
| Estimaciones que coinciden al redondeo publicado | 8 de 8 |
| CV que coinciden al redondeo publicado | 8 de 8 |
| Diferencia absoluta media del CV | 0,0238 puntos porcentuales |

La base anual contiene 18.376 UPM compuestas. De ellas, 14.065 aparecen en más
de un mes, por lo que agregar el mes a la UPM cambia indebidamente la unidad de
muestreo. No hay estratos faltantes en el insumo anual 2024 usado para este
contraste. Sus ocho estratos publicados contienen más de una UPM; no hay
estratos solitarios en esta especificación.

## Reglas incorporadas en la API

- El cálculo puntual no requiere reconstruir UPM ni estratos.
- La inferencia exige al menos dos UPM y no admite identificadores de UPM
  incompletos.
- Cuando la UPM se detecta automáticamente, se compone con muestra y región para
  evitar colisiones entre departamentos.
- Un estrato incompleto produce un error; no se reemplaza silenciosamente por
  un diseño que use solo pesos.
- `var_strata = NA` permite declarar sin ambigüedad una variante sin estrato
  explícito, cuando la documentación de esa variante lo respalda.
- Los estratos con una sola UPM producen un error porque no se conoce el
  tratamiento oficial aplicable.

## Límites

Esta validación muestra equivalencia práctica con cifras publicadas, no identidad
con el sistema de estimación interno del INEI. Las variantes trimestral de Lima
y anual departamental requieren especificaciones distintas. La base procesada
anual 2025 todavía contiene estratos ausentes; por diseño, la inferencia se
detendrá hasta que esos casos puedan reconstruirse o se documente otra
especificación válida.

## Reproducción

- `data-raw/validar_diseno_epen.R`: contraste trimestral 2024-2025.
- `data-raw/validar_diseno_epen_anual.R`: contraste anual 2024.
- Resultados detallados y diagnósticos: archivos CSV de esta carpeta con fecha
  `2026-11-12`.

Entorno de ejecución: R 4.5.1, `survey` 4.4-8 y `data.table` 1.17.8.

## Revisión independiente de cierre

La revisión del 12 de noviembre de 2026 volvió a ejecutar el contraste
trimestral desde los ZIP, verificó la transcripción de los cuadros oficiales y
revisó las fórmulas y dominios del script. No encontró discrepancias de cálculo.
Se corrigieron dos aspectos de reproducibilidad y comunicación:

- la raíz de los ZIP trimestrales puede configurarse ahora mediante
  `EMPLER_EPEN_LIMA_RAW_ROOT`;
- la documentación distingue el diseño trimestral validado, sin estrato
  explícito, del diseño anual departamental validado con `ESTRATO`.
