# Data classification — `<Project name>`

> **AI-DLC phase:** `00-project`
> Inventory every kind of data by sensitivity so design (encryption, access control, retention, audit)
> can be driven by it, not guessed.

| Data | Category | Sensitivity | Handling requirements |
|---|---|---|---|
| `<e.g. user contact info>` | PII | Restricted | `<encryption in transit + at rest, access by role, retention>` |
| `<e.g. clinical/financial notes>` | Sensitive | Restricted | `<column encryption, audit log, pseudonymization>` |
| `<e.g. public catalog>` | Public | Low | `<no special handling>` |

**Sensitivity levels:** `Public` < `Internal` < `Confidential` < `Restricted`.

## Cross-cutting requirements
- `<e.g. immutable audit log for access to Restricted data>`
- `<e.g. retention policy owner / regulation that applies>`
