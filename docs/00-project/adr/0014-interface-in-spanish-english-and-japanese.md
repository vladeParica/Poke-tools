# ADR-0014 — Interface in Spanish, English and Japanese

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted (configurator done; bots in progress)
> **Date:** 2026-10-31  ·  **Owner:** vladeParica

## Context
Everything the player sees was written in Spanish only: the configurator page and the bots'
panel, console and logs. The owner wants English and Japanese too, so players of those
languages can use the tools. JSON values (mode names like `"Salvaje RNG"`, English species,
move and item names) are read by the bots and must not change, or existing configs would break.
VBA-rr draws the in-game panel with a font that only has Latin letters.

## Decision
- **Spanish stays the source text.** Code keeps writing Spanish and passes it through a
  translation function; each language has a dictionary from the Spanish text to its own.
  Text with data uses placeholders (`"{label}: debe estar entre {min} y {max}"`). A missing
  translation falls back to Spanish.
- **Configurator:** `js/i18n.js` + `js/lang/en.js` + `js/lang/ja.js`. The language is picked in
  *Apariencia* (or `?lang=`), remembered in the browser, and defaults to the browser's language.
  Schema labels, validation messages, the JSON comments it writes and the static page text are
  all translated. `tools/i18n_keys.js` collects every source text and `tests/i18n.test.js` fails
  if any is untranslated or a placeholder doesn't match.
- **Bots (phase 2):** a `language` option (`es`, `en`, `ja`) in each bot's JSON. The panel drawn
  by VBA-rr uses romaji for Japanese; console and logs use real Japanese. The configurator's log
  stats read logs in any of the three languages.
- **Values never change with the language.** JSON keys and values, file names and route
  formats stay as they are.

## Alternatives considered
- **Translation keys instead of Spanish source text** (`t('save')`) — cleaner for big apps,
  but it would rewrite every string and make the Spanish code harder to read; the project's
  first language is Spanish.
- **Translating the DOM after rendering** — fewer code changes, but messages built from pieces
  can't be matched reliably and nothing can check completeness.
- **English as the base language** — the owner and the first players use Spanish.

## Consequences
- **Positive:** three languages with one code path; a test guarantees nothing is left
  untranslated; existing JSON and routes keep working.
- **Negative / costs:** every new text needs an English and a Japanese entry (the test enforces
  it). The Japanese text is written by the maintainers and should be reviewed by a native
  speaker.
- **Open (Human-in-the-Loop):** whether real Japanese shows correctly in the VBA-rr Lua console
  (to be checked in the emulator; the fallback is romaji like the panel).
