# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each bot has
its own version. Record here any change to the JSON, the route format or the keys: they
are the contract with users ([contracts](docs/02-design/api-contracts.md)).

## [Unreleased]

### Added
- Shiny Bot: mode 11 **Pesca** (fishing). It uses the rod registered on SELECT while you face the
  water, closes the fishing texts with B (A facing water would offer Surf) and runs from every
  battle until the target appears, like *Salvaje*; `species` works too. It refuses to start without
  a rod on SELECT and stops if nothing bites. New `mode` value `"Pesca"`; existing modes keep their numbers.
- Shiny Bot: mode 12 **Pesca RNG** (ADR-0016). It casts until something bites, saves a state on
  "A POKéMON's on the hook!" (that text waits for a button while the RNG keeps advancing) and, like
  the Static RNG modes, calibrates the B press and presses it on the exact frame of the target,
  with the fishing slots of the registered rod and the map's fishing table. USA FireRed/LeafGreen
  1.0/1.1 only (it reads the fishing task by its address). New option `fishSearch` (default
  1000000): no Teachy TV while fishing. `afterSeedMode` can hand over to it.
- **Farm Bot 1.0** (`farmbot/`): farms levels, items with Pickup, items stolen with Thief/Covet,
  and money from trainer rematches with the VS Seeker; takes held items through the party menu
  on USA versions. Separate script; the Shiny Bot and Train Bot are unchanged.
- Farm Bot: key **4**, a read-only diagnostic that shows the menu state the bot reads and logs
  each change, to check a game before letting the bot press buttons.
- Releases: pushing a tag `<bot>-vX.Y` runs the CI and publishes a zip with the bot, its
  examples and the configurator (`tools/package.py`, ADR-0012).
- Configurator: a Pokémon behind each bot's form (Pikachu, Machop, Meowth), FireRed/LeafGreen
  sprites from Pokémon Database loaded when online and never stored in the repo (ADR-0013).
  The *Apariencia* dialog changes it: any Gen 1–3 Pokémon per bot, style (game sprite, HOME,
  official artwork), shiny, your own image or none, and its intensity.
- Configurator in **English and Japanese** besides Spanish (🌐 selector in the top bar, *Apariencia* or
  `?lang=`), including
  validation messages and the JSON comments it writes; a test checks nothing is untranslated
  (ADR-0014).
- Farm Bot: **double trainer battles** in `dinero` (both Pokémon attack, the default target is
  confirmed) instead of stopping; single battles are unchanged.
- **Bots in English and Japanese:** new `language` option (`"es"`, `"en"`, `"ja"`) in the three
  bots' JSON for the panel, console and log; Japanese is written in romaji because VBA-rr can't
  draw kana. Game logic is unchanged (every simulator scenario gives the same numbers in the three
  languages), and the configurator's log stats read logs in any of them.
- Configurator: log stats (chart button): Shiny Bot finds with attempts, Train Bot runs, and Farm
  Bot money and level over time, items per type and rates per hour.
- Configurator: route viewer (*Ver ruta*): draws a route file map by map and flags empty halves,
  jumps, a way back that ends elsewhere and door glitches, with the bots' own cleanup rules.
- Configurator: *Farm Bot* tab.
- Configurator: *Game Boy Advance* skin (indigo shell, speaker grille, screen-like panels) and a
  `--bg-size`, `--on-bg` and `--on-bg-muted` skin variables. The *Noche* and *Shiny* skins were removed; saved choices fall back
  to *Rojo Fuego*.
- Configurator: the default *Poké Ball* skin became *Rojo Fuego* (FireRed colors), pairing with
  *Verde Hoja*.
- Configurator: the *Retro portátil* skin became *Gengar* (ghost purple, shows Gengar behind
  the forms); skins can set their background Pokémon with `backdrop`.
- Configurator: *Mewtwo* (light psychic lilac) and *Charizard* (dark ember) skins, each with its
  Pokémon behind the forms.
- **Configurator** (`configurator/index.html`): visual editor for both bots' JSON with live
  validation, sections as tabs (no page scrolling), examples, folder access in Edge/Chrome, four
  skins and custom skin import.
- AI-DLC documentation in `docs/` (project charter, PRDs, architecture, C4 diagrams,
  threat model, ADRs, testing, installation, monitoring) and gates in `.ai-dlc/gates/`.
- Usage guides for each bot (`shinybot/README.md`, `trainbot/README.md`).
- Reusable routes documented in `trainbot/examples/routes/`.
- GitHub Actions CI: checks that the generated `.lua` files are up to date and runs the simulator.
- GPL-3.0 license, `CONTRIBUTING.md`, `SECURITY.md`, issue and PR templates.
- Project logo (`assets/logo.svg`) and social preview image.

- **Game guide** in Spanish (`docs/guia/`): a page per Pokémon, TMs/HMs, items and shops, move
  tutors, trainers, EV spots, version exclusives and every move with who learns it (by level,
  TM/HM or tutor), generated from pret/pokefirered with `tools/guia/gen_guia.py` (names from
  PokeAPI); `--check` compares random values with pret. Sprites and item icons are linked from
  PokeAPI/sprites, never stored (ADR-0013).
- Shiny Bot, Static/Gift/Roamer RNG without the Teachy TV: on a far target the bot saves a
  state shortly before it, and the tries after the first one start there instead of waiting
  from the base again.

- Train Bot: optional **Pickup while training** (`pickup`, `pickupTakeAt`): with Pickup Pokémon
  (Meowth) in slots 2–6, the bot takes the items they find through the party menu and stores
  them in the bag (USA versions), or pauses and notifies. Off by default (ADR-0011 amended).

