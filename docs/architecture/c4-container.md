# C4 — Containers

> **AI-DLC phase:** `02-design`  ·  Level 2: the pieces that run or are stored.

```mermaid
C4Container
    title Containers — Poke-tools

    Person(player, "Player")

    System_Boundary(pc, "Player's PC") {
        Container(vba, "VBA-rr", "Emulator + Lua 5.1", "Runs the ROM and the scripts")
        Container(shiny, "FRLG_ShinyBot.lua", "Lua 5.1 (generated)", "Shiny and IV search, blind or with RNG")
        Container(train, "FRLG_TrainBot.lua", "Lua 5.1 (generated)", "EV and level training")
        ContainerDb(cfg, "Configuration JSON", "Files", "FRLG_ShinyBot.json / FRLG_TrainBot.json")
        ContainerDb(files, "Working files", "Text", "Logs, inst_N.lock, shiny_stop.flag, train_running.lock")
        ContainerDb(route, "Route", "Text", "FRLG_TrainRoute*.txt")
        Container(rng, "tools/rng", "C + Python", "Finds targets and seeds outside the emulator")
    }

    System_Ext(notif, "ntfy.sh / Discord", "Notifications")

    Rel(player, vba, "Keys 6-9, 0")
    Rel(vba, shiny, "Calls every frame")
    Rel(vba, train, "Calls every frame")
    Rel(shiny, cfg, "Reads")
    Rel(train, cfg, "Reads")
    Rel(shiny, files, "Writes / reads")
    Rel(train, files, "Writes / reads")
    Rel(train, route, "Records / reads")
    Rel(train, notif, "Background curl", "HTTPS")
    Rel(player, rng, "Computes seeds for initialSeeds")
```

**Notes**
- Only **one** script is loaded per Lua window. The Shiny Bot allows several windows
  coordinated through files; the Train Bot only one.
- The `.lua` files are generated from `src/` with `build.py` ([ADR-0002](../00-project/adr/0002-single-generated-script.md)).
