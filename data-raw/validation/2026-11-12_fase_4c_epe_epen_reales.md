# Fase 4C: validación con EPE y EPEN reales

**Ejecución inicial:** 12 de noviembre de 2026  
**Revisión de cierre:** 14 de noviembre de 2026  
**Alcance:** EPE octubre-noviembre-diciembre de 2021 y EPEN
octubre-noviembre-diciembre de 2024  
**Decisión:** el recorrido técnico funciona con ambas encuestas y reproduce
los indicadores oficiales seleccionados. No se valida una serie temporal
EPE–EPEN ni una comparación agregada del índice de IA.

## Qué se probó

Esta fase distingue tres niveles de evidencia:

1. **Pruebas sintéticas:** las pruebas automatizadas del paquete verifican
   casos controlados, errores esperados y contratos de las funciones.
2. **Integración con microdatos reales:** `validar_epe_epen_reales.R` lee los
   ZIP oficiales, conserva los códigos originales, filtra residentes
   habituales, procesa las ocupaciones y registra muestras, pesos,
   correspondencias y cobertura del índice.
3. **Contraste oficial:** se recalcularon 24 tasas de actividad y ocupación y
   se compararon con las tablas de error muestral del INEI. Las 24 coinciden
   al redondeo de una decimal publicado.

No se usó una réplica del formato para sustituir la validación real.

## Fuentes e integridad

| Encuesta | Archivo dentro del ZIP | SHA-256 del ZIP | Ficha y cifras oficiales |
|---|---|---|---|
| EPE 2021 | `Trim Oct-Nov-Dic21.csv` | `6f741cdcb1b26451d638befb8c1e4dfa8cad63ec1d6b31305c5921c26f514d3c` | [Ficha técnica](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2021-45/Ficha_Tecnica.pdf) y [errores muestrales](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2021-45/Error_Muestral_por_Trimestre.pdf) |
| EPEN 2024 | `Trim_Oct_Nov_Dic24.csv` | `b6328af0265738dcf0621beb26042ec373ab4870e60f44db960ccb1ec7b43fb2` | [Ficha técnica](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-45/Ficha_Tecnica.pdf) y [errores muestrales](https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-45/Error_Muestral_por_Trimestre.pdf) |

Las rutas locales no se guardan en las salidas. La raíz se configura mediante
`EMPLER_INEI_RAW_ROOT`; los nombres y las huellas quedan en
`2026-11-12_epe_epen_fuentes.csv`.

## Universo, pesos y muestra

| Encuesta | Filas | Residentes de 14+ | PET con factor | PEA | Ocupados | Ocupados sin factor | Población ocupada expandida |
|---|---:|---:|---:|---:|---:|---:|---:|
| EPE 2021 | 16 018 | 12 481 | 12 034 | 7 751 | 7 157 | 0 | 4 909 261 |
| EPEN 2024 | 13 673 | 10 643 | 9 529 | 6 076 | 5 720 | 0 | 5 554 272 |

Hay 447 residentes de 14 años o más sin `fa_ond21` en EPE y 1 114 sin
`fa_ond24` en EPEN. Ninguno pertenece al universo ocupado usado aquí. No se
imputaron factores ni se eliminaron silenciosamente registros.

La identificación de UPM usada para describir la muestra combina
`submuestra + conglome` en EPE y `MUESTRA + REGION + CONGLOMERADO` en EPEN.
Esta fase no usa esa reconstrucción para afirmar que el diseño completo de una
encuesta sea idéntico al de la otra.

## Reproducción de las cifras oficiales

Se calcularon, para cada encuesta, las tasas de actividad y ocupación para el
total, hombres, mujeres y tres grupos de edad. Los 24 resultados coinciden con
el valor oficial redondeado a una decimal. Por ejemplo:

| Encuesta | Indicador | Cálculo | Oficial |
|---|---|---:|---:|
| EPE 2021 | Actividad total | 66,1121 | 66,1 |
| EPE 2021 | Ocupación total | 92,1667 | 92,2 |
| EPEN 2024 | Actividad total | 65,5622 | 65,6 |
| EPEN 2024 | Ocupación total | 94,4728 | 94,5 |

