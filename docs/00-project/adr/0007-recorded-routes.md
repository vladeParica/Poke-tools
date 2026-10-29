# ADR-0007 — Routes to the Center recorded by the player

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted
> **Date:** 2026-10-29 (retroactive)  ·  **Owner:** vladeParica

## Context
The Train Bot has to go heal and come back to the training spot on its own. Computing the
path would require reading collisions, map connections, doors and moving NPCs.

## Decision
The player **records the route once** with the 6 key (there, heal, back). It is saved to a
plain-text `.txt` (`GO` and `BACK`, steps `group map x y direction`) that the bot replays.
On load, `cleanRoute()` removes the bogus steps that appear when going through doors and
`fixRoute()` repairs the route. Useful routes are shared in `trainbot/examples/routes/`.

## Alternatives considered
- **Pathfinding (A\*) with collision data** — a lot of code and per-map data; doesn't solve
  NPCs or special doors.
- **Healing with items** — costs money and doesn't restore PP in a practical way.

## Consequences
- **Positive:** works anywhere, including the Pokémon Tower healing tile
  (`healMode: "tile"`); routes are reusable and easy to review.
- **Costs:** the bot only starts from the training spot (±2 tiles) or from a tile on the
  way back; an NPC in the way can block the route (the bot stops with a message).
