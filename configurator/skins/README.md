# Configurator skins

A skin changes the configurator's colors, fonts, background and sprites. There are two kinds:

- **Built-in skins** (`*.js` in this folder): `fuego` (Rojo Fuego, default), `hoja`, `gameboy`
  and `gba`. Each one calls `PT.registerSkin({...})` and is loaded by a
  `<script>` tag in `index.html`.
- **Your own skins**: a `.json` file you import from the *Skins* button. It is stored in
  your browser, so it survives updates of the configurator.

## Making your own

1. Open the configurator, pick the skin closest to what you want, press *Skins* →
   *Exportar el actual*. You get a JSON to start from (or copy [`template.json`](template.json)).
2. Change its `id` and `name` and edit the values.
3. *Skins* → *Importar skin* and pick your file. Re-import it after each change.

To ship it with the configurator, turn it into a `skins/<id>.js` file that calls
`PT.registerSkin(...)` with the same object and add a `<script>` tag for it in `index.html`.

## Format

```json
{
  "id": "mi-skin",
  "name": "Mi skin",
  "author": "tu nombre",
  "dark": false,
  "pixelated": false,
  "vars": { "--accent": "#7b5cff" },
  "sprites": { "mascot": "data:image/png;base64,..." },
  "fonts": [{ "family": "Mi Fuente", "src": "data:font/woff2;base64,..." }]
}
```

| Field | Meaning |
|---|---|
| `id` | Lowercase letters, numbers and `-` |
| `name`, `author` | Shown in the skin list |
| `dark` | `true` for dark skins (native controls follow it) |
| `pixelated` | `true` to draw image sprites without smoothing (pixel art) |
| `vars` | CSS variables (table below). Anything you leave out keeps the default |
| `sprites` | Replace any icon or the mascot with your own image |
| `fonts` | Up to 4 embedded fonts; use their `family` in `--font-body` / `--font-display` |

### Variables

| Variable | Used for |
|---|---|
| `--bg`, `--bg-pattern`, `--bg-size` | Page background color, an optional pattern/gradient and its tile size (e.g. `14px 14px`) |
| `--on-bg`, `--on-bg-muted` | Text placed straight on the page background (the section list); default `--text` / `--muted` |
| `--surface`, `--surface-2` | Cards and inputs |
| `--border` | Borders |
| `--text`, `--muted` | Main and secondary text |
| `--accent`, `--accent-ink`, `--accent-soft` | Main color, text on top of it, and its light tint |
| `--accent-2` | Secondary highlight (e.g. the RNG badge) |
| `--ok`, `--warn`, `--error` | Status colors |
| `--header-bg`, `--header-ink` | Top bar |
| `--radius`, `--radius-sm` | Corner rounding |
| `--shadow` | Card shadow |
| `--font-body`, `--font-display`, `--font-mono` | Fonts |
| `--backdrop-opacity` | Opacity of the artwork behind the form (default `.14`; `0` hides it) |

### Sprites

`mascot` (the pixel bot in the top bar), `backdrop-shinybot` / `backdrop-trainbot` /
`backdrop-farmbot` (the image behind each bot's form; by default a FireRed/LeafGreen sprite
from Pokémon Database, loaded at runtime. A background the player picks in *Apariencia* wins over the skin's) and every icon name from `js/sprites.js`:
`bot-shiny`, `bot-train`, `bot-farm`, `mode-coin`, `stat-hp`, `stat-atk`, `stat-def`, `stat-spa`, `stat-spd`,
`stat-spe`, `mode-wild`, `mode-static`, `mode-gift`, `mode-roamer`, `mode-seed`,
`mode-newgame`, and the UI icons (`folder`, `save`, `palette`…).

A sprite value is either an image as a data URL (`data:image/png|gif|webp|svg+xml`) or the
name of a built-in sprite (e.g. `"mascot": "mascot-shiny"`). A built-in skin can draw its own
pixel sprites from character maps with `PT.art.addPixel(name, rows, colors)`; see
[`aventura.js`](aventura.js). Convert an image to a data URL
with any "image to base64" tool.

## Safety rules

Imported skins are data, never code. The configurator drops anything that doesn't follow
these rules:

- Only the variables in the table above.
- Values can't contain `;`, `{`, `}`, `<` or `>`, and `url(...)` only accepts `data:image/...`.
- Sprites must be `data:image/...` (shown with `<img>`, which can't run scripts).
- Fonts must be `data:font/...`.

## Art

Only share art you made or are allowed to share. The built-in sprites are original
Poke-tools work; the project doesn't ship third-party Pokémon art.
