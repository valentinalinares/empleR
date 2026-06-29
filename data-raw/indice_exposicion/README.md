# Fuente final del indice de exposicion IA

El dataset interno `indice_ia` se reconstruye con
`data-raw/02_build_indice_ia.R` a partir del paquete metodologico Sonnet
2026-06-15. La fuente principal es `02_exposure_index_por_ocupacion.xlsx`.

Directorio fuente local usado:

`C:/Users/VALENTINALINARES/OneDrive - Universidad del Pacifico/Desktop/CIUP/IA_Empleo_Peru/2026-06-15_VRI_Fiorella/VRI 2026 - Fiorella/01_Indice_exposicion`

Archivos del paquete metodologico:

- `02_exposure_index_por_ocupacion.xlsx`: indice final por ocupacion.
- `03_comparison_by_task_fused.xlsx`: comparacion por tarea entre corridas.
- `04_agreement_summary.json`: resumen de acuerdo entre corridas.
- `05_strip_claude_por_sector.html`: visualizacion exploratoria por sector.
- `06_memo_paquete_sonnet_para_compartir.md`: memo metodologico.

Checksums SHA256:

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

Decision metodologica:

- El score final recomendado para analisis es `mean_exposure_score`.
- La escala del indice es 0-1.
- `median_exposure_score` y `std_score` se conservan para sensibilidad.
- El tipo de impacto por tarea usa `A` aumento, `S` sustitucion y `N` nulo.
