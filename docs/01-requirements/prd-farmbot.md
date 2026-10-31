# PRD — Farm Bot

> **AI-DLC phase:** `01-requirements`  ·  **Status:** approved
> **Author:** vladeParica  ·  **Date:** 2026-10-29

## 1. Problem
Players spend hours repeating the same loops to collect items, level up a team or make
money. The existing bots don't cover it: the Shiny Bot only searches and the Train Bot
targets EVs. The owner wants a **separate script** that farms, without touching the other
two bots.

## 2. Actors
- **Player**: configures `FRLG_FarmBot.json`, records the routes, positions the character.
- **Farm Bot** (`farmbot/FRLG_FarmBot.lua`, a single instance).
- Optional notification service (ntfy / Discord), as in the Train Bot.

## 3. Modes and main flows
All modes walk in the grass (or along a route), fight with the Train Bot's battle engine
(best move, move learning, evolution, healing trips) and stop at their goal.

| Mode (`mode`) | What it farms | Loop |
|---|---|---|
| `nivel` | Experience | Fight every wild Pokémon (except `avoidSpecies`) until the first party Pokémon reaches `targetLevel` |
| `objetos` | Items from **Pickup** | Defeat wild Pokémon (Pickup only triggers on a win). When the Pickup Pokémon are holding items, take them to the bag through the party menu |
| `robar` | Items wild Pokémon hold | Read the wild Pokémon's held item; if it's wanted and the lead holds nothing, use Thief/Covet, then run. Take the stolen item to the bag |
| `dinero` | Money from trainers | Use the VS Seeker (registered on SELECT) when charged, walk the recorded trainer route so rematch trainers see the player, win the battles, repeat |

Taking items (`objetos`, `robar`): START → POKéMON → each Pokémon holding an item →
ITEM → TAKE → back to the field. Every step is checked against game memory; success is
confirmed by the held item disappearing from the party data.

## 4. Business rules (from the game code, pret/pokefirered)
- Pickup: after a **won** battle, each party Pokémon with Pickup that holds nothing has a
  10% chance to get an item (fixed table in FRLG). Running away gives nothing.
- Wild held items: 50% common item, 5% rare item (100% if both are the same).
- Thief/Covet only steal if the attacker holds nothing and the target isn't Sticky Hold.
- Money and bag quantities are stored XOR the save's encryption key.
- VS Seeker: usable when its charge (SaveBlock1 + 0x638, low byte) is 100; every step
  adds 1; leaving the map resets rematches.
- Trainer battles can't be fled.

## 5. Edge, abuse and risk scenarios
| Scenario | Expected behavior |
|---|---|
| Game version without verified menu addresses (EUR, JPN) | Taking items falls back to pausing and notifying the player |
| The bag pocket is full, so TAKE fails | The held item is still there after the attempt: stop with a message |
| Menu navigation gets lost (unexpected screen) | Back out with B, retry once, then stop with a message |
| A Pickup/Thief Pokémon is not in the party | `objetos`/`robar` refuse to start and explain why |
| No Thief or Covet on the lead in `robar` | Refuse to start |
| Wild Pokémon holds nothing wanted | Run immediately |
| Thief misses or the target has Sticky Hold | Retry up to 3 times, then run |
| The lead faints in a trainer battle | Stop: the player finishes the battle |
| VS Seeker not registered on SELECT or not in the bag | `dinero` refuses to start |
| VS Seeker not charged yet | Walk back and forth until the charge reaches 100 |
| "No trainers in range" | Close the message and walk the route anyway; count the lap |
| Shiny wild Pokémon | Pause (`stopOnShiny`), as in the Train Bot |
| Two farm bots, or farm bot + train bot in two windows | Lock file stops the second instance |

## 6. Acceptance criteria
- [ ] Each mode reaches its goal in the simulator (level, item count, money).
- [ ] Taking items empties the held items and adds them to the bag in the simulator, and
      stops cleanly when the bag is full.
- [ ] Thief is only used on wanted held items, then the bot runs.
- [ ] Trainer battles are never fled; the VS Seeker is used only when charged.
- [ ] The Shiny Bot and Train Bot tests give the same results as before (nothing shared changed).
- [x] Double trainer battles in `dinero`: both Pokémon attack and the target is confirmed (simulator).
- [ ] Every mode tried by the owner in the real game.

## 7. Out of scope
- Catching Pokémon, Pay Day money, berries (FRLG has no berry planting).
- Healing with items or buying items.

## 8. Open decisions
- None.
