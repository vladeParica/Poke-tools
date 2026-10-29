# Project charter — Poke-tools

> **AI-DLC phase:** `00-project`  ·  **Status:** approved (retroactive documentation)
> **Owner:** vladeParica  ·  **Date:** 2026-10-29

## Vision
Getting a shiny, perfect Pokémon in FireRed / LeafGreen, and training it to exact EVs,
should be a matter of filling in a JSON file and leaving the emulator running, not hours
of manual resets and battles.

## Context
In Gen 3, everything random comes from a single generator (LCRNG) whose state can be read
from memory. Tools like [Devon Studios'](https://github.com/DevonStudios/LuaScripts) show
that state on screen, but the player still has to press the button on the exact frame,
walk to the encounter or fight hundreds of battles for EVs. VBA-rr lets a Lua script read
memory and press buttons, so that part can be automated.

## Problem
For a FRLG player on an emulator:
- RNG manipulation needs one-frame precision (1/60 s) and a lot of repetition.
- Blind soft resetting can take thousands of attempts.
- Training exact EVs is tedious and easy to ruin (one extra battle against the wrong species).

## Scope
**In scope**
- Shiny Bot: searching for shinies / natures / IVs, blind and with RNG (statics, gifts,
  roamers, wild), initial seed and new-game SID.
- Train Bot: EVs and levels, choice of opponent and move, move learning, evolution, trips
  to and from the Pokémon Center, phone notifications.
- RNG calculation tools outside the emulator (`tools/rng/`).
- FireRed and LeafGreen, USA and Europe (ESP, FRA, ITA, GER); JPN with its own addresses.

**Out of scope (explicit)**
- Other games (Ruby/Sapphire/Emerald, Gen 4–5) — Devon Studios' scripts already cover them;
  they could be ported later.
- Other emulators (BizHawk, mGBA) — see [ADR-0001](adr/0001-lua-51-on-vba-rr.md).
- Distributing ROMs, save files or savestates.
- Online play, real trades or anything on original hardware.

## Success metrics
- A reachable RNG target (within `farSearch`) is obtained with no intervention other than
  saving the state at the end.
- The Train Bot finishes with **exactly** the requested EVs (no overshoot when
  `allowOvershoot` is false).
- No change in one mode breaks another: every simulator test keeps giving the expected result.
- Modes are validated in the real game before they are considered done (not only in the simulator).

## Principles (non-negotiable)
- **Don't break what already works.** A change in one mode must not affect the others.
- **The Shiny Bot only searches.** New things go in separate scripts ([ADR-0003](adr/0003-separate-bots.md)).
- **Everything the player sees in the game is in Spanish** (panel, console, logs, JSON).
- **Honesty about testing:** anything only tested in the simulator is reported as such.
- **ROMs, save files and savestates are never committed** to the repository.
- **The repository is generic:** nothing from a specific save file.

## Key risks
| Risk | Impact | Mitigation |
|---|---|---|
| Memory addresses differ by language/revision | The bot reads garbage or misses battles | Addresses relative to `gEnemyParty` ([ADR-0006](adr/0006-relative-addresses.md)); console warning when the language isn't verified; diagnostics in the panel |
| The simulator doesn't reproduce the real game | A change passes tests and fails in the emulator | Test in the game before calling something done; document what wasn't tested |
| VBA-rr quirks (error dialogs, pauses) | The bot gets stuck | Documented in `CLAUDE.md`; numbered `savestate.create` is avoided and *Pause When Inactive* must be off |
| Two instances pressing buttons at once | Erratic actions | Lock files (`inst_N.lock`, `train_running.lock`) |
| License of the code base (GPL-3.0) | Obligations when redistributing | Repository under GPL-3.0 ([ADR-0008](adr/0008-gpl-3-license.md)) |

## Open decisions
- None. The GPL-3.0 license was accepted in [ADR-0008](adr/0008-gpl-3-license.md).
