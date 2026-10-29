# C4 — Contenedores

> **Fase AI-DLC:** `02-design`  ·  Nivel 2: las piezas que se ejecutan o se guardan.

```mermaid
C4Container
    title Contenedores — Poke-tools

    Person(jugador, "Jugador")

    System_Boundary(pc, "PC del jugador") {
        Container(vba, "VBA-rr", "Emulador + Lua 5.1", "Ejecuta la ROM y los scripts")
        Container(shiny, "FRLG_ShinyBot.lua", "Lua 5.1 (generado)", "Búsqueda de shinies e IVs, a ciegas o con RNG")
        Container(train, "FRLG_TrainBot.lua", "Lua 5.1 (generado)", "Entrenamiento de EVs y nivel")
        ContainerDb(cfg, "JSON de configuración", "Archivos", "FRLG_ShinyBot.json / FRLG_TrainBot.json")
        ContainerDb(files, "Archivos de trabajo", "Texto", "Logs, inst_N.lock, shiny_stop.flag, train_running.lock")
        ContainerDb(route, "Ruta", "Texto", "FRLG_TrainRoute*.txt")
        Container(rng, "tools/rng", "C + Python", "Busca objetivos y semillas fuera del emulador")
    }

    System_Ext(notif, "ntfy.sh / Discord", "Avisos")

    Rel(jugador, vba, "Teclas 6-9, 0")
    Rel(vba, shiny, "Llama cada frame")
    Rel(vba, train, "Llama cada frame")
    Rel(shiny, cfg, "Lee")
    Rel(train, cfg, "Lee")
    Rel(shiny, files, "Escribe / lee")
    Rel(train, files, "Escribe / lee")
    Rel(train, route, "Graba / lee")
    Rel(train, notif, "curl en segundo plano", "HTTPS")
    Rel(jugador, rng, "Calcula semillas para initialSeeds")
```

**Notas**
- Solo se carga **un** script a la vez por ventana de Lua. El Shiny Bot admite varias
  ventanas coordinadas por archivos; el Train Bot solo una.
- Los `.lua` se generan desde `src/` con `build.py` ([ADR-0002](../00-project/adr/0002-script-unico-generado.md)).
