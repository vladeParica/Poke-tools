# Test strategy — `<Project name>`

> **AI-DLC phase:** `04-testing`
> How the system is verified — including the abuse/edge scenarios from the PRD, not just the happy path.

## Levels
| Level | Scope | Tooling | What it covers |
|---|---|---|---|
| Unit | `<pure logic / rules>` | `<...>` | `<...>` |
| Integration | `<with DB / external services>` | `<...>` | `<...>` |
| End-to-end | `<user flows>` | `<...>` | `<...>` |
| `<load / security>` | `<...>` | `<...>` | `<...>` |

## Critical / safety paths (must be covered)
- `<the paths where a bug hurts most — from the charter's non-negotiables and the PRD abuse cases>`

## Fixtures / seed data
- `<how test data is provisioned; keep it separate from production seed>`

## Known gaps
| Gap | Risk | Decision (fix now / accept) |
|---|---|---|
| `<...>` | `<...>` | `<...>` |
