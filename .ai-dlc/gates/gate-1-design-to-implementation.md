# Gate 1 — Design → Implementation

> **AI-DLC phase:** exit of `02-design`.
> **Goal:** confirm architecture, threat model and decisions (ADRs) before writing code.

Tick each item only when it is complete **and reviewed by a person**.

## Architecture
- [x] [`architecture.md`](../../docs/02-design/architecture.md) describes style, components and data model.
- [x] C4 diagrams present and valid (Mermaid): context, containers and each bot's components in [`docs/architecture/`](../../docs/architecture/).

## Security
- [x] [`threat-model.md`](../../docs/02-design/threat-model.md) applies STRIDE to the components.
- [x] Threats prioritized with DREAD (injection via `notify`, secrets in the repo, lost progress).

## Contracts
- [x] [`api-contracts.md`](../../docs/02-design/api-contracts.md) documents the JSON, route file, keys and generated files, and matches the code's `CONFIG` table.

## Decisions (ADRs)
- [x] Every non-trivial decision has an ADR (context, decision, alternatives, consequences).
- [x] Open decisions are still marked `TODO — Human-in-the-Loop`.

## Verdict
- [x] **Gate 1 passed** — cleared to move to `03-implementation`.
- Approved by: vladeParica (review delegated to Claude)  ·  Date: 2026-10-29
