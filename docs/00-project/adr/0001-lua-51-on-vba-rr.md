# ADR-0001 — Lua 5.1 en VBA-rr como plataforma

> **Fase AI-DLC:** `00-project`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29 (registro retroactivo)  ·  **Dueño:** vladeParica

## Contexto
Los bots necesitan leer la memoria del juego en cada frame, pulsar botones con precisión
de un frame, cargar estados y dibujar texto sobre la pantalla. El dueño juega en VBA-rr y
las herramientas de RNG de referencia (Devon Studios) están escritas para VBA-rr.

## Decisión
Los bots son scripts **Lua 5.1 para VBA-rr**: usan su API (`memory`, `joypad`, `emu`,
`savestate`, `gui`, `input`) y solo la biblioteca estándar de Lua 5.1.

## Alternativas consideradas
- **BizHawk** — Lua más moderno y mejor depuración, pero el dueño no lo usa y la API de
  memoria/botones es distinta. Devon Studios tiene versión BizHawk si algún día se porta.
- **mGBA (scripting en Lua 5.4)** — API reciente y distinta; habría que reescribir la capa
  de acceso al emulador.
- **Programa externo que controle el emulador** — más complejo y sin precisión de frame.

## Consecuencias
- **Positivas:** acceso directo a la memoria y a los frames; compatible con las direcciones
  y tablas de Devon Studios.
- **Costos:** Lua 5.1 (sin enteros de 64 bits ni operadores de bits: se usa `bit`/funciones
  propias); rarezas de VBA-rr que hay que esquivar (diálogo de error de
  `savestate.create(n)`, *Pause When Inactive*). Portar a otro emulador implica reescribir
  la capa de acceso.
