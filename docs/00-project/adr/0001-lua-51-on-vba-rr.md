# ADR-0001 — Lua 5.1 on VBA-rr as the platform

> **AI-DLC phase:** `00-project`  ·  **Status:** accepted
> **Date:** 2026-10-29 (retroactive)  ·  **Owner:** vladeParica

## Context
The bots need to read the game's memory every frame, press buttons with one-frame
precision, load states and draw text over the screen. The owner plays on VBA-rr, and the
reference RNG tools (Devon Studios) are written for VBA-rr.

## Decision
The bots are **Lua 5.1 scripts for VBA-rr**: they use its API (`memory`, `joypad`, `emu`,
`savestate`, `gui`, `input`) and only the Lua 5.1 standard library.

## Alternatives considered
- **BizHawk** — more modern Lua and better debugging, but the owner doesn't use it and the
  memory/button API is different. Devon Studios has a BizHawk version if we ever port.
- **mGBA (Lua 5.4 scripting)** — recent and different API; the emulator access layer would
  have to be rewritten.
- **External program driving the emulator** — more complex and without frame precision.

## Consequences
- **Positive:** direct access to memory and frames; compatible with Devon Studios'
  addresses and tables.
- **Costs:** Lua 5.1 (no 64-bit integers or bitwise operators: `bit`/own helpers are used);
  VBA-rr quirks to work around (error dialog from `savestate.create(n)`, *Pause When
  Inactive*). Porting to another emulator means rewriting the access layer.
