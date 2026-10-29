# RNG tools

They search the **whole** Gen 3 RNG cycle (2^32 states) for targets for your save file
(your TID/SID), and then for the initial seeds that reach them. The resulting seeds go in
the Shiny Bot's `initialSeeds` (Initial seed mode).

| File | What it does |
|---|---|
| `static_perfect_positions.py` | The 6×31 Method 1 positions and whether they are shiny for your save: `python static_perfect_positions.py <TID> <SID>` |
| `static_search.c` | Method 1 (statics/gifts): shiny + nature + minimum IVs. Compile with `-DTID -DSID`; edit natures and filter |
| `wild_h1_search.c` | Wild Method H-1: shiny + nature + IVs + valid slot. Configured with `-DTID -DSID -DNAT1 -DNAT2 -DMASK` and `IV_OK` |
| `seeds_near_target.py` | Initial seeds (16 bits) that reach a state: `python seeds_near_target.py <state_hex> [max]` |
| `ev_spots.py` | Best places to train each EV (downloads the pokefirered tables) |

Example: a shiny Timid or Modest Gastly in the Pokémon Tower (use your TID and SID):
```
gcc -O2 -o wild wild_h1_search.c -DTID=12345 -DSID=54321 -DNAT1=10 -DNAT2=15 -DMASK=0xD7F
./wild | sort -k4,4nr | head
python seeds_near_target.py <initial state of the chosen row>
```
Nature indexes are `PID % 25`: 3 Adamant, 10 Timid, 13 Jolly, 15 Modest, 23 Careful
(order: Hardy, Lonely, Brave, Adamant, Naughty, Bold, Docile, Relaxed, Impish, Lax, Timid,
Hasty, Serious, Jolly, Naive, Modest, Mild, Quiet, Bashful, Rash, Calm, Gentle, Sassy,
Careful, Quirky).
