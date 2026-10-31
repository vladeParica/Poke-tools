# Configurator

A visual editor for the bots' JSON files. Open `index.html` with a double click: it runs
locally in the browser, with no install and no internet connection. The interface is in
Spanish, English or Japanese (*Apariencia* → *Idioma · Language · 言語*, or `?lang=en`); it
starts in your browser's language. When online, it also shows a Pokémon behind each
form (FireRed/LeafGreen sprites from Pokémon Database, loaded at runtime)
([ADR-0013](../docs/00-project/adr/0013-official-artwork-behind-the-configurator-forms.md)).
Change it in *Apariencia* (gear button, or *Fondo* when the pointer is over the form): another
Pokémon, the style (game sprite, HOME, official artwork), shiny, your own image, none, and how
strong it looks.

![Configurator](../assets/configurator.png)

## What it does

- **Three bots:** Shiny Bot, Train Bot and Farm Bot, one tab each.
- **One screen, no scrolling:** each bot's options are split into short sections shown as
  tabs (Modo, Qué buscar, IVs… / Objetivo, Rivales, Combate…), with *Anterior / Siguiente*
  buttons. Sections and options that don't apply to the chosen mode are hidden, and each
  tab shows a badge when it has errors or warnings.
- **Validation as you type**, with the same rules the bots apply when they load the JSON,
  plus warnings for configs that load but won't do what you expect (e.g. a species that
  gives EVs outside your goal). Click an issue to jump to its field.
- **Smart inputs:** mode cards, nature/species/move pickers with autocomplete (Spanish
  nature names are accepted), IV ranges, EV sliders with the 510 total, EV-yield badges on
  each species, a ready-made route picker that also sets the healing mode, and a random
  ntfy topic generator.
- **Examples:** load the default config or the ready-made training examples.
- **Log stats:** the chart button reads a bot log (`shiny_log.txt`, `train_log.txt`,
  `farm_log.txt`; drop it, pick it, or read it from the opened folder) and shows the numbers:
  shinies found with their attempts, training runs, and for the Farm Bot money and level over
  time, items per type and rates per hour.
- **Route viewer:** *Ver ruta* next to each route file draws it map by map (way there, way
  back, training spot) and lists what the bot would trip on: empty halves, jumps, a way back
  that ends somewhere else, door glitches. It reads the ready-made routes directly, your own
  from the opened folder, or a `.txt` you pick.
- **Side panel** with two tabs: *Estado* (issues) and *JSON* (live preview of the exact
  commented file that will be saved).
- **Saving:** in Edge or Chrome, *Abrir carpeta* opens the bot's folder and *Guardar*
  writes `FRLG_ShinyBot.json` / `FRLG_TrainBot.json` straight into it. Other browsers
  download the file. *Abrir JSON* (or drag and drop) loads an existing file.
- **Skins:** six built-in themes (Rojo Fuego, Verde Hoja, Gengar, Mewtwo, Charizard, Game Boy Advance) and support for your own (see [skins/](skins/README.md)).
- Your work in progress is kept in the browser between visits.

Deep links: `index.html#trainbot` opens the Train Bot tab, `index.html?skin=gba` picks a skin.

## Files

| Path | What it is |
|---|---|
| `index.html` | The page |
| `css/app.css` | Styles; every color, font and radius is a CSS variable that skins override |
| `js/data.js` | **Generated** game data (natures, species, moves, EV yields, presets) |
| `js/schema.js` | Every bot option: type, default, Spanish label and help |
| `js/i18n.js`, `js/lang/*.js` | Translation: Spanish source text → English / Japanese ([ADR-0014](../docs/00-project/adr/0014-interface-in-spanish-english-and-japanese.md)) |
| `tools/i18n_keys.js` | Lists every text to translate; `tests/i18n.test.js` checks they all are |
| `js/core.js` | Parse, normalize, validate and serialize configs (no DOM; tested in Node) |
| `js/sprites.js` | Our original icons and the pixel-art mascot |
| `js/skin.js` | Skin registry, sanitizer and import/export |
| `js/app.js` | The UI |
| `skins/*.js` | Built-in skins |
| `tools/build_data.py` | Regenerates `js/data.js` from the bots' Lua tables and example configs |
| `tests/` | Unit, integration and UI smoke tests |

## Development

- After changing the bots' tables or example configs, regenerate the data:
  `python configurator/tools/build_data.py`. CI fails if `js/data.js` is stale.
- When a bot gains or loses an option, update `js/schema.js`: the parity test fails otherwise.
- Tests:
  ```
  node --test configurator/tests/core.test.js          # core logic
  python configurator/tests/test_bots_accept.py        # schema parity + the real bots accept the exported JSON
  ```
  The UI smoke test (`tests/ui-smoke.html`) drives the page in headless Chrome/Edge; the
  command is at the top of the file.

Design decisions: [ADR-0009](../docs/00-project/adr/0009-local-web-configurator.md) and
[ADR-0010](../docs/00-project/adr/0010-skins-as-sanitized-data.md).
