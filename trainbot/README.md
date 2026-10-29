# Train Bot — `FRLG_TrainBot.lua`

Entrena al **primer Pokémon del equipo** hasta unos EVs exactos y/o un nivel: elige contra
quién pelear, usa el ataque que más daño hace, aprende los ataques que quieras y vuelve
solo al Centro Pokémon a curarse.

## Uso

1. Copia `FRLG_TrainBot.lua` y un JSON (el de esta carpeta o uno de [`examples/configs/`](examples/configs/))
   con el nombre `FRLG_TrainBot.json`.
2. Pon al Pokémon que vas a entrenar **primero en el equipo**.
3. Ten una ruta al Centro Pokémon:
   - **Usa una ya grabada** de [`examples/routes/`](examples/routes/) (Cueva Diglett →
     Velocidad, Torre Pokémon → At. Esp.), o
   - **graba la tuya** (una vez): **6** en el punto de entreno → camina hasta quedar frente
     a la enfermera (o dentro de la zona que cura con `"healMode": "tile"`) → **6** →
     vuelve al punto → **6**.
4. Pulsa **7** para iniciar.

| Tecla | Acción |
|---|---|
| **6** | Grabar la ruta al Centro (ida y vuelta) |
| **7** | Iniciar / detener |
| **8** | Ficha completa: stats, IVs, EVs, ataques |
| **9** | Panel: compacto, completo u oculto |
| **0** | Recargar el JSON (con el bot detenido) |

## Configuración

`FRLG_TrainBot.json`, comentado línea por línea:

- **Objetivo:** `evs`, `targetLevel`, `maxLevel`, `allowOvershoot`.
- **Rivales:** `species` (solo estas), `avoidSpecies` (nunca estas).
- **Combate:** `healBelow`, `fleeBelow`, `minPP`.
- **Ataques:** `learnMoves` (`auto`, `never`, `ask`), `wantedMoves`, `keepMoves`, `askTimeout`.
- **Otros:** `evolve`, `stopOnShiny`, `healMode` (`nurse` o `tile`), `routeFile`.
- **Avisos al celular:** `notify` con ntfy o un webhook de Discord.

La referencia completa está en [docs/02-design/api-contracts.md](../docs/02-design/api-contracts.md).

## Ejemplos

- [`examples/configs/`](examples/configs/): configuraciones listas por estadística
  (Velocidad en la Cueva Diglett, At. Esp. en la Torre Pokémon).
- [`examples/routes/`](examples/routes/): rutas listas para reutilizar.
