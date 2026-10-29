# ADR-0004 — Configuration in a commented JSON next to the script

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-10-29 (retroactive)  ·  **Owner:** vladeParica

## Context
Players must be able to change what the bot searches for or how it trains without touching
the code, and understand each option without opening separate documentation. VBA-rr has
no UI for forms.

## Decision
Each bot reads `FRLG_<Bot>.json` from **its own folder**. `//` comments are allowed
(stripped before parsing) so the example file explains every option (in Spanish, like
everything the player sees). Options accept English or Spanish names (natures, stats). A
configuration error doesn't stop the emulator: the bot shows it in the console and waits
for it to be fixed and **0** to be pressed.

## Alternatives considered
- **Constants at the top of the `.lua`** — forces editing the script and is lost on update.
- **In-game menu** — a lot of UI code and impractical for lists (species, IVs).
- **Strict JSON** — without comments, players don't know what each option does.

## Consequences
- **Positive:** updating the bot doesn't overwrite the configuration; reusable examples
  (`trainbot/examples/`); validation with Spanish messages.
- **Costs:** a hand-maintained JSON parser in Lua 5.1. The format is the public contract:
  renaming an option breaks users' JSON files (see [contracts](../../02-design/api-contracts.md)).
