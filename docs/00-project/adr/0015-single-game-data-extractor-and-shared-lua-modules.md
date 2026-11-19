# ADR-0015 — One game data extractor and shared Lua modules

> **AI-DLC phase:** `02-design`  ·  **Status:** accepted (amends [ADR-0011](0011-farm-bot-forked-from-train-bot.md))
> **Date:** 2026-11-20  ·  **Owner:** vladeParica

## Context
Three programs read pret/pokefirered on their own: `trainbot/tools/gen_tables.py` (the bots'
species, moves and type chart), `tools/guia/gen_guia.py` (the guide) and, through the bots'
tables, `configurator/tools/build_data.py`. Each one parses the same C files its own way, so a
mistake in one doesn't show in the others: `gen_tables.py` stored Bulbasaur's data under index 0
(the first entry, `[SPECIES_NONE] = {0},`, swallowed it), so for the Train and Farm Bots a wild
Bulbasaur had no data at all, while the guide had it right.

The Farm Bot is a fork of the Train Bot (ADR-0011): every battle or menu fix has to be copied by
hand, as happened with the fainted-lead and can't-run fixes. Both bots are close to Lua 5.1's
limit of 200 locals per function, which is why constants ended up in `K` and `PK` tables. The
bots' code grew as long `if/elseif` chains over a state string, and `afterBattleDecide` collects
more and more steps in one function.

The owner asked to improve maintenance without breaking what works, and to evaluate first. A
`.env` file or a data file read at run time were considered and rejected (see below).

## Decision
1. **One extractor**, `tools/gamedata/`: it reads pret once (a sparse clone in
   `trainbot/tools/pret_cache/pokefirered`) and writes a neutral, versioned
   `shared/gamedata/gamedata.json` (species, moves, effects, type chart, learnsets, TM/HM,
   tutors, evolutions, items, abilities, with the pret commit). It is committed, so building a
   bot never needs the network.
2. **Consumers take what they need from it**: the Train and Farm Bots' Lua tables are rendered
   from it by `build.py` (the hand-kept `train_tables.lua` and `gen_tables.py` go away), and the
   guide reads its core data from it. The configurator keeps reading the bots' tables, so it
   accepts exactly what the bots accept.
3. **Shared Lua modules**, `shared/lua/*.lua`, inserted by each `build.py` at a
   `--@@INCLUDE name@@` marker, so every bot is still one `.lua` file (what VBA-rr loads). Each
   module is one local (`local Menus = (function() ... return M end)()`), which also eases the
   200-locals limit. The first ones are the party/START menu code and the battle rules shared by
   the Train and Farm Bots.
4. **Patterns inside the bots**, applied step by step: a state dispatch table instead of the
   `if/elseif` chain (State), the after-battle steps as an ordered list of handlers (Chain of
   Responsibility), per-build addresses in one game profile (Adapter), and decision functions
   that take data instead of reading memory, with unit tests (functional core).
5. **Equivalence is the safety net**: every step must leave the generated files and the
   simulator output identical, except where a difference is intended and stated (the
   Bulbasaur fix).

## Alternatives considered
- **A `.env` file for the configuration** — VBA-rr's Lua has no support for it and the JSON
  already keeps the settings out of the script. Kept as an idea only for secrets (`notify`).
- **Game data in a JSON file read at run time** — smaller scripts, but one more file to ship
  next to each script, and a script with a data file of another version could behave wrongly
  without any error. The size (about 70 KB of 250) doesn't matter to VBA-rr.
- **`require` real Lua modules** — VBA-rr's module paths are unreliable and players would have
  to copy several files; building one file keeps installation as it is.
- **Rewriting the bots in one go** — too risky for code calibrated in the real game.

## Consequences
- **Positive:** game data is parsed once and fixed once; a battle or menu fix lands in both
  bots; fewer locals per bot; the decisions get unit tests.
- **Costs:** `build.py` gains an include step; the refactors are done over several commits,
  each with its equivalence check. Until every step is done, part of the fork's duplication
  remains.
- **Open (Human-in-the-Loop):** none.
