# ADR-0012 — Release zips per bot

> **AI-DLC phase:** `05-deployment`  ·  **Status:** accepted
> **Date:** 2026-10-30  ·  **Owner:** vladeParica

## Context
Players had to clone the repository or download the `.lua` and `.json` one by one, then
fetch the examples and the configurator separately. Each bot already has its own version
and tag convention (`shinybot-vX.Y`, `trainbot-vX.Y`; [ADR-0003](0003-separate-bots.md)),
and publishing a release was a manual step in the deploy guide. Nothing stopped a tag from
naming a version different from the one the script prints.

## Decision
- Pushing a tag `<bot>-vX.Y` (shinybot, trainbot, farmbot) runs `.github/workflows/release.yml`:
  it runs the whole CI (`ci.yml` as a reusable workflow) and, only if it passes, publishes a
  GitHub release with one zip.
- The zip is built by `tools/package.py` and unpacks into one folder: the bot's `.lua`
  (byte for byte, CRLF), its `.json`, README, `examples/`, the license and the
  configurator (no tests or build tools).
- The tag must match the version in the bot's startup `print`; otherwise packaging fails.
- Release notes come from the CHANGELOG section headed `## [<bot> vX.Y]` (or
  `## [<bot>-vX.Y]`); without one, GitHub generates them from the commits.
- A bot whose README says **Experimental.** is published as a *pre-release*.
- CI builds every zip as a dry run, so packaging can't break unnoticed.

## Alternatives considered
- **One zip with every bot** — simpler, but bots are versioned separately and a player
  usually wants one; it would also force a release of all bots for a change in one.
- **Attach only the `.lua` and `.json`** — what the guide said before; the player still
  had to find the examples and the configurator.
- **Build releases by hand** — no setup, but easy to ship a stale or mismatched script.

## Consequences
- **Positive:** one download per bot, ready to use; a release can't ship a script that
  fails CI or prints another version; the experimental status is visible on GitHub.
- **Negative / costs:** the configurator is duplicated in each zip (about 100 KB); pushing
  a tag needs the owner's OK like any push.
- **Open (Human-in-the-Loop):** which bot versions to publish first, and when the Farm Bot
  stops being experimental.
