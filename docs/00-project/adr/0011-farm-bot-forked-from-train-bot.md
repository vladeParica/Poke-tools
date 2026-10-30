# ADR-0011 — Farm Bot is a separate script forked from the Train Bot

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-10-29  ·  **Owner:** vladeParica

## Context
The owner wants a bot that farms items, levels and money, and asked explicitly for a
separate script so nothing that works today breaks. The Train Bot already has a battle
engine (fight/run, best move, move learning, evolution, healing trips, routes) proven in
the real game. Farming also needs things no bot has: menu navigation to take held items,
reading money, using the VS Seeker and trainer battles.

## Decision
- A new bot in `farmbot/`, built like the others (`src/` → `build.py` → one
  `FRLG_FarmBot.lua`), with its own JSON, simulator and tests.
- Its body starts as a **copy** of `trainbot/src/train_body.lua`; the farm modes are added
  on top. Nothing is extracted into a shared library, so the Train Bot's source is not
  touched ([ADR-0003](0003-separate-bots.md)).
- Menu automation uses addresses from pret's published symbol maps
  (`pret/pokefirered` branch `symbols`) for the four USA builds (FireRed/LeafGreen 1.0/1.1).
  RAM addresses are the same in the four; ROM function addresses come from a per-version
  table. Every menu step is verified by reading memory, and the final result by the
  party's held items.
- On versions without verified symbols (EUR, JPN), taking items falls back to pausing and
  notifying the player.

## Alternatives considered
- **Add the modes to the Train Bot** — fewer files, but every change would risk the
  calibrated EV training.
- **Extract a shared battle library** — less duplicated code, but changing the Train Bot
  to use it is exactly what the owner wants to avoid right now.
- **Blind button sequences for menus (fixed timings)** — simple, but fragile: the start
  menu remembers its cursor and the action list changes with field moves.

## Consequences
- **Positive:** the Shiny Bot and Train Bot can't be broken by farm work; menu automation
  is checked step by step.
- **Costs:** the battle engine is duplicated; a fix there must be copied to both bots.
  Menu automation, trainer battles and the VS Seeker are tested only in the simulator
  until the owner tries them in the real game.
