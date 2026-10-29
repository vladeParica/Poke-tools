# Herramientas de RNG

Buscan objetivos en **todo** el ciclo del RNG de Gen 3 (2^32 estados) para tu partida
(tu TID/SID) y luego las semillas iniciales que llegan a ellos. Las semillas que salgan
van en `initialSeeds` del Shiny Bot (modo Semilla inicial).

| Archivo | Qué hace |
|---|---|
| `static_perfect_positions.py` | Las posiciones 6×31 de Method 1 y si son shiny para tu partida: `python static_perfect_positions.py <TID> <SID>` |
| `static_search.c` | Method 1 (estáticos/regalos): shiny + naturaleza + IVs mínimos. Compila con `-DTID -DSID`; edita naturalezas y filtro |
| `wild_h1_search.c` | Salvajes Method H-1: shiny + naturaleza + IVs + slot válido. Se configura con `-DTID -DSID -DNAT1 -DNAT2 -DMASK` e `IV_OK` |
| `seeds_near_target.py` | Semillas iniciales (16 bits) desde las que se llega a un estado: `python seeds_near_target.py <estado_hex> [max]` |
| `ev_spots.py` | Mejores zonas para entrenar cada EV (descarga las tablas de pokefirered) |

Ejemplo: un Gastly shiny Timid o Modest en la Torre Pokémon (pon tu TID y SID):
```
gcc -O2 -o wild wild_h1_search.c -DTID=12345 -DSID=54321 -DNAT1=10 -DNAT2=15 -DMASK=0xD7F
./wild | sort -k4,4nr | head
python seeds_near_target.py <estado_inicial de la fila elegida>
```
Los índices de naturaleza son `PID % 25`: 3 Adamant, 10 Timid, 13 Jolly, 15 Modest,
23 Careful (orden: Hardy, Lonely, Brave, Adamant, Naughty, Bold, Docile, Relaxed,
Impish, Lax, Timid, Hasty, Serious, Jolly, Naive, Modest, Mild, Quiet, Bashful, Rash,
Calm, Gentle, Sassy, Careful, Quirky).
