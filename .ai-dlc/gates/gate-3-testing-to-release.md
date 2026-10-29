# Gate 3 — Testing → Release

> **AI-DLC phase:** exit of `04-testing` (with `05-deployment` and `06-monitoring` ready).
> **Goal:** confirm the bot is tested, installable and observable before publishing a release.

Tick each item only when it is complete **and reviewed by a person**.

## Testing
- [x] [`test-strategy.md`](../../docs/04-testing/test-strategy.md) exists and was run: every scenario gives the expected result.
- [x] Critical paths and the PRDs' risk scenarios are covered.
- [x] Tested in the real game, or noted what couldn't be tested.
- [x] Known gaps listed with a decision.

## Installation
- [x] [`deploy-guide.md`](../../docs/05-deployment/deploy-guide.md) with installation, updating and rollback.
- [x] `notify` documented as sensitive data.

## Monitoring
- [x] [`monitoring.md`](../../docs/06-monitoring/monitoring.md) defines panel, alerts and logs.

## Sign-off
- [x] Data-classification obligations met (nothing Restricted in the repo).
- [x] Remaining `TODO — Human-in-the-Loop` items are resolved or consciously deferred.

## Verdict
- [x] **Gate 3 passed** (with conditions) — cleared to move to publishing the release.
- Approved by: vladeParica (review delegated to Claude)  ·  Date: 2026-10-29

**Condition:** the `logDir`/`sharedDir` check (2026-10-29) was only tested in the
simulator; confirm in the real game that logs are still created in `logs/`. The runners
still have no checks of their own (gap accepted in the test strategy).
