# Data classification — Poke-tools

> **AI-DLC phase:** `00-project`
> Everything runs on the player's PC; there is no server or database. The only data that
> leaves the machine are the Train Bot's optional notifications.

| Data | Where it lives | Sensitivity | Handling |
|---|---|---|---|
| Game ROM | Player's PC | **Restricted** (copyright) | Never in the repo; `.gitignore` blocks `*.gba` |
| Save files and savestates (`.sav`, `.sgm`, `.sg0-9`) | Player's PC | **Restricted** (copyrighted and private content) | Never in the repo; blocked in `.gitignore` |
| Discord webhook URL (`notify.discord`) | Local JSON | **Confidential** (anyone who has it can post to the channel) | Don't commit JSON with real webhooks; examples use `null` |
| ntfy topic (`notify.ntfy`) | Local JSON | **Confidential** (ntfy.sh topics are public: whoever guesses the name reads the notifications) | Use a hard-to-guess name; don't commit it |
| Notification text | ntfy.sh / Discord | **Internal** | Only bot status (species, level, EVs); characters are filtered before sending |
| TID / SID and seeds of a specific save | Player's PC | **Internal** | Not committed: examples use neutral values (TID 12345 / SID 54321) |
| Logs (`logs/*.txt`), locks (`*.lock`, `*.flag`) | Script folder | **Internal** | Generated; ignored by git |
| Recorded routes (`FRLG_TrainRoute*.txt`) | Script folder | **Public** | Map coordinates only; the ones in `trainbot/examples/routes/` are shared on purpose |
| Configuration (`*.json`) | Script folder | **Internal** | Examples are public; personal ones may contain `notify` |
| Game data (species, moves tables…) | `shinybot/src/tables2.lua`, `trainbot/src/train_tables.lua` | **Public** | Derived from pret/pokefirered and Devon Studios (see [credits](credits.md)) |

**Levels:** Public < Internal < Confidential < Restricted.

## Cross-cutting requirements
- No Restricted data enters the repository: `.gitignore` enforces it and every PR is
  reviewed for it (see [CONTRIBUTING](../../CONTRIBUTING.md)).
- Notifications are sent over HTTPS (curl to `https://ntfy.sh/…` and to the webhook's `https://` URL).
- There is no third-party personal data: the project collects nothing from other users.