### Fixed
- Shiny Bot, *Semilla inicial* handing over to *Regalo RNG* (e.g. Eevee) with a full party: the gift
  went to the PC, the bot never saw it and kept retrying ("Comprobando" forever). It now checks the
  mode in `afterSeedMode` when you press 7 (a free party slot for a gift, the roamer not out yet),
  and checks again, with the party read again, when it hands over after the seed.
- Shiny Bot: pressing 7 before the save was loaded (title screen, after a reset) read TID 0 / SID 0
  and kept them, so the panel showed them and the RNG modes checked shininess against them. IDs of
  0/0 now count as "load your save", and the RNG modes read the IDs again when they start.
- Train Bot and Farm Bot: "can't call vba.frameadvance() from here" when the bot paused the
  emulator (stopping with a message, training finished, evolution, items to take). `emu.pause()`
  ran inside `pcall`, where VBA-rr can't yield; the bots now ask with `Game.pauseSoon()` and the
  main loop pauses. The test mocks behave like VBA-rr here, so the error shows up in the tests.
- Train Bot: against a wanted opponent the lead can't hurt with any move (e.g. only Normal moves
  against Gastly) it ran from every battle forever. After 3 such battles in a row it now stops and
  says the lead needs a move that damages that species.
- Train Bot: with a `species` list, the PP that decide when to heal only count moves that can hurt
  one of those species. Normal moves kept the count up against Gastly, so once Bite ran out it never
  went to heal. If not even full PP would help, it stops and says why instead of healing in a loop.
- Train Bot and Farm Bot: Bulbasaur had no game data (its row was stored under index 0), so a
  wild Bulbasaur counted as "no data" and a trained one had no types for the damage formula.
- Train Bot and Farm Bot: when the lead fainted in a wild battle and running away failed, the
  forced "choose a Pokémon" screen (it can't be closed with B, the cursor starts on the fainted
  lead) left the bot in a loop. It now sends out the healthy Pokémon with the highest level,
  runs, and goes to heal. Against trainers the Farm Bot still stops and lets you choose.
- Train Bot and Farm Bot: a wild Pokémon that doesn't let you run (Shadow Tag, Arena Trap, Magnet
  Pull, Mean Look, Wrap…) made the bot choose RUN forever. It now checks the game's own rules
  (pret `IsRunningFromBattleImpossible`) and fights; after 3 failed RUNs for any other reason too.
- Train Bot: after reaching part of the goal it kept looking for battles forever when no
  opponent there gave the missing EVs (e.g. a plan in phases: Attack on Route 24, Speed later).
  It now ends the phase ("FASE TERMINADA", with the EVs still missing) when no species in
  `species` helps any more, or after 40 battles in a row without a useful opponent.
- Train Bot: EVs could go past the goal when a wild Pokémon wouldn't let it run (e.g. Diglett's
  Arena Trap in Diglett's Cave) and it fought it. Now, if beating it would push an EV past the
  goal, it pauses and notifies instead (catching it gives no EVs). It also stops at 510 EVs in
  total when the missing ones can't fit.
- Shiny Bot, *Salvaje RNG* with `species` on LeafGreen 1.1: the bot read the encounter table
  from the FireRed 1.0 address, which falls 17 headers inside LeafGreen 1.1's table, so maps such
  as Viridian Forest "had no encounters". It now uses each build's address (pret symbols) and
  always starts from the first header; the error message also names the map.
- Shiny Bot, *Partida nueva*: it refuses to start before the character has a name (TID 0)
  and, if no SID appears after two tries (started before naming the rival), it stops with a
  message saying when to press 7 instead of retrying forever.

### Changed
- Game data comes from one extractor, `tools/gamedata/gamedata.py`, which reads pret once into
  `shared/gamedata/gamedata.json`; the bots' tables are rendered from it at build time and the
  guide reads it too. `trainbot/tools/gen_tables.py` and `trainbot/src/train_tables.lua` are gone
  (ADR-0015).
- The Train Bot and the Farm Bot share their menu and escape code (`shared/lua/menus.lua`) and
  the per-build addresses (`shared/lua/game.lua`, also used by the Shiny Bot) instead of copies.
- The bots pick each state's step from a table, the Train Bot's after-battle steps are an ordered
  list, and the escape and EV-goal decisions are pure functions (`shared/lua/rules.lua`) with unit
  tests (`shared/tests/test_rules.py`, in CI).
- Train Bot: when training (or a phase) ends it first goes to heal at the Center, if a route is
  recorded, and then pauses.
- Train Bot examples moved to `trainbot/examples/configs/` with per-stat names
  (`FRLG_TrainBot_Speed_Diglett.json`, `FRLG_TrainBot_SpAtk_Tower.json`).
- Pokémon Tower route renamed to `FRLG_TrainRoute_Tower.txt`.
- `tools/rng/`: TID and SID are passed at compile time (`-DTID -DSID`) or as arguments;
  they are no longer hard-coded.
- Repository documentation translated to English (in-game text stays in Spanish).

### Security
- Both bots no longer pass a log folder (`logDir`, `sharedDir`) containing `"`, `%`, `$`
  or `` ` `` to the shell; in that case they use the script's folder.

### Removed
- Notes from a specific save file (computed seeds, team plan).

## Shiny Bot 4.3 — Train Bot 1.10
First version published in this repository.

- **Shiny Bot 4.3:** Wild, Static, Gift and Roamer modes, their RNG variants, Wild RNG one
  step before the encounter, New game and Initial seed; Teachy TV; multiple instances.
- **Train Bot 1.10:** exact EVs and levels, battle decisions, move learning, evolution,
  recorded routes, healing with the nurse or a tile, ntfy/Discord notifications.
