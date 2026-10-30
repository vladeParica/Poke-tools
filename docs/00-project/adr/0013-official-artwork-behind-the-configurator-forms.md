# ADR-0013 — Pokémon sprites behind the configurator forms, loaded at runtime

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted (amends the art rule of [ADR-0010](0010-skins-as-sanitized-data.md))
> **Date:** 2026-10-30  ·  **Owner:** vladeParica

## Context
The owner wanted a translucent Pokémon behind each bot's form so the page doesn't look
flat. Our own 32×32 pixel silhouettes were tried first and rejected as too crude; the owner
asked for third-party art for these backgrounds, and then for the game sprites published by
[Pokémon Database](https://pokemondb.net/sprites). That site states that official artwork and
sprites "are used under a Fair Use Policy, so you are free to use them however you like", and
offers a way to add them to other sites. [ADR-0010](0010-skins-as-sanitized-data.md) says all
art in the repository is original, and the repository and release zips are GPL-3.0, which
can't relicense Pokémon art.

## Decision
- Behind each form the configurator shows one Pokémon at low opacity
  (`--backdrop-opacity`, default `.14`): Pikachu (Shiny Bot), Machop (Train Bot),
  Meowth (Farm Bot).
- By default it is the **FireRed/LeafGreen sprite** from Pokémon Database
  (`img.pokemondb.net/sprites/firered-leafgreen/<normal|shiny>/<name>.png`), scaled up with
  crisp pixels. That set only has some species, so the **Emerald** sprite fills the rest (all
  386 checked), and the PokeAPI official artwork is the last fallback.
- The images are **loaded at runtime** and **never stored** in this repository or in the
  release zips. Offline, or if every source fails, the image is removed and the page works
  as before.
- The player can change it in the *Apariencia* dialog (gear button, or the *Fondo* button on
  the form): any Gen 1–3 Pokémon by name, the style (FireRed/LeafGreen sprite, Pokémon HOME
  render, or official artwork from PokeAPI), shiny, their own image or none, and the intensity.
  The choice is stored in their browser (Pokémon per bot; style, shiny and intensity for all).
- Order: the player's choice, then the skin's image (`backdrop-<bot>` sprite), then the skin's
  Pokémon (`backdrop`, e.g. the Gengar skin), then the bot's default.
  A skin can also hide them (`--backdrop-opacity: 0`).
- Everything else keeps ADR-0010's rule: icons, mascot and skin sprites are original work.

## Alternatives considered
- **Our own silhouettes** — no third-party art, but the owner found them too crude.
- **PokeAPI official artwork as the default** — tried; the owner preferred the game sprites,
  which match a FireRed/LeafGreen tool. Kept as a style and as the last fallback.
- **Copy the images into the repository** — works offline, but it would redistribute
  Nintendo / Creatures / GAME FREAK art inside a GPL repository and its releases.
- **No background** — the flat look the owner wanted to avoid.

## Consequences
- **Positive:** the page looks finished and on theme; the repository and releases stay free
  of copyrighted images.
- **Negative / costs:** when online, the page requests one image per form from
  `img.pokemondb.net` (or GitHub for the artwork style). That reveals the visitor's IP to those
  hosts; nothing else is sent (`no-referrer`). If a site moves its files, the backgrounds
  disappear until the URLs in `configurator/js/sprites.js` are updated.
- **Open (Human-in-the-Loop):** none.
