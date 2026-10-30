# Installation and releases — Poke-tools

> **AI-DLC phase:** `05-deployment`
> There are no servers: "deploying" means installing the script on the player's PC and
> publishing a release on GitHub.

## 1. Player requirements
| What | What for | Notes |
|---|---|---|
| VBA-rr with Lua | Running the bots | Turn off *Pause When Inactive* |
| FireRed or LeafGreen ROM | The game | Not included or distributed |
| `curl` | Train Bot notifications (optional) | Ships with Windows 10/11 |

## 2. Installation
1. Download the bot's zip from *Releases* (`poke-tools-<bot>-vX.Y.zip`) and unpack it into
   a folder. It has the `.lua`, the `.json`, the README, the examples and the configurator.
   Without a release, take the `.lua` and `.json` from the bot's folder in the repository.
2. For the Train Bot or the Farm Bot, add the route (`FRLG_TrainRoute*.txt`) if you use a
   recorded one.
3. Save the game where the bot is going to work (modes with soft resets go back to that save).
4. VBA-rr → *Tools → Lua Scripting → New Lua Script Window* → open the `.lua` → *Run*.
5. Optional: open `configurator/index.html` to create or edit the JSON visually; in Edge or
   Chrome, *Abrir carpeta* + *Guardar* writes it straight into the bot's folder.
6. Check the `Juego: FireRed USA…` line in the console (detected game and language).
7. Press **7**.

**Secret configuration:** the only sensitive value is `notify` (ntfy topic or Discord
webhook). It goes in your local JSON; never commit it to any repository.

## 3. Updating
1. Stop the bot (**7**) and close the Lua window.
2. Replace only the `.lua`; **keep your JSON and your routes**.
3. Check the [CHANGELOG](../../CHANGELOG.md) in case an option was renamed.

**Rolling back:** use the previous version's `.lua` (from *Releases* or the git history).

## 4. Publishing a release (maintainer)
1. Update the version in the bot's startup `print` (`src/`) and rebuild with `build.py`;
   if the tables or examples changed, also run `configurator/tools/build_data.py`.
2. Run every test ([strategy](../04-testing/test-strategy.md)) and test in the real game.
3. Move the `[Unreleased]` entries of `CHANGELOG.md` to the new version.
   Head the section `## [<bot> vX.Y] - YYYY-MM-DD`: it becomes the release notes.
4. Check the zip locally: `python tools/package.py <bot>-vX.Y` (it fails if the tag and the
   script's version differ) and open `dist/`.
5. Commit `chore: release <bot> vX.Y`, tag `<bot>-vX.Y` (`shinybot`, `trainbot`, `farmbot`)
   and push the commit and the tag (with the owner's OK).
6. The *Release* workflow runs the whole CI and, if it passes, publishes the release with the
   zip ([ADR-0012](../00-project/adr/0012-release-zips-per-bot.md)). A bot whose README says
   **Experimental.** goes out as a *pre-release*.

## 5. Pre-release checklist
- [ ] CI green (up-to-date build + simulator with no errors)
- [ ] Tested in the real game (or noted that it couldn't be)
- [ ] `CHANGELOG.md` and [contracts](../02-design/api-contracts.md) updated if the JSON, route format or keys changed
- [ ] No JSON with a real `notify`, no ROM or save file in the commit
