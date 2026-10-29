# Deployment guide — `<Project name>`

> **AI-DLC phase:** `05-deployment`
> Step-by-step to production, plus the runbook. Secrets live in the environment, never in the repo.

## 1. Services to provision
| Service | For | Notes |
|---|---|---|
| `<host>` | `<frontend/backend>` | `<plan>` |
| `<database>` | `<data + backups>` | `<backups/PITR>` |

## 2. Environment variables
| Variable | Use | Secret |
|---|---|---|
| `<NAME>` | `<...>` | `<yes/no>` |

**Secret generation:** `<command/script to generate production secrets; where they are stored>`

## 3. Steps
1. Provision services and set env vars.
2. Apply database migrations (do NOT load test seed).
3. Deploy backend, then frontend.
4. Connect domains + HTTPS.
5. Smoke-test (health check, a core flow).

## 4. Runbook / rollback
- **Rollback (app):** `<how>`
- **Rollback (data):** `<restore from backup/PITR>`
- **Migrations:** `<incremental; avoid destructive changes>`

## 5. Go-live checklist
- [ ] Secrets set  · [ ] Migrations applied, seed NOT run  · [ ] Backups + restore tested
- [ ] Domains + HTTPS  · [ ] Smoke tests pass  · [ ] Monitoring on (see `06-monitoring`)
