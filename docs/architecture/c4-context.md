# C4 — Context

> **AI-DLC phase:** `02-design`  ·  Level 1: the system in its environment.

```mermaid
C4Context
    title Context — Poke-tools

    Person(player, "Player", "Fills in the JSON, positions the character and saves the state at the end")
    Person(dev, "Developer", "Edits src/, runs build.py and the tests")

    System(bots, "Poke-tools", "Shiny Bot and Train Bot: Lua scripts that play by themselves")

    System_Ext(vba, "VBA-rr", "GBA emulator with Lua 5.1; runs the FRLG ROM")
    System_Ext(ntfy, "ntfy.sh", "Push notifications to the phone (optional)")
    System_Ext(discord, "Discord", "Channel webhook (optional)")
    System_Ext(pret, "pret/pokefirered", "Decompilation: game symbols and data")
    System_Ext(github, "GitHub Actions", "CI: up-to-date build + simulator")

    Rel(player, vba, "Plays and loads the script")
    Rel(vba, bots, "Runs every frame")
    Rel(bots, ntfy, "Sends notifications", "HTTPS / curl")
    Rel(bots, discord, "Sends notifications", "HTTPS / curl")
    Rel(dev, bots, "Develops and tests")
    Rel(dev, pret, "Generates tables", "gen_tables.py")
    Rel(github, bots, "Checks every push and PR")
```

**Notes**
- The ROM and the save files belong to the player and never enter the repository.
- ntfy.sh and Discord are only used if the Train Bot has `notify` configured.
