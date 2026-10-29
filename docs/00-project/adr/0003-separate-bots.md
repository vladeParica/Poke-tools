# ADR-0003 — Bots separados: el Shiny Bot solo busca

> **Fase AI-DLC:** `02-design`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29 (registro retroactivo)  ·  **Dueño:** vladeParica

## Contexto
El Shiny Bot creció a 10 modos calibrados uno a uno en el juego real. Añadir
entrenamiento (combates, rutas, menús de aprender ataques) al mismo script ponía en riesgo
los modos que ya funcionan. El dueño lo pidió explícitamente: mejorar, no arreglar uno y
dañar otro.

## Decisión
El **Shiny Bot es "estándar, solo búsquedas"**. Cada función nueva de otro tipo va en un
**script aparte** (el primero: `trainbot/`). Los bots comparten las tablas de nombres
(`shinybot/src/tables2.lua`) pero no código de comportamiento.

## Alternativas consideradas
- **Un solo bot con más modos** — más fácil de distribuir, pero cada cambio tocaría el
  bucle principal de todos los modos.
- **Biblioteca común de comportamiento** — menos código repetido, pero un cambio en la
  biblioteca afecta a los dos bots a la vez (ver [ADR-0002](0002-script-unico-generado.md)
  sobre por qué no se usa `require`).

## Consecuencias
- **Positivas:** un bot no puede romper al otro; cada uno tiene su versión (Shiny v4.3,
  Train v1.10) y sus pruebas.
- **Costos:** código repetido (lectura del equipo, panel, logs, detección del juego); un
  arreglo en esa parte hay que hacerlo en los dos. Solo se carga un script a la vez.
