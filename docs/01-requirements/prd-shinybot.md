# PRD — Shiny Bot

> **AI-DLC phase:** `01-requirements`  ·  **Status:** approved (retroactive documentation of v4.3)
> **Author:** vladeParica  ·  **Date:** 2026-10-29

## 1. Problem
Getting a shiny Pokémon, or one with a specific nature and IVs, takes thousands of blind
soft resets or pressing a button on the exact frame the RNG dictates. The player wants to
say **what** they are looking for and let the bot get it.

## 2. Actors
- **Player**: fills in the JSON, positions the character and saves the state at the end.
- Bot **instance** (there can be several in parallel).
- **Game** (FRLG ROM) inside **VBA-rr**.

## 3. Main flow
1. The player saves in front of the target (or in the grass), fills in the JSON and loads
   the script; the bot resets the game (`resetOnLoad`).
2. They pick the **mode** (key 8) and press **7**.
3. **Blind modes** (Wild, Static, Gift, Roamer): repeat soft resets or encounters and read
   the created Pokémon until it matches the filter.
4. **RNG modes**: calibrate the delay, find the next **target** within `farSearch`
   advances, wait (or use the Teachy TV if it's far) and press on the exact frame; on a
   miss, correct by ±1, ±2… up to `triesPerTarget`.
5. **Initial seed**: tries timings on the title screen until it hits one of
   `initialSeeds`, loads the save and chains `afterSeedMode`.
6. **New game**: restarts the new-game creation until `TID xor SID` falls in `newGameTSV`.
7. On a match: writes the log, tells the other instances (`stopOthers`) and **pauses the
   game** so the player can save the state.

## 4. Business rules
- Shiny: `(TID ^ SID ^ PIDhigh ^ PIDlow) < 8`.
- Method 1 for statics, gifts, starters and roamers; Method H-1 for wild Pokémon (slot,
  level, nature, PID pairs, IVs).
- In FRLG, Synchronize and Cute Charm have **no** effect; the bot doesn't use them.
- Combinable filters: `shiny`, `species`, `natures`, `minIVs`/`maxIVs`, `minIVTotal`,
  `hiddenPower`. Natures and stats in English or Spanish.
- Each reset can only reach seeds of one class mod 64: it pays to provide many seeds.

## 5. Edge, abuse and risk scenarios
| Scenario | Expected behavior |
|---|---|
| The Pokémon is half-created when the frame ends | Read it only after 3 stable frames and with level 1–100 |
| JSON with errors (unknown nature, invalid type) | Doesn't start; explains the error in the console and waits for a fix and key 0 |
| No target within `farSearch`, or several misses in a row | With `reseed`, soft reset for another seed (up to `maxReseeds`); otherwise stops with a message |
| The requested seed can't be reached from the title screen | Keeps trying timings; message suggesting more seeds |
| Lag or variable delay between the press and the creation | Recalibrate; correct the advance (±1, ±2…) |
| Several instances pressing at once | Each has its own `inst_N.lock`; the one that finds the target creates `shiny_stop.flag` and the others stop |
| Numbered `savestate.create(n)` in VBA-rr | Not used by default (`savestateSlot: null`): it opens an error dialog |
| *Pause When Inactive* turned on | Documented: the emulator stops when unfocused; it must be off |
| Snorlax (Poké Flute + `setwildbattle`) | The PID is created before the battle; Static RNG mode handles it by pressing only A |
| Unverified language (EUR/JPN) | Console warning; the panel lets the player check the battle flag |

## 6. Acceptance criteria
- [x] In the simulator, Wild, Static, Gift and Roamer modes end in `PAUSED` with a Pokémon
  that matches the filter (`run_test.py`).
- [x] RNG modes calibrate and hit the target in the simulator (`run_rng.py`,
  `run_wild.py`, `run_far.py`).
- [x] An invalid JSON doesn't start the bot and shows the error (`run_cfg.py`).
- [ ] Every new or modified mode is confirmed in the real game before it's published.

## 7. Out of scope
- Training, battling or moving around the map beyond walking in grass ([ADR-0003](../00-project/adr/0003-separate-bots.md)).
- Catching the Pokémon: the player does it after the pause.
- Eggs and breeding, Pickup, critical hits.

## 8. Open decisions
- None for this version.
