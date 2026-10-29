# C4 — Contexto

> **Fase AI-DLC:** `02-design`  ·  Nivel 1: el sistema en su entorno.

```mermaid
C4Context
    title Contexto — Poke-tools

    Person(jugador, "Jugador", "Configura el JSON, coloca al personaje y guarda el estado al final")
    Person(dev, "Desarrollador", "Edita src/, corre build.py y las pruebas")

    System(bots, "Poke-tools", "Shiny Bot y Train Bot: scripts Lua que juegan solos")

    System_Ext(vba, "VBA-rr", "Emulador de GBA con Lua 5.1; ejecuta la ROM de FRLG")
    System_Ext(ntfy, "ntfy.sh", "Avisos push al celular (opcional)")
    System_Ext(discord, "Discord", "Webhook de un canal (opcional)")
    System_Ext(pret, "pret/pokefirered", "Decompilación: símbolos y datos del juego")
    System_Ext(github, "GitHub Actions", "CI: build al día + simulador")

    Rel(jugador, vba, "Juega y carga el script")
    Rel(vba, bots, "Ejecuta cada frame")
    Rel(bots, ntfy, "Envía avisos", "HTTPS / curl")
    Rel(bots, discord, "Envía avisos", "HTTPS / curl")
    Rel(dev, bots, "Desarrolla y prueba")
    Rel(dev, pret, "Genera tablas", "gen_tables.py")
    Rel(github, bots, "Verifica cada push y PR")
```

**Notas**
- La ROM y las partidas son del jugador y nunca entran al repositorio.
- ntfy.sh y Discord solo se usan si el Train Bot tiene `notify` configurado.
