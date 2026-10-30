# ADR-0010 — Skins are sanitized data, and all art is original

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted; art rule amended by [ADR-0013](0013-official-artwork-behind-the-configurator-forms.md)
> **Date:** 2026-10-29  ·  **Owner:** vladeParica

## Context
The owner wants the configurator to be themable so anyone can make their own look. Skins
will be shared between players, so a skin file is untrusted input. The owner also wanted
Pokémon-style icons; existing icon sets (e.g. Pokémon HOME sprites) are owned by Nintendo /
The Pokémon Company and are not ours to redistribute, credited or not.

## Decision
- A skin is **data, not code**: CSS variables, sprite images and fonts. Built-in skins are
  `configurator/skins/*.js` files that call `PT.registerSkin()`; players import their own as
  `.json` (kept in the browser's storage).
- Every skin goes through `PT.skins.sanitize()`: only a fixed list of CSS variables; values
  without `;{}<>`; `url(...)`, sprites and fonts only as `data:image/...` / `data:font/...`;
  sprites are rendered as `img` elements, where SVG can't run scripts.
- The UI draws everything with CSS variables, so a skin can restyle the whole page.
- All built-in art (line icons and the pixel-art mascot) is **original Poke-tools work**. The
  repository ships no third-party Pokémon art; players can put any image in their own
  local skins.

## Alternatives considered
- **Skins as JavaScript** — unlimited power, but importing a shared skin would mean running
  someone else's code.
- **Free-form CSS files** — flexible, but CSS can exfiltrate data via `url()` and break the
  layout; hard to sanitize.
- **Ship species icons from an existing set** — looks nicer, but it's someone else's
  copyrighted art.

## Consequences
- **Positive:** sharing skins is safe; the built-in look is consistent and legally clean.
- **Costs:** skins can't change the layout or add behavior; species are shown by name and
  EV badges rather than pictures.
