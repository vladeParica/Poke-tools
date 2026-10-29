# ADR-0005 — Pruebas con un simulador del juego (lupa + mocks)

> **Fase AI-DLC:** `04-testing`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29 (registro retroactivo)  ·  **Dueño:** vladeParica

## Contexto
Probar en el emulador real es lento (minutos u horas por escenario), manual y no se puede
automatizar en CI. Además no se pueden distribuir ROMs.

## Decisión
Cada bot tiene un **simulador en Lua** (`tests/mock*.lua`) que imita la API de VBA-rr, la
memoria relevante y la lógica mínima del juego (RNG, combates con menús reales, puertas,
enfermera, prompts de aprender ataque, evolución). Python con
[lupa](https://pypi.org/project/lupa/) ejecuta el bot generado dentro de Lua 5.1 contra
cada escenario (`tests/run_*.py`).

## Alternativas consideradas
- **Solo pruebas manuales en el emulador** — sin red de seguridad al cambiar un modo.
- **Emulador sin interfaz en CI** — necesitaría la ROM (no distribuible).
- **Pruebas unitarias de funciones sueltas** — el código vive en un único script con
  estado global; los errores reales están en la interacción con el juego.

## Consecuencias
- **Positivas:** cada escenario corre en segundos; se reproducen casos raros (lag, Pokémon
  a medio crear, puertas, Pokérus) que en el juego son difíciles de provocar.
- **Costos:** el simulador puede divergir del juego real; por regla, lo que solo se probó
  en el simulador se dice así. Hoy los runners **imprimen** el resultado de cada escenario
  y una persona lo compara con lo esperado; no fallan solos (ver
  [estrategia de pruebas](../../04-testing/test-strategy.md)).
