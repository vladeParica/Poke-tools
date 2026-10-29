# ADR-0008 — GPL-3.0 license

> **AI-DLC phase:** `00-project`  ·  **Status:** accepted
> **Date:** 2026-10-29  ·  **Owner:** vladeParica

## Context
The bots use memory addresses and name tables from
[DevonStudios/LuaScripts](https://github.com/DevonStudios/LuaScripts), which is distributed
under **GPL-3.0**. A redistributed derivative work must use the same license and publish
its source code. The repository had no license.

## Decision
The repository is published under **GPL-3.0** (`LICENSE` file at the root).

## Alternatives considered
- **MIT or another permissive license** — not compatible with including GPL-3.0 code.
- **No license** — by default nobody can reuse the code, and the obligations inherited
  from the code base remain unclear.
- **Rewriting without Devon Studios' code base** — a lot of work, and the already verified
  addresses would be lost.

## Consequences
- **Positive:** complies with the code base's license; anyone can use and modify the bots
  as long as they share their changes under the same license.
- **Costs:** anyone redistributing modified versions must publish their source code.
- Confirmed by the owner on 2026-10-29.
