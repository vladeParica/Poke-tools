# Threat model — Poke-tools

> **AI-DLC phase:** `02-design`  ·  **Method:** STRIDE + DREAD prioritization
> **Author:** vladeParica  ·  **Date:** 2026-10-29

## 1. Scope and assets
The system runs on the player's PC, with no server or accounts. What needs protecting:
- **The player's PC**: the bots run system commands (`os.execute` to create folders and
  launch `curl`).
- **The player's Discord webhook and ntfy topic** ([classification](../00-project/data-classification.md)).
- **The player's save**: the bot presses buttons and resets the game; a failure can lose
  unsaved progress.
- **The repository**: must not contain ROMs, save files or secrets.

## 2. Data flow
See the [container diagram](../architecture/c4-container.md). Untrusted inputs: the
**JSON** and the **route file** (anyone can write or share them). Network output: the
Train Bot's **notifications**.

## 3. STRIDE analysis
| Category | Threat | Component | Mitigation |
|---|---|---|---|
| **S**poofing | Someone guesses the ntfy topic and sends fake notifications or reads real ones | Notifications | Long, hard-to-guess topic (documented in the JSON); notifications carry no sensitive data |
| **T**ampering | A downloaded JSON or route crafted to inject commands into `os.execute` | Configuration, notifications | The ntfy topic only allows `[A-Za-z0-9_-]`; the Discord URL only `https://` + safe characters; the notification text is filtered to an allow-list before reaching curl |
| **T**ampering | `logDir` or `sharedDir` with quotes or variables to inject into `mkdir` | Log | The path is double-quoted and, if it contains `"`, `%`, `$` or `` ` ``, it isn't passed to the shell: the bot uses the script folder |
| **T**ampering | A shared configurator skin with CSS injection, remote `url()` (tracking) or script in an SVG sprite | Configurator skins | `PT.skins.sanitize()`: allow-listed variables, no `;{}<>`, only `data:` images and fonts, sprites rendered as `img` elements ([ADR-0010](../00-project/adr/0010-skins-as-sanitized-data.md)) |
| **T**ampering | A crafted JSON loaded into the configurator to inject HTML | Configurator | Every value is rendered with `textContent`; only our own SVG strings use `innerHTML` |
| **R**epudiation | Not knowing what the bot did while the player wasn't watching | Log | `shiny_log.txt` / `train_log.txt` with date, game version and every relevant event |
| **I**nformation disclosure | Committing a JSON with the webhook, or a ROM/save | Repository | `.gitignore` blocks ROMs, saves, savestates, logs and locks; examples use `notify: null`; PR review ([CONTRIBUTING](../../CONTRIBUTING.md)) |
| **I**nformation disclosure | The configurator keeps the draft (which may hold `notify` secrets) in the browser's local storage | Configurator | Stays on the player's machine, per browser profile; nothing is sent anywhere |
| **D**enial of service | Two instances pressing buttons at once; a notification blocking the emulator | Main loop, notifications | Lock files; curl in the background with `-m 15` |
| **D**enial of service | The bot resets the game with unsaved progress | Modes | `resetOnLoad` documented; the player saves before starting (README) |
| **E**levation of privilege | The script runs with the user's permissions | All | No extra permissions requested; only `mkdir` and `curl`. Third-party scripts should be reviewed before loading (advice in [SECURITY](../../SECURITY.md)) |

## 4. DREAD prioritization
| Threat | D | R | E | A | D | Total |
|---|---|---|---|---|---|---|
| Command injection via `notify` in a downloaded JSON | 8 | 2 | 2 | 2 | 3 | **17** (mitigated) |
| Discord webhook published in the repo | 4 | 8 | 6 | 1 | 6 | **25** |
| Guessed ntfy topic | 2 | 5 | 4 | 1 | 3 | **15** |
| Injection via `logDir` / `sharedDir` | 8 | 2 | 2 | 1 | 2 | **15** (mitigated) |
| Malicious configurator skin | 5 | 3 | 3 | 2 | 4 | **17** (mitigated) |
| Lost progress due to a reset | 4 | 6 | 1 | 3 | 8 | **22** |

## 5. Accepted risks
- The player runs Lua scripts with their own permissions: that's how VBA-rr works; accepted.
- ntfy.sh notifications go through a public service: accepted because they only carry the
  bot's status.
