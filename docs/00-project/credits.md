# Créditos y fuentes

## Devon Studios — LuaScripts

La base de estos bots sale de [**DevonStudios/LuaScripts**](https://github.com/DevonStudios/LuaScripts)
(Devon Studios x Real.96, licencia GPL-3.0), una colección de scripts Lua para manipular
el RNG en los juegos de Pokémon.

De [`Gen 3/VBA/FRLG_RNG_2.0.lua`](https://github.com/DevonStudios/LuaScripts/blob/main/Gen%203/VBA/FRLG_RNG_2.0.lua)
y [`Gen 3/VBA/E_RNG_2.0.lua`](https://github.com/DevonStudios/LuaScripts/blob/main/Gen%203/VBA/E_RNG_2.0.lua)
tomamos las direcciones de memoria base, la lectura del frame y de la semilla inicial, y
las tablas de nombres (especies, naturalezas, ataques).

En ese repo hay más scripts que pueden servir para próximas funciones:

| Script | Para qué |
|---|---|
| `Side Beta/Gen3/FRLG_Pickup_RNG.lua` | RNG de Recogida (objetos) en FRLG |
| `Side Beta/Gen3/FRLG_Critical_Hit_RNG.lua` | RNG de golpes críticos en FRLG |
| `Gen 3/BizHawk/FRLG_RNG_2.0_BizHawk.lua` | Versión para BizHawk |
| `Gen 3/VBA/RS_RNG_2.0.lua`, `E_RNG_2.0.lua` | Rubí/Zafiro y Esmeralda |
| `Gen 3/VBA/Side/` | Pokérus, Feebas, lotería, Isla Espejismo (RSE) |

## pret/pokefirered

[pret/pokefirered](https://github.com/pret/pokefirered) es la decompilación de Rojo Fuego.
De ahí salen los símbolos de memoria (`gBattleMons`, `gMain`…), los opcodes de los scripts
de combate y las tablas que genera `trainbot/tools/gen_tables.py` (estadísticas base, EVs
que da cada especie, ataques por nivel, encuentros por zona).
