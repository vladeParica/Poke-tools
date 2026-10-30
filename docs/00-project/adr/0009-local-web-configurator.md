# ADR-0009 — The configurator is a local web page

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-10-29  ·  **Owner:** vladeParica

## Context
Editing the bots' JSON by hand is error-prone: option names, Spanish/English values, EV
totals and mode-specific options are easy to get wrong, and the bot only reports the
problem when it loads. Players need a visual editor. VBA-rr can only draw simple text
over the game, so an in-emulator menu would be cramped and limited.

## Decision
The configurator is a **static web page** (`configurator/index.html`) that runs from the
local disk with a double click: plain HTML, CSS and JavaScript loaded through classic
script tags (ES modules and `fetch` don't work on `file://`), no build step, no
dependencies, no network access. In Edge and Chrome it uses the File System Access API to
open the bot's folder and write the JSON in place; other browsers download the file.
Its lists (natures, species, moves, EV yields, presets) are **generated from the bots' Lua
tables** by `configurator/tools/build_data.py`, and its option list is checked against the
bots' `CONFIG` tables in CI.

## Alternatives considered
- **Windows `.exe` (Electron / Tauri / PyInstaller)** — writes files without prompts, but
  it's Windows-only, needs a build per release, and an unsigned executable triggers
  SmartScreen/antivirus warnings that put users off a "bot". The same page can still be
  wrapped later if needed. The owner chose the page.
- **Menu inside the emulator** — no context switch, but tiny space, keyboard-only and
  skins limited to colors.
- **Hosted website** — needs hosting and would have to deal with users' files remotely.

## Consequences
- **Positive:** zero install, works offline and on any OS; the UI can't drift from the bots
  (generated data + parity test + an integration test that feeds the exported JSON to the
  real bots in the simulator).
- **Costs:** writing straight into the folder only works in Chromium browsers (elsewhere
  the user moves the downloaded file); `js/data.js` must be regenerated when the bots'
  tables change (CI enforces it); the UI duplicates the bots' validation rules in
  JavaScript, kept honest by the integration test.
