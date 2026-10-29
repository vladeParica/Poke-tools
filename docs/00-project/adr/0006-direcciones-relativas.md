# ADR-0006 — Direcciones de combate relativas a `gEnemyParty`

> **Fase AI-DLC:** `02-design`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29 (registro retroactivo)  ·  **Dueño:** vladeParica

## Contexto
Las direcciones de memoria cambian entre USA, Europa y Japón y entre revisiones (1.0/1.1).
Solo la versión USA tiene mapa de símbolos verificado (pret/pokefirered). Devon Studios
da, para cada versión, unas pocas direcciones base (semilla del RNG, equipos, SaveBlocks).

## Decisión
El bot detecta juego, idioma y revisión leyendo la cabecera de la ROM (`0x080000AE`,
`0x080000AF`, `0x080000BC`), toma las direcciones base de Devon Studios para esa versión y
calcula el resto (cursores de combate, `gBattleMons`, `gBattleOutcome`…) como
**desplazamientos fijos desde `gEnemyParty`**, medidos en USA. `gMain` se estima desde la
semilla del RNG cuando no está verificado, y el panel muestra un diagnóstico para
comprobarlo.

## Alternativas consideradas
- **Tablas completas por versión** — exactas, pero sin mapa de símbolos para EUR/JPN no se
  pueden verificar.
- **Buscar patrones en memoria en tiempo real** — frágil y lento en Lua.

## Consecuencias
- **Positivas:** un solo código para todas las versiones; añadir una versión = 6–8
  direcciones base.
- **Costos:** en versiones distintas de USA las direcciones derivadas no están verificadas
  en el juego real. El bot avisa en consola ("la bandera de combate no está verificada
  para este idioma") y la línea de diagnóstico del panel permite comprobarlo.
