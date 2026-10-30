# Architecture — Poke-tools

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted (describes the current code)
> **Related ADRs:** [0001](../00-project/adr/0001-lua-51-on-vba-rr.md) ·
> [0002](../00-project/adr/0002-single-generated-script.md) ·
> [0003](../00-project/adr/0003-separate-bots.md) ·
> [0004](../00-project/adr/0004-commented-json-config.md) ·
> [0005](../00-project/adr/0005-simulator-testing.md) ·
> [0006](../00-project/adr/0006-relative-addresses.md) ·
> [0007](../00-project/adr/0007-recorded-routes.md) ·
> [0009](../00-project/adr/0009-local-web-configurator.md) ·
> [0010](../00-project/adr/0010-skins-as-sanitized-data.md) ·
> [0011](../00-project/adr/0011-farm-bot-forked-from-train-bot.md)

## 1. Style
Each bot is a **monolithic Lua script** that runs inside the emulator and works as a
**per-frame state machine**: every frame it reads the game's memory, decides, and queues
the buttons to press. There is no server, database or separate process; state lives in
the script's memory and in text files next to it.

| Layer | Technology | ADR |
|---|---|---|
| Runtime | VBA-rr with Lua 5.1 | [ADR-0001](../00-project/adr/0001-lua-51-on-vba-rr.md) |
| Source code | `src/*.lua` joined by `build.py` (Python 3) | [ADR-0002](../00-project/adr/0002-single-generated-script.md) |
| Configuration | JSON with comments | [ADR-0004](../00-project/adr/0004-commented-json-config.md) |
| Persistence | Text files (logs, routes, locks) | — |
| Notifications | Background `curl` → ntfy.sh / Discord | — |
| Game data | Tables generated from pret/pokefirered | — |
| Testing | Python + lupa (Lua 5.1) + Lua simulators | [ADR-0005](../00-project/adr/0005-simulator-testing.md) |
| RNG calculation outside the emulator | C (2^32 brute force) and Python | — |
| Configurator | Static HTML/CSS/JS page on `file://`, no dependencies | [ADR-0009](../00-project/adr/0009-local-web-configurator.md) |
| Configurator skins | Sanitized data (CSS variables, data-URL images and fonts) | [ADR-0010](../00-project/adr/0010-skins-as-sanitized-data.md) |

## 2. Components

Shared by both bots (duplicated in each, see [ADR-0003](../00-project/adr/0003-separate-bots.md)):
- **Game detection** — reads the ROM header and picks addresses ([ADR-0006](../00-project/adr/0006-relative-addresses.md)).
- **Memory reader** — decrypts the Pokémon (PID, OTID, 4 substructures ordered by
  `PID % 24`), reads the battle state and the map position.
- **Configuration** — strips comments, parses the JSON, validates and normalizes names.
- **Button queue** — presses with a duration in frames (`joypad.set`).
- **Panel** — text over the game (`gui.text`), three levels with key 9.
- **Log and locks** — files in `logDir`.

Shiny Bot (`shinybot/src/bot_body.lua`):
- **Modes** — one step per frame for the active mode (10 modes).
- **RNG engine** — forward and backward LCRNG, Method 1 and H-1, target search, delay
  calibration, Teachy TV.
- **Filter** — shiny, species, nature, IVs, Hidden Power.
- **Instance coordination** — `inst_N.lock`, `shiny_stop.flag`.

Train Bot (`trainbot/src/train_body.lua`):
- **Walking and encounters** — walks along the chosen axis until a battle starts.
- **Battle decisions** — fight or run (`shouldFight`), pick a move (`bestMove`, Gen 3 damage formula).
- **Move learning / evolution** — detects the prompts (opcodes 0x5A/0x5B) and the evolution scene.
- **Navigation** — records, cleans (`cleanRoute`, `fixRoute`) and replays routes; heals with the nurse or a tile.
- **Notifications** — `notify()` via curl.

Farm Bot (`farmbot/src/farm_body.lua`, a copy of the Train Bot's body plus):
- **Farm modes** — `nivel`, `objetos` (Pickup), `robar` (Thief/Covet), `dinero` (trainer rematches).
- **Save data reader** — money and bag quantities (XOR the save key), VS Seeker charge, registered item.
- **Take-items routine** — START → POKéMON → ITEM → TAKE, every step checked in memory with
  addresses from pret's symbol maps (four USA builds); other versions pause instead.
- **Trainer loop** — charge the VS Seeker, use it, walk the trainer route (key 5), come back.

Configurator (`configurator/`, outside the emulator):
- **Schema** — every bot option with type, default and Spanish label; checked against the bots' `CONFIG`.
- **Core** — parses commented JSON, normalizes names like the bots, validates and serializes.
- **Generated data** — natures, species, moves, EV yields and presets from the bots' Lua tables.
- **UI and skins** — forms per field type, live validation and preview, file access, sanitized themes.

Diagrams: [context](../architecture/c4-context.md) ·
[containers](../architecture/c4-container.md) ·
[Shiny Bot components](../architecture/c4-component-shinybot.md) ·
[Train Bot components](../architecture/c4-component-trainbot.md) ·
[Farm Bot components](../architecture/c4-component-farmbot.md) ·
[Configurator components](../architecture/c4-component-configurator.md).

## 3. Data model
- **Party / opponent Pokémon** (100 bytes): PID, OTID, checksum, encrypted substructures
  (species, item, moves, PP, EVs, IVs, ability), status, level, HP, stats.
- **RNG target**: advance, PID, nature, IVs, slot (wild).
- **Route**: `GO` and `BACK` lists of `{group, map, x, y, dir}` steps.
- **Configuration**: `CONFIG` table (defaults) + the user's JSON.
- **Game tables**: names (species, natures, moves), base stats, EV yields per species,
  level-up moves, types.

## 4. Access control
Not applicable: everything runs on the player's PC with their permissions. The only data
that leaves it are the optional notifications ([threat model](threat-model.md)).

## 5. Quality attributes
- **Correctness:** the product's value is hitting the frame and not overshooting EVs;
  every mode has simulator scenarios.
- **Robustness:** expected situations (game reset, blocked route, another instance,
  invalid configuration) stop the bot with a Spanish message (`halt`). File access and
  notifications run inside `pcall`. An unexpected programming error stops the script and
  VBA-rr shows the error in the Lua console.
- **Isolation:** a change in one mode must not affect the others ([ADR-0003](../00-project/adr/0003-separate-bots.md)).
- **Performance:** the target search covers up to `farSearch` advances (20 million by
  default). In Wild RNG the value table is built in chunks of 100,000 advances per frame
  so the emulator doesn't freeze.
- **Portability:** USA verified; EUR and JPN through offsets ([ADR-0006](../00-project/adr/0006-relative-addresses.md)).
