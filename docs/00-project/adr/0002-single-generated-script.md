# ADR-0002 — Un solo script generado desde `src/` con `build.py`

> **Fase AI-DLC:** `03-implementation`  ·  **Estado:** aceptada
> **Fecha:** 2026-10-29 (registro retroactivo)  ·  **Dueño:** vladeParica

## Contexto
El jugador copia el bot a una carpeta y lo abre en VBA-rr. `require` de Lua depende del
directorio de trabajo del emulador, que no es el del script, y repartir varios archivos
complica la instalación. A la vez, el código con tablas de datos de miles de líneas es
difícil de mantener en un solo archivo.

## Decisión
Se edita en `src/` (cuerpo + tablas) y `build.py` une las piezas en **un único `.lua`
autónomo** por bot, con finales de línea **CRLF** para Windows. El `.lua` generado se
versiona en el repo para que el jugador lo descargue tal cual. Nunca se edita a mano.

## Alternativas consideradas
- **Varios archivos con `require`** — frágil en VBA-rr (rutas) y más difícil de instalar.
- **Un único archivo editado a mano** — tablas y lógica mezcladas, diffs enormes.
- **No versionar el generado** — obligaría al jugador a tener Python para usar el bot.

## Consecuencias
- **Positivas:** instalación de un archivo; `src/` legible; las tablas se regeneran desde pret.
- **Costos:** hay que acordarse de correr `build.py` antes del commit. El CI lo verifica
  (regenera y falla si el resultado no coincide con lo versionado).
