# Fase 4A: universo, variables y estimadores puntuales de `indicadores()`

Fecha de ejecución: 12 de noviembre de 2026

## Alcance

Esta validación revisa los tres indicadores que calcula `indicadores()`:
ingreso promedio, ingreso mediano y horas promedio. Comprueba el universo, las
variables, el factor de expansión, los valores ausentes o inválidos y los
estimadores puntuales con los microdatos oficiales de la EPEN 2022-2025.

Los errores estándar no se validan en esta fase. Continúan documentados como
provisionales hasta contrastar especificaciones del diseño muestral en la fase
4B.

## Fuentes y definiciones

Se utilizaron los ZIP anuales del módulo 76 y la documentación oficial de cada
año. En el Diccionario de Variables EPEN Anual 2024:

- la página 6 identifica `whoraT` como el número total de horas trabajadas;
- la página 12 define `OCUP300 = 1` como ocupado;
- la página 13 distingue `INGTOTP`, ingreso de la actividad principal, de
  `ingtrabw`, ingreso mensual de las ocupaciones principal y secundaria con
  ingresos extraordinarios, y distingue `FAC_T300` del factor anual
  `FAC300_ANUAL`.

La Ficha Técnica EPEN 2024 define la población ocupada en la página 10 y, en
la página 13, separa las horas de la ocupación principal, las de la secundaria
y el total semanal en todas las ocupaciones.

El informe oficial *Perú: Indicadores del Mercado Laboral a nivel
departamental, 2022-2024* define el ingreso mensual proveniente del trabajo como
las remuneraciones de las ocupaciones principal o secundaria, incluidos los
ingresos extraordinarios (p. 60), y publica los promedios de 2022-2024 en el
Cuadro 7.1 (p. 61). El informe nacional del primer trimestre de 2026 publica la
serie anual 2022-2025 en los Cuadros 17 y 18 (pp. 42-43).

En consecuencia, las definiciones auditadas son:

| Indicador | Universo | Variable EPEN | Tratamiento | Factor |
|---|---|---|---|---|
| Ingreso promedio | `OCUP300 = 1`, con ingreso positivo | `ingtrabw` | Excluye ingreso cero o negativo | `FAC300_ANUAL` |
| Ingreso mediano | Igual al ingreso promedio | `ingtrabw` | Regla matemática: extremo inferior donde la distribución ponderada alcanza 0,5 | `FAC300_ANUAL` |
| Horas promedio | `OCUP300 = 1` | `whoraT` | Admite cero horas; excluye ausentes o no numéricos | `FAC300_ANUAL` |

## Problemas encontrados antes de la corrección

1. El ingreso se calculaba con `INGTOTP`, que representa solo la actividad
   principal. No correspondía al indicador general descrito por la función ni
   al ingreso oficial publicado por el INEI.
2. La base procesada llamaba `hours_week` a `C318_T`, horas de la ocupación
   principal. La función cruda utilizaba `whoraT`, que sí representa el total,
   de modo que el mismo indicador cambiaba de concepto según la entrada.
3. Los datos descargados llegan como texto, pero la función no los convertía
   de forma controlada antes de comparar o ponderar.
4. La función no filtraba explícitamente `OCUP300 = 1` en el módulo completo.
5. Si había varios factores, elegía el primero reconocido sin pedir que el
   usuario declarara el periodo correspondiente.
6. La salida no informaba cuántas observaciones quedaban fuera por factor,
   valor ausente, dato inválido o definición del indicador.

## Correcciones implementadas

- `indicadores()` filtra el universo ocupado cuando encuentra `OCUP300` o
  `labor_status_code`.
- El ingreso predeterminado usa `ingtrabw` o
  `labor_income_work_weighted`; no sustituye silenciosamente ese concepto por
  ingreso principal.
- Las horas predeterminadas usan `whoraT` o `hours_week_total`; si solo existe
  una variable ambigua de ocupación principal, se exige declararla con
  `var_indicador`.
- Los pesos y valores en texto se convierten y auditan. Los no numéricos,
  infinitos y pesos no positivos no entran al estimador.
- Si hay más de un factor compatible, `var_peso` es obligatorio.
- La salida agrega el universo, los casos efectivos, cada motivo de exclusión
  y la población representada.
- La muestra incluida conserva `hours_week` como ocupación principal y agrega
  `hours_week_total` desde `whoraT`, sin cambiar las 2.000 personas.
