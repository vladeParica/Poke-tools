# Gate 1 — Diseño → Implementación

> **Fase AI-DLC:** salida de `02-design`.
> **Objetivo:** confirmar arquitectura, modelo de amenazas y decisiones (ADR) antes de escribir código.

Marca cada punto solo cuando esté completo **y revisado por una persona**.

## Arquitectura
- [x] [`architecture.md`](../../docs/02-design/architecture.md) describe estilo, componentes y modelo de datos.
- [x] Diagramas C4 presentes y válidos (Mermaid): contexto, contenedores y componentes de cada bot en [`docs/architecture/`](../../docs/architecture/).

## Seguridad
- [x] [`threat-model.md`](../../docs/02-design/threat-model.md) aplica STRIDE a los componentes.
- [x] Amenazas priorizadas con DREAD (inyección por `notify`, secretos en el repo, pérdida de progreso).

## Contratos
- [x] [`api-contracts.md`](../../docs/02-design/api-contracts.md) documenta el JSON, la ruta, las teclas y los archivos generados, y coincide con la tabla `CONFIG` del código.

## Decisiones (ADR)
- [x] Cada decisión no trivial tiene su ADR (contexto, decisión, alternativas, consecuencias).
- [x] Las decisiones abiertas siguen marcadas `TODO — Human-in-the-Loop`.

## Veredicto
- [x] **Gate 1 passed** (aprobada) — se puede pasar a `03-implementation`.
- Aprobada por: vladeParica (revisión delegada a Claude)  ·  Fecha: 2026-10-29
