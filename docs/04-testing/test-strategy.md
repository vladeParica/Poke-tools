# Test strategy — Poke-tools

> **AI-DLC phase:** `04-testing`
> How the bots are verified, including the PRDs' edge cases.

## Levels
| Level | Scope | Tools | What it covers |
|---|---|---|---|
| Build | `src/` → generated `.lua` | `build.py`, CI | That what's committed matches the sources |
| Simulator | Whole bot against an imitated game | Python + lupa (Lua 5.1), `tests/mock*.lua`, `tests/run_*.py` | Modes, filters, RNG, battles, routes, moves, invalid configuration |
| Farm Bot simulator | Whole Farm Bot against `farmbot/tests/mock_farm.lua` | Python + lupa (`farmbot/tests/run_farm.py`, fails on its own) | Every mode to its goal, take-items menus (also with a field move), full bag, pause mode, refusals to start, shipped configs load |
| Configurator unit | `configurator/js/core.js` | Node `node:test` (`configurator/tests/core.test.js`) | Parsing, name normalization, validation rules, serialization format |
| Configurator integration | Exported JSON → real bots | Python + lupa (`configurator/tests/test_bots_accept.py`) | Option parity with the bots' `CONFIG`; every exported example prints "Config cargada" in both bots |
| Configurator UI | The page in a browser | Headless Chrome/Edge (`configurator/tests/ui-smoke.html`) | 29 interaction checks: no page scroll at 1366×768, section tabs and badges, modes, chips, IVs, EVs, routes, ntfy, skins, skin sanitizer |
| Real game | Bot in VBA-rr with the ROM | Manual | What the simulator doesn't imitate: real timings, languages, emulator quirks |

## How to run them
```
pip install -r requirements-dev.txt
python shinybot/build.py && python trainbot/build.py   # must not change any file
cd shinybot/tests && python run_test.py && python run_rng.py && python run_wild.py \
  && python run_cfg.py && python run_far.py && cd ../..
python trainbot/tests/run_train.py && python trainbot/tests/run_learn.py && python trainbot/tests/run_want.py
```
Farm Bot (exits with an error if a scenario fails):
```
python farmbot/build.py && python farmbot/tests/run_farm.py
```

Configurator:
```
python configurator/tools/build_data.py     # must not change configurator/js/data.js
node --test configurator/tests/core.test.js
python configurator/tests/test_bots_accept.py
```
Approximate duration: Shiny Bot ~40 s, Train Bot ~50 s, configurator ~10 s.

## Scenarios and expected results

| Runner | Scenarios | Expected |
|---|---|---|
| `shinybot/tests/run_test.py` | wild, static, gift, roamer (with and without clearing RAM) | All end in `PAUSED` |
| `run_rng.py` | Roamer RNG | Calibrates and finds the target (`PAUSED`) |
| `run_wild.py`, `run_far.py` | Wild RNG, near and far target (Teachy TV) | Gets one step away, calibrates and finds it (`PAUSED`) |
| `run_cfg.py` | Valid JSON in several modes; invalid JSON | `PAUSED` for the valid ones; the invalid one doesn't start (`TIMEOUT` waiting for a fix) |
| `trainbot/tests/run_train.py` | evs, record, pokerus, level, nolearn | Goal EVs and level; route recorded; no overshoot with Pokérus |
| `run_learn.py` | Move learning (`auto`, `never`, `ask` with and without an answer) | Learns or forgets according to the configuration |
| `run_want.py` | `wantedMoves` | Only learns the requested moves |

## Critical paths (always tested)
- Read the Pokémon only when it's complete (3 stable frames).
- No EV overshoot without `allowOvershoot`, also with Pokérus.
- Invalid configuration: don't start and explain the error.
- Go back to the training spot after healing; routes through doors.

## Test data
Scenarios are defined inside each `mock*.lua` and `run_*.py`; they use fictitious save
files (the Shiny Bot's is TID 12345 / SID 54321) and need no ROM.

## Known gaps
| Gap | Risk | Decision |
|---|---|---|
| Runners print results and don't fail by themselves | A regression passes CI if it doesn't raise an exception | Accepted for now: CI catches runtime errors and stale builds (and checks the 8 `PAUSED` in `run_test.py`); adding checks is in the [backlog](../03-implementation/backlog.md) |
| The simulator doesn't imitate real timings or graphics | Something that passes in the simulator fails in the game | Test in the real game before publishing; say so when it wasn't possible |
| EUR/JPN languages untested in the real game | Wrong derived addresses | Console warning + panel diagnostics; pending verification |
| `tools/rng/` has no tests | Wrong search results | Validated when the seeds are used in the game |
