# Contracts — Poke-tools

> **AI-DLC phase:** `02-design`
> There is no network API. The public contracts are what the player writes or keeps: the
> **configuration JSON**, the **route file**, the **keys** and the **files each bot
> generates**. Changing any of them breaks users' configuration or routes: record it in
> `CHANGELOG.md`.
>
> **Source of truth:** the `CONFIG` table at the top of `shinybot/src/bot_body.lua` and of
> `trainbot/src/train_body.lua` (defaults), and each bot's commented JSON.

## JSON conventions
- File `FRLG_ShinyBot.json` / `FRLG_TrainBot.json` in the **same folder** as the script.
- JSON with `//` comments ([ADR-0004](../00-project/adr/0004-commented-json-config.md)).
- `null` (or omitting the key) = default value.
- Stats: `hp, atk, def, spa, spd, spe` or the Spanish `ps, ata, def, ate, dfe, vel`.
- Natures in English or Spanish; species and moves by their English in-game name.
- Errors: the bot doesn't start, lists them in the console and waits for **0** to be pressed.

## Shiny Bot — `FRLG_ShinyBot.json`

| Key | Type | Default | What it does |
|---|---|---|---|
| `shiny` | bool | `true` | Require shiny |
| `species` | list of text | `null` | Only these species (wild modes) |
| `natures` | list of text | `null` | Accepted natures |
| `minIVs` / `maxIVs` | object stat → 0–31 | `null` | IV range |
| `minIVTotal` | number 0–186 | `null` | Minimum IV sum |
| `hiddenPower` | `{type, minPower}` | `null` | Hidden Power |
| `mode` | text | `null` (the bundled JSON uses `"Salvaje RNG"`) | Mode on load (Spanish name) |
| `newGameTSV` | list of hex text | `null` = TSVs that give a shiny 6×31 Ditto | New game |
| `initialSeeds` | list of hex text | `null` | Seeds for Initial seed mode |
| `afterSeedMode` | text | `null` | Mode to launch after hitting the seed |
| `walkAxis` | `"horizontal"` \| `"vertical"` | `"horizontal"` | Walking axis |
| `walkFrames` | number | `16` | Frames per step |
| `holdB` | bool | `false` | Run (Wild only) |
| `wildOneStep` | bool | `true` | Wild RNG: get one step away from the encounter first |
| `pressGapMin` / `pressGapMax` | number | `2` / `24` | Random wait between A presses |
| `resetTimeout` | number | `5400` | Frames without a result before resetting |
| `farSearch` | number | `20000000` | Advances to scan for a target |
| `teachy` | bool | `true` | Use the Teachy TV (registered on SELECT) |
| `teachyBeyond` | number | `5000` | Use it if it saves more than this many advances |
| `teachyMargin` | number | `null` = delay + 1500 | Close it this many advances before |
| `triesPerTarget` | number | `10` | Correction attempts per target |
| `reseed` | bool | `true` | Soft reset for another seed if there is no target |
| `reseedAfterFailedTargets` | number | `3` | Failed targets before changing seed |
| `maxReseeds` | number | `10` | Maximum seed changes |
| `savestateSlot` | 1–10 | `null` | Save a state automatically (errors on VBA-rr v22) |
| `logFile` | text | `"shiny_log.txt"` | Match log |
| `stopOthers` | bool | `true` | Stop other instances on a match |
| `sharedDir` | text | `null` = script folder | Folder shared between instances (`logDir` goes inside) |
| `logDir` | text | `"logs"` | Subfolder for logs and working files |
| `resetOnLoad` | bool | `true` | Reset the game when the script loads |

Obsolete, ignored: `rngMaxSearch`, `wildMaxSearch`, `reseedBeyond`.

## Train Bot — `FRLG_TrainBot.json`

| Key | Type | Default | What it does |
|---|---|---|---|
| `evs` | object stat → 0–255 | `null` = level only | Target EVs (max 510 total) |
| `targetLevel` | number | `null` | Target level |
| `maxLevel` | number | `null` | Stop at this level even if EVs are missing |
| `species` | list of text | `null` = based on EVs | Only fight these |
| `avoidSpecies` | list of text | `null` (the bundled JSON lists the self-destructing ones) | Never fight these |
| `allowOvershoot` | bool | `false` | Allow going past the goal |
| `healBelow` | % | `40` | Heal after a battle below this HP % |
| `fleeBelow` | % | `20` | Run mid-battle below this % |
| `minPP` | number | `3` | Heal if fewer PP are left in damaging moves |
| `learnMoves` | `"auto"` \| `"never"` \| `"ask"` | `"auto"` | What to do with new moves |
| `wantedMoves` | list (max 4) | `null` | Only learn these |
| `keepMoves` | list | `null` | Never forget these |
| `askTimeout` | seconds | `300` | With `ask`: how long to wait before deciding alone |
| `evolve` | bool | `false` | Allow evolution |
| `stopOnShiny` | bool | `true` | Pause on a wild shiny |
| `notify` | `{ntfy, discord}` | `null` | Phone notifications |
| `walkAxis` / `walkFrames` | same as the Shiny Bot | | |
| `routeFile` | text | `"FRLG_TrainRoute.txt"` | Route file |
| `healMode` | `"nurse"` \| `"tile"` | `"nurse"` | Nurse or healing tile |
| `logFile` / `logDir` | text | `"train_log.txt"` / `"logs"` | Log |

