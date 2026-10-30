# Glossary — Poke-tools

> **AI-DLC phase:** `00-project`
> The project's shared vocabulary. In-game names use the official English names; the
> Spanish name the player sees in the bots is given where it matters.

| Term | Definition |
|---|---|
| **FRLG** | Pokémon FireRed (*Rojo Fuego*) and LeafGreen (*Verde Hoja*), GBA. |
| **VBA-rr** | VisualBoyAdvance-ReRecording: GBA emulator with Lua 5.1 to read memory and press buttons. |
| **Bot** | A Lua script that plays by itself. There are two: **Shiny Bot** and **Train Bot**. |
| **Mode** | What the Shiny Bot does in a run (Wild, Static RNG…). Changed with key 8. |
| **Instance** | A Lua window running a bot. The Shiny Bot allows several; the Train Bot only one. |
| **Run** | From pressing 7 until the bot stops or finds the target. |
| **RNG / LCRNG** | The game's random number generator: `s = s*0x41C64E6D + 0x6073`. Everything random comes from it. |
| **Advance** | One RNG call. "The target is at advance 2786" = after 2786 calls since the seed. |
| **Initial seed** | RNG state when the save is loaded; set by the moment A is pressed on the title screen (16 bits). |
| **Target** | The RNG advance that produces the wanted Pokémon. |
| **Calibrate** | Measure how many advances pass between the bot's button press and the Pokémon's creation (the **delay**). |
| **Method 1 / Method H-1** | The order in which the game asks the RNG for numbers when creating a Pokémon (statics/gifts vs. wild). |
| **PID** | 32-bit number that sets nature, gender, ability and whether it's shiny. |
| **TID / SID** | Visible and secret trainer IDs. Together with the PID they decide shininess. |
| **TSV** | `TID xor SID`; what the New game mode searches for. |
| **Shiny** | `(TID ^ SID ^ PIDhigh ^ PIDlow) < 8`. |
| **IVs** | Individual values (0–31) per stat. "6×31" = all six maxed. |
| **EVs** | Effort values gained from each battle; max 255 per stat and 510 total. |
| **Soft reset** | Resetting the game (A+B+START+SELECT) to change the seed. |
| **Teachy TV** | Item (*Tele Pokémon*) that advances the RNG ~313 times per frame; the bot opens it when registered on SELECT. |
| **Roamer** | Legendary Pokémon that moves around the map (Raikou, Entei, Suicune). |
| **Training spot** | Tile where the Train Bot walks looking for battles. |
| **Route** | `FRLG_TrainRoute*.txt` file with the way to the healing place (`GO`) and back (`BACK`). |
| **`healMode`** | How the Train Bot heals: `nurse` or `tile` (healing tile, Pokémon Tower 5F). |
| **Pickup** | Ability (*Recogida*) that may give an item after a won battle; used by the Farm Bot's `objetos` mode. |
| **Thief / Covet** | Moves (*Ladrón / Antojo*) that steal the target's held item; used by `robar`. |
| **VS Seeker** | Key item (*Buscapelea*) that makes trainers ready for a rematch; recharges in 100 steps. |
| **Trainer route** | Route recorded with key 5 that passes through the trainers' lines of sight (`dinero`). |
| **Panel** | Text the bot draws over the game (key 9). |
| **Simulator / mock** | Lua code that imitates the game's memory and buttons to test the bots without an emulator. |
| **pret** | The `pret/pokefirered` decompilation project: source of game symbols and data. |
| **Generated** | `FRLG_ShinyBot.lua` and `FRLG_TrainBot.lua`: built from `src/` with `build.py`; never edited by hand. |
