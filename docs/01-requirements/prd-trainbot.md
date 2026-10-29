# PRD — Train Bot

> **AI-DLC phase:** `01-requirements`  ·  **Status:** approved (retroactive documentation of v1.10)
> **Author:** vladeParica  ·  **Date:** 2026-10-29

## 1. Problem
Training exact EVs takes hundreds of battles against specific species, running from the
rest, healing in time and not overshooting the target. One mistake (an extra battle
against the wrong species) ruins the spread. The player wants to set the EVs and level and
let the bot do it.

## 2. Actors
- **Player**: fills in the JSON, records (or picks) the **route**, positions the character.
- **Train Bot** (a single instance).
- Optional **notification service**: ntfy.sh or a Discord webhook.

## 3. Main flow
1. The player puts the Pokémon to train first in the party, sets `evs` / `targetLevel` and
   the route, and presses **7** at the training spot.
2. The bot walks in the grass (`walkAxis`, `walkFrames`) until a battle starts.
3. In battle it decides: **fight** if the species gives useful EVs (or is in `species`)
   and isn't in `avoidSpecies`; otherwise **run**.
4. It picks the most damaging move (Gen 3 damage formula, STAB, types, abilities;
   physical/special by type).
5. It handles what happens in battle: level-ups, move learning
   (`learnMoves`/`wantedMoves`/`keepMoves`), evolution (`evolve`), wild shinies (`stopOnShiny`).
6. After each battle it adds up the EVs gained; if HP is below `healBelow` or PP below
   `minPP`, it walks the `GO` route, heals (nurse or tile) and returns via `BACK`.
7. When the goal is reached it stops, logs it, notifies (`notify`) and pauses the game.

## 4. Business rules
- EVs: max 255 per stat and 510 total. Pokérus ×2 and Macho Brace ×2 per battle.
- Without `allowOvershoot`, it doesn't fight if the battle would push it past the goal; if
  every battle gives more EVs than are missing, it stops and explains why.
- With `learnMoves: "auto"` it learns a move if it does more damage than the worst one; it
  never forgets HMs or `keepMoves`; with `wantedMoves` it only learns those.
- `evolve: false` cancels evolution by holding B.
- Physical/special by type (Normal, Fighting, Flying, Poison, Ground, Rock, Bug, Ghost,
  Steel = physical).

## 5. Edge, abuse and risk scenarios
| Scenario | Expected behavior |
|---|---|
| Opponent with Selfdestruct / Explosion | The default `avoidSpecies` avoids them (Geodude, Voltorb, Koffing…) |
| The Pokémon faints and wakes up in the Center | If it's on the way back, it follows it; otherwise it stops with a message |
| The character isn't at the training spot or on the route | Doesn't start: "El personaje no está en el punto de entreno" |
| Recorded route with bogus steps at doors | `cleanRoute()` filters them on load and saves the fixed route |
| An NPC blocks the route | Stops: "No pude volver al punto de entreno" |
| Evolution scene while `gMain.inBattle` is still set | Told apart by `callback2`; holds B if `evolve: false` |
| Move-learning prompt (opcodes 0x5A/0x5B) | Answers according to `learnMoves`; with `ask` it notifies and waits `askTimeout` |
| A wild shiny appears | Pauses (`stopOnShiny`) and notifies |
| Two windows running the Train Bot | The second one doesn't start (recent `train_running.lock`) |
| `notify` with a malicious topic or URL | Only accepts a `[A-Za-z0-9_-]` topic and an `https://` URL with safe characters; the text is filtered before reaching curl |
| Pokérus or Macho Brace make the exact number impossible | Stops and suggests `allowOvershoot` or another method |

## 6. Acceptance criteria
- [x] The `evs`, `record`, `pokerus`, `level` and `nolearn` scenarios end with the
  requested EVs and level in the simulator (`run_train.py`).
- [x] Learns and rejects moves according to `learnMoves` and `wantedMoves` (`run_learn.py`, `run_want.py`).
- [x] Records, cleans and replays the route, including the healing tile (`tile`).
- [ ] Every change is confirmed in the real game before it's published.

## 7. Out of scope
- Training more than one Pokémon at a time, or one that isn't first (Exp. Share).
- Using items in battle or vitamins.
- Computing paths on its own ([ADR-0007](../00-project/adr/0007-recorded-routes.md)).

## 8. Open decisions
- None for this version.
