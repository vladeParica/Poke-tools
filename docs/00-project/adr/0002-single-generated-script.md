# ADR-0002 — A single script generated from `src/` with `build.py`

> **AI-DLC phase:** `03-implementation`  ·  **Status:** accepted
> **Date:** 2026-10-29 (retroactive)  ·  **Owner:** vladeParica

## Context
The player copies the bot into a folder and opens it in VBA-rr. Lua's `require` depends on
the emulator's working directory, which is not the script's, and shipping several files
makes installation harder. At the same time, code with data tables thousands of lines long
is hard to maintain in a single file.

## Decision
We edit in `src/` (body + tables) and `build.py` joins the pieces into **one standalone
`.lua`** per bot, with **CRLF** line endings for Windows. The generated `.lua` is committed
so the player can download it as is. It is never edited by hand.

## Alternatives considered
- **Several files with `require`** — fragile in VBA-rr (paths) and harder to install.
- **A single hand-edited file** — tables and logic mixed together, huge diffs.
- **Not committing the generated file** — players would need Python to use the bot.

## Consequences
- **Positive:** one-file install; readable `src/`; tables are regenerated from pret.
- **Costs:** you have to remember to run `build.py` before committing. CI checks it
  (rebuilds and fails if the result doesn't match what is committed).
