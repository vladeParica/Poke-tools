# Decisiones de arquitectura (ADR)

Una decisión por archivo: contexto, decisión, alternativas y consecuencias. Una ADR
aceptada no se reescribe: se reemplaza con otra nueva que diga "reemplaza a ADR-NNNN".
Plantilla: [`.ai-dlc/templates/adr.md`](../../../.ai-dlc/templates/adr.md).

| ADR | Decisión | Estado | Fecha |
|---|---|---|---|
| [ADR-0001](0001-lua-51-en-vba-rr.md) | Lua 5.1 en VBA-rr como plataforma | aceptada | 2026-10-29 |
| [ADR-0002](0002-script-unico-generado.md) | Un solo script generado desde `src/` con `build.py` | aceptada | 2026-10-29 |
| [ADR-0003](0003-bots-separados.md) | Bots separados: el Shiny Bot solo busca | aceptada | 2026-10-29 |
| [ADR-0004](0004-configuracion-json-comentado.md) | Configuración en un JSON comentado junto al script | aceptada | 2026-10-29 |
| [ADR-0005](0005-pruebas-con-simulador.md) | Pruebas con un simulador del juego (lupa + mocks) | aceptada | 2026-10-29 |
| [ADR-0006](0006-direcciones-relativas.md) | Direcciones de combate relativas a `gEnemyParty` | aceptada | 2026-10-29 |
| [ADR-0007](0007-rutas-grabadas.md) | Rutas al Centro grabadas por el jugador | aceptada | 2026-10-29 |
| [ADR-0008](0008-licencia-gpl-3.md) | Licencia GPL-3.0 | aceptada | 2026-10-29 |

Las ADR 0001–0007 se registraron después de tomar la decisión (documentación retroactiva):
describen cómo está hecho el código hoy.
