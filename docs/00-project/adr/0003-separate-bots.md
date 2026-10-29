# ADR-0003 — Separate bots: the Shiny Bot only searches

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-10-29 (retroactive)  ·  **Owner:** vladeParica

## Context
The Shiny Bot grew to 10 modes, each calibrated in the real game. Adding training
(battles, routes, move-learning menus) to the same script put the working modes at risk.
The owner asked for it explicitly: improve things, don't fix one and break another.

## Decision
The **Shiny Bot is "standard, search only"**. Any other kind of feature goes in a
**separate script** (the first one: `trainbot/`). The bots share the name tables
(`shinybot/src/tables2.lua`) but no behavior code.

## Alternatives considered
- **One bot with more modes** — easier to distribute, but every change would touch the
  main loop of every mode.
- **Shared behavior library** — less duplicated code, but a change in the library affects
  both bots at once (see [ADR-0002](0002-single-generated-script.md) on why `require` isn't used).

## Consequences
- **Positive:** one bot can't break the other; each has its own version (Shiny v4.3,
  Train v1.10) and its own tests.
- **Costs:** duplicated code (party reading, panel, logs, game detection); a fix there has
  to be made in both. Only one script is loaded at a time.
