# Ready-to-use training routes

Routes recorded with the Train Bot's **6** key. They work for any Pokémon and any save
file (FRLG USA or EUR), as long as you start **from the same training spot**.

| File | EVs | Training spot | Healing | `healMode` | Example JSON |
|---|---|---|---|---|---|
| `FRLG_TrainRoute_Diglett.txt` | Speed (Diglett +1, Dugtrio +2) | Diglett's Cave B1F, Route 11 side | Vermilion City Pokémon Center | `nurse` | `../configs/FRLG_TrainBot_Speed_Diglett.json` |
| `FRLG_TrainRoute_Tower.txt` | Sp. Atk (Gastly +1, Haunter +2) | Pokémon Tower, two floors above 5F | 5F purified zone | `tile` | `../configs/FRLG_TrainBot_SpAtk_Tower.json` |

## How to use them

1. Copy the `.txt` next to `FRLG_TrainBot.lua` (keep the file name).
2. In your `FRLG_TrainBot.json`, set `"routeFile"` to that name and the `healMode` from
   the table. To fight only the Pokémon that give those EVs, use `"species"`
   (for example `["Diglett", "Dugtrio"]`).
3. Go to one of the starting points (see below) and press **7**.

To see a route drawn map by map, or to check one you recorded, use *Ver ruta* in the
[configurator](../../../configurator/README.md).

## Where to start

You don't need to know the exact tile of the training spot. When you press **7**, the bot:

- **trains right there** if you are within 2 tiles of the training spot, on the same map;
- **walks to the training spot** if you are standing on any tile of the way back (`BACK`),
  facing any direction;
- **stops** with "El personaje no está en el punto de entreno" anywhere else.

The easiest is to start where you heal, which is the first step of `BACK`:

| Route | Start here |
|---|---|
| Diglett | Vermilion City Pokémon Center, **in front of the nurse** (map 9.1, tile 14,11) |
| Tower | Pokémon Tower 5F, **inside the purified zone** (map 1.92, tile 19,16) |

To see your position, press **9** until the diagnostics panel: the `Pos` line shows
`group.map (x,y)` with the same coordinates as the route file.

## Format

Two lines, `GO` (training spot → healing) and `BACK` (healing → training spot). Each step
is `group map x y direction`, separated by `;`. Coordinates are memory coordinates (map
tile + 7). On load, the bot removes the bogus steps recorded at doors (`cleanRoute`).

Paths:

- **Diglett:** B1F (1-37, x86 y77) → south exit (1-38) → Route 11 (3-29) → Vermilion City
  (3-5) → Pokémon Center (9-1), in front of the nurse.
- **Tower:** map 1-94 (x17 y21) → 1-93 → 1-92 (5F), to x19 y16, inside the healing zone.

## Adding a route

Record yours with the **6** key (see the [Train Bot README](../../README.md)), rename it
`FRLG_TrainRoute_<Place>.txt`, copy it here and add a row to the table.
