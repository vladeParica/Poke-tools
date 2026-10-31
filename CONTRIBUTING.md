# Contributing

Thanks for wanting to improve the bots. Before you start, read the
[project documentation](docs/README.md), especially the
[architecture](docs/02-design/architecture.md) and the [decisions (ADRs)](docs/00-project/adr/).

## Rules
- **Don't break what already works.** A change in one mode must not affect the others.
- **The Shiny Bot only searches.** Other kinds of features go in a separate bot ([ADR-0003](docs/00-project/adr/0003-separate-bots.md)).
- **Player-facing text is written in Spanish and translated** ([ADR-0014](docs/00-project/adr/0014-interface-in-spanish-english-and-japanese.md)):
  in the bots wrap it as `TX"..."` and add it to `shared/lang/en.json` and `ja.json` (Japanese in
  ASCII romaji; `python tools/lua_i18n.py check`); in the configurator use `tr()` and
  `js/lang/*.js`. Never translate values the logic compares (modes, JSON keys, file names).
  Repository documentation, code comments and commit messages are in English.
- **The repo is generic:** nothing from a specific save file (TID/SID, seeds computed for it).
  Use neutral values in examples (TID 12345 / SID 54321).
- **Never commit ROMs, save files, savestates or a JSON with a real `notify`.**
- If you couldn't test something in the real game, say so in the PR.

## Setup
```
pip install -r requirements-dev.txt
git config core.hooksPath .githooks
```

## Workflow
1. Edit **`*/src/*`**, never the generated `.lua` files ([ADR-0002](docs/00-project/adr/0002-single-generated-script.md)).
2. Rebuild: `python shinybot/build.py` and `python trainbot/build.py`.
3. Run the simulator tests ([test strategy](docs/04-testing/test-strategy.md)) and compare
   with each scenario's expected result.
4. If you change the JSON, the route format or the keys, update the
   [contracts](docs/02-design/api-contracts.md) and the [CHANGELOG](CHANGELOG.md).
5. If you change a design decision, update its ADR or add a new one.
6. If you change the bots' tables, example configs or options, run
   `python configurator/tools/build_data.py` and update `configurator/js/schema.js`; then run
   the configurator tests (see [configurator/README.md](configurator/README.md)).

## Commits
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) **in English**,
**3 lines at most** and **no `Co-Authored-By` lines**. The `.githooks/commit-msg` hook
checks this.

```
feat(trainbot): pause on evolution
fix(shinybot): recalibrate after lag
docs: reusable training routes
```

## Pull requests
Fill in the PR template. CI must pass: it checks that the generated `.lua` files match
`src/` and that every simulator scenario runs without errors.
