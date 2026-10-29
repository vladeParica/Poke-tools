# Gate 2 — Implementación → Pruebas

> **Fase AI-DLC:** salida de `03-implementation`.
> **Objetivo:** confirmar que lo construido coincide con el diseño y está listo para probarse.

Marca cada punto solo cuando esté completo **y revisado por una persona**.

## Código vs. diseño
- [x] El comportamiento coincide con `docs/02-design/` (o la diferencia está en una ADR).
- [x] [`backlog.md`](../../docs/03-implementation/backlog.md) refleja lo hecho y lo pendiente.

## Calidad básica
- [x] `build.py` regenera los `.lua` sin cambios (el CI lo comprueba).
- [x] Las mitigaciones del modelo de amenazas están en el código (filtro de `notify`, archivos de bloqueo).
- [x] Ningún secreto, ROM ni partida en el repo; la configuración está en el JSON del jugador.

## Documentación al día
- [x] Contratos y `CHANGELOG.md` actualizados si cambió el JSON, la ruta o las teclas.
- [x] Las notas de implementación cubren lo que no es obvio.

## Veredicto
- [x] **Gate 2 passed** (aprobada) — se puede pasar a `04-testing`.
- Aprobada por: vladeParica (revisión delegada a Claude)  ·  Fecha: 2026-10-29
