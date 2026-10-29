# ADR-0005 — Testing with a game simulator (lupa + mocks)

> **AI-DLC phase:** `04-testing`  ·  **Status:** accepted
> **Date:** 2026-10-29 (retroactive)  ·  **Owner:** vladeParica

## Context
Testing in the real emulator is slow (minutes or hours per scenario), manual and can't be
automated in CI. ROMs also can't be distributed.

## Decision
Each bot has a **Lua simulator** (`tests/mock*.lua`) that imitates the VBA-rr API, the
relevant memory and the minimum game logic (RNG, battles with real menus, doors, the nurse,
move-learning prompts, evolution). Python with [lupa](https://pypi.org/project/lupa/) runs
the generated bot inside Lua 5.1 against each scenario (`tests/run_*.py`).

## Alternatives considered
- **Manual testing in the emulator only** — no safety net when changing a mode.
- **Headless emulator in CI** — would need the ROM (not distributable).
- **Unit tests of individual functions** — the code lives in a single script with global
  state; the real bugs are in the interaction with the game.

## Consequences
- **Positive:** each scenario runs in seconds; rare cases (lag, half-created Pokémon,
  doors, Pokérus) that are hard to trigger in the game can be reproduced.
- **Costs:** the simulator can diverge from the real game; as a rule, anything only tested
  in the simulator is reported as such. Today the runners **print** each scenario's result
  and a person compares it with the expected one; they don't fail by themselves (see the
  [test strategy](../../04-testing/test-strategy.md)).
