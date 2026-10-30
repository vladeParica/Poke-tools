# ADR-0013 — Official artwork behind the configurator forms

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted (amends the art rule of [ADR-0010](0010-skins-as-sanitized-data.md))
> **Date:** 2026-10-30  ·  **Owner:** vladeParica

## Context
The owner wanted a translucent Pokémon behind each bot's form so the page doesn't look
flat. Our own 32×32 pixel silhouettes were tried first and rejected as too crude; the owner
asked for third-party art for these backgrounds. [ADR-0010](0010-skins-as-sanitized-data.md)
says all art in the repository is original, and the repository and release zips are
GPL-3.0, which can't relicense Pokémon artwork.

## Decision
- Behind each form the configurator shows the official artwork of one Pokémon:
  Pikachu (Shiny Bot), Machop (Train Bot), Meowth (Farm Bot), at low opacity
  (`--backdrop-opacity`, default `.14`).
- The images are **loaded at runtime** from the public PokeAPI sprites repository
  (`raw.githubusercontent.com/PokeAPI/sprites/.../official-artwork/<id>.png`). They are
  **never stored** in this repository or in the release zips.
- Offline, or if the request fails, the image is removed and the page works as before.
- The player can change it in the *Apariencia* dialog (gear button, or the *Fondo* button on
  the form): any Gen 1–3 Pokémon by name (same PokeAPI source, by national dex number), their
  own image, or none, plus the intensity. The choice is stored in their browser, per bot.
- Order: the player's choice, then the skin's image (`backdrop-<bot>` sprite), then the default.
  A skin can also hide them (`--backdrop-opacity: 0`).
- Everything else keeps ADR-0010's rule: icons, mascot and skin sprites are original work.

## Alternatives considered
- **Our own silhouettes** — no third-party art, but the owner found them too crude.
- **Copy the artwork into the repository** — works offline, but it would redistribute
  Nintendo / Creatures / GAME FREAK artwork inside a GPL repository and its releases.
- **No background** — the flat look the owner wanted to avoid.

## Consequences
- **Positive:** the page looks finished; the repository and releases stay free of
  copyrighted images.
- **Negative / costs:** the page now makes three requests to GitHub when online (they reveal
  the visitor's IP to GitHub, nothing else is sent; `no-referrer`); if PokeAPI moves the files,
  the backgrounds disappear until the URLs are updated in `configurator/js/sprites.js`.
- **Open (Human-in-the-Loop):** none.
