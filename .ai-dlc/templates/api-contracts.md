# API contracts — `<Project name>`

> **AI-DLC phase:** `02-design`
> Design-time contract. If the code generates a live spec (e.g. OpenAPI from validation schemas), that
> live spec is the source of truth; note where to find it.

## Conventions
- Base path: `<e.g. /api/v1>`
- Format: JSON. Auth: `<scheme>`. Error envelope: `<shape>`.

## Endpoints
| Method + path | Auth | Purpose | Request | Response |
|---|---|---|---|---|
| `<POST /resource>` | `<role/none>` | `<what it does>` | `<body / schema>` | `<status + body>` |

## Business rules reflected in the API
- `<rule that shapes a request/response, with a pointer to the PRD/ADR>`