La tabla completa está en
`2026-11-12_epe_epen_indicadores_oficiales.csv`. Este contraste valida el
universo, los factores y la interpretación de las variables para cada entrega;
no convierte las dos entregas en una serie comparable.

## Límite territorial

La ficha de EPE 2021 define 43 distritos de la provincia de Lima y 6 de la
Provincia Constitucional del Callao. La ficha de EPEN 2024 define los mismos
43 distritos de Lima y 7 del Callao. El módulo 76 de EPEN usado en esta prueba
no publica distrito ni ubigeo, por lo que no permite excluir Mi Perú.

Por tanto:

- la comparación territorial exacta queda **no validada**;
- seleccionar todo el departamento de Lima no sería una solución equivalente;
- los cálculos de cada encuesta se pueden validar por separado, pero su
  diferencia no debe interpretarse como cambio temporal limpio.

## Homologación ocupacional y cobertura del índice

En la EPE, la correspondencia CO-95–CNO 2015 dio:

| Estado | Observaciones | % muestra | Población | % población |
|---|---:|---:|---:|---:|
| Única | 2 475 | 34,58 | 1 700 640 | 34,64 |
| Múltiples destinos | 4 591 | 64,15 | 3 154 034 | 64,25 |
| Discrepancia de fuente | 88 | 1,23 | 53 016 | 1,08 |
| Código no encontrado | 3 | 0,04 | 1 572 | 0,03 |

Los tres códigos no encontrados fueron `337`, `527` y `727`. Las siete
discrepancias observadas en la fuente fueron `141`, `148`, `242`, `749`,
`791`, `843` y `844`; sus candidatos y frecuencias se conservan en las tablas
de auditoría. Ningún caso ambiguo o discrepante recibió un código homologado.

La cobertura poblacional con puntaje de IA fue 33,37 % en EPE y 97,72 % en
EPEN. La diferencia proviene principalmente de las correspondencias múltiples
del clasificador antiguo, no de una ausencia comparable de puntajes. En
consecuencia, comparar promedios agregados del índice entre EPE y EPEN
seleccionaría poblaciones ocupacionales muy distintas y no es defendible como
estimación de tendencia.

A nivel de gran grupo se recupera parte de la cobertura cuando todos los
candidatos comparten el mismo primer dígito. Aun así, 18,53 % de la población
ocupada EPE permanece sin asignación a gran grupo. Cualquier análisis agregado
debe presentar ese porcentaje y una comprobación de sensibilidad.

## Conclusión

Queda validado que:

- `cno()`, `ia_exposicion()` y `cobertura()` recorren microdatos reales de EPE
  y EPEN sin inventar correspondencias;
- los códigos ambiguos y discrepantes permanecen sin asignación;
- los universos y factores elegidos reproducen 24 cifras oficiales;
- las salidas guardan fuentes, huellas, conteos, pares y cobertura.

No queda validado que:

- los ámbitos territoriales EPE 2021 y EPEN 2024 sean idénticos;
- una diferencia EPE–EPEN sea una tendencia temporal;
- los promedios del índice de IA sean directamente comparables entre ambas;
- el módulo 76 permita reconstruir el distrito faltante.

La recomendación es usar esta fase como validación técnica de cada encuesta y
como advertencia obligatoria de comparabilidad. Para resultados sustantivos,
reportar EPE y EPEN por separado o limitar el análisis a una agregación con
cobertura explícita y sensibilidad documentada.

## Reproducción y archivos

Ejecutar desde la raíz del repositorio:

```r
Sys.setenv(EMPLER_INEI_RAW_ROOT = "ruta/a/inei_data_core")
source("data-raw/validar_epe_epen_reales.R")
```

El script regenera:

- `2026-11-12_epe_epen_fuentes.csv`;
- `2026-11-12_epe_epen_muestra.csv`;
- `2026-11-12_epe_epen_indicadores_oficiales.csv`;
- `2026-11-12_epe_epen_cobertura.csv`;
- `2026-11-12_epe_homologacion.csv`;
- `2026-11-12_epe_homologacion_codigos.csv`;
- `2026-11-12_epe_homologacion_pares.csv`;
- `2026-11-12_epe_epen_gran_grupo.csv`.
