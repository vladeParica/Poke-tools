# ADR-0014 — Interface in Spanish, English and Japanese

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-10-31  ·  **Owner:** vladeParica

## Context
Everything the player sees was written in Spanish only: the configurator page and the bots'
panel, console and logs. The owner wants English and Japanese too, so players of those
languages can use the tools. JSON values (mode names like `"Salvaje RNG"`, English species,
move and item names) are read by the bots and must not change, or existing configs would break.
VBA-rr draws the in-game panel with a font that only has Latin letters, and its Lua console is a
Windows control that uses the system code page. The bots took a long time to stabilise: the
translation must not change a single decision they make.

## Decision
- **Spanish stays the source text.** Code keeps writing Spanish and passes it through a
  translation function; each language has a dictionary from the Spanish text to its own.
  A missing translation falls back to Spanish.
- **Configurator:** `js/i18n.js` + `js/lang/en.js` + `js/lang/ja.js`, text through `tr()` with
  `{name}` placeholders. The language is picked in *Apariencia* (or `?lang=`), remembered in the
  browser, and defaults to the browser's language. Schema labels, validation messages, the JSON
  comments it writes and the static page text are translated. `tools/i18n_keys.js` collects
  every source text and `tests/i18n.test.js` fails if any is untranslated.
- **Bots:** a `language` option (`"es"`, `"en"`, `"ja"`) in each bot's JSON. Player-facing text
  is wrapped as `TX"..."`; `shared/langgen.py` builds the `LANG` table from
  `shared/lang/<code>.json` into each generated script. Lookup tables shown with `TX(t[k])` (mode
  names, phases, types…) carry a `--@i18n` mark. `tools/lua_i18n.py check` fails if a text is
  untranslated, if `%d`/`%s` don't match (that would crash `string.format` in the game) or if the
  Japanese is not plain ASCII.
- **Japanese in the bots is romaji everywhere** (panel, console and log). The same message is
  often drawn on the panel, printed and logged, and neither the panel font nor the console can be
  relied on to show kana. The configurator shows real Japanese.
- **Never translated:** values the logic compares (modes, JSON keys and values, file names, route
  format), the version line read by the release packager, the debug file, and the log tags the
  configurator's stats rely on (`[Instancia N]`, `[SHINY Star]` / `[SHINY Square]`, `OBJETIVO`,
  `+$N  (total $M)`). The stats parser accepts the translated lines of the three languages; its
  test builds them from `shared/lang/*.json`.
- **Proof that logic is unchanged:** `shared/tests/run_lang.py` runs the Farm Bot and Train Bot
  scenarios in es/en/ja and requires identical numbers. The Shiny Bot was checked the same way
  with the clock and random seed pinned (same PIDs in the three languages).

## Alternatives considered
- **Translation keys instead of Spanish source text** (`t('save')`) — cleaner for big apps,
  but it would rewrite every string and make the Spanish code harder to read; the project's
  first language is Spanish.
- **Real Japanese in the console and log, romaji only on the panel** — the first plan; dropped
  because one message usually goes to all three places and the console's code page would garble
  kana on non-Japanese Windows.
- **Translating at load time** — simpler, but reloading the JSON (key 0) wouldn't switch the
  language of lookup tables; they are translated where they are shown instead.

## Consequences
- **Positive:** three languages with one code path; tests guarantee nothing is left
  untranslated and that the bots behave identically; existing JSON and routes keep working.
- **Negative / costs:** every new text needs an English and a Japanese entry (the checks enforce
  it). The generated scripts are larger (the dictionaries). The Japanese text is written by the
  maintainers and should be reviewed by a native speaker.
- **Open (Human-in-the-Loop):** review of the Japanese wording; whether real Japanese would show
  in the VBA-rr console on a Japanese Windows (romaji works everywhere meanwhile).
