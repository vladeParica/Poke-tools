# Documentación de Poke-tools

La documentación sigue la práctica **AI-DLC**: una carpeta por fase del ciclo de vida, y
entre fases una **puerta** (*gate*) que una persona revisa antes de avanzar. Las listas de
las puertas están en [`.ai-dlc/gates/`](../.ai-dlc/gates/) y las plantillas en
[`.ai-dlc/templates/`](../.ai-dlc/templates/).

| Fase | Contenido |
|---|---|
| [00 · Proyecto](00-project/) | [Carta del proyecto](00-project/charter.md) · [Glosario](00-project/glossary.md) · [Clasificación de datos](00-project/data-classification.md) · [Decisiones (ADR)](00-project/adr/) · [Créditos](00-project/creditos.md) |
| [01 · Requisitos](01-requirements/) | [PRD Shiny Bot](01-requirements/prd-shinybot.md) · [PRD Train Bot](01-requirements/prd-trainbot.md) |
| [02 · Diseño](02-design/) | [Arquitectura](02-design/architecture.md) · [Contratos: JSON, archivos, teclas y memoria](02-design/api-contracts.md) · [Modelo de amenazas](02-design/threat-model.md) · [Diagramas C4](architecture/) |
| [03 · Implementación](03-implementation/) | [Backlog y notas](03-implementation/backlog.md) |
| [04 · Pruebas](04-testing/) | [Estrategia de pruebas](04-testing/test-strategy.md) |
| [05 · Despliegue](05-deployment/) | [Instalación y publicación de versiones](05-deployment/deploy-guide.md) |
| [06 · Monitoreo](06-monitoring/) | [Panel, logs y avisos](06-monitoring/monitoring.md) |

El contexto técnico completo para desarrollar (direcciones de memoria, comportamientos
del juego descubiertos) está en [`CLAUDE.md`](../CLAUDE.md).

## Estado de las puertas

La documentación se escribió **después** del código (documentación retroactiva) y las
puertas se revisaron contra el código del 2026-10-29.

| Puerta | Estado |
|---|---|
| [Gate 0 · Inicio → Requisitos](../.ai-dlc/gates/gate-0-inception-to-requirements.md) | Aprobada |
| [Gate 1 · Diseño → Implementación](../.ai-dlc/gates/gate-1-design-to-implementation.md) | Aprobada |
| [Gate 2 · Implementación → Pruebas](../.ai-dlc/gates/gate-2-implementation-to-testing.md) | Aprobada |
| [Gate 3 · Pruebas → Versión](../.ai-dlc/gates/gate-3-testing-to-release.md) | Aprobada con condiciones (probar en el juego real la carpeta de logs) |
