# ADR-0006 — Battle addresses relative to `gEnemyParty`

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-10-29 (retroactive)  ·  **Owner:** vladeParica

## Context
Memory addresses change between USA, Europe and Japan and between revisions (1.0/1.1).
Only the USA version has a verified symbol map (pret/pokefirered). Devon Studios provides,
for each version, a few base addresses (RNG seed, parties, SaveBlocks).

## Decision
The bot detects the game, language and revision from the ROM header (`0x080000AE`,
`0x080000AF`, `0x080000BC`), takes Devon Studios' base addresses for that version, and
computes the rest (battle cursors, `gBattleMons`, `gBattleOutcome`…) as **fixed offsets from
`gEnemyParty`**, measured on USA. `gMain` is estimated from the RNG seed address when not
verified, and the panel shows diagnostics to check it.

## Alternatives considered
- **Full tables per version** — exact, but without a symbol map for EUR/JPN they can't be verified.
- **Pattern search in memory at runtime** — fragile and slow in Lua.

## Consequences
- **Positive:** one codebase for every version; adding a version = 6–8 base addresses.
- **Costs:** on non-USA versions the derived addresses are not verified in the real game.
  The bot warns in the console ("la bandera de combate no está verificada para este
  idioma") and the panel's diagnostics line lets the player check it.
