# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each bot has
its own version. Record here any change to the JSON, the route format or the keys: they
are the contract with users ([contracts](docs/02-design/api-contracts.md)).

## [Unreleased]

### Added
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
- Configurator: *Farm Bot* tab.
- Configurator: *Game Boy Advance* skin (indigo shell, speaker grille, screen-like panels) and a
  `--bg-size`, `--on-bg` and `--on-bg-muted` skin variables. The *Noche* and *Shiny* skins were removed; saved choices fall back
  to *Poké Ball*.
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

### Changed
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
