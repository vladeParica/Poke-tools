# ADR-0016 — Fishing RNG presses B on the "on the hook!" text

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-11-21  ·  **Owner:** vladeParica

## Context
The Shiny Bot had no fishing at all. Fishing is the only way to get some Pokémon (Dratini,
Horsea, Krabby…), and the owner asked for both a plain fishing mode and an RNG one, the RNG one
being the important one.

In the other RNG modes the delay between the bot's press and the moment the game generates the
Pokémon is fixed, so the bot calibrates it once and presses on the exact frame. Fishing looks
different: in pret's `Task_Fishing` (`field_player_avatar.c`) a cast spends a random number of
dots (4 to 10, 20 frames each, from `Random() % 10`), then `Random() & 1` decides whether
anything bites. The time from SELECT to the encounter is not fixed.

Reading the same code more closely:
- On a bite FRLG skips the reel-in steps (`Fishing7` adds 3 to the step) and goes straight to
  "A POKéMON's on the hook!", a text that ends in `{PAUSE_UNTIL_PRESS}`: it waits for A or B
  for as long as it takes.
- The VBlank handler (`main.c`) calls `Random()` once per frame, so the RNG keeps advancing while
  that text waits.
- One frame after the press, `FishingWildEncounter` generates the Pokémon like a wild one
  (Method H-1): a slot from `Random() % 100` over the rod's part of the 10-slot fishing table
  (Old Rod 70/30, Good Rod 60/20/20, Super Rod 40/40/15/4/1), level, nature, PID, IVs.

## Decision
1. **The base is the hook text.** The bot casts (SELECT, the registered rod) until something
   bites, waits for the text to finish printing, and saves the state there. From then on it is
   the Static RNG flow with B instead of A: calibrate the delay from one press, search a target,
   wait on the text and press B on the exact frame, reload the base on a miss.
2. **The bot reads the fishing task instead of predicting the dots.** It finds `Task_Fishing` in
   `gTasks` by its address (pret `symbols` branch, the four USA builds, in `Game.taskFishing`)
   and looks at its step: the hook text, or "Not even a nibble", which it closes with B before
   casting again.
3. **The generation reuses the Wild RNG code** (`predictWild`, `findWildE`, the far search) with
   the fishing slot thresholds and the fishing table of the map (`gWildMonHeaders` + 16).
4. **Plain fishing (mode 11) closes every text with B.** On the map, A facing water would offer
   Surf; B does nothing there and also closes the fishing texts.
5. **No Teachy TV in Fishing RNG.** SELECT holds the rod, and the base is inside the fishing
   task. The search is limited by its own `fishSearch` (default 1 000 000 advances, about
   4.6 hours at normal speed, minutes with the emulator's speed-up).

## Alternatives considered
- **Simulate the whole cast from the SELECT frame** (dots and bite from the RNG at each step):
  every frame offset of the task would have to match the real game, which can't be tested here,
  and a wrong offset would miss every target. Pressing B from a saved hook text needs only the
  one delay the bot already measures.
- **Detect the bite by timing or by the screen**: the dots make the timing variable, and VBA-rr
  gives no reliable way to read the text box. The task's step is exact.
- **Swap the registered item to the Teachy TV and back** (it is one word in SaveBlock1) to reach
  far targets: possible later, but it changes the save and adds a phase that can't be tested in
  the real game yet.

## Consequences
- Fishing RNG works only on the four USA builds; on others the bot refuses and points to the
  plain fishing mode. Adding a build means adding its `Task_Fishing` address.
- Far targets (strict IV filters) need long waits on the hook text; the bot saves a state near
  the target (`saveNear`) so retries don't wait from the base again.
- `mock_fish.lua` follows `Task_Fishing` step by step (dots, bite, the text that waits, the
  generation) so the flow is tested; the real game still has to confirm the measured delay and
  the text wait (`FR.TEXT_WAIT`, 240 frames).
