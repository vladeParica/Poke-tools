# C4 — Farm Bot components

> **AI-DLC phase:** `02-design`  ·  Level 3: inside `FRLG_FarmBot.lua`.

```mermaid
C4Component
    title Components — Farm Bot

    Container_Boundary(farm, "FRLG_FarmBot.lua") {
        Component(engine, "Battle engine (copy of the Train Bot's)", "Lua", "Fight/run, best move, move learning, evolution, healing trips")
        Component(modes, "Farm modes", "Lua", "nivel, objetos (Pickup), robar (Thief/Covet), dinero (trainers)")
        Component(memory, "Save data reader", "Lua", "Money and bag (XOR key), VS Seeker charge, registered item, held items")
        Component(take, "Take-items routine", "Lua", "START > POKEMON > ITEM > TAKE, each step checked in memory")
        Component(loop, "Trainer loop", "Lua", "Charge VS Seeker, use it, walk trainer route, come back")
        Component(routes, "Routes", "Lua", "Center route (key 6) and trainer route (key 5)")
        Component(out, "Log, panel and notifications", "Lua", "farm_log.txt, per-mode panel, notify via curl")
    }

    System_Ext(game, "FRLG in VBA-rr", "Party, battle, menus, SaveBlocks")

    Rel(modes, engine, "Decides fight / run / steal")
    Rel(modes, take, "Items to store")
    Rel(modes, loop, "dinero")
    Rel(take, game, "Reads menu state, presses buttons")
    Rel(memory, game, "Reads")
    Rel(loop, routes, "Walks")
    Rel(modes, out, "Events")
```

**Notes**
- Menu addresses come from pret's symbol maps for the four USA builds; on other versions the
  take-items routine falls back to pausing ([ADR-0011](../00-project/adr/0011-farm-bot-forked-from-train-bot.md)).
