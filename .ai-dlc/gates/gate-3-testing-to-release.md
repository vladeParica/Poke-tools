# Gate 3 — Pruebas → Versión

> **Fase AI-DLC:** salida de `04-testing` (con `05-deployment` y `06-monitoring` listos).
> **Objetivo:** confirmar que el bot está probado, se puede instalar y se puede vigilar antes de publicar una versión.

Marca cada punto solo cuando esté completo **y revisado por una persona**.

## Pruebas
- [x] [`test-strategy.md`](../../docs/04-testing/test-strategy.md) existe y se ejecutó: todos los escenarios dan el resultado esperado.
- [x] Los caminos críticos y los escenarios de riesgo de los PRD están cubiertos.
- [x] Probado en el juego real, o anotado qué no se pudo probar.
- [x] Huecos conocidos listados con una decisión.

## Instalación
- [x] [`deploy-guide.md`](../../docs/05-deployment/deploy-guide.md) con instalación, actualización y vuelta atrás.
- [x] `notify` documentado como dato sensible.

## Monitoreo
- [x] [`monitoring.md`](../../docs/06-monitoring/monitoring.md) define panel, avisos y logs.

## Cierre
- [x] Obligaciones de la clasificación de datos cumplidas (nada Restringido en el repo).
- [x] Los `TODO — Human-in-the-Loop` restantes están resueltos o aplazados a conciencia.

## Veredicto
- [x] **Gate 3 passed** (aprobada con condiciones) — se puede pasar a publicar la versión.
- Aprobada por: vladeParica (revisión delegada a Claude)  ·  Fecha: 2026-10-29

**Condición:** la protección de `logDir`/`sharedDir` (2026-10-29) solo se probó en el
simulador; confirmar en el juego real que los logs se siguen creando en `logs/`. Los
runners siguen sin comprobaciones propias (hueco aceptado en la estrategia de pruebas).
