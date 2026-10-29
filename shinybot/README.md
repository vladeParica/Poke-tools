# Shiny Bot — `FRLG_ShinyBot.lua`

Hunts shiny Pokémon, and Pokémon with exact natures and IVs, in FireRed / LeafGreen,
either blind (soft resets) or by manipulating the RNG.

## Usage

1. Copy `FRLG_ShinyBot.lua` and `FRLG_ShinyBot.json` into the same folder.
2. VBA-rr → *Tools → Lua Scripting → New Lua Script Window* → open the `.lua` → *Run*.
3. Pick a mode with **8** and press **7** to start.

| Key | Action |
|---|---|
| **7** | Start / stop |
| **8** | Change mode |
| **9** | Panel: compact, full or hidden |
| **0** | Reload the JSON (with the bot stopped) |

When it finds a match, the game is **paused**: save a state with **Shift+F1** and catch it.

## Modes

The in-game mode names are in Spanish (shown in parentheses).

| # | Mode | What it does |
|---|---|---|
| 1 | Wild (*Salvaje*) | Walks in the grass and runs from battles until the target appears |
| 2–4 | Static, Gift, Roamer (*Estático, Regalo, Roamer*) | Blind soft resets in front of the Pokémon |
| 5–7 | Static RNG, Gift RNG, Roamer RNG | Computes the exact advance and presses A on that frame |
| 8 | Wild RNG (*Salvaje RNG*) | Walks to one step before the encounter and takes the step on the exact frame |
| 9 | New game (*Partida nueva*) | Restarts until it gets the TID/SID you want |
| 10 | Initial seed (*Semilla inicial*) | Hits a seed on the title screen, then launches `afterSeedMode` |

For far targets, **register the Teachy TV on SELECT**: the bot opens it to advance the RNG
about 313 times per frame.

## Configuration

Everything lives in `FRLG_ShinyBot.json`, commented line by line (in Spanish): `shiny`,
`species`, `natures`, `minIVs`/`maxIVs`, `hiddenPower`, `mode`, `initialSeeds`,
`afterSeedMode`… Full reference in [docs/02-design/api-contracts.md](../docs/02-design/api-contracts.md).

Seeds for `initialSeeds` depend on your TID/SID: compute them with [tools/rng/](../tools/rng/).

## Multiple windows

You can run several instances at once (each one creates `inst_N.lock`). With
`"stopOthers": true`, the one that finds the target stops the others.