`notify.ntfy` must match `[A-Za-z0-9_-]+`; `notify.discord` must start with `https://`.
Otherwise the notification isn't sent.

## Farm Bot — `FRLG_FarmBot.json`

| Key | Type | Default | What it does |
|---|---|---|---|
| `mode` | `"nivel"` \| `"objetos"` \| `"robar"` \| `"dinero"` | `"nivel"` | What to farm |
| `targetLevel` | number 1–100 | `null` | `nivel`: stop at this level (required unless `maxBattles`) |
| `itemTarget` | number | `null` | `objetos`/`robar`: stop after storing this many items |
| `takeItems` | `"auto"` \| `"pause"` | `"auto"` | Take held items through the menu, or pause and notify |
| `wantedItems` | list of English item names | `null` = any | `robar`: only steal these |
| `moneyTarget` | number 1–999999 | `null` | `dinero`: stop at this amount |
| `trainerRouteFile` | text | `"FRLG_FarmTrainers.txt"` | `dinero`: route recorded with key 5 |
| `maxBattles` | number | `null` | Stop after this many battles (any mode) |
| `species`, `avoidSpecies`, `healBelow`, `fleeBelow`, `minPP`, `learnMoves`, `wantedMoves`, `keepMoves`, `askTimeout`, `evolve`, `stopOnShiny`, `notify`, `walkAxis`, `walkFrames`, `routeFile`, `healMode` | | as in the Train Bot | `fleeBelow` doesn't apply to trainer battles |
| `logFile` / `logDir` | text | `"farm_log.txt"` / `"logs"` | Log |

The trainer route file has the same format as the Center route; its `GO` and `BACK` start and
end at the spot where the VS Seeker is used.

## Route file — `FRLG_TrainRoute*.txt`

```
GO group map x y dir;group map x y dir;...
BACK group map x y dir;...
```
- `GO`: from the training spot to the healing place. `BACK`: the way back.
- `x`, `y`: memory coordinates (map tile + 7). `dir`: 0 none, 1 down, 2 up, 3 left, 4 right.
- The last step of `BACK` is the **training spot**. Details and ready-made routes in
  [`trainbot/examples/routes/`](../../trainbot/examples/routes/README.md).

## Keys

| Key | Shiny Bot | Train Bot |
|---|---|---|
| 5 | — | — (Farm Bot: record the trainer route) |
| 6 | — | Record route (there, heal, back) (Farm Bot: same) |
| 7 | Start / stop | Start / stop |
| 8 | Change mode | Full Pokémon summary |
| 9 | Panel compact / full / hidden | Panel compact / full / hidden |
| 0 | Reload JSON | Reload JSON (with the bot stopped) |

## Files generated by the bots

| File | Bot | Where | What for |
|---|---|---|---|
| `shiny_log.txt` | Shiny | `logDir` | Matches with PID, nature, IVs and attempts |
| `inst_N.lock` | Shiny | `logDir` | Instance N is alive (multiple windows) |
| `shiny_stop.flag` | Shiny | `logDir` | An instance found the target: the others stop |
| `train_log.txt` | Train | `logDir` | Battles, EVs, learned moves, healing trips |
| `train_running.lock` | Train | `logDir` | Prevents two Train Bots at once |
| `FRLG_TrainRoute.txt` | Train, Farm | script folder | Route recorded with key 6 |
| `farm_log.txt` | Farm | `logDir` | Items found and stored, money, laps, level-ups |
| `farm_running.lock` | Farm | `logDir` | Prevents two Farm Bots, and refuses to start while a Train Bot runs |
| `FRLG_FarmTrainers.txt` | Farm | script folder | Trainer route recorded with key 5 |

## Configurator output

The configurator (`configurator/`) writes the same JSON files, with a header comment, one
section comment per group and a short comment per key, all in Spanish. It only uses syntax
both bots' parsers accept: `//` comments between tokens, integer numbers and no `\u`
escapes. `configurator/tests/test_bots_accept.py` feeds its output to the real bots.

## Configurator skin file

A `.json` imported from the configurator's *Skins* button. Full reference in
[`configurator/skins/README.md`](../../configurator/skins/README.md).

| Key | Type | Notes |
|---|---|---|
| `id` | text | `[a-z0-9-]`, max 40 |
| `name`, `author` | text | Max 60 |
| `dark`, `pixelated` | bool | |
| `vars` | object | Only the documented CSS variables; values without `;{}<>`; `url()` only `data:image/...` |
| `sprites` | object | Icon/mascot name → a `data:image/...` (png, gif, webp, svg+xml) or a built-in sprite name |
| `fonts` | list (max 4) | `{family, src}` with `src` = `data:font/...` |

## Game memory
The addresses and structures the bots read (party, battle, map, RNG) are in the
**Addresses** section of [`CLAUDE.md`](../../CLAUDE.md), with the USA version as reference
and the offset rule from [ADR-0006](../00-project/adr/0006-relative-addresses.md).
