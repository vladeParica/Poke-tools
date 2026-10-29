# Monitoring — Poke-tools

> **AI-DLC phase:** `06-monitoring`
> The bots run for hours with nobody watching. This is what the player has to know what
> they're doing and to find out when something happens.

## Health
- **Panel** (key 9): current mode or state, attempts, target, EVs gained, last message.
  The full level adds a diagnostics line (`Menu`, `Espera`, `Cursor`, `Combate`, `Pos`) to
  check the addresses on other languages.
- **Lua console**: detected game and language, configuration errors and warnings on load.
- "Healthy" = the panel changes state and the counters go up.

## Metrics
| Metric | Why it matters | Where |
|---|---|---|
| Attempts / resets until the match | Tells you if the filter is too strict | Panel, `shiny_log.txt` |
| Calibrated delay | If it varies a lot, there is lag | Console, panel |
| Battles fought / fled | If it runs from almost everything, the area is a poor choice | Panel, `train_log.txt` |
| EVs gained per battle | Spot Pokérus or Macho Brace | Panel ("+2 Vel (Diglett)") |
| Trips to the Center | If there are many, raise `healBelow` or change area | Panel, `train_log.txt` |

## Alerts
| Situation | Severity | How the player finds out |
|---|---|---|
| Target found (Shiny Bot) | High | Game paused + message + `shiny_log.txt` |
| Training complete | High | Pause + `notify` notification |
| Wild shiny in the Train Bot | High | Pause (`stopOnShiny`) + notification |
| Wants to learn a move (`ask`) | Medium | Notification; waits `askTimeout` |
| Evolution with `evolve: true` | Medium | Notification; the player finishes the scene and the bot continues |
| Bot stopped by a problem (blocked route, game reset, another instance) | Medium | Pause + orange message on the panel + log line + notification |

Phone notifications (`notify`) only exist in the Train Bot.

## Service objectives
SLOs don't apply: it's a local tool. The expectation is that the bot **never keeps
pressing buttons in a state it doesn't understand**: when in doubt it stops and says so.

## Logs
- `logs/shiny_log.txt` and `logs/train_log.txt`: one line per event, with date and game
  version (`[FireRed USA v1.0]`).
- `logs/` is in `.gitignore`.
