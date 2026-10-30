# PRD — Configurator

> **AI-DLC phase:** `01-requirements`  ·  **Status:** approved
> **Author:** vladeParica  ·  **Date:** 2026-10-29

## 1. Problem
Configuring the bots means hand-editing a JSON file: long option lists, names in English
or Spanish, IV/EV rules and options that only matter in some modes. Mistakes only show up
when the bot loads the file in the emulator. Players want a visual, guided way to do it,
and a look they can customize.

## 2. Actors
- **Player**: creates or edits a bot's configuration and saves it next to the script.
- **Skin author**: a player who makes and shares a theme.
- **Configurator** (`configurator/index.html`) running locally in the browser.

## 3. Main flow
1. The player opens `configurator/index.html` (double click).
2. Picks the bot (Shiny Bot / Train Bot); optionally opens the bot's folder (Edge/Chrome),
   loads an existing JSON, or loads an example.
3. Goes through the sections as tabs (one at a time, no page scrolling); options that
   don't apply to the chosen mode are hidden and tabs with problems show a badge.
4. Sees validation and a live preview of the JSON as they type.
5. Saves: the JSON is written into the bot's folder (or downloaded).
6. In the game, presses **0** to reload the configuration.

## 4. Business rules
- The exported JSON uses the bots' exact option names and only syntax both parsers accept
  (`//` comments between tokens, integer numbers, no `\u` escapes).
- Names are normalized like the bots do (case, accents, Spanish natures and types).
- Validation mirrors the bots' load-time checks (unknown options, unknown names, IV 0–31,
  EVs ≤ 255 and ≤ 510 total, ≤ 4 wanted moves, ntfy topic and Discord URL format, hex seeds).
- Every interface text is in Spanish.
- Skins can only change look (colors, fonts, background, sprites), never behavior.

## 5. Edge, abuse and risk scenarios
| Scenario | Expected behavior |
|---|---|
| Loading a JSON with unknown options or names | Loaded anyway; each problem listed as an error and highlighted on its field |
| Loading a file that isn't JSON | Toast with the parse error; current config untouched |
| Saving with errors | Asks for confirmation, explaining the bot won't start |
| Browser without File System Access (Firefox, Safari) | "Abrir carpeta" hidden; saving downloads the file |
| A shared skin with CSS injection, remote `url()` or script in sprites | Unsafe values dropped by the sanitizer; the rest applied |
| Browser storage blocked (private mode) | Works; draft and imported skins just aren't remembered |
| Species picked that gives EVs outside the goal | Warning: the bot will run from it |
| The bots gain or rename an option | CI fails (schema parity test) until the configurator is updated |
| The bots' tables change (new move names) | CI fails until `js/data.js` is regenerated |
| `notify` secrets in the config | Kept local; help text says they are secrets |

## 6. Acceptance criteria
- [x] Every option of both bots is editable, and the option list matches the bots' `CONFIG` (parity test).
- [x] Every exported example is accepted by the real bots in the simulator ("Config cargada").
- [x] Validation catches the same errors the bots report (unit tests).
- [x] Desktop (1366×768) fits in one screen without page scrolling; usable at 390 px wide.
- [x] Built-in skins: Rojo Fuego, Verde Hoja, Gengar, Mewtwo, Charizard, Game Boy Advance; custom skins import/export.
- [x] UI smoke test (43 checks) passes in headless Chromium.
- [x] Route viewer: draws a route file map by map and flags what the bot would trip on.
- [ ] Tried by the owner in their own browser with their bot folder.

## 7. Out of scope
- Editing the route files (they are recorded in the game with key 6); the configurator only shows them.
- Controlling the running bot from the page.
- A packaged `.exe` ([ADR-0009](../00-project/adr/0009-local-web-configurator.md)).
- Species pictures ([ADR-0010](../00-project/adr/0010-skins-as-sanitized-data.md)).

## 8. Open decisions
- None.
