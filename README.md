<p align="center">
  <img src="assets/logo.svg" alt="Poke-tools logo" width="160">
</p>

<h1 align="center">Poke-tools</h1>

<p align="center">
  Lua bots for <b>Pokémon FireRed &amp; LeafGreen</b>: RNG-based shiny hunting and automatic EV training.
</p>

<p align="center">
  <a href="https://github.com/vladeParica/Poke-tools/actions/workflows/ci.yml"><img src="https://github.com/vladeParica/Poke-tools/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue.svg" alt="License: GPL-3.0"></a>
  <img src="https://img.shields.io/badge/Lua-5.1-2C2D72.svg" alt="Lua 5.1">
  <img src="https://img.shields.io/badge/emulator-VBA--rr-555.svg" alt="VBA-rr">
</p>

Scripts for the **VBA-rr** emulator that hunt shinies by manipulating the RNG and train
EVs and levels automatically in **Pokémon FireRed and LeafGreen** (GBA).

| Bot | What it does |
|---|---|
| [**Shiny Bot**](shinybot/) | Shiny and perfect-IV Pokémon: blind or frame-exact RNG (statics, gifts, roamers, wild), initial seed and SID on a new game |
| [**Train Bot**](trainbot/) | Exact EVs and levels: picks opponents and moves, learns moves, walks back to the Pokémon Center on its own |
| [**Farm Bot**](farmbot/) *(experimental)* | Farms items (Pickup, Thief), levels or money (trainer rematches with the VS Seeker) |
| [**Configurator**](configurator/) | Visual editor for the bots' settings, with live validation and skins. Open `configurator/index.html` |

> The bots and the configurator speak **Spanish, English or Japanese**: set `"language"` in the
> bot's JSON (`"es"`, `"en"`, `"ja"`; Japanese in romaji, since the emulator can't draw kana).

## Quick start

1. Install VBA-rr and turn off *Pause When Inactive*. The ROM is not included.
2. Download the bot's zip from [Releases](https://github.com/vladeParica/Poke-tools/releases)
   and unpack it into a folder (or copy the bot's `.lua` and `.json` from this repository).
   Set it up visually with the configurator included in the zip, or edit the JSON by hand.
3. VBA-rr → *Tools → Lua Scripting → New Lua Script Window* → open the `.lua` → *Run*.
4. Press **7** to start.

Load **only one script at a time**. How to use each bot: [Shiny Bot](shinybot/README.md) ·
[Train Bot](trainbot/README.md) · [Farm Bot](farmbot/README.md).

## Documentation

- [Project documentation](docs/README.md): requirements, architecture, decisions (ADRs),
  testing and installation.
- [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md) · [Security](SECURITY.md)

## Credits and license

Built on [DevonStudios/LuaScripts](https://github.com/DevonStudios/LuaScripts)
(Devon Studios x Real.96) and data from [pret/pokefirered](https://github.com/pret/pokefirered).
Details in [docs/00-project/credits.md](docs/00-project/credits.md).

Licensed under [GPL-3.0](LICENSE). Pokémon is a trademark of Nintendo, Game Freak and
Creatures; this project is not affiliated with them.
