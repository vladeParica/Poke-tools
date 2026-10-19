# FRLG Bots — Rojo Fuego / Verde Hoja

Scripts Lua para **VBA-rr** (VBA-ReRecording) que automatizan la caza de shinies
con manipulación del RNG y el entrenamiento de EVs y nivel en **Pokémon Rojo Fuego
y Verde Hoja** (Game Boy Advance).

| Bot | Para qué |
|---|---|
| [`shinybot/`](shinybot/) — **FRLG_ShinyBot.lua** | Cazar shinies y Pokémon perfectos: a ciegas o con RNG exacto (estáticos, regalos, roamers, salvajes), elegir semilla inicial y SID en partida nueva |
| [`trainbot/`](trainbot/) — **FRLG_TrainBot.lua** | Entrenar EVs exactos y nivel: elige rivales y ataques, aprende los ataques que quieras, va solo al Centro Pokémon |

> Carga **un solo script a la vez** y en **una sola ventana de Lua**.

## Requisitos

- VBA-rr (con soporte Lua) y tu ROM de Rojo Fuego o Verde Hoja (no se incluye).
- En VBA-rr: desactiva *Pause When Inactive* para que siga corriendo en segundo plano.

## Shiny Bot

1. Copia `shinybot/FRLG_ShinyBot.lua` y `shinybot/FRLG_ShinyBot.json` a una carpeta.
2. VBA-rr → *Tools → Lua Scripting → New Lua Script Window* → abre el `.lua` → *Run*.
3. Teclas: **7** iniciar/detener · **8** cambiar modo · **9** panel · **0** recargar el JSON.

Modos: Salvaje, Estático, Regalo, Roamer (soft reset a ciegas) · Estático/Regalo/Roamer
RNG · Salvaje RNG · Partida nueva (elegir TID/SID) · Semilla inicial (busca una semilla
del título y luego lanza el modo RNG). Para objetivos lejanos usa la **Tele Pokémon
registrada en SELECT**. Ejemplos de semillas en [`docs/semillas.md`](docs/semillas.md).

## Train Bot

1. Copia `trainbot/FRLG_TrainBot.lua` y un JSON (por ejemplo, de `trainbot/examples/`)
   con el nombre `FRLG_TrainBot.json`.
2. Pon al Pokémon que vas a entrenar **primero en el equipo**.
3. Graba la ruta al Centro (una vez): **6** en el punto de entreno → camina hasta quedar
   **frente a la enfermera** (o dentro de la zona que cura si usas `"healMode": "tile"`)
   → **6** → vuelve al punto → **6**. También puedes usar una ruta ya grabada de
   `trainbot/examples/routes/` (Cueva Diglett → Velocidad, Torre Pokémon → At. Esp.).
4. **7** para iniciar. **8** muestra la ficha completa (stats, IVs, EVs, ataques).

Lo que configuras en el JSON: `evs` objetivo, `targetLevel`, `species` (contra quién
pelear), `wantedMoves`/`keepMoves`/`learnMoves`, `evolve`, `healMode`, `notify`
(avisos al celular con ntfy o Discord). Cada opción está comentada en el JSON.

## Para desarrollar

- Edita `*/src/*` y genera los scripts: `python shinybot/build.py`, `python trainbot/build.py`.
- Pruebas en simulador (necesitas `pip install lupa`): ver `shinybot/tests/` y `trainbot/tests/`.
- Herramientas de búsqueda de RNG: [`tools/rng/`](tools/rng/).
- Contexto técnico completo: [`CLAUDE.md`](CLAUDE.md).

## Créditos

### Devon Studios — LuaScripts

La base de estos bots sale de [**DevonStudios/LuaScripts**](https://github.com/DevonStudios/LuaScripts)
(Devon Studios x Real.96, licencia GPL-3.0), una colección de scripts Lua para manipular
el RNG en los juegos de Pokémon.

- De [`Gen 3/VBA/FRLG_RNG_2.0.lua`](https://github.com/DevonStudios/LuaScripts/blob/main/Gen%203/VBA/FRLG_RNG_2.0.lua)
  y [`Gen 3/VBA/E_RNG_2.0.lua`](https://github.com/DevonStudios/LuaScripts/blob/main/Gen%203/VBA/E_RNG_2.0.lua)
  tomamos las direcciones de memoria base, la lectura del frame y la semilla inicial,
  y las tablas de nombres (especies, naturalezas, ataques).

En ese repo hay más scripts que pueden servir para próximas funciones:

| Script | Para qué |
|---|---|
| `Side Beta/Gen3/FRLG_Pickup_RNG.lua` | RNG de Recogida (objetos) en FRLG |
| `Side Beta/Gen3/FRLG_Critical_Hit_RNG.lua` | RNG de golpes críticos en FRLG |
| `Gen 3/BizHawk/FRLG_RNG_2.0_BizHawk.lua` | Versión para BizHawk |
| `Gen 3/VBA/RS_RNG_2.0.lua`, `E_RNG_2.0.lua` | Rubí/Zafiro y Esmeralda |
| `Gen 3/VBA/Side/` | Pokérus, Feebas, lotería, Isla Espejismo (RSE) |

### Otros

- Datos del juego: [pret/pokefirered](https://github.com/pret/pokefirered).
