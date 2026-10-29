# Backlog and implementation notes — Poke-tools

> **AI-DLC phase:** `03-implementation`
> What is done, what is left and what a maintainer needs to know.

## Status
Shiny Bot v4.3 and Train Bot v1.10 work and have been used in the real game (FireRed USA).
The AI-DLC documentation was written after the code.

## Done
- [x] Shiny Bot: 10 modes, shiny / nature / IV / Hidden Power filters, multiple instances.
- [x] Shiny Bot: Wild RNG one step before the encounter, Teachy TV for far targets.
- [x] Shiny Bot: initial seed chained with another mode; pick TID/SID on a new game.
- [x] Train Bot: exact EVs and levels, battle decisions with the Gen 3 damage formula.
- [x] Train Bot: move learning (`auto`, `never`, `ask`, `wantedMoves`, `keepMoves`), evolution.
- [x] Train Bot: recorded routes, healing with the nurse or a tile, ntfy/Discord notifications.
- [x] RNG tools outside the emulator (`tools/rng/`).
- [x] Simulators and test scenarios for both bots.
- [x] AI-DLC documentation, CI, license, logo and GitHub templates.

## Pending
- [ ] Make the test runners **fail by themselves** when a scenario doesn't give the
  expected result (today they print and a person compares) — see the [test strategy](../04-testing/test-strategy.md).
- [ ] Verify the derived addresses for EUR and JPN in the real game ([ADR-0006](../00-project/adr/0006-relative-addresses.md)).
- [ ] Ideas from Devon Studios' scripts: Pickup RNG, critical hits, BizHawk version
  ([credits](../00-project/credits.md)).

## Implementation notes
- **Never edit the generated `.lua` files**: edit `src/` and run `build.py`
  ([ADR-0002](../00-project/adr/0002-single-generated-script.md)). CI fails if they don't match.
- **Game and emulator behaviors already discovered** (half-created Pokémon, evolution with
  `inBattle` set, doors that move the SaveBlock, purified zone, Snorlax,
  `savestate.create`): see the corresponding section of [`CLAUDE.md`](../../CLAUDE.md).
- **Memory addresses**: table in `CLAUDE.md`; everything battle-related is relative to
  `gEnemyParty`.
- `trainbot/src/train_tables.lua` is regenerated with `python trainbot/tools/gen_tables.py`
  (downloads pokefirered to `tools/pret_cache/`, ignored by git).
- The Train Bot includes the Shiny Bot's name tables (`shinybot/src/tables2.lua`) when
  built: changing them affects both.

## Deviations from design
| Design said | We did | Why | ADR |
|---|---|---|---|
| — | — | The documentation describes the existing code; no deviations recorded | — |
