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
- **Phone notifications:** `notify` with ntfy or a Discord webhook.
- **Language:** `language` (`"es"`, `"en"` or `"ja"` in romaji) for the panel, console and log.

Full reference in [docs/02-design/api-contracts.md](../docs/02-design/api-contracts.md).

## Examples

- [`examples/configs/`](examples/configs/): ready-made configs per stat
  (Speed in Diglett's Cave, Sp. Atk in the Pokémon Tower).
- [`examples/routes/`](examples/routes/): routes ready to reuse.
