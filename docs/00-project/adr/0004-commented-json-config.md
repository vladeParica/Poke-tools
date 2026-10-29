# ADR-0004 — Configuración en un JSON comentado junto al script

> **Fase AI-DLC:** `02-design`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29 (registro retroactivo)  ·  **Dueño:** vladeParica

## Contexto
El jugador tiene que poder cambiar qué busca o cómo entrena sin tocar el código, y
entender cada opción sin abrir documentación aparte. VBA-rr no tiene interfaz para
formularios.

## Decisión
Cada bot lee `FRLG_<Bot>.json` de **su misma carpeta**. Se admiten comentarios `//`
(se quitan antes de leer) para que el archivo de ejemplo explique cada opción. Las
opciones aceptan nombres en inglés o español (naturalezas, estadísticas). Un error de
configuración no detiene el emulador: el bot lo muestra en consola y espera a que se
corrija y se pulse **0**.

## Alternativas consideradas
- **Constantes al principio del `.lua`** — obliga a editar el script y se pierde al actualizar.
- **Menú dentro del juego** — mucho código de interfaz y poco práctico para listas (especies, IVs).
- **JSON estricto** — sin comentarios, el jugador no sabe qué hace cada opción.

## Consecuencias
- **Positivas:** actualizar el bot no pisa la configuración; ejemplos reutilizables
  (`trainbot/examples/`); validación con mensajes en español.
- **Costos:** parser JSON propio en Lua 5.1, mantenido a mano. El formato es el contrato
  público: renombrar una opción rompe los JSON de los usuarios (ver
  [contratos](../../02-design/api-contracts.md)).
