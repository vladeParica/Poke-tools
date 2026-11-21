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
| 11 | Fishing (*Pesca*) | Fishes with the rod registered on SELECT (face the water) and runs from battles until the target appears |
| 12 | Fishing RNG (*Pesca RNG*) | Casts until something bites, saves a state on "on the hook!" and presses B on the target's exact frame (USA FireRed/LeafGreen) |

### New game (mode 9): where to start the bot

1. Set `"mode": "Partida nueva"` and the `newGameTSV` you want in the JSON.
2. Start a **new game** and name your character. That fixes the TID.
3. Name your rival.
4. When Oak says *"That's right! I remember now! His name is [RIVAL]!"*, **don't press A**.
5. Press **0** to reload the config, then **7**.

The bot presses A through the rest of Oak's speech (the SID is created at the end of it),
reloads and tries other frames until TID xor SID falls in a `newGameTSV` range. Then it pauses
the game: save a state (Shift+F1) and keep playing.

If you press 7 too early, the bot tells you: before naming your character there is no TID yet
(TID 0) and it refuses to start; before naming the rival, its presses land on the naming
keyboard, so after two tries without a SID it stops and says when to press 7.

For far targets, **register the Teachy TV on SELECT**: the bot opens it to advance the RNG
about 313 times per frame.

Without the Teachy TV (modes 5–7), the first try still waits at normal speed, but the bot saves
a state about 1800 advances before the target: the following tries load that state instead of
waiting from the start again.

## Configuration

The easiest way is the [configurator](../configurator/README.md). Everything lives in `FRLG_ShinyBot.json`, commented line by line (in Spanish): `shiny`,
`species`, `natures`, `minIVs`/`maxIVs`, `hiddenPower`, `mode`, `initialSeeds`,
`afterSeedMode`… Full reference in [docs/02-design/api-contracts.md](../docs/02-design/api-contracts.md).

Seeds for `initialSeeds` depend on your TID/SID: compute them with [tools/rng/](../tools/rng/).

`language` sets the panel, console and log language: `"es"` (default), `"en"` or `"ja"`
(Japanese in romaji, since VBA-rr can't draw kana).

## Multiple windows

You can run several instances at once (each one creates `inst_N.lock`). With
`"stopOthers": true`, the one that finds the target stops the others.