- La mediana fija explícitamente `qrule = "math"`.

## Resultados con bases reales

Los resultados siguientes provienen de los cuatro ZIP oficiales. El archivo
`2026-11-12_indicadores_epen.csv` conserva el detalle reproducible.

| Año | Ocupados | Factor ausente | Factor cero | Población por factor | Población oficial | Ingreso paquete | Ingreso oficial | Diferencia |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2022 | 192.416 | 0 | 0 | 17.336.509,7 | 17.336.500 | 1.524,037 | 1.524,0 | 0,037 |
| 2023 | 196.595 | 1.113 | 4 | 17.179.796,2 | 17.179.800 | 1.674,368 | 1.674,4 | -0,032 |
| 2024 | 200.630 | 7.778 | 0 | 17.322.935,8 | 17.322.900 | 1.765,936 | 1.765,9 | 0,036 |
| 2025 | 207.407 | 14.399 | 0 | 17.575.150,0 | 17.575.200 | 1.887,161 | 1.887,2 | -0,039 |

Las 23.290 personas sin `FAC300_ANUAL` coinciden con el diagnóstico previo de
`ia_empleo_peru`, revisado en el commit
`d7a179f143bb33a6fef23cd0394d8b3053eb89ec`. La recomendación analítica de
ese proyecto no se trasladó automáticamente al paquete: `indicadores()` informa
las exclusiones y no imputa factores. Además, los microdatos de 2023 contienen
cuatro ocupados con
factor igual a cero; la función los reporta como peso inválido, no como factor
ausente.

El estimador del paquete coincide con el cálculo ponderado independiente sin
diferencia numérica en los cuatro años. Las diferencias frente al ingreso
publicado por el INEI están entre -0,039 y 0,037 soles y se explican por la
publicación oficial a una decimal. La suma de factores válidos también reproduce
la población ocupada oficial dentro del redondeo a centenas.

| Año | Mediana ponderada | Horas totales promedio | Casos con ingreso | Ingreso cero | Casos con horas |
|---:|---:|---:|---:|---:|---:|
| 2022 | 1.150 | 42,707 | 176.068 | 16.344 | 192.416 |
| 2023 | 1.280 | 43,054 | 178.865 | 16.645 | 195.478 |
| 2024 | 1.300 | 43,277 | 176.161 | 16.942 | 192.852 |
| 2025 | 1.414 | 43,750 | 176.055 | 17.368 | 193.008 |

Las medianas y las horas coinciden exactamente con cálculos independientes.
No se localizaron cifras anuales oficiales de horas o medianas con una
definición idéntica para usarlas como segundo punto de contraste, por lo que no
se afirma una validación externa de esos dos niveles.

## Hallazgo que pasa a la fase 4B

En 2025 hay 211 ocupados con factor anual válido pero `ESTRATO` ausente. Para
no cambiar el estimador puntual, `indicadores()` conserva esas personas y avisa
que no puede usar el estrato incompleto para el error estándar. No se rellenó
el estrato ni se eliminaron observaciones. La especificación inferencial y la
comparación con CV o DEFF oficiales corresponden a la fase 4B.

## Huellas de los insumos

| Año | SHA-256 del ZIP oficial |
|---:|---|
| 2022 | `ee64092dcf3d144ddc3a76f5d26af6717dececa2c2bc4a429e42e99157e9e9d2` |
| 2023 | `80b270a27a170af5c27390f5ed9dcdefc2e13b5201ecb982f1bd7cdea705759f` |
| 2024 | `a33d062bc3f7bdfe86b91f89beadf13b32ad590f384dd79f1d24b79ae25c86e2` |
| 2025 | `56892e6aa9749bd1c50be664431cdb0eee5f96295cf3261c44aff735747de830` |

## Enlaces oficiales

- Ficha Técnica EPEN 2024:
  <https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Ficha_Tecnica.pdf>
- Diccionario EPEN 2024:
  <https://proyectos.inei.gob.pe/iinei/srienaho/Descarga/DocumentosMetodologicos/2024-156/Diccionario.pdf>
- Indicadores departamentales 2022-2024:
  <https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib2029/libro.pdf>
- Informe nacional con serie anual 2022-2025:
  <https://www.inei.gob.pe/media/MenuRecursivo/boletines/empleo-nacional-i-trimestre-2026.pdf>
