# ADR-0007 — Rutas al Centro grabadas por el jugador

> **Fase AI-DLC:** `02-design`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29 (registro retroactivo)  ·  **Dueño:** vladeParica

## Contexto
El Train Bot tiene que ir a curarse y volver al punto de entreno sin ayuda. Calcular el
camino exigiría leer colisiones, conexiones entre mapas, puertas y NPCs que se mueven.

## Decisión
El jugador **graba la ruta una vez** con la tecla 6 (ida, curación, vuelta). Se guarda en
un `.txt` de texto plano (`GO` y `BACK`, pasos `grupo mapa x y dirección`) que el bot
repite. Al cargarla, `cleanRoute()` quita los pasos falsos que aparecen al cruzar puertas y
`fixRoute()` corrige la ruta. Las rutas útiles se comparten en `trainbot/examples/routes/`.

## Alternativas consideradas
- **Buscar el camino (A\*) con los datos de colisión** — mucho código y datos por mapa; no
  resuelve NPCs ni puertas especiales.
- **Curarse con objetos** — gasta dinero y no recupera PP de forma práctica.

## Consecuencias
- **Positivas:** funciona en cualquier sitio, incluida la casilla que cura de la Torre
  Pokémon (`healMode: "tile"`); rutas reutilizables y fáciles de revisar.
- **Costos:** el bot solo arranca desde el punto de entreno (±2 casillas) o desde una
  casilla del camino de vuelta; un NPC en medio puede bloquear la ruta (el bot se detiene
  con un mensaje).
