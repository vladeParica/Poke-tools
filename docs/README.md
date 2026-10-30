# Poke-tools documentation

The documentation follows the **AI-DLC** practice: one folder per lifecycle phase and,
between phases, a **gate** that a person reviews before moving on. The gate checklists
are in [`.ai-dlc/gates/`](../.ai-dlc/gates/) and the templates in
[`.ai-dlc/templates/`](../.ai-dlc/templates/).

| Phase | Contents |
|---|---|
| [00 · Project](00-project/) | [Project charter](00-project/charter.md) · [Glossary](00-project/glossary.md) · [Data classification](00-project/data-classification.md) · [Decisions (ADRs)](00-project/adr/) · [Credits](00-project/credits.md) |
| [01 · Requirements](01-requirements/) | [Shiny Bot PRD](01-requirements/prd-shinybot.md) · [Train Bot PRD](01-requirements/prd-trainbot.md) · [Configurator PRD](01-requirements/prd-configurator.md) · [Farm Bot PRD](01-requirements/prd-farmbot.md) |
| [02 · Design](02-design/) | [Architecture](02-design/architecture.md) · [Contracts: JSON, files, keys and memory](02-design/api-contracts.md) · [Threat model](02-design/threat-model.md) · [C4 diagrams](architecture/) |
| [03 · Implementation](03-implementation/) | [Backlog and notes](03-implementation/backlog.md) |
| [04 · Testing](04-testing/) | [Test strategy](04-testing/test-strategy.md) |
| [05 · Deployment](05-deployment/) | [Installation and releases](05-deployment/deploy-guide.md) |
| [06 · Monitoring](06-monitoring/) | [Panel, logs and notifications](06-monitoring/monitoring.md) |

The visual configurator for the bots' JSON lives in [`configurator/`](../configurator/README.md).

The full technical context for development (memory addresses, game behaviors we
discovered) is in [`CLAUDE.md`](../CLAUDE.md).

## Language

Repository documentation is in English. Everything the player sees **in the game** (panel,
console, logs, JSON comments) is in Spanish, so in-game messages are quoted in Spanish.

## Gate status

The documentation was written **after** the code (retroactive documentation) and the
gates were reviewed against the code on 2026-10-29.

| Gate | Status |
|---|---|
| [Gate 0 · Inception → Requirements](../.ai-dlc/gates/gate-0-inception-to-requirements.md) | Passed |
| [Gate 1 · Design → Implementation](../.ai-dlc/gates/gate-1-design-to-implementation.md) | Passed |
| [Gate 2 · Implementation → Testing](../.ai-dlc/gates/gate-2-implementation-to-testing.md) | Passed |
| [Gate 3 · Testing → Release](../.ai-dlc/gates/gate-3-testing-to-release.md) | Passed with conditions (check the log folder in the real game) |
