# Architecture decision records (ADRs)

One decision per file: context, decision, alternatives and consequences. An accepted ADR
is not rewritten: it is replaced by a new one that says "supersedes ADR-NNNN".
Template: [`.ai-dlc/templates/adr.md`](../../../.ai-dlc/templates/adr.md).

| ADR | Decision | Status | Date |
|---|---|---|---|
| [ADR-0001](0001-lua-51-on-vba-rr.md) | Lua 5.1 on VBA-rr as the platform | accepted | 2026-10-29 |
| [ADR-0002](0002-single-generated-script.md) | A single script generated from `src/` with `build.py` | accepted | 2026-10-29 |
| [ADR-0003](0003-separate-bots.md) | Separate bots: the Shiny Bot only searches | accepted | 2026-10-29 |
| [ADR-0004](0004-commented-json-config.md) | Configuration in a commented JSON next to the script | accepted | 2026-10-29 |
| [ADR-0005](0005-simulator-testing.md) | Testing with a game simulator (lupa + mocks) | accepted | 2026-10-29 |
| [ADR-0006](0006-relative-addresses.md) | Battle addresses relative to `gEnemyParty` | accepted | 2026-10-29 |
| [ADR-0007](0007-recorded-routes.md) | Routes to the Center recorded by the player | accepted | 2026-10-29 |
| [ADR-0008](0008-gpl-3-license.md) | GPL-3.0 license | accepted | 2026-10-29 |

ADRs 0001–0007 were recorded after the decision was made (retroactive documentation):
they describe how the code is built today.
