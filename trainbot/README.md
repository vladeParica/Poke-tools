# Train Bot — `FRLG_TrainBot.lua`

Trains the **first Pokémon in your party** to exact EVs and/or a level: it picks which
opponents to fight, uses the most damaging move, learns the moves you want and walks back
to the Pokémon Center to heal on its own.

## Usage

1. Copy `FRLG_TrainBot.lua` and a JSON (the one in this folder or one from
   [`examples/configs/`](examples/configs/)) named `FRLG_TrainBot.json`.
2. Put the Pokémon you want to train **first in the party**.
3. Have a route to the Pokémon Center:
   - **Use a recorded one** from [`examples/routes/`](examples/routes/) (Diglett's Cave →
     Speed, Pokémon Tower → Sp. Atk), or
   - **record your own** (once): **6** at the training spot → walk until you stand in front
     of the nurse (or inside the healing area with `"healMode": "tile"`) → **6** → walk back
     to the spot → **6**.
4. Press **7** to start.

| Key | Action |
|---|---|
| **6** | Record the route to the Center (there and back) |
| **7** | Start / stop |
| **8** | Full summary: stats, IVs, EVs, moves |
| **9** | Panel: compact, full or hidden |
| **0** | Reload the JSON (with the bot stopped) |

## Configuration

Use the [configurator](../configurator/README.md) or edit `FRLG_TrainBot.json`, commented line by line (in Spanish):

- **Goal:** `evs`, `targetLevel`, `maxLevel`, `allowOvershoot`.
- **Opponents:** `species` (only these), `avoidSpecies` (never these).
- **Battle:** `healBelow`, `fleeBelow`, `minPP`.
- **Moves:** `learnMoves` (`auto`, `never`, `ask`), `wantedMoves`, `keepMoves`, `askTimeout`.
- **Other:** `evolve`, `stopOnShiny`, `healMode` (`nurse` or `tile`), `routeFile`.
- **Pickup (optional):** `pickup`, `pickupTakeAt`. See [below](#pickup-while-training).
- **Phone notifications:** `notify` with ntfy or a Discord webhook.
- **Language:** `language` (`"es"`, `"en"` or `"ja"` in romaji) for the panel, console and log.

Full reference in [docs/02-design/api-contracts.md](../docs/02-design/api-contracts.md).

## When it stops

- **Training complete** (EVs and level reached): it heals at the Center (if a route is recorded)
  and pauses.
- **Phase complete**: if you train in phases (e.g. Attack on Route 24 with
  `"species": ["Bellsprout", "Weepinbell"]`, Speed later somewhere else), when no species in
  `species` gives a missing EV any more it heals and pauses with "FASE TERMINADA" and the EVs
  still missing. Without a `species` list, the same after 40 battles in a row without a useful
  opponent. Change the area and the species, and press 7. It also stops when the Pokémon has 510
  EVs in total and the missing ones can't fit.
- **A wild Pokémon won't let it run** (Arena Trap, Shadow Tag, Mean Look…): it fights, unless
  beating it would push an EV past your goal; then it pauses and notifies you to finish the
  battle yourself (catching it gives no EVs). EVs never go past the goal unless `allowOvershoot`.

## Pickup while training

Optional, off by default. Fill party slots 2 to 6 with Pokémon that have **Pickup** (Meowth),
keep the one you train first, and set `"pickup": "auto"`:

- Pickup works only after a **won** battle, which is what training does. Each Pickup Pokémon
  that holds nothing may find an item.
- When enough Pickup Pokémon hold an item (half of them by default, e.g. 3 of 5, or
  `pickupTakeAt` of them), the bot opens
  START → POKéMON → the Pokémon → ITEM → TAKE and stores each item in the bag. Every step is
  checked in memory.
- Before training ends it takes whatever is left, so nothing stays on them.
- The first Pokémon is never touched: it may be holding a Macho Brace on purpose.
- Pickup Pokémon don't fight, so they gain no EVs or experience.
- If the trained Pokémon faints and running fails, the bot sends out the healthy Pokémon with
  the highest level and runs. If the wild Pokémon won't let it run (Shadow Tag, Arena Trap,
  Mean Look, Wrap…), it fights instead.

The menu automation is the Farm Bot's and works on the **USA** versions (FireRed/LeafGreen 1.0
and 1.1). On other versions, or with `"pickup": "pause"`, the bot pauses and notifies you so you
take the items yourself. It is tested only in the simulator: keep an eye on the first trips and
make room in the bag.

## Examples

- [`examples/configs/`](examples/configs/): ready-made configs per stat
  (Speed in Diglett's Cave, Sp. Atk in the Pokémon Tower).
- [`examples/routes/`](examples/routes/): routes ready to reuse.
