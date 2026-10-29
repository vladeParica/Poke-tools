# Security

## Scope
The bots run on your PC with your permissions: they create folders and, if you configure
`notify`, run `curl` to send notifications. The full analysis is in the
[threat model](docs/02-design/threat-model.md).

## Recommendations for users
- Only download the scripts from this repository, and review any third-party `.lua`
  before loading it in VBA-rr: a Lua script can run commands on your PC.
- Your Discord webhook and your ntfy topic are **secrets**: don't publish them or commit
  your JSON with them. If a webhook leaks, delete it in Discord and create a new one.
- Use a long, hard-to-guess ntfy topic.

## Reporting a vulnerability
Don't open a public issue. Use
[**Report a vulnerability**](https://github.com/vladeParica/Poke-tools/security/advisories/new)
in the repository's *Security* tab, with steps to reproduce it.
