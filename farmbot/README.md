# Farm Bot — `FRLG_FarmBot.lua`

> [!WARNING]
> **Experimental.** The Farm Bot is new and has only been tested in the simulator, not in the
> real game. It is not stable yet and may fail: menus may be navigated wrongly, items may not
> be taken, or the bot may stop mid-run. Save your game before using it and keep an eye on it.
> Please report what you find in an [issue](https://github.com/vladeParica/Poke-tools/issues).

Farms **items, levels or money** in FireRed / LeafGreen. It's a separate script: it doesn't
change the Shiny Bot or the Train Bot (it starts from a copy of the Train Bot's battle engine,
see [ADR-0011](../docs/00-project/adr/0011-farm-bot-forked-from-train-bot.md)).

## Modes

| `mode` | What it farms | What you need |
|---|---|---|
| `nivel` | Experience: fights every wild Pokémon until the first party Pokémon reaches `targetLevel` | A grassy spot |
| `objetos` | Items from **Pickup**: wins battles (Pickup only works after a **win**) and moves the items to the bag | One or more Pokémon with Pickup (e.g. Meowth) in the party |
| `robar` | Items wild Pokémon hold: uses **Thief / Covet** only when the wild Pokémon holds an item you want, then runs | Thief (TM46) or Covet on the first party Pokémon, holding nothing |
| `dinero` | Money from **trainer rematches**: uses the **VS Seeker** and walks a recorded route past the trainers | VS Seeker registered on SELECT, and the trainer route (key 5) |

When Pokémon are holding items (`objetos`, `robar`), the bot opens START → POKéMON → the
Pokémon → ITEM → TAKE and checks every step in memory. This automatic menu navigation works on
the **USA** versions (FireRed/LeafGreen 1.0 and 1.1); on other versions, or with
`"takeItems": "pause"`, the bot pauses and notifies you so you take them yourself.

> Menu automation, trainer battles and the VS Seeker are the least proven parts: tell us how
> they behave in your game.

## Usage

1. Copy `FRLG_FarmBot.lua` and `FRLG_FarmBot.json` (or one from [`examples/`](examples/)) into a
   folder. The easiest way to edit the JSON is the [configurator](../configurator/README.md)
   (*Farm Bot* tab).
2. Put the Pokémon that fights **first in the party**.
3. Routes:
   - **To the Pokémon Center (key 6)** — same as the Train Bot; its `FRLG_TrainRoute.txt` works here.
   - **Past the trainers (key 5, `dinero` mode)** — stand where you'll use the VS Seeker, press 5,
     walk through the trainers' lines of sight to the end, press 5, walk back to the start, press 5.
4. Press **7**.

| Key | Action |
|---|---|
| **4** | Diagnostic: shows what the bot reads from the menus, never presses a button |
| **5** | Record the trainer route (`dinero`) |
| **6** | Record the route to the Center |
| **7** | Start / stop |
| **8** | Full Pokémon summary |
| **9** | Panel: compact, full or hidden |
| **0** | Reload the JSON (with the bot stopped) |

## Configuration

`FRLG_FarmBot.json`, commented line by line (in Spanish):

- **Mode and goal:** `mode`, `targetLevel`, `itemTarget`, `moneyTarget`, `maxBattles`.
- **Items:** `takeItems` (`auto` or `pause`), `wantedItems` (English item names, `robar`).
- **Opponents:** `species`, `avoidSpecies` (`nivel` and `objetos`; `robar` and `dinero` run from wild Pokémon they don't need).
- **Battle, moves, healing, notifications:** same options as the Train Bot.
- **Routes:** `routeFile` (Center), `trainerRouteFile` (trainers), `healMode`.

Full reference in [docs/02-design/api-contracts.md](../docs/02-design/api-contracts.md).

## Examples

| File | What it does |
|---|---|
| [`FRLG_FarmBot_Nivel.json`](examples/FRLG_FarmBot_Nivel.json) | Level the lead to 50 |
| [`FRLG_FarmBot_Recogida.json`](examples/FRLG_FarmBot_Recogida.json) | Collect 20 items with Pickup |
| [`FRLG_FarmBot_Robar_MtMoon.json`](examples/FRLG_FarmBot_Robar_MtMoon.json) | Steal mushrooms (Paras) and Moon Stones (Clefairy) in Mt. Moon |
| [`FRLG_FarmBot_Dinero.json`](examples/FRLG_FarmBot_Dinero.json) | Trainer rematches up to $500,000 |

## Checking it in your game (key 4)

Before the first run, use the diagnostic to check that the bot reads your game correctly.
It only reads memory and never presses a button:

1. With the bot stopped, press **4**.
2. Open START by hand and move the cursor: the panel must name the option you're on
   (POKEMON, MOCHILA…).
3. Enter POKéMON and pick a Pokémon: the panel must show the right Pokémon and its item,
   and then the action list (DATOS, MOVER, OBJETO…) with the cursor on the right option.
4. Check that SELECT shows the VS Seeker (`dinero`), and that money and Pickup Pokémon match.
5. Press **4** again to leave.

Every change is written to `logs/farm_log.txt` as a `DIAG` line. If something doesn't match
the screen, attach those lines to an [issue](https://github.com/vladeParica/Poke-tools/issues).

## Good to know

- Pickup gives an item 10% of the time per Pickup Pokémon per **won** battle; the item table is fixed in FRLG.
- Wild Pokémon hold their common item 50% of the time and the rare one 5% of the time.
- The VS Seeker needs 100 steps to recharge; the bot walks back and forth at the start until it's charged.
- Trainer battles can't be fled: keep `healBelow` high in `dinero`. If the lead faints against a
  trainer, or a double battle starts, the bot stops and lets you finish it.
- Don't run the Farm Bot and the Train Bot at the same time: the Farm Bot refuses to start if it
  sees the Train Bot running.
